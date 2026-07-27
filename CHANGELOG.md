# Changelog

How the template has evolved. Every entry answers "would I want this on day one of the next project?"

## v1.0

Rebuilt from the harness of a production project, porting the mechanics that earned their place and deliberately leaving behind everything stack-specific or personal.

### Fixed — three live bugs in v0.1

- **Doc globs silently skipped root-level docs.** In a git pathspec, `**` is not special without `:(glob)` magic, so `docs/**/*.md` requires an intervening path segment and never matched `docs/PATTERNS.md`. Cross-reference, decision-sync, and length checks were all blind to every root-level doc. Now paired with `docs/*.md`, with depth filters where depth matters.
- **The pull request template was in a location GitHub does not read.** It lived at `.github/templates/pull_request_template.md`; GitHub reads `.github/PULL_REQUEST_TEMPLATE.md`, the repo root, or `docs/`. It had never rendered.
- **`AGENTS.md` and `CLAUDE.md` had already drifted.** Two files with overlapping content and nothing comparing them — they disagreed on the doc length cap and on the review mechanism. `CLAUDE.md` is now a symlink.

### Added — mechanics

- `--session-start` fast path: branch hygiene and the context-budget line only. The full suite is repo health, which CI already gates, and its per-line loops fork enough subprocesses to take minutes on some platforms.
- Branch hygiene: uncommitted-work and stale-base warnings, with **default-branch detection** via `origin/HEAD` rather than a hardcoded branch name.
- **Byte budgets alongside line caps**, on the agent guide, the decision tracker, and all reachable docs. A line cap is blind to long-line bloat: a doc packing entries into dense single lines reads green while costing thousands of tokens.
- Decision-record number uniqueness. Two branches taking "the next number" collide silently — differing slugs mean no merge conflict, and both files existing means every other check passes.
- Decision-tracker hygiene: pending-only, enforced. Closing a row in place is the mechanism by which the tracker bloats.
- Hardened cross-references: every match on a line rather than only the first; source-path references inside source files; skips for globs, brace expansion, placeholders, and command strings; resolution of the trailing `:NNN` line-number convention.
- **Scans now include untracked files.** `git grep` and `git ls-files` default to tracked files only, so a brand-new doc passed every check until it was committed — and the green run read as "fine" rather than "not examined". Found by planting a broken reference in an untracked file; standard excludes still keep build output out.
- Agent-guide aliasing check — warn-only, because Windows checkouts cannot always create symlinks.
- Retrospective check with an inline opt-out marker rather than a filename heuristic.
- **All tunable knobs hoisted into one CONFIG block.** The source project scattered them beside their checks across 1300 lines; a fork should edit one block, not read the whole file.

### Added — docs and wiring

- `docs/harness/README.md` — what each check is for and the incident behind it; the design principles (cheapest layer, warn vs. fail, escape hatches, forward-only baselines).
- `docs/harness/recipes.md` — ten opt-in stack-specific guards, each with its motivating bug: numbered-artifact uniqueness, row-level-security invariants, grant coverage, CI config coverage, dependency-override enforcement, output-parsing fragility, section-pointer resolution, dead template fields, and how to test a guard's own parser.
- `docs/patterns/` pre-split by domain, replacing the monolith that was destined to be split later.
- `docs/decisions/RESOLVED.md`, `docs/PRE-PLAN.md`, `docs/TESTS.md`, `docs/ENVIRONMENTS.md`, `docs/exec-plans/module-index.md`.
- `scripts/check.sh` — aggregate local gate, configured by array.
- `.codex/hooks.json` mirroring the Claude session hook, so the harness does not depend on which runtime someone opens.
- `.github/dependabot.yml` and a stack-agnostic `ci.yml` that runs the harness lint out of the box and skips heavy jobs for docs-only changes.
- `review-changes` skill; `harness-bootstrap` and `harness-ingest` rewritten.
- Planning method gained the retrospective requirement, the one-pull-request-per-module rule, and an anti-pattern list.

### Removed

- Every reference to the originating project and its maintainer — the old project name appeared in the agent guide, both skills, and the planning doc, and the workflow doc named one person roughly thirty times.
- `.github/review-agents/` — it duplicated prompts that the project's own workflow doc said must have a single source in `.agents/skills/`.
- `.github/templates/` and the empty, unrouted `docs/api/`.
- `docs/PATTERNS.md`, superseded by the split.
- Roughly 470 lines from the workflow doc: per-phase responsibility matrices, named third-party tools with pricing, and first-person narrative.

### Deliberately not included

Guards requiring a specific stack (database migration invariants, package-manager behavior, CI environment coverage) are in `docs/harness/recipes.md` rather than commented out in the validator. Section-pointer resolution is a recipe too, with the measurement that motivates scoping it: in the source project, **44% of ~600 section references named a bold lead-in rather than a heading**, so a repo-wide version cannot distinguish drift from house style.

## v0.1

Initial template: agent guide with doc-boundary definitions, architecture skeleton, patterns monolith, a single CI review-agent prompt, PR template, setup script, and pre-commit/pre-push hooks.
