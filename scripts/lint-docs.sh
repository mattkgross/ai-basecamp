#!/usr/bin/env bash
# lint-docs.sh — Validate doc health for the harness.
# Runs at session start (--quiet) and on /harness-check (full output).
#
# This is the ai-basecamp template version. When you fork this template,
# tune the project-specific bits (REQUIRED_FILES additions, content denylist,
# dead-name patterns, length-cap allowlist) for your project.
#
# Exit codes: 0 = all pass or warn-only, 1 = any fail.
# Flags:
#   --quiet  errors only (used by SessionStart hook).
#   --fix    auto-create missing dirs.
#   --budget print context-budget diagnostic and exit (does not run checks).

set -euo pipefail

QUIET=false
FIX=false
BUDGET=false
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=true ;;
    --fix) FIX=true ;;
    --budget) BUDGET=true ;;
  esac
done

# All recursive scans use `git grep` so .gitignore is honored automatically
# and we get BSD/macOS grep compatibility for free. Requires a git working tree.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "✗ lint-docs.sh must run inside a git repository" >&2
  exit 1
fi

# --- Budget diagnostic ---
# Prints the context-budget meter (auto-load lines + top reachable docs +
# skill sizes) and exits without running validation checks. Used by
# /harness-check --budget to track token-economy progress over time.
if $BUDGET; then
  echo "== Context budget =="
  if [[ -f AGENTS.md && -f CLAUDE.md ]]; then
    auto=$(($(wc -l < AGENTS.md) + $(wc -l < CLAUDE.md)))
    echo "  Auto-load (CLAUDE.md + AGENTS.md): $auto lines"
  fi
  echo ""
  echo "  Top 8 reachable docs by line count (excludes completed/debt/planned/research/legal):"
  git ls-files 'docs/**/*.md' \
    ':!docs/exec-plans/completed/*' ':!docs/exec-plans/debt/*' \
    ':!docs/exec-plans/planned/*' ':!docs/research/*' ':!docs/legal/*' \
    2>/dev/null | xargs -I{} wc -l {} 2>/dev/null \
    | sort -rn | head -8 \
    | awk '{ printf "    %5d  %s\n", $1, $2 }'
  echo ""
  echo "  Skills (.agents/skills/*/SKILL.md):"
  if compgen -G ".agents/skills/*/SKILL.md" >/dev/null; then
    wc -l .agents/skills/*/SKILL.md 2>/dev/null \
      | sort -rn | head -10 \
      | awk '$2 != "total" { printf "    %5d  %s\n", $1, $2 }'
  fi
  exit 0
fi

PASS=0
WARN=0
FAIL=0

pass() { PASS=$((PASS + 1)); $QUIET || echo "  ✓ $1"; }
warn() { WARN=$((WARN + 1)); echo "  ⚠ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

# --- Check 1: Required files exist ---
$QUIET || echo "== Required files =="
# Add project-specific required files here (e.g. docs/DESIGN.md, docs/PRODUCT.md)
# once they exist. Removing a row is the right call when the file's role moves.
REQUIRED_FILES=(
  "AGENTS.md"
  "CLAUDE.md"
  "ARCHITECTURE.md"
  "docs/PATTERNS.md"
  "docs/decisions/OPEN.md"
)
for f in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    pass "$f exists"
  else
    fail "$f missing"
  fi
done

# --- Check 2: Required dirs exist ---
$QUIET || echo "== Required directories =="
REQUIRED_DIRS=(
  "docs/exec-plans/active"
  "docs/exec-plans/completed"
  "docs/exec-plans/debt"
  "docs/exec-plans/planned"
  "docs/decisions"
)
for d in "${REQUIRED_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    pass "$d/ exists"
  else
    if $FIX; then
      mkdir -p "$d"
      warn "$d/ created (--fix)"
    else
      fail "$d/ missing (use --fix to create)"
    fi
  fi
done

# --- Check 3: Cross-reference integrity ---
$QUIET || echo "== Cross-reference integrity =="
XREF_ERRORS=0
while IFS= read -r line; do
  file=$(echo "$line" | cut -d: -f1)
  path=$(echo "$line" | grep -oE '\]\([^)]+\)' | head -1 | sed 's/^](//;s/)$//')
  [[ "$path" == http* || "$path" == mailto* || "$path" == "#"* || -z "$path" ]] && continue
  path="${path%%#*}"
  path="${path%% §*}"
  dir=$(dirname "$file")
  resolved="$dir/$path"
  if [[ ! -e "$resolved" && ! -e "$path" ]]; then
    fail "Broken link in $file → $path"
    XREF_ERRORS=$((XREF_ERRORS + 1))
  fi
done < <(git grep -nE '\]\([^)]+\)' -- '*.md' \
  ':!docs/exec-plans/completed/*' ':!docs/exec-plans/debt/*' ':!docs/exec-plans/planned/*' \
  2>/dev/null || true)

while IFS= read -r line; do
  file=$(echo "$line" | cut -d: -f1)
  path=$(echo "$line" \
    | grep -oE '`(docs/|scripts/|src/|\.claude/|\.github/|\.agents/)[^`]+`' \
    | head -1 | sed 's/^`//;s/`$//')
  [[ -z "$path" ]] && continue
  [[ "$path" == *"*"* ]] && continue
  path="${path%% §*}"
  path="${path%%§*}"
  path="${path%.}"
  path="${path%,}"
  if [[ ! -e "$path" ]]; then
    fail "Broken ref in $file → \`$path\`"
    XREF_ERRORS=$((XREF_ERRORS + 1))
  fi
done < <(git grep -nE '`(docs/|scripts/|src/|\.claude/|\.github/|\.agents/)[^`]+`' -- '*.md' \
  ':!docs/exec-plans/completed/*' ':!docs/exec-plans/debt/*' ':!docs/exec-plans/planned/*' \
  2>/dev/null || true)

if [[ $XREF_ERRORS -eq 0 ]]; then
  pass "All cross-references resolve"
fi

# --- Check 4: Decision sync ---
$QUIET || echo "== Decision sync =="
if [[ -f "docs/decisions/OPEN.md" ]]; then
  MISSING_DECISIONS=0
  while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    [[ "$file" == *"decisions/"* ]] && continue
    [[ "$file" == *"exec-plans/completed/"* ]] && continue
    [[ "$file" == *"exec-plans/debt/"* ]] && continue
    # For split-doc indexes (e.g. docs/db/README.md), every basename is "README" — fall
    # back to the parent directory name so OPEN.md can match the topic instead.
    base=$(basename "$file" .md)
    if [[ "$base" == "README" ]]; then
      base=$(basename "$(dirname "$file")")
    fi
    if ! grep -qiF "$base" docs/decisions/OPEN.md 2>/dev/null; then
      warn "🚧/⏳ in $file may not be tracked in docs/decisions/OPEN.md"
      MISSING_DECISIONS=$((MISSING_DECISIONS + 1))
    fi
  done < <(git grep -nE '🚧|⏳' -- 'docs/*.md' 2>/dev/null || true)

  if [[ $MISSING_DECISIONS -eq 0 ]]; then
    pass "All 🚧/⏳ markers tracked in OPEN.md"
  fi
else
  fail "docs/decisions/OPEN.md missing — cannot check decision sync"
fi

# --- Check 5: File length limits ---
$QUIET || echo "== File length limits =="
for f in AGENTS.md CLAUDE.md; do
  if [[ -f "$f" ]]; then
    lines=$(wc -l < "$f")
    if [[ $lines -gt 100 ]]; then
      warn "$f is $lines lines (limit: 100)"
    else
      pass "$f is $lines lines"
    fi
  fi
done

# --- Check 5.5: Doc length budget ---
# Soft cap of 400 lines on top-level reachable docs. Active exec plans, ADRs,
# legal docs, and research notes are exempt because they legitimately run long.
# Warn-only — flip to fail in your project once the codebase is below cap.
$QUIET || echo "== Doc length budget =="
LENGTH_OVER=0
LENGTH_CAP=400
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  lines=$(wc -l < "$f" 2>/dev/null || echo 0)
  if [[ $lines -gt $LENGTH_CAP ]]; then
    warn "$f is $lines lines (soft cap: $LENGTH_CAP)"
    LENGTH_OVER=$((LENGTH_OVER + 1))
  fi
done < <(git ls-files 'docs/**/*.md' \
  ':!docs/exec-plans/completed/*' ':!docs/exec-plans/debt/*' \
  ':!docs/exec-plans/planned/*' ':!docs/exec-plans/active/*' \
  ':!docs/research/*' ':!docs/legal/*' ':!docs/decisions/0*-*.md' \
  2>/dev/null || true)
if [[ $LENGTH_OVER -eq 0 ]]; then
  pass "All reachable docs under $LENGTH_CAP lines"
fi

# --- Check 6: Content violations ---
# Project-specific deny patterns. Add patterns that suggest copied / pasted /
# externally-sourced content that shouldn't live in the repo (vendor docs you
# can't republish, leaked competitor material, regulated PII, etc.).
# Keep this list minimal — false positives erode the signal.
$QUIET || echo "== Content violations =="
VIOLATIONS=0
DENY_PATTERNS=(
  # "copied from VendorX"
  # "pasted from"
  :  # placeholder so the array is non-empty; the loop below tolerates
)
for pattern in "${DENY_PATTERNS[@]}"; do
  [[ "$pattern" == ":" ]] && continue
  if git grep -qiE "$pattern" -- 'docs/*.md' ':!docs/research/*' 2>/dev/null; then
    fail "Content violation: pattern '$pattern' found in docs/ (outside research/)"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done
if [[ $VIOLATIONS -eq 0 ]]; then
  pass "No content violations detected"
fi

# --- Check 6.5: Banned automated commands ---
# Project-specific deny list for commands that should never run in CI or as
# npm scripts (destructive operations against shared environments, hook
# bypasses, etc.). Add your project's equivalents here.
$QUIET || echo "== Banned automated commands =="
BANNED_AUTO_FOUND=0
BANNED_PATTERNS=""  # Pipe-separated regex; e.g. "supabase db push|--no-verify"
if [[ -n "$BANNED_PATTERNS" ]]; then
  if [[ -d ".github/workflows" ]]; then
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      fail "Banned command in CI workflow: $match"
      BANNED_AUTO_FOUND=$((BANNED_AUTO_FOUND + 1))
    done < <(git grep -nE "($BANNED_PATTERNS)" \
      -- '.github/workflows/*.yml' '.github/workflows/*.yaml' 2>/dev/null \
      | grep -vE '(echo|::error|::warning|::notice|^[^:]+:[0-9]+:[[:space:]]*#|name:|with:|description:)' \
      || true)
  fi
  if [[ -f "package.json" ]]; then
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      fail "Banned command in package.json script: $match"
      BANNED_AUTO_FOUND=$((BANNED_AUTO_FOUND + 1))
    done < <(grep -nE "\"[^\"]+\"[[:space:]]*:[[:space:]]*\"[^\"]*($BANNED_PATTERNS)" \
      package.json 2>/dev/null || true)
  fi
fi
if [[ $BANNED_AUTO_FOUND -eq 0 ]]; then
  pass "No banned commands in automated execution paths"
fi

# --- Check 7: Dead-name drift ---
# Project-specific stale names that the cross-ref checker can't catch (because
# they aren't backtick-quoted as canonical paths). Add patterns for renamed or
# relocated docs that occasionally re-appear in prose.
$QUIET || echo "== Dead-name drift =="
DEAD_NAMES=0
DEAD_NAME_PATTERNS=(
  # 'old-doc-name\.md|old-doc-name §|old-doc-name#'
  :
)
DEAD_NAME_DESCS=(
  # "'old-doc-name' is a dead name — use 'docs/NEW-NAME.md'"
  :
)
for i in "${!DEAD_NAME_PATTERNS[@]}"; do
  pattern="${DEAD_NAME_PATTERNS[$i]}"
  desc="${DEAD_NAME_DESCS[$i]}"
  [[ "$pattern" == ":" ]] && continue
  matches=$(git grep -nE "$pattern" -- 'docs/*.md' 2>/dev/null || true)
  if [[ -n "$matches" ]]; then
    while IFS= read -r match; do
      fail "Dead-name drift: $desc → $match"
      DEAD_NAMES=$((DEAD_NAMES + 1))
    done <<< "$matches"
  fi
done
if [[ $DEAD_NAMES -eq 0 ]]; then
  pass "No dead-name drift detected"
fi

# --- Check 7.5: AGENTS.md index completeness ---
# Every root-level file in docs/ should be discoverable via AGENTS.md. Same
# for split-doc indexes (docs/<topic>/README.md) at depth 3. Match the full
# repo-relative path, not just the basename.
$QUIET || echo "== AGENTS.md index completeness =="
INDEX_GAPS=0
if [[ -f "AGENTS.md" ]]; then
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qF "$f" AGENTS.md 2>/dev/null; then
      warn "$f not referenced in AGENTS.md § Where to look"
      INDEX_GAPS=$((INDEX_GAPS + 1))
    fi
  done < <(git ls-files 'docs/*.md' 2>/dev/null \
    | awk -F/ 'NF==2' || true)

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qF "$f" AGENTS.md 2>/dev/null; then
      warn "$f (split-doc index) not referenced in AGENTS.md § Where to look"
      INDEX_GAPS=$((INDEX_GAPS + 1))
    fi
  done < <(git ls-files 'docs/*/README.md' \
    ':!docs/exec-plans/completed/*' ':!docs/exec-plans/debt/*' ':!docs/exec-plans/planned/*' \
    2>/dev/null \
    | awk -F/ 'NF==3' || true)
fi
if [[ $INDEX_GAPS -eq 0 ]]; then
  pass "All docs/ root files and split-doc indexes referenced in AGENTS.md"
fi

# --- Check 7.6: Module-plan retrospectives ---
# Every completed module plan must end with a "What actually shipped"
# retrospective. Module plans are identified by the H1 pattern
# "# Module NN: <Title>". Warn (not fail).
$QUIET || echo "== Module-plan retrospectives =="
MISSING_RETROS=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if ! head -20 "$f" | grep -qE '^# Module [0-9]+: '; then
    continue
  fi
  if ! grep -qE '^## What actually shipped' "$f" 2>/dev/null; then
    warn "$f missing '## What actually shipped' retrospective"
    MISSING_RETROS=$((MISSING_RETROS + 1))
  fi
done < <(git ls-files 'docs/exec-plans/completed/*.md' 2>/dev/null || true)
if [[ $MISSING_RETROS -eq 0 ]]; then
  pass "All completed module plans have retrospectives"
fi

# --- Check 8: Quality gates (post-code) ---
if [[ -d "src" ]]; then
  $QUIET || echo "== Quality gates (post-code) =="
  if [[ -d "tests" || -d "__tests__" || -d "test" ]]; then
    pass "Test directory exists alongside src/"
  else
    fail "src/ exists but no test directory found (tests/, __tests__/, or test/)"
  fi
fi


# --- Summary ---
echo ""
echo "== Summary: $PASS passed, $WARN warnings, $FAIL failures =="

# SessionStart summary: when run quietly with no failures, emit a single
# signal-rich line so the hook gives the agent a context-budget cue without
# adding noise.
if $QUIET && [[ $FAIL -eq 0 ]]; then
  if [[ -f AGENTS.md && -f CLAUDE.md ]]; then
    auto=$(($(wc -l < AGENTS.md) + $(wc -l < CLAUDE.md)))
    over_msg=""
    if [[ ${LENGTH_OVER:-0} -gt 0 ]]; then
      over_msg=" · $LENGTH_OVER doc(s) over cap"
    fi
    echo "harness OK · $auto auto-load lines${over_msg} (run /harness-check --budget for details)"
  fi
fi

if [[ $FAIL -gt 0 ]]; then
  exit 1
else
  exit 0
fi
