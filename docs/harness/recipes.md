# Harness Recipes — Opt-in Guards

Guards that cannot ship active in a stack-neutral template, written up so you do not have to rediscover them.

**Nothing here runs by default.** Each recipe names the stack it applies to, the failure it catches, and why nothing else caught it. Paste the ones that fit into `scripts/lint-docs.sh` — the check bodies assume the `pass` / `warn` / `fail` helpers and the CONFIG conventions already there.

Every entry earned its place by shipping a real bug in a production codebase. The bug is included because that is the part that convinces a future maintainer not to delete the guard.

---

## 1. Numbered artifacts must have unique numbers

**Applies to:** any repo with sequentially-numbered files — database migrations, decision records, RFCs.

**The failure:** two branches each take "one higher than the highest number on disk". Both land on the same number. Nothing catches it: the filenames differ because the slugs differ, so git merges both cleanly with no conflict to resolve. Type checks, linters, and the test suite all pass, because none of them assert uniqueness. The only thing that reveals it is `ls`.

For migrations this is worse than untidy. Tools that apply migrations in lexical order have no defined order between two files sharing a prefix, so if both touch the same object the result is non-deterministic across environments.

```bash
# --- Migration sequence numbers must be unique ---
$QUIET || echo "== Migration sequence-number uniqueness =="
DUPLICATE_MIGRATIONS=0
while IFS= read -r dup; do
  [[ -z "$dup" ]] && continue
  files=$(git ls-files "migrations/${dup}_*.sql" | sed -E 's|.*/||' | tr '\n' ' ')
  fail "Migration number ${dup} used by more than one file: ${files}— renumber the newer one"
  DUPLICATE_MIGRATIONS=$((DUPLICATE_MIGRATIONS + 1))
done < <(git ls-files 'migrations/*.sql' 2>/dev/null \
  | sed -E 's|.*/||' | grep -oE '^[0-9]{5}_' | tr -d '_' \
  | sort | uniq -d)
[[ $DUPLICATE_MIGRATIONS -eq 0 ]] && pass "All migration numbers are unique"
```

The decision-record version of this ships active as Check 4.6.

---

## 2. Row-level-security policies must not re-evaluate per row

**Applies to:** Postgres with row-level security (Supabase, and anything else using RLS).

**The failure:** a bare function call in a policy predicate is re-evaluated for every row the query touches. Wrapping it in a scalar subquery makes the planner evaluate it once per query. On a small table nobody notices; at a hundred thousand rows the same policy is the reason a page takes four seconds.

```bash
# --- Policy predicates wrap auth function calls ---
# Bare auth.uid() re-evaluates per row; (SELECT auth.uid()) evaluates once.
# BASELINE grandfathers migrations that predate the rule — without it, adopting
# this guard means rewriting history before anything can ship.
BASELINE=27
while IFS= read -r f; do
  prefix=$(basename "$f" | grep -oE '^[0-9]+' | head -1 || true)
  [[ -n "$prefix" ]] && (( 10#$prefix < BASELINE )) && continue
  # Blank out `AS $$ ... $$` function bodies (the rule is about policy
  # expressions, not function bodies) while preserving line numbers, strip
  # comments, then strip every correctly-wrapped occurrence. What remains is bare.
  bare=$(awk '
    /^[[:space:]]*AS \$\$[[:space:]]*$/ { inbody=1; print ""; next }
    inbody && /^[[:space:]]*\$\$;?[[:space:]]*$/ { inbody=0; print ""; next }
    inbody { print ""; next }
    { print }
  ' "$f" | sed -e 's/--.*$//' -e 's/(SELECT auth\.uid())//g' | grep -nE 'auth\.uid\(\)' || true)
  [[ -n "$bare" ]] && fail "Unwrapped auth.uid() in $f: $bare"
done < <(git ls-files 'migrations/*.sql')
```

**The general lesson, beyond Postgres:** when a guard must ignore certain regions of a file, blank those lines rather than deleting them. Deleting shifts every subsequent line number, so the violation you report points at the wrong line — and a guard that misreports locations gets distrusted and then removed.

---

## 3. New tables need explicit grants after default privileges are revoked

**Applies to:** Postgres where default `public` schema privileges have been revoked (a common hardening step).

**The failure:** once default privileges are revoked, a newly created table has *zero* privileges for your application roles. Row-level security on top of it is unreachable — every query fails with a permission error. The migration itself succeeds, because migrations run as a superuser that bypasses privilege checks entirely. So the schema looks correct and every request fails.

```bash
# --- New tables in a locked-down schema need explicit GRANT ---
LOCKDOWN=24  # the migration that revoked default privileges
for f in migrations/*.sql; do
  [[ "$(basename "$f")" =~ ^([0-9]{5})_ ]] || continue
  (( 10#${BASH_REMATCH[1]} <= LOCKDOWN )) && continue
  # Escape hatch: tables only ever touched by a privileged backend role.
  grep -qiE 'service-role-only' "$f" && continue
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    grep -qE "GRANT[[:space:]]+[A-Z, ]+ON[[:space:]]+public\.${t}\b" "$f" && continue
    fail "$f creates public.${t} without a GRANT and no service-role-only marker"
  done < <(grep -oE 'CREATE TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?public\.[a-z_][a-z0-9_]*' "$f" \
    | sed -E 's/.*public\.//')
done
```

A sibling guard covers functions: a migration that `REVOKE`s execute on a function but never `GRANT`s it back leaves the function callable by the owner alone, so every application call fails. Keying the rule off `REVOKE` rather than off `SECURITY DEFINER` matters — plenty of definer functions are invoked by the database itself and correctly hold no grant.

---

## 4. One permissive policy per (table, action, role)

**Applies to:** Postgres row-level security.

**The failure:** two or more permissive policies covering the same role and action are each evaluated for every row, so cost scales with policy count. The fix is one policy with `USING (a OR b)`. Nothing surfaces this except a linter or a slow query, and it accumulates naturally — each policy was added by a different change, each reasonable in isolation.

Implementation is a single `awk` pass that accumulates `CREATE POLICY` / `DROP POLICY` statements into one-line records, extracts (table, name, action, role), and flags any group with two or more active permissive policies. Non-obvious pieces worth knowing before you write it:

- Track `DROP POLICY` too, or a policy that was replaced still counts.
- `RESTRICTIVE` policies are excluded — the rule is about permissive ones.
- Normalize schema qualification (`public.foo` and `foo` are the same table).
- Name the parser's limits in a comment: multi-role `TO a, b`, `ALTER POLICY … RENAME`, and block comments inside a statement are the shapes a simple version gets wrong.

That last point generalizes: **document what your guard cannot see.** A guard trusted beyond its actual coverage is more dangerous than no guard, because a green result gets read as proof.

---

## 5. CI build environment covers every required runtime variable

**Applies to:** any project that validates configuration at startup and builds in CI.

**The failure:** configuration validation runs at module load. The CI build step runs that code. Any required variable missing from the build step's environment kills the build — but only in CI, because local development has a populated `.env`, and the local test command never runs a production build. The result is a slow red CI build for a mistake that was visible at the desk.

```bash
# --- CI build env covers required runtime config ---
# Only `KEY: process.env.KEY` assignment lines count, so prose or JSDoc that
# mentions an env var as an example is correctly ignored.
read_vars=$(grep -hE ':[[:space:]]*process\.env\.[A-Za-z_]' src/config.ts 2>/dev/null \
  | grep -oE 'process\.env\.[A-Za-z_][A-Za-z0-9_]*' | sed 's/process\.env\.//' | sort -u)
# Keys set in the Build step's env: block, scoped so other steps do not leak in.
build_keys=$(awk '
  /^      - name: Build$/ { inb=1 }
  inb && /^      - name: / && $0 !~ /Build$/ { inb=0 }
  inb && /^          [A-Za-z_][A-Za-z0-9_]*:/ { l=$0; sub(/:.*/,"",l); gsub(/ /,"",l); print l }
' .github/workflows/ci.yml | sort -u)
for v in $read_vars; do
  case " $BUILD_OPTIONAL " in *" $v "*) continue ;; esac
  printf '%s\n' "$build_keys" | grep -qxF "$v" \
    || fail "'$v' is read by config but missing from the CI Build env"
done
```

Maintain a `BUILD_OPTIONAL` allowlist for variables that are genuinely optional at build time, **with a reason per entry**. An allowlist without reasons becomes a place to hide problems.

---

## 6. Declared dependency overrides must match the lockfile

**Applies to:** any package manager supporting version overrides — most relevantly `pnpm`, where the field moved between major versions.

**The failure:** a security override declared in a location the package manager no longer reads is *silently ignored*. No error, no warning. The pinned floor simply does not apply, and a transitive dependency drifts below it. A declared-but-unenforced override is worse than no override, because it appears in review as though the vulnerability were addressed.

```bash
# --- Overrides live where the tool reads them, and match the lockfile ---
if grep -qE '^[[:space:]]*"pnpm"[[:space:]]*:' package.json; then
  fail "package.json has a \"pnpm\" field — pnpm 11+ ignores it, so overrides there are silently unenforced"
fi
extract() { awk '/^overrides:/{f=1;next} f&&/^[^[:space:]]/{f=0} f&&NF{print}' "$1" \
  | sed "s/[[:space:]\"']//g" | sort; }
if [[ "$(extract pnpm-workspace.yaml)" != "$(extract pnpm-lock.yaml)" ]]; then
  fail "Declared overrides do not match the lockfile — run install so the declared floors are the resolved ones"
fi
```

**Fail, do not warn.** An unenforced security override is live exposure, not a style nit. This is the clearest case in this document for choosing `fail`.

---

## 7. Captured command output must silence tool chatter

**Applies to:** any script that parses the stdout of a package-manager or task-runner command.

**The failure:** a tool adds a progress or dependency-check summary to **stdout**. Anything piping that output into a parser now receives the summary as data. It breaks on a routine version bump of a tool nobody thought of as a dependency of the script.

```bash
# --- Captured/piped runner output must silence the reporter ---
# Consumed = command-substituted `$(… run …)` or piped `… run … |`.
CONSUMED='\$\(\s*pnpm[^)]*exec|pnpm[^|]*exec[^|]*\|'
while IFS= read -r line; do
  content=$(echo "$line" | cut -d: -f3-)
  echo "$content" | grep -qE "$CONSUMED" || continue
  echo "$content" | grep -qE -- '--reporter=silent|--silent' && continue
  echo "$content" | grep -qF 'noise-ok:' && continue   # escape hatch
  fail "${line%%:*} — captured runner output without --reporter=silent"
done < <(git grep -nE 'pnpm[^|]*exec' -- '.github/workflows/*.yml' '*.sh' 'package.json')
```

**The general lesson:** treat any tool's stdout as an interface that can change. If a script parses it, pin the output format explicitly — a `--json`, a `--quiet`, a `--reporter` flag — rather than relying on today's default.

---

## 8. Section pointers resolve, for a curated set of documents

**Applies to:** projects whose docs cross-reference specific sections and that periodically move content between a live doc and an archive.

**The failure:** a reference of the form *path* § *Section name* has two halves. Path checking validates the file and strips the section, so the section half can rot indefinitely. In the source project nine such pointers broke across two archive sweeps — six of them naming a section that by then existed in neither the live document nor any archive. Nothing failed. Nothing warned.

**Measure before enabling this repo-wide.** A repo-wide version was built and measured in the source project first: **44% of roughly 600 section references named a bold lead-in or a numbered sub-item rather than an actual heading.** At that rate the check cannot distinguish drift from house style, and the noise buries the signal.

So scope it to the specific documents that content moves *between* — which is where every real instance came from. Add a document only when both hold: its sections are real headings, and content migrates in or out of it.

Two things to know before implementing. Write the parser in a real language, not shell — you need heading extraction and normalization across several files, and shell makes that fragile. And accept a known limitation: a reference is read as a live pointer, so prose that *quotes* a broken pointer verbatim fails too. Rephrasing around it is cheaper than an escape marker until it happens more than once.

---

## 9. Dead heading names in templates

**Applies to:** any project whose plan or spec templates have renamed fields.

**The failure:** a renamed template field survives in older files, and its stale name gets read as a live instruction. In the source project a `## v0 Prototype` field — named for a tool that had been replaced — was being answered "No", and that answer was read as "this module needs no design pass". A tool change had silently become a process exemption.

```bash
# --- Legacy template field ---
# Scope to planned/ and active/ only. Completed plans are immutable record —
# those modules really did use the old tool, and rewriting history to satisfy a
# lint falsifies it.
while IFS= read -r line; do
  fail "Legacy '## Old Field' heading in ${line%%:*} — rename to '## New Field'"
done < <(git grep -nE '^## Old Field$' -- \
  'docs/exec-plans/planned/*.md' 'docs/exec-plans/active/*.md')
```

**The general lesson:** when you rename a template field, add a guard in the same change. The old name will otherwise persist in files nobody reopens, and a stale field that *looks* answerable is worse than a missing one — a missing field prompts a question, while a stale field supplies a wrong answer.

---

## 10. Test the guard itself

**Applies to:** any check containing a parser or a state machine.

**The failure:** a guard silently stops matching. Perhaps the code it scans adopted a new shape — a schema-qualified name, a different quoting style — that the regex does not cover. The check keeps reporting success. This is strictly worse than having no check, because the green result is read as evidence.

The source project hit exactly this: a policy parser captured the table name from an `ON <table>` clause and broke the day a migration wrote `ON public.<table>` instead, silently matching the schema name as the table. Every run stayed green.

Keep a small script that deliberately introduces a violation, asserts the guard fires, and restores the file from git:

```bash
#!/usr/bin/env bash
# Self-test for the policy-recursion guard. Mutates a known-good file,
# asserts the guard fires, then restores from HEAD.
set -euo pipefail
TARGET=migrations/00027_fix.sql
trap 'git checkout HEAD -- "$TARGET"' EXIT

# Introduce the exact shape the guard exists to catch.
sed -i.bak 's/private\.foo_pinned()/(SELECT x FROM foo)/' "$TARGET" && rm -f "$TARGET.bak"

if bash scripts/lint-docs.sh --quiet 2>&1 | grep -q 'Recursion risk'; then
  echo "PASS — guard fired on the injected violation"
else
  echo "FAIL — guard did NOT fire; its parser has stopped matching"
  exit 1
fi
```

Run it after touching the guard. It does not need to be in CI — its job is to answer "did I just break this parser?", and that question only comes up when you edited it.

---

## 11. Repeating rows need a cap on the row, not just the file

**Applies to:** any project with an index or registry document whose entries follow a repeating convention — a module index, an ADR index, a service catalog, a supported-platforms table.

**The failure:** a byte cap on a whole file is a lagging indicator. It fires only after the damage, and it cannot say *which* section bloated, so its remedy text can only guess ("split by topic, or archive settled content"). In the source project a module index reached its cap with one table holding **71% of the file** — 39KB across 88 lines — and 40% of that table came from 13% of its rows. Four separate archive passes deleted old rows to make room for one new one each. Every pass treated the symptom; none touched the row convention that was the actual cause.

**Fix the table's shape first, then guard it.** The root cause was structural, not editorial: the table declared four columns and had no **Status** column, so status, date, narrative, and links all landed in the last cell — and a last cell has no successor to stop it. Nothing in the row's shape said "you are done." The template's own index table in `docs/exec-plans/module-index.md` already has Status and Plan as separate columns, which is the shape that prevents this; the guard below is what keeps a fork from drifting out of it. A tell that you have this problem: the row sizes are bimodal rather than gradually rising — two conventions coexisting, not slow growth.

```bash
# --- Index rows stay pointers ---
# Strip link TARGETS before measuring, deliberately. A legitimate row may carry
# several ~50-char plan paths that are irreducible and are exactly what the row
# is FOR; measuring them penalises the pointer and lets prose hide behind a short
# path. What is capped is the prose the author actually wrote.
# LC_ALL=C so length() counts bytes, not characters — index rows are usually full
# of multi-byte status emoji and em-dashes.
MAP_FILE="docs/exec-plans/module-index.md"
MAP_ROW_CAP=500
while IFS=$'\t' read -r map_line map_bytes map_label; do
  [[ -z "$map_line" ]] && continue
  warn "$MAP_FILE:$map_line — row '$map_label' is $map_bytes bytes of prose (cap: $MAP_ROW_CAP). Rows are pointers: status + one clause + a plan link."
done < <(LC_ALL=C awk -v cap="$MAP_ROW_CAP" '
  /^## Build order/ { intable = 1; next }
  /^## / { intable = 0 }
  intable && /^\| / {
    split($0, f, "|"); label = f[2]; gsub(/^ +| +$/, "", label)
    if (label ~ /^[0-9~]/) {
      row = $0; gsub(/\]\([^)]*\)/, "]", row)
      n = length(row) + 1
      if (n > cap) printf "%d\t%d\t%s\n", NR, n, label
    }
  }
' "$MAP_FILE")
```

Set the cap from measurement, not taste: in the source project the reshaped rows topped out at 367 bytes, so 500 left room for a long entry name plus one clause while making the 800–2,000-byte rows that caused the problem impossible. Confirm the number would have caught the original offenders — 34 of 69 rows, there — before committing to it. Then prove the guard fires (recipe 10): reinstating one pre-reshape row reported `855 bytes` and named it, which is what makes the green result mean something.

**The general lesson:** cap the repeating unit, not only its container. A container budget lets five entries bloat while five stay terse and reads green the whole way — which is precisely the drift dynamic, so the check is blind to exactly the thing it exists to catch. And when a document has a *shape* that invites the sprawl, the guard is the second fix; the first is giving the overflowing content its own column.

---

## 12. A ported surface can drop a behavior while every presence check stays green

**Applies to:** any project that ships the same product on two platforms and ports surfaces between them — most concretely a React web app and a React Native / Expo app sharing a feature set, but the shape holds for any primary → secondary port (a desktop app and its CLI, an API and its SDK).

**The failure:** platform-parity ratchets almost always check *presence* — for each surface reachable on the second platform, does a screen file exist? That question is blind to what the screen *does*. So a port can silently drop a behavior the original performs and stay green through type-checks, lint, the test suite, and merge, because none of them assert that the second platform's surface *behaves* like the first's.

In the source project a mobile port of a practice surface dropped a terminal-branch behavior: when a caught-up learner hit Start with nothing fresh or due, the web surface auto-originated a dedicated re-review session; the mobile port dead-ended that branch and showed an empty state instead. Every surface-presence guard passed — the screen file existed. The drop surfaced only weeks later in a hand-audit, and only because that audit enumerated the *web* surface's behaviors and checked each against mobile. An audit that started from the mobile side could not have found it: you cannot notice the absence of a behavior by looking at the platform that lacks it.

**Two parts, and they live in the test suite, not in `scripts/lint-docs.sh`.** This is a *code-time* concern — does the second platform's code implement the first's behavior — so it belongs with your route/screen ratchets, next to the code, not in the docs linter. (Match a gate's lane to its concern's granularity: a plan-time gate reads outlines; a code-time gate reads code.) The policy and the stack-neutral mechanism are in `docs/patterns/platform-parity.md`.

*Part one — the schema that makes a malformed or silently-dropped row un-representable.* One Zod `superRefine` carries a per-disposition contract, mirroring a surface-level `deferred ⟺ tracking` rule one level down:

```ts
import { z } from "zod";

const DispositionSchema = z.enum(["ported", "deferred", "primary-only", "secondary-only"]);

export const BehaviorSchema = z
  .object({
    id: z.string().min(1),
    description: z.string().min(1),
    primary: z.string().min(1).nullable(),   // stable anchor (file + symbol), or null if absent here
    secondary: z.string().min(1).nullable(),
    disposition: DispositionSchema,
    tracking: z.string().min(1).nullable(),  // fix/debt ref; required iff `deferred`
    reason: z.string().min(1).nullable(),    // required iff an intentional `*-only` divergence
    note: z.string().min(1).nullable(),
  })
  .superRefine((b, ctx) => {
    const fail = (message: string, path: keyof typeof b) =>
      ctx.addIssue({ code: z.ZodIssueCode.custom, message, path: [path] });
    switch (b.disposition) {
      case "ported":
        if (b.primary === null || b.secondary === null) fail("`ported` needs both sides' evidence.", "secondary");
        if (b.tracking !== null) fail("`ported` owes no fix — `tracking` must be null.", "tracking");
        if (b.reason !== null) fail("`reason` is only for a `*-only` divergence; explain a port in `note`.", "reason");
        break;
      case "deferred":
        if (b.tracking === null) fail("`deferred` must carry a `tracking` ref.", "tracking");
        if ((b.primary === null) === (b.secondary === null))
          fail("`deferred` is present on exactly one platform: set one side, null the other.", "secondary");
        if (b.reason !== null) fail("A deferred gap is explained by `tracking` + `note`, not `reason`.", "reason");
        break;
      case "primary-only":
        if (b.primary === null || b.secondary !== null) fail("`primary-only` sets `primary`, nulls `secondary`.", "secondary");
        if (b.reason === null) fail("`primary-only` is intentional — give a `reason`.", "reason");
        if (b.tracking !== null) fail("`primary-only` owes no fix — `tracking` must be null.", "tracking");
        break;
      case "secondary-only":
        if (b.secondary === null || b.primary !== null) fail("`secondary-only` sets `secondary`, nulls `primary`.", "primary");
        if (b.reason === null) fail("`secondary-only` is intentional — give a `reason`.", "reason");
        if (b.tracking !== null) fail("`secondary-only` owes no fix — `tracking` must be null.", "tracking");
        break;
      default: {
        const _exhaustive: never = b.disposition; // a new disposition without a case is a compile error
        return _exhaustive;
      }
    }
  });

export const LedgerSchema = z.object({ surface: z.string().min(1), behaviors: z.array(BehaviorSchema).min(1) });
```

*Part two — the coverage gate that rides the secondary-platform delivery map.* It needs no per-surface wiring: coverage is derived from `SECONDARY_DELIVERY`, so the same PR that marks a surface delivered must add its ledger. Empty map ⇒ empty required set ⇒ the gate is a no-op (the dormant, single-platform default). Written for Jest, whose assertions carry no per-assertion message — hence the `report()`-returns-`""` pattern, so the failure diff shows the fix instructions:

```ts
import { PARITY_LEDGERS } from "../src/parity-ledgers";

// surface -> screen file(s) that must exist on the secondary platform. EMPTY by default.
const SECONDARY_DELIVERY: Record<string, readonly string[]> = {};

const report = (title: string, items: string[], ...help: string[]) =>
  items.length === 0 ? "" : ["", title, "", ...items.map((i) => `  ${i}`), "", ...help].join("\n");

const delivered = () => Object.keys(SECONDARY_DELIVERY);
const ledgered = () => Object.keys(PARITY_LEDGERS);

it("gives every delivered surface a behavior parity ledger", () => {
  const missing = delivered().filter((k) => !(k in PARITY_LEDGERS)).sort();
  expect(report("Delivered surface(s) with no parity ledger:", missing,
    "Add a ledger in src/parity-ledgers.ts — run the platform-parity-audit skill on the surface.")).toBe("");
});

it("keeps no ledger for a surface not delivered on the secondary platform", () => {
  const orphan = ledgered().filter((k) => !(k in SECONDARY_DELIVERY)).sort();
  expect(report("Parity ledger(s) for undelivered surface(s):", orphan,
    "Deliver the surface (add it to SECONDARY_DELIVERY) or remove the stray ledger.")).toBe("");
});

it("keys each ledger to its own surface", () => {
  const mismatched = ledgered().filter((k) => PARITY_LEDGERS[k]?.surface !== k).sort();
  expect(report("Ledger(s) whose `surface` disagrees with their key:", mismatched)).toBe("");
});
```

Pin the schema itself with unit tests that assert each disposition's refinement *fires* — a `ported` row carrying a `tracking` ref must fail to parse, a `deferred` row present on both sides must fail, and so on. And pin your one known dropped behavior as a checked-in `deferred` row plus a test asserting its presence and tracking, so the bug that motivated the ledger can never silently vanish from it. That is the parser-self-test discipline of recipe 10 applied to the thing the ledger exists to catch.

**The general lesson:** a presence check and a behavior check are different granularities, and the coarse one reads as reassurance for the fine one it cannot see — "the surface is there" gets heard as "the surface works." When you port across platforms, enumerate from the source of truth and check the target; a target-first audit is structurally blind to what the target is missing. And bind the coverage to the delivery map, not to a hand-maintained list, so the harness stays dormant until a second platform exists and enrolls each port automatically thereafter.

---

## Adding a recipe

If you build a guard in a forked project that would help someone on a different stack, add it here in the same shape: **what it applies to, the failure it catches, why nothing else caught it, the code, and the general lesson underneath.** The last part is the most portable — a reader on another stack cannot use your `awk`, but they can use the reason you needed it.
