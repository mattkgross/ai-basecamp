# Module Decomposition — Full-Stack Feature Planning

*Created: 2026-04-14*
*Origin: PrepDVM project — extracted as a reusable methodology*

This document describes how to break a product spec into discrete, independently-buildable implementation modules for use by Claude Code (or any AI coding agent) in a full-stack project.

---

## The Core Principle

**One module = one complete, shippable product segment.**

Each module ships UI + API routes + database changes together. Never split a feature into separate FE/BE/DB modules — that creates coordination overhead and leaves things in half-built states. If a module needs "and" more than once to describe its job, it's too big. Split it.

---

## Sizing Heuristics

A well-sized module fits these constraints:

| Dimension | Target |
|-----------|--------|
| Describable in one sentence (without "and") | Required |
| UI screens | 1-3 |
| New API routes | 1-4 |
| New database tables | 0-2 |
| Cross-boundary? (student vs. admin, user vs. internal) | Avoid — split on boundary |
| Completable in one Claude Code session | Required |

If a module fails two or more of these checks, split it.

---

## Decomposition Process

### Step 1: List all features from the product spec
Go through every section of the spec. Write down every distinct feature, screen, and user action. Don't group yet.

### Step 2: Identify natural clusters
Group features that share the same user journey, the same database table, or the same API surface. These are module candidates.

### Step 3: Apply the sizing check
For each candidate, apply the heuristics above. If it fails: split on the most natural boundary. Common splits:
- **Active + Results**: a complex flow and its output are often two modules (e.g., exam-taking vs. exam-results)
- **User + Admin**: user-facing and admin-facing sides of the same feature are separate modules
- **Core logic + Wiring**: algorithm/engine modules separate from the UI surfaces that consume them

### Step 4: Map dependencies
For each module, identify:
- **Hard dependencies**: upstream modules that must be built first (required tables, APIs, auth)
- **Soft dependencies**: modules that enrich this one but aren't blockers (can use mock data if absent)

### Step 5: Order the build sequence
Build order follows the dependency graph:
1. Foundation (app shell, auth)
2. Core product loop (the thing that creates primary value)
3. Layers that depend on the loop (feature modes, AI integrations)
4. Intelligence/analytics surfaces (need real data from the loop)
5. Conversion and business features (payments, referrals)
6. Admin and marketing (largely independent, can be parallelized)

---

## Module Outline Format

Each module lives in "docs/exec-plans/planned/module-NN-slug.md". The outline is intentionally lightweight — detailed plans are written JIT when the module enters active development.

```markdown
# Module NN: [Name]

*Status: Planned — outline only*
*Dependencies: Module XX, Module YY*

> **Before executing:** Review this plan against the current repo state.
> Verify assumptions, check for drift from earlier modules, and surface
> any conflicts or questions before building.

## Goal
[One sentence. No "and".]

## Scope
### In
[Bullet list of what this module ships]

### Out
[Explicit exclusions — prevents scope creep]

## Key Deliverables
### UI / API Routes / Database
[Concrete outputs — screens, routes, tables]

## Acceptance Criteria
[Binary pass/fail checks — not "should be fast" but "P95 < 200ms"]

## v0 Prototype
[Yes / No — and why]

## Environment
[Local / Dev / Prod notes. New env vars.]

## References
[Links to relevant spec sections]
```

---

## The Drift Header

Every module outline includes this header:

> **Before executing:** Review this plan against the current repo state. Verify assumptions, check for drift from earlier modules, and surface any conflicts or questions before building.

This is critical. Modules are written before the code exists. By the time Claude Code picks up a late module, the codebase may look very different from what the plan assumed. The builder must reconcile before executing, not after.

---

## v0 Prototyping

Run v0 (or equivalent UI prototyping tool) **before** full-stack implementation for any module with significant UI surface. This prevents building to a blind design.

**Modules that benefit from v0:**
- Any user-facing screen (core product UI, home, analytics surfaces)
- Any conversion flow (trial results, pricing page, landing page)
- Any complex navigation or layout (multi-state flows, desktop-first layouts)

**Modules that can skip v0:**
- Backend-heavy modules (algorithm engines, webhook handlers, cron jobs)
- Admin-only interfaces (functional over beautiful)
- Modules where the spec provides detailed wireframes

---

## Lifecycle: Planned → Active → Completed

| State | Location | Detail Level |
|-------|----------|-------------|
| Planned | `docs/exec-plans/planned/` | Lightweight outline — goal, scope, key deliverables, acceptance criteria sketch |
| Active | `docs/exec-plans/active/` | Full plan — exact API contracts, complete schema, full acceptance criteria, test cases |
| Completed | `docs/exec-plans/completed/` | Record of what shipped — what was built, what changed from plan |
| Debt | `docs/exec-plans/debt/` | Known shortcuts taken — what needs revisiting later |

**Don't write all detailed plans upfront.** Write the outline, move to active when work starts, flesh out the detail then. Plan 18 written today is stale by the time you reach it.

---

## Anti-Patterns to Avoid

- **Too big:** "Implement the full admin panel" — split into CRUD, review queue, analytics, dashboard
- **FE/BE split:** "Build the UI, then wire up the API" — these go in one module
- **No explicit exclusions:** Without Scope Out, future builders add scope. Always say what this module is NOT.
- **Stale detailed plans:** Writing all detailed plans upfront means late plans are stale by the time you reach them. Outlines now, details JIT.
- **Missing drift header:** Plans age. The drift check is the defense against building on stale assumptions.
- **Too small:** If a module is just one API route with no meaningful UI or schema change, consider whether it belongs in an adjacent module.
