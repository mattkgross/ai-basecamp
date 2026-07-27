#!/usr/bin/env bash
# lint-docs.sh — Validate documentation health for the harness.
#
# Stack-neutral by design: no assumptions about language, framework, or vendor.
# Every project-specific knob lives in the CONFIG block below — tune that block
# when you fork, and you should never need to touch the check bodies.
#
# Exit codes: 0 = all pass or warn-only, 1 = any failure.
#
# Flags:
#   --session-start  Fast path — branch hygiene + the context-budget line only.
#                    Wired to the SessionStart hook. Implies --quiet.
#   --quiet          Errors only. Used by pre-commit and scripts/check.sh.
#   --fix            Auto-create missing required directories.
#   --budget         Print the context-budget diagnostic and exit without
#                    running checks.
#
# Stack-specific guards that cannot live in a neutral template — database
# migration invariants, package-manager override enforcement, CI env-var
# coverage — are documented as copy-paste recipes in docs/harness/recipes.md.
# Paste the ones your stack needs.

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# CONFIG — everything a fork needs to tune lives here.
# ═══════════════════════════════════════════════════════════════════════════

# --- Check 1: files that must exist. Add yours as they land; remove a row when
# the file's role moves elsewhere. A missing required file is a failure.
REQUIRED_FILES=(
  "AGENTS.md"
  "CLAUDE.md"
  "ARCHITECTURE.md"
  "docs/patterns/README.md"
  "docs/decisions/OPEN.md"
)

# --- Check 2: directories that must exist (`--fix` creates them).
REQUIRED_DIRS=(
  "docs/exec-plans/active"
  "docs/exec-plans/completed"
  "docs/exec-plans/planned"
  "docs/exec-plans/debt"
  "docs/decisions"
)

# --- Check 3: where source lives, and which file extensions to scan for stale
# path references in comments and docstrings. Only applies if SOURCE_DIR exists.
SOURCE_DIR="src"
SOURCE_EXTENSIONS="ts|tsx|js|jsx|py|go|rs|rb|java|cs|kt|swift|php|md"

# Path prefixes that make a backticked string in a doc a *canonical path claim*
# worth resolving. Add your source directory — `src/|lib/|app/` — once your docs
# start citing source files, which is when this check earns the most. It is
# omitted by default only because this template's own docs cite example paths
# that exist in a real project and not here.
XREF_PREFIXES='docs/|scripts/|\.claude/|\.codex/|\.github/|\.agents/'

# Files excluded from the cross-reference scan. A changelog necessarily names
# paths that were deliberately REMOVED — those are historical record, not live
# pointers, and "fixing" them would falsify the log. Same reasoning as the
# historical-plan exclusions below. Keep this list very short: every entry is a
# file where stale paths can now accumulate unseen.
XREF_EXCLUDE_PATHS=(':!CHANGELOG.md')

# --- Check 5: the auto-loaded agent guide. Budget it in BOTH lines and bytes.
# Bytes matter independently: one very long line (a dense status paragraph, a
# packed table row) can outweigh dozens of short ones, so a pure line cap reads
# "green" while real token cost balloons. ~4 bytes ≈ 1 token.
AGENTS_FILE="AGENTS.md"
AGENTS_LINE_CAP=200
AGENTS_BYTE_CAP=12000 # ~3k tokens.

# --- Check 5.5: soft caps for every other reachable doc.
DOC_LINE_CAP=800
DOC_BYTE_CAP=56000 # ~14k tokens.

# Docs exempt from the BYTE cap only (the line cap still applies). Use this for
# files whose access pattern is grep-a-section rather than read-the-whole-thing,
# or that carry their own budget elsewhere. Space-separated repo-relative paths.
DOC_BYTE_EXEMPT="docs/decisions/OPEN.md docs/decisions/RESOLVED.md"

# --- Check 4.5: the open-decision tracker. Kept pending-only so it stays cheap
# to load; closed rows move to RESOLVED.md.
OPEN_DECISIONS_FILE="docs/decisions/OPEN.md"
OPEN_DECISIONS_BYTE_CAP=40000 # ~10k tokens.

# --- Check 6: content that must never appear in docs/. Add patterns that
# signal copied or improperly-sourced material — vendor documentation you
# cannot republish, competitor content, regulated personal data. Keep this list
# short; false positives erode the signal. Empty = check passes trivially.
#   e.g. DENY_PATTERNS=( "copied from AcmeCorp" "pasted from" )
DENY_PATTERNS=()

# Paths excluded from the content scan. Research and competitive-analysis notes
# legitimately quote outside sources.
DENY_EXCLUDE_PATHS=(':!docs/research/*')

# --- Check 6.5: commands that must never run unattended. Scanned only in
# automated execution paths (CI workflow files, task-runner manifests) — docs
# that merely *describe* a command for a human are correctly out of scope.
# Pipe-separated regex. Empty = check passes trivially.
#   e.g. BANNED_AUTO_COMMANDS='terraform destroy|db push|--no-verify'
BANNED_AUTO_COMMANDS=''

# Task-runner manifests scanned for banned commands.
BANNED_AUTO_SCRIPT_FILES=("package.json" "Makefile" "justfile")

# --- Check 7: dead names. After a doc is renamed or relocated, prose mentions
# of the old name survive without a backticked path for Check 3 to catch. Make
# each pattern precise enough not to match incidental prose. Parallel arrays.
#   e.g. DEAD_NAME_PATTERNS=( 'old-name\.md|old-name §' )
#        DEAD_NAME_DESCS=( "'old-name' is dead — use 'docs/new-name.md'" )
DEAD_NAME_PATTERNS=()
DEAD_NAME_DESCS=()

# --- Check 8: directory names that count as a test suite.
TEST_DIRS=("tests" "test" "__tests__" "spec")

# --- Check 9: branch hygiene thresholds and default-branch resolution.
STALE_BRANCH_THRESHOLD=20
DEFAULT_BRANCH_CANDIDATES=("main" "master" "trunk")

# ═══════════════════════════════════════════════════════════════════════════
# END CONFIG — you should not need to edit below this line.
# ═══════════════════════════════════════════════════════════════════════════

QUIET=false
FIX=false
BUDGET=false
SESSION_START=false
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=true ;;
    --fix) FIX=true ;;
    --budget) BUDGET=true ;;
    # --session-start implies --quiet and short-circuits to the fast path.
    --session-start)
      SESSION_START=true
      QUIET=true
      ;;
    *)
      echo "✗ unknown flag: $arg" >&2
      exit 2
      ;;
  esac
done

# Recursive scans use `git grep` / `git ls-files` so .gitignore is honored for
# free (no build-output exclude lists to maintain) and BSD/macOS grep quirks stop
# mattering. Both require a git working tree.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "✗ lint-docs.sh must run inside a git repository" >&2
  exit 1
fi

# Two globs, deliberately. In a git pathspec `**` is not special without
# `:(glob)` magic, so `docs/**/*.md` requires at least one intervening path
# segment and silently skips root-level `docs/foo.md`. Pairing it with
# `docs/*.md` covers both depths. Depth-sensitive checks additionally filter with
# `awk -F/ 'NF==n'`, because a bare `*` in a pathspec DOES match `/`.
DOC_GLOBS=('docs/*.md' 'docs/**/*.md')

# Historical plans are frozen artifacts — their decisions were tracked when they
# were live, and rewriting them to satisfy today's lint would falsify the record.
HISTORICAL_EXCLUDES=(
  ':!docs/exec-plans/completed/*'
  ':!docs/exec-plans/debt/*'
  ':!docs/exec-plans/planned/*'
)

PASS=0
WARN=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  $QUIET || echo "  ✓ $1"
}
warn() {
  WARN=$((WARN + 1))
  echo "  ⚠ $1"
}
fail() {
  FAIL=$((FAIL + 1))
  echo "  ✗ $1"
}

# Strip the leading whitespace BSD `wc` emits.
bytes_of() { wc -c <"$1" | tr -d ' '; }
lines_of() { wc -l <"$1" | tr -d ' '; }

# ── Shared helpers ─────────────────────────────────────────────────────────
# Defined once, used by both the session-start fast path and the full run.

# Resolve the repository's default branch instead of hardcoding one. Prefers the
# remote's advertised HEAD, then falls back to well-known local names. A template
# cannot assume `main` or `master`, and a fork should not have to patch this
# script to get working branch hygiene.
resolve_default_branch() {
  local ref candidate
  ref=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  if [[ -n "$ref" ]]; then
    echo "${ref#origin/}"
    return
  fi
  for candidate in "${DEFAULT_BRANCH_CANDIDATES[@]}"; do
    if git rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return
    fi
  done
  echo ""
}

# Branch hygiene: uncommitted-work and stale-base signals. Genuinely session-
# local — meaningless in CI on a detached PR checkout — so it is the core of the
# session-start fast path as well as a check in the full run. Warn-only: these
# are orientation cues for the agent and the human, not gates.
run_branch_hygiene() {
  $QUIET || echo "== Branch hygiene =="
  local current default base behind dirty_count
  current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  default=$(resolve_default_branch)

  [[ -z "$current" || "$current" == "HEAD" ]] && return 0
  # "Behind the default branch" is meaningless while standing on it.
  [[ -n "$default" && "$current" == "$default" ]] && return 0

  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    dirty_count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    warn "Working tree has $dirty_count uncommitted change(s) on $current — review before starting new work"
  else
    pass "Working tree clean on $current"
  fi

  [[ -z "$default" ]] && return 0
  # Prefer the remote ref: a local default branch can itself be stale, which
  # would report a stale base as fresh.
  if git rev-parse --verify --quiet "origin/$default" >/dev/null 2>&1; then
    base="origin/$default"
  elif git rev-parse --verify --quiet "$default" >/dev/null 2>&1; then
    base="$default"
  else
    return 0
  fi
  behind=$(git rev-list --count "HEAD..$base" 2>/dev/null || echo 0)
  if [[ $behind -gt $STALE_BRANCH_THRESHOLD ]]; then
    warn "$current is $behind commits behind $base (threshold: $STALE_BRANCH_THRESHOLD) — rebase before starting new work"
  else
    pass "$current within $STALE_BRANCH_THRESHOLD commits of $base ($behind behind)"
  fi
}

# Tally plus, when quiet and clean, the one-line context-budget cue the agent
# reads at session start. LENGTH_OVER is set by Check 5.5 and defaults to 0 when
# that check did not run (the fast path), so the "N doc(s) over cap" suffix never
# appears there. That is deliberate: the full run is the authority on doc length.
print_summary() {
  echo ""
  echo "== Summary: $PASS passed, $WARN warnings, $FAIL failures =="
  if $QUIET && [[ $FAIL -eq 0 && -f "$AGENTS_FILE" ]]; then
    local lines bytes over_msg=""
    lines=$(lines_of "$AGENTS_FILE")
    bytes=$(bytes_of "$AGENTS_FILE")
    if [[ ${LENGTH_OVER:-0} -gt 0 ]]; then
      over_msg=" · $LENGTH_OVER doc(s) over cap"
    fi
    echo "harness OK · $AGENTS_FILE auto-load $lines lines / ~$((bytes / 4)) tokens${over_msg} (run /harness-check --budget for details)"
  fi
}

# ── Budget diagnostic ──────────────────────────────────────────────────────
# Tracks token economy over time. Exits without running validation.
if $BUDGET; then
  echo "== Context budget =="
  if [[ -f "$AGENTS_FILE" ]]; then
    b=$(bytes_of "$AGENTS_FILE")
    echo "  Auto-load ($AGENTS_FILE): $(lines_of "$AGENTS_FILE") lines · $b bytes (~$((b / 4)) tokens)"
  fi
  echo ""
  echo "  Largest reachable docs (excludes historical plans, research, legal):"
  git ls-files "${DOC_GLOBS[@]}" \
    "${HISTORICAL_EXCLUDES[@]}" ':!docs/research/*' ':!docs/legal/*' \
    2>/dev/null | xargs -I{} wc -c {} 2>/dev/null |
    sort -rn | head -8 |
    awk '{ printf "    %7d bytes (~%5d tokens)  %s\n", $1, $1 / 4, $2 }'
  echo ""
  echo "  Skills:"
  if compgen -G ".agents/skills/*/SKILL.md" >/dev/null; then
    wc -l .agents/skills/*/SKILL.md 2>/dev/null |
      sort -rn | head -10 |
      awk '$2 != "total" { printf "    %5d  %s\n", $1, $2 }'
  else
    echo "    (none)"
  fi
  exit 0
fi

# ── Session-start fast path ────────────────────────────────────────────────
# The SessionStart hook needs a sub-second orientation signal, not the full
# repo-health suite. The heavy checks ARE repo health, and repo health is already
# gated in CI and pre-commit — re-running it on every session start is redundant.
# It is also pathologically slow on some platforms: the per-line post-processing
# loops fork several subprocesses per match, so a few thousand matches becomes
# minutes of wall time on Windows Git Bash. Session start therefore runs only the
# genuinely session-local signals.
if $SESSION_START; then
  run_branch_hygiene
  print_summary
  # Unreachable while branch hygiene is warn-only; kept correct in case a
  # fail()-emitting check ever joins the fast path.
  [[ $FAIL -gt 0 ]] && exit 1
  exit 0
fi

# ── Check 1: Required files exist ──────────────────────────────────────────
$QUIET || echo "== Required files =="
for f in "${REQUIRED_FILES[@]}"; do
  # -e not -f: CLAUDE.md is conventionally a symlink to AGENTS.md.
  if [[ -e "$f" ]]; then
    pass "$f exists"
  else
    fail "$f missing"
  fi
done

# ── Check 1.5: Agent-guide aliasing ────────────────────────────────────────
# Different agent runtimes look for different filenames (CLAUDE.md, AGENTS.md,
# GEMINI.md). Maintaining them as separate files means maintaining the same
# content twice, and it drifts — silently, because nothing compares them. A
# symlink makes drift structurally impossible.
#
# Warn, never fail: Windows checkouts without developer mode or
# `core.symlinks=true` materialize symlinks as plain text files, and a template
# must not be unusable there. A fork that keeps real files should keep the
# duplicated content to an absolute minimum.
$QUIET || echo "== Agent-guide aliasing =="
if [[ -L "CLAUDE.md" ]]; then
  target=$(readlink "CLAUDE.md")
  if [[ "$target" == "$AGENTS_FILE" ]]; then
    pass "CLAUDE.md → $AGENTS_FILE (drift structurally impossible)"
  else
    warn "CLAUDE.md is a symlink to '$target', not '$AGENTS_FILE' — intended?"
  fi
elif [[ -f "CLAUDE.md" ]]; then
  warn "CLAUDE.md is a regular file, so it can drift from $AGENTS_FILE — prefer 'ln -sf $AGENTS_FILE CLAUDE.md' (expected on Windows checkouts without symlink support; keep duplicated content minimal)"
fi

# ── Check 2: Required directories exist ────────────────────────────────────
$QUIET || echo "== Required directories =="
for d in "${REQUIRED_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    pass "$d/ exists"
  elif $FIX; then
    mkdir -p "$d"
    touch "$d/.gitkeep"
    warn "$d/ created (--fix)"
  else
    fail "$d/ missing (use --fix to create)"
  fi
done

# ── Check 3: Cross-reference integrity ─────────────────────────────────────
# Every path a doc names must resolve. This is the highest-value check here:
# stale paths are how an agent gets sent to a file that no longer exists, and
# they accumulate invisibly because nothing else reads prose.
$QUIET || echo "== Cross-reference integrity =="
XREF_ERRORS=0

# 3a — Markdown links: [text](path) with a relative filesystem target.
while IFS= read -r line; do
  file=${line%%:*}
  path=$(echo "$line" | grep -oE '\]\([^)]+\)' | head -1 | sed 's/^](//;s/)$//')
  [[ -z "$path" || "$path" == http* || "$path" == mailto* || "$path" == "#"* ]] && continue
  path="${path%%#*}"  # strip anchor
  path="${path%% §*}" # strip section pointer
  [[ -z "$path" ]] && continue
  dir=$(dirname "$file")
  if [[ ! -e "$dir/$path" && ! -e "$path" ]]; then
    fail "Broken link in $file → $path"
    XREF_ERRORS=$((XREF_ERRORS + 1))
  fi
done < <(git grep -nE '\]\([^)]+\)' -- '*.md' "${HISTORICAL_EXCLUDES[@]}" "${XREF_EXCLUDE_PATHS[@]}" 2>/dev/null || true)

# 3b — Backticked paths that look canonical. Loop over EVERY match on the line,
# not just the first: a single sentence often names two paths, and checking only
# the first lets a stale second reference hide indefinitely.
while IFS= read -r line; do
  file=${line%%:*}
  while IFS= read -r raw; do
    [[ -z "$raw" ]] && continue
    path="${raw#\`}"
    path="${path%\`}"
    # A glob documents structure rather than naming a file.
    [[ "$path" == *"*"* ]] && continue
    # Brace expansion is shorthand for a set — `docs/x/{a,b}/` names no one file.
    [[ "$path" == *"{"* ]] && continue
    # Template placeholders — `docs/decisions/NNNN-slug.md`, `docs/<topic>/`.
    [[ "$path" == *"NNNN"* || "$path" == *"<"* ]] && continue
    # A real path has no spaces; a match with one is a quoted command whose
    # arguments the regex swallowed up to the closing backtick.
    [[ "$path" == *" "* ]] && continue
    path="${path%% §*}"
    path="${path%%§*}"
    path="${path%.}"
    path="${path%,}"
    # Trailing :NNN is the clickable line-number convention — resolve the file.
    [[ "$path" =~ ^(.+):[0-9]+$ ]] && path="${BASH_REMATCH[1]}"
    if [[ ! -e "$path" ]]; then
      fail "Broken ref in $file → \`$path\`"
      XREF_ERRORS=$((XREF_ERRORS + 1))
    fi
  done < <(echo "$line" | grep -oE "\`($XREF_PREFIXES)[^\`]+\`" || true)
done < <(git grep -nE "\`($XREF_PREFIXES)[^\`]+\`" -- '*.md' "${HISTORICAL_EXCLUDES[@]}" "${XREF_EXCLUDE_PATHS[@]}" 2>/dev/null || true)

# 3c — Source-path references inside source files. Real imports go through the
# build system's resolution, so a literal source path in a source file is almost
# always a comment or docstring pointer — exactly the form that rots silently on
# a rename, because no compiler reads it.
if [[ -d "$SOURCE_DIR" ]]; then
  while IFS= read -r line; do
    file=${line%%:*}
    # Drop the "file:lineno:" prefix first, or the filename itself (which starts
    # with the source dir) matches on every single line.
    content=$(echo "$line" | cut -d: -f3-)
    while IFS= read -r path; do
      [[ -z "$path" ]] && continue
      if [[ ! -e "$path" ]]; then
        fail "Broken source ref in $file → $path"
        XREF_ERRORS=$((XREF_ERRORS + 1))
      fi
    done < <(echo "$content" | grep -oE "$SOURCE_DIR/[a-zA-Z0-9_./-]+\.($SOURCE_EXTENSIONS)" || true)
  done < <(git grep -nE "$SOURCE_DIR/[a-zA-Z0-9_./-]+\.($SOURCE_EXTENSIONS)" -- "$SOURCE_DIR/*" 2>/dev/null || true)
fi

if [[ $XREF_ERRORS -eq 0 ]]; then
  pass "All cross-references resolve"
fi

# ── Check 4: Decision sync ─────────────────────────────────────────────────
# Every open-decision marker in docs/ must be tracked centrally, so the set of
# things awaiting a human call is discoverable in one cheap read instead of by
# grepping the whole doc tree. 🚧 = needs a human decision; ⏳ = decided in
# principle, waiting on an event. Ordinary TODO/FIXME comments are deliberately
# not elevated to decision-record status.
$QUIET || echo "== Decision sync =="
if [[ -f "$OPEN_DECISIONS_FILE" ]]; then
  MISSING_DECISIONS=0
  while IFS= read -r line; do
    file=${line%%:*}
    # The tracker and the decision records themselves are exempt.
    [[ "$file" == *"decisions/"* ]] && continue
    base=$(basename "$file" .md)
    # In a split doc every basename is "README" — fall back to the topic
    # directory so the tracker can name something meaningful.
    if [[ "$base" == "README" ]]; then
      base=$(basename "$(dirname "$file")")
    fi
    if ! grep -qiF "$base" "$OPEN_DECISIONS_FILE" 2>/dev/null; then
      warn "🚧/⏳ in $file may not be tracked in $OPEN_DECISIONS_FILE"
      MISSING_DECISIONS=$((MISSING_DECISIONS + 1))
    fi
  done < <(git grep -nE '🚧|⏳' -- "${DOC_GLOBS[@]}" "${HISTORICAL_EXCLUDES[@]}" 2>/dev/null || true)
  if [[ $MISSING_DECISIONS -eq 0 ]]; then
    pass "All 🚧/⏳ markers tracked in $OPEN_DECISIONS_FILE"
  fi
else
  fail "$OPEN_DECISIONS_FILE missing — cannot check decision sync"
fi

# ── Check 4.5: Open-decision tracker hygiene ───────────────────────────────
# The tracker is loaded often, so it has to stay cheap. Two guards:
#
#   (a) No resolved row left sitting in a pending table. Closing a decision in
#       place feels tidier than relocating it, so it is what everyone does — and
#       it is exactly how this file bloats, because a resolved row never gets
#       deleted either. Matching only TABLE ROWS (lines starting `| `) lets the
#       file's own header explain the rule without self-triggering.
#   (b) A BYTE budget, not a line cap. Each decision is one long table row, so a
#       line cap sees almost nothing: the file reads green at 150 lines while
#       costing thousands of tokens.
$QUIET || echo "== Open-decision tracker hygiene =="
if [[ -f "$OPEN_DECISIONS_FILE" ]]; then
  resolved_rows=$(grep -nE '^\| .*(✅ *Resolved|✅ *Done)' "$OPEN_DECISIONS_FILE" || true)
  if [[ -n "$resolved_rows" ]]; then
    while IFS= read -r r; do
      [[ -z "$r" ]] && continue
      warn "$OPEN_DECISIONS_FILE:${r%%:*} carries a resolved row — move it to docs/decisions/RESOLVED.md (this file is pending-only)"
    done <<<"$resolved_rows"
  else
    pass "$OPEN_DECISIONS_FILE carries no resolved-in-place rows"
  fi
  open_bytes=$(bytes_of "$OPEN_DECISIONS_FILE")
  if [[ $open_bytes -gt $OPEN_DECISIONS_BYTE_CAP ]]; then
    warn "$OPEN_DECISIONS_FILE is $open_bytes bytes / ~$((open_bytes / 4)) tokens (budget: $OPEN_DECISIONS_BYTE_CAP) — close stale rows to RESOLVED.md or tighten entries"
  else
    pass "$OPEN_DECISIONS_FILE is $open_bytes bytes (~$((open_bytes / 4)) tokens, budget $OPEN_DECISIONS_BYTE_CAP)"
  fi
fi

# ── Check 4.6: Decision-record numbers are unique ──────────────────────────
# Two branches each take "one higher than the highest record on disk", both land
# on the same number, and nothing catches it: the slugs differ, so the files
# merge cleanly with no conflict to resolve, and every other check passes because
# both files exist. The next author who scans the directory for the highest
# number is then misled about which slot is free.
#
# Records are NNNN-slug.md, so the 4-digit filter naturally skips OPEN.md and
# RESOLVED.md.
$QUIET || echo "== Decision-record number uniqueness =="
DUPLICATE_ADRS=0
while IFS= read -r dup; do
  [[ -z "$dup" ]] && continue
  files=$(git ls-files "docs/decisions/${dup}-*.md" | sed -E 's|.*/||' | tr '\n' ' ')
  fail "Decision-record number ${dup} is used by more than one file: ${files}— renumber the newer one to the next free number"
  DUPLICATE_ADRS=$((DUPLICATE_ADRS + 1))
done < <(git ls-files 'docs/decisions/*.md' 2>/dev/null |
  sed -E 's|.*/||' | grep -oE '^[0-9]{4}-' | tr -d '-' |
  sort | uniq -d)
if [[ $DUPLICATE_ADRS -eq 0 ]]; then
  pass "All decision-record numbers are unique"
fi

# ── Check 5: Agent-guide budget ────────────────────────────────────────────
# This file is loaded on every single session, so its weight is the one cost paid
# unconditionally. Keep it pointers, not content. Both caps warn.
$QUIET || echo "== Agent-guide budget =="
if [[ -f "$AGENTS_FILE" ]]; then
  lines=$(lines_of "$AGENTS_FILE")
  bytes=$(bytes_of "$AGENTS_FILE")
  if [[ $lines -gt $AGENTS_LINE_CAP ]]; then
    warn "$AGENTS_FILE is $lines lines (cap: $AGENTS_LINE_CAP)"
  else
    pass "$AGENTS_FILE is $lines lines (cap $AGENTS_LINE_CAP)"
  fi
  if [[ $bytes -gt $AGENTS_BYTE_CAP ]]; then
    warn "$AGENTS_FILE is $bytes bytes / ~$((bytes / 4)) tokens (budget: $AGENTS_BYTE_CAP) — move content to a doc and leave a pointer"
  else
    pass "$AGENTS_FILE is $bytes bytes (~$((bytes / 4)) tokens, budget $AGENTS_BYTE_CAP)"
  fi
fi

# ── Check 5.5: Doc length budget ───────────────────────────────────────────
# Soft caps on every reachable doc, in lines AND bytes for the reason given at
# AGENTS_BYTE_CAP. Active plans, decision records, legal docs, and research notes
# are exempt — they legitimately run long. Warn-only; a mature project can flip
# these to fail.
#
# Over cap is a signal to SPLIT (docs/<topic>/README.md as the routing index plus
# slice files, so consumers fetch a slice) or to ARCHIVE (age settled content
# into a history file the live doc points at) — not to write less.
$QUIET || echo "== Doc length budget =="
LENGTH_OVER=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  lines=$(lines_of "$f")
  if [[ $lines -gt $DOC_LINE_CAP ]]; then
    warn "$f is $lines lines (soft cap: $DOC_LINE_CAP) — split by topic or archive settled content"
    LENGTH_OVER=$((LENGTH_OVER + 1))
  fi
  case " $DOC_BYTE_EXEMPT " in *" $f "*) continue ;; esac
  doc_bytes=$(bytes_of "$f")
  if [[ $doc_bytes -gt $DOC_BYTE_CAP ]]; then
    warn "$f is $doc_bytes bytes / ~$((doc_bytes / 4)) tokens (soft byte cap: $DOC_BYTE_CAP) — long-line bloat the line cap cannot see"
    LENGTH_OVER=$((LENGTH_OVER + 1))
  fi
done < <(git ls-files "${DOC_GLOBS[@]}" \
  "${HISTORICAL_EXCLUDES[@]}" ':!docs/exec-plans/active/*' \
  ':!docs/research/*' ':!docs/legal/*' ':!docs/decisions/0*-*.md' \
  2>/dev/null || true)
if [[ $LENGTH_OVER -eq 0 ]]; then
  pass "All reachable docs under $DOC_LINE_CAP lines and $DOC_BYTE_CAP bytes"
fi

# ── Check 6: Content violations ────────────────────────────────────────────
$QUIET || echo "== Content violations =="
VIOLATIONS=0
for pattern in ${DENY_PATTERNS[@]+"${DENY_PATTERNS[@]}"}; do
  if git grep -qiE "$pattern" -- "${DOC_GLOBS[@]}" "${DENY_EXCLUDE_PATHS[@]}" 2>/dev/null; then
    fail "Content violation: '$pattern' found in docs/"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done
if [[ $VIOLATIONS -eq 0 ]]; then
  pass "No content violations detected"
fi

# ── Check 6.5: Banned commands in automated paths ──────────────────────────
# A hard rule like "never run this against a shared environment" applies to
# programmatic execution, not to documentation. Scanning only the paths where a
# command actually gets invoked is what keeps this check from fighting the docs
# that legitimately teach the command to a human.
$QUIET || echo "== Banned commands in automated paths =="
BANNED_FOUND=0
if [[ -n "$BANNED_AUTO_COMMANDS" ]]; then
  if [[ -d ".github/workflows" ]]; then
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      fail "Banned command in CI workflow: $match"
      BANNED_FOUND=$((BANNED_FOUND + 1))
      # Filter non-execution contexts: echoed strings, workflow annotations,
      # comment lines, and metadata value fields.
    done < <(git grep -nE "($BANNED_AUTO_COMMANDS)" -- '.github/workflows/*.yml' '.github/workflows/*.yaml' 2>/dev/null |
      grep -vE '(echo|::error|::warning|::notice|^[^:]+:[0-9]+:[[:space:]]*#|name:|with:|description:)' || true)
  fi
  for manifest in "${BANNED_AUTO_SCRIPT_FILES[@]}"; do
    [[ -f "$manifest" ]] || continue
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      fail "Banned command in $manifest: $match"
      BANNED_FOUND=$((BANNED_FOUND + 1))
    done < <(grep -nE "($BANNED_AUTO_COMMANDS)" "$manifest" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*#' || true)
  done
fi
if [[ $BANNED_FOUND -eq 0 ]]; then
  pass "No banned commands in automated execution paths"
fi

# ── Check 7: Dead-name drift ───────────────────────────────────────────────
$QUIET || echo "== Dead-name drift =="
DEAD_NAMES=0
for i in ${DEAD_NAME_PATTERNS[@]+"${!DEAD_NAME_PATTERNS[@]}"}; do
  pattern="${DEAD_NAME_PATTERNS[$i]}"
  desc="${DEAD_NAME_DESCS[$i]:-stale name}"
  matches=$(git grep -nE "$pattern" -- "${DOC_GLOBS[@]}" 2>/dev/null || true)
  if [[ -n "$matches" ]]; then
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      fail "Dead-name drift: $desc → $match"
      DEAD_NAMES=$((DEAD_NAMES + 1))
    done <<<"$matches"
  fi
done
if [[ $DEAD_NAMES -eq 0 ]]; then
  pass "No dead-name drift detected"
fi

# ── Check 7.5: Routing-table completeness ──────────────────────────────────
# The agent guide's routing table is the canonical entry point, so a doc absent
# from it is unreachable in practice — it exists, but no agent will find it.
# Match the full repo-relative path, not the basename: basename matching passes
# falsely whenever a longer listed path happens to contain it as a substring.
$QUIET || echo "== Routing-table completeness =="
INDEX_GAPS=0
if [[ -f "$AGENTS_FILE" ]]; then
  # Root-level docs (depth 2), then split-doc indexes (depth 3). Only the README
  # of a split doc needs routing — the slices hang off it.
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qF "$f" "$AGENTS_FILE" 2>/dev/null; then
      warn "$f not referenced in $AGENTS_FILE § Where to look"
      INDEX_GAPS=$((INDEX_GAPS + 1))
    fi
  done < <(git ls-files 'docs/*.md' 2>/dev/null | awk -F/ 'NF==2' || true)

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qF "$f" "$AGENTS_FILE" 2>/dev/null; then
      warn "$f (split-doc index) not referenced in $AGENTS_FILE § Where to look"
      INDEX_GAPS=$((INDEX_GAPS + 1))
    fi
  done < <(git ls-files 'docs/*/README.md' "${HISTORICAL_EXCLUDES[@]}" 2>/dev/null | awk -F/ 'NF==3' || true)
fi
if [[ $INDEX_GAPS -eq 0 ]]; then
  pass "All root docs and split-doc indexes are reachable from $AGENTS_FILE"
fi

# ── Check 7.6: Completed plans carry a retrospective ───────────────────────
# What actually shipped, what changed from the plan, and why is the highest-value
# paragraph in the repo — and the easiest to skip, because by the time a plan is
# done everyone has moved on. Without it the next plan's drift check has nothing
# to reconcile against, and the lessons live only in a chat log nobody can read.
#
# Escape hatch for supporting artifacts that live alongside plans (design briefs,
# interview transcripts, research notes): add `<!-- no-retrospective: reason -->`.
$QUIET || echo "== Completed-plan retrospectives =="
MISSING_RETROS=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  grep -q '<!-- *no-retrospective:' "$f" 2>/dev/null && continue
  if ! grep -qE '^## What actually shipped' "$f" 2>/dev/null; then
    warn "$f missing '## What actually shipped' — see docs/exec-plans/PLANNING.md § The retrospective (or mark it '<!-- no-retrospective: reason -->' if it is a supporting artifact)"
    MISSING_RETROS=$((MISSING_RETROS + 1))
  fi
done < <(git ls-files 'docs/exec-plans/completed/*.md' 2>/dev/null || true)
if [[ $MISSING_RETROS -eq 0 ]]; then
  pass "All completed plans carry a retrospective"
fi

# ── Check 8: Tests exist alongside source ──────────────────────────────────
if [[ -d "$SOURCE_DIR" ]]; then
  $QUIET || echo "== Tests alongside source =="
  found_tests=false
  for d in "${TEST_DIRS[@]}"; do
    if [[ -d "$d" ]]; then
      found_tests=true
      break
    fi
  done
  # Co-located tests are equally valid — only conclude "no suite" if neither
  # shape is present.
  if ! $found_tests && git ls-files "$SOURCE_DIR/*" 2>/dev/null | grep -qiE '(\.|_|-)(test|spec)\.'; then
    found_tests=true
  fi
  if $found_tests; then
    pass "Test suite found alongside $SOURCE_DIR/"
  else
    fail "$SOURCE_DIR/ exists but no test suite found (${TEST_DIRS[*]}/, or co-located *.test.* / *.spec.* files)"
  fi
fi

# ── Check 9: Branch hygiene ────────────────────────────────────────────────
run_branch_hygiene

# ── Summary ────────────────────────────────────────────────────────────────
print_summary

[[ $FAIL -gt 0 ]] && exit 1
exit 0
