# AI Basecamp — Agent Guide

> This is a **map**, not a manual. It points to the docs that hold the actual content. When you fork this template, replace each placeholder paragraph with project-specific text and add routing rows as new docs land.

## What this project is

*Replace this paragraph with one paragraph about your project: what it is, who it serves, the load-bearing constraints, partners or stakeholders, and the single most important thing an agent should know in the first ten seconds.*

## Repo state

*Replace this section as the project develops. Track shipped milestones, current stack, and architectural state. The pattern in PrepDVM's AGENTS.md is to keep one dense paragraph that lists shipped modules with one-line summaries; an agent who reads only this section knows what's live.*

## Where to look

| You need... | Read |
|---|---|
| Code conventions and patterns | `docs/PATTERNS.md` |
| System architecture | `ARCHITECTURE.md` |
| Module planning methodology | `docs/exec-plans/PLANNING.md` |
| Active, completed, planned, debt plans | `docs/exec-plans/` |
| Open decisions (🚧 and ⏳ items, consolidated) | `docs/decisions/OPEN.md` |
| Decision records (why we chose X over Y) | `docs/decisions/` |
| Development workflow | `docs/process/development-workflow.md` |
| Bootstrap a new project / audit an existing one | `.agents/skills/` |

When the project gains a product spec, business doc, design doc, etc., add rows for them here. Every doc that an agent might need to find should be reachable from this table or one hop downstream.

`docs/` is the system of record. If something isn't in the repo, it effectively doesn't exist — push it into a doc before acting on it.

## Core beliefs

1. **Docs are the source of truth.** Not Slack, not chat, not heads. If a decision matters, it lives in `docs/`.
2. **Plans are artifacts.** Active work has a plan in `docs/exec-plans/active/`. Completion moves to `completed/`. Known shortcuts go to `debt/`.
3. **Decisions are tracked.** Significant choices get an ADR in `docs/decisions/NNNN-slug.md`; the consolidated index is `docs/decisions/OPEN.md`.
4. **Progressive disclosure beats context dumps.** Load the doc you need, not all of them. When a doc grows past ~400 lines, split it into `docs/<topic>/{README.md,slice.md,...}` so consumers fetch a slice, not the whole file.
5. **Project-specific rules go in the repo, not in personal memory.** Codify in `docs/PATTERNS.md` or an ADR so every agent inherits them.

## Boundaries

- **Do not** add features, abstractions, or dependencies "for later." Build what the current task requires.
- **Do not** invent specific numbers, timeframes, or commitments without explicit input from the project owner. Use placeholder language and add a 🚧 entry to `docs/decisions/OPEN.md`.
- **Do not** merge branches or PRs. The project owner owns the merge call.
- **Do not** delete an ADR or rewrite it after the fact — decisions are append-only history. Supersede with a new ADR instead.

*Add project-specific boundaries as the project develops (e.g., content/legal/security restrictions, third-party API limits, domain-specific don'ts).*

## Decision rule

*Replace this section with the actual rule for your project. Examples: "Architectural decisions require an ADR before merge." "Major business decisions (pricing, partnerships, scope, legal) require agreement from both founders." "Anything affecting end users requires a paired ADR + product spec update."*

## Open decisions

See `docs/decisions/OPEN.md` for the consolidated list. Don't encode pending decisions as if they're settled.

## Keeping this file healthy

- Stay under ~100 lines. If it grows, something belongs in `docs/` instead.
- When a section stops being true, delete it the same day. Stale guidance is worse than no guidance.
- Commands, stack, and scaffolding instructions get added here **when** they exist, not before.
