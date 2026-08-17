# Agent Guide

> This is a **map**, not a manual. It routes to the docs that hold the content; it does not hold the content itself. When you fork, replace every *italic placeholder* with project-specific text and add a routing row as each new doc lands.
>
> `CLAUDE.md` is a symlink to this file, so the two names cannot drift apart.

## What this project is

*Replace with one paragraph: what this is, who it serves, the load-bearing constraints, who the stakeholders are, and the single most important thing an agent should know in its first ten seconds.*

## Repo state

*Replace as the project develops: what is shipped and live, the current stack, the architectural state. Keep it to a dense paragraph — an agent who reads only this section should know what exists. Per-module detail belongs in `docs/exec-plans/module-index.md`, not here.*

## Where to look

| You need... | Read |
|---|---|
| Current system architecture | `ARCHITECTURE.md` |
| Code conventions and patterns | `docs/patterns/README.md` |
| How this harness works and why each check exists | `docs/harness/README.md` |
| Testing rules and conventions | `docs/TESTS.md` |
| Per-environment differences (local / staging / production) | `docs/ENVIRONMENTS.md` |
| Third-party integrations — config + external state CI can't verify | `docs/integrations/README.md` |
| Plan-mode prelude — read before drafting any plan | `docs/PRE-PLAN.md` |
| Planning methodology (decomposition, outlines, retrospectives) | `docs/exec-plans/PLANNING.md` |
| Build order and per-unit status | `docs/exec-plans/module-index.md` |
| Active, completed, planned, and deferred plans | `docs/exec-plans/` |
| Open decisions (🚧 and ⏳ items, consolidated) | `docs/decisions/OPEN.md` |
| Decision records (why we chose X over Y) | `docs/decisions/` |
| Development workflow and maturity tiers | `docs/process/development-workflow.md` |
| Feature specifications | `docs/specs/` |

*Add a row for every doc as it lands — product spec, data model, integrations, deploy guide, security notes. `scripts/lint-docs.sh` warns when a doc is not reachable from this table, because a doc no agent can find may as well not exist.*

`docs/` is the system of record. If something is not in the repo, it effectively does not exist — write it down before acting on it.

## Core beliefs

1. **Docs are the source of truth.** Not chat, not tickets, not memory. If a decision matters, it lives in `docs/`.
2. **Plans are artifacts.** Substantial work gets a plan in `docs/exec-plans/active/`, which moves to `completed/` with a retrospective. Known shortcuts go to `debt/`.
3. **Decisions are tracked.** Significant choices get a record in `docs/decisions/NNNN-slug.md`; anything still open gets a row in `docs/decisions/OPEN.md`.
4. **Progressive disclosure beats context dumps.** Load the doc you need, not all of them. When a doc outgrows its budget, split it into `docs/<topic>/{README.md,slice.md,…}` so consumers fetch a slice.
5. **Project rules live in the repo, not in an agent's memory.** Codify in `docs/patterns/` or a decision record so every agent inherits them. Personal memory does not transfer between agents, runtimes, or people.

## Boundaries

- **Do not** merge branches or pull requests. Open them, address review, push fixes — the merge is the maintainer's call, even when they have signalled approval in spirit.
- **Do not** mutate a shared environment. Never apply a migration, run a destructive command, or change configuration against staging or production. Write the artifact and stop; a human applies it. *Name your project's specific shared-environment commands here.*
- **Do not** invent specific numbers, dates, or commitments — refund windows, response times, discount percentages, launch dates. If a figure is needed and nobody supplied it, use placeholder language and open a 🚧 row in `docs/decisions/OPEN.md`.
- **Do not** add features, abstractions, or dependencies "for later." Build what the current task requires.
- **Do not** rewrite or delete a decision record after the fact. Records are append-only history — supersede with a new one.
- **Do not** duplicate doc content inline in code or in this file. Link to the doc.

*Add project-specific boundaries as they emerge: content licensing, regulated data, third-party API limits, domain-specific prohibitions.*

## Harness invariants

Mechanically enforced. `scripts/lint-docs.sh --session-start` runs a fast subset at session start; the full suite runs on `/harness-check`, in CI, and in the pre-commit hook. Details and rationale: `docs/harness/README.md`.

1. **Plans are artifacts.** Substantial work has a plan in `docs/exec-plans/active/`. It closes out — retrospective, rename, move to `completed/` — **in the same pull request as the work's final phase**, never a follow-up. Focused changes (bug fixes, doc edits, small refactors) ship as ordinary PRs with no plan artifact. When it is genuinely ambiguous which one you are doing, ask.
2. **Decisions are tracked.** Every 🚧 or ⏳ in `docs/` has a matching row in `docs/decisions/OPEN.md`. Resolved rows move to `RESOLVED.md` rather than being marked resolved in place.
3. **Cross-refs resolve.** Every file path named in any `.md` — markdown link or backticked path — points to a file that exists.
4. **Docs stay lean, measured in tokens.** This file is the only auto-loaded doc, so it carries the map and the universal rules and routes everything else. Budgeted by **byte count**, not just lines: one long line can outweigh dozens of short ones, so a line cap alone reads green while real cost balloons.

## Quality gates

**Before code:** the relevant doc exists and is current; cross-refs resolve; an architectural choice has a decision record.

**After code:** tests ship with the change; the aggregate gate (`bash scripts/check.sh`) is green locally *before* pushing; a reviewer — human or agent — has looked at it.

## Decision rule

*Replace with the actual rule for your project. Examples: "Architectural decisions need a decision record before merge." "Pricing, partnership, scope, and legal calls require both founders." "Anything user-visible needs a paired decision record and spec update."*

## Open decisions

See `docs/decisions/OPEN.md`. Do not encode a pending decision as though it were settled.

## House style

*Preferences, not lessons — delete any you disagree with. They are here because they are easy to state and easy to forget.*

- **Commit locally as you go**, in coherent chunks. Pushing and opening a PR waits for an explicit ask.
- **Lead with the canonical path.** When context determines the answer (local vs. CI, one platform vs. another), do not frame it as Option A vs. Option B — state the canonical path and treat the edge case as a sub-section.
- **No elapsed-time estimates** for implementation work. Describe scope instead — file count, test count, surfaces touched. Estimates in agent-authored docs are guesses that later read as commitments.
- **Comments explain why, never what.** Full sentences, ending in periods. Delete a comment when you delete what it described.

## Keeping this file healthy

- **Pointers only.** This file does not accumulate a changelog or per-feature behavior detail — those live in their content homes and are one `grep` away when an agent actually needs them. The byte budget in `scripts/lint-docs.sh` is the mechanical guard.
- When a section stops being true, delete it that day. Stale guidance is worse than none.
- Commands, stack details, and scaffolding instructions get added **when they exist**, not in anticipation.
