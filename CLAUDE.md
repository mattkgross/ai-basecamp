# CLAUDE.md — Agent Operating Manual

This file is automatically loaded by Claude Code at session start. It serves as a **map** — pointing to deeper docs rather than containing everything itself.

## Before You Write Code

1. Read the relevant **feature spec** in `docs/specs/` for your task
2. Read `ARCHITECTURE.md` for system structure, component boundaries, and tech decisions
3. Read `docs/PATTERNS.md` for established code conventions
4. Check if the acceptance criteria and test cases exist for your task — implement to satisfy them

## Core Rules

- **Update docs with every change.** If you modify code, update the relevant docs (ARCHITECTURE.md, PATTERNS.md, feature spec, module README). This is enforced by CI — PRs that change code without updating related docs will be flagged.
- **Check for existing code before creating new code.** Search PATTERNS.md and the codebase for utilities, helpers, and abstractions before building something new. Reuse > reinvent.
- **Tests ship with code.** Every implementation includes unit tests. Every bug fix includes a regression test.
- **Specs are the source of intent.** If your implementation needs to deviate from the spec, pause and update the spec first — don't silently diverge.
- **Flag decisions that need human judgment.** If you encounter a trade-off, an architectural question, or something the spec doesn't cover, surface it clearly rather than guessing.

## Project Structure

```
CLAUDE.md                ← You are here (agent operating manual)
ARCHITECTURE.md          ← System map, component boundaries, tech decisions
docs/
  PATTERNS.md            ← Code patterns, conventions, lessons learned
  specs/                 ← Feature specifications + acceptance criteria
  exec-plans/            ← Module plans: planned → active → completed → debt
    PLANNING.md          ← Module decomposition methodology
```

## What Goes Where

| Document | Contains | Does NOT Contain |
|---|---|---|
| CLAUDE.md | Agent rules, pointers to other docs | Implementation details, architecture, patterns |
| ARCHITECTURE.md | System structure, components, data flow, tech decisions + rationale, scaling levers | Code patterns, agent instructions |
| PATTERNS.md | How we do things in this codebase, conventions, anti-patterns, lessons from bugs | Architecture decisions, system structure |
| Feature specs | What to build, acceptance criteria, test cases, explicit exclusions | How to build it (that's your job) |

## Harness invariants

Mechanically enforced — `scripts/lint-docs.sh` runs at session start and on `/harness-check`.

1. **Plans are artifacts.** Active work gets a plan in `docs/exec-plans/active/`. Move to `docs/exec-plans/completed/` when done, `docs/exec-plans/debt/` for known shortcuts.
2. **Decisions are tracked.** Every 🚧 or ⏳ in docs/ must have a matching entry in `docs/decisions/OPEN.md`. Significant choices get their own record in `docs/decisions/NNNN-slug.md`.
3. **Cross-refs resolve.** Every file reference in any .md must point to a file that exists.
4. **Docs stay lean.** AGENTS.md and CLAUDE.md under 100 lines each.

## Quality gates

Pre-code: doc completeness, cross-ref integrity, decision record for arch choices. Post-code: tests ship with code, lint passes, reviewer agent approves.
