# AI Basecamp

An engineering harness to fork when starting a new project. Stack-neutral, opinionated only where a lesson earned it.

## What a harness is

The set of mechanical guards that keep documentation, decisions, and plans honest without depending on anyone remembering. Docs rot through ordinary work — a file gets renamed and eight prose references still point at the old path; a decision gets made in conversation and never written down; a plan ships and nobody records what changed. Each is trivial alone and fatal together, because an agent starting a fresh session has nothing but the docs. It cannot ask what happened last week.

Willpower does not fix this; the failures are invisible, so there is nothing to feel bad about. Mechanism does.

## What you get

**A validator** — `scripts/lint-docs.sh` checks that every path referenced in any doc resolves, that open decisions are tracked, that record numbers are unique, that the auto-loaded guide stays within its token budget, and that finished plans say what shipped. Every knob lives in one CONFIG block at the top.

**Agent-runtime wiring** — a session-start hook giving any agent an immediate orientation signal (branch state, context budget), for Claude Code and Codex, extensible to others.

**A doc architecture that survives growth** — a pointers-only routing table as the single auto-loaded file; patterns pre-split by domain; decisions split into pending and resolved so the always-loaded tracker stays cheap.

**A planning method** — decomposition heuristics, a drift header that forces reconciliation before building, and a retrospective requirement that captures what actually changed.

**Local gates** — an aggregate check command, plus hooks that scope enforcement to what you are committing rather than to the whole repo.

**Recipes for what cannot be generic** — `docs/harness/recipes.md` carries stack-specific guards (database invariants, package-manager behavior, CI config coverage) each paired with the bug that motivated it. Nothing runs by default; take what fits.

## Quick start

```bash
git clone https://github.com/mattkgross/ai-basecamp.git my-project
cd my-project
rm -rf .git && git init
./scripts/setup.sh
```

Then work through [TEMPLATE_README.md](TEMPLATE_README.md), which is the fork checklist.

## Layout

```
AGENTS.md                    Routing table + universal rules. The only auto-loaded doc.
CLAUDE.md → AGENTS.md        Symlink, so the two names cannot drift.
ARCHITECTURE.md              System design. Yours to write.
docs/
  harness/README.md          How the harness works and why each check exists
  harness/recipes.md         Opt-in stack-specific guards
  patterns/                  Code conventions, pre-split by domain
  decisions/                 Records, plus pending (OPEN) and closed (RESOLVED)
  exec-plans/                Planning method, build index, and plan lifecycle
  integrations/              Third-party config + the external-state mirror discipline
  process/                   Development workflow and maturity tiers
  PRE-PLAN.md                Read before drafting any plan
  TESTS.md  ENVIRONMENTS.md  Testing rules; per-environment differences
  specs/                     Feature specifications
scripts/
  lint-docs.sh               The validator
  check.sh                   Aggregate local gate
  setup.sh  hooks/           Setup and git hooks
```

## Commands

| Command | What it does |
|---|---|
| `./scripts/setup.sh` | Install hooks, create the agent-guide symlink, validate |
| `bash scripts/check.sh` | Every local gate. Run before pushing. |
| `bash scripts/lint-docs.sh` | Full harness validation |
| `bash scripts/lint-docs.sh --budget` | Context-budget diagnostic |
| `/harness-check` | The full validation, as an agent command |
| `/harness-bootstrap` | Scaffold the harness into a new repo, or audit one |
| `/harness-ingest` | Plan a phased retrofit into an established repo |
| `/review-changes` | Local read-only review of the current branch |

## Philosophy

**Every guard exists because something failed silently.** That is the bar for adding one, and it is why each check carries the incident in a comment rather than only the rule. A suite where green means something is a suite people act on.

**Push enforcement to the cheapest layer.** Local hooks are free, non-model CI costs compute, model-powered review costs tokens. Most drift does not need language understanding.

**Warn for judgment, fail for facts.** A doc over its length budget might be legitimately long. A broken path is never fine. Making judgment calls hard failures trains everyone to bypass the gate, and a bypassed gate enforces nothing.

**No opinions you would have to undo.** Stack-specific and personal-preference content is either absent, quarantined in a labelled house-style section, or parked in recipes. Fork it and the only thing you should have to remove is the placeholder text.
