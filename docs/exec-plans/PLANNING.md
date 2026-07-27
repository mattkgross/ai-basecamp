# Planning Methodology

How to break work into discrete, independently-buildable modules that a coding agent can execute without guessing at intent.

> **Before drafting any plan, read `docs/PRE-PLAN.md`.** Short by design. It catches the mistakes that plans actually make — pre-deciding things that are not the planner's to decide, and skipping the design step for user-visible surfaces.

A **module** here means one complete, shippable segment of the product — not a layer of one. Adjust the vocabulary to your project; the sizing logic is what matters.

## The core principle

**One module ships end to end.** Interface, logic, and data changes go together. Splitting a feature into separate front-end / back-end / schema modules creates coordination overhead and leaves the system in half-built states that nobody can test.

If describing a module needs the word "and" more than once, it is too big. Split it.

## Sizing heuristics

| Dimension | Target |
|---|---|
| Describable in one sentence without "and" | Required |
| Completable in one focused working session | Required |
| User-facing screens or surfaces | 1–3 |
| New API endpoints | 1–4 |
| New data-model entities | 0–2 |
| Crosses an audience boundary (end user vs. internal) | Avoid — split on the boundary |

Failing two or more of these means split.

## Decomposition process

1. **List every feature** from the spec. Every distinct screen, action, and behavior. Do not group yet.
2. **Find the natural clusters.** Features sharing a user journey, a data entity, or an API surface are module candidates.
3. **Apply the sizing check.** Where a candidate fails, split on the most natural seam. The ones that recur:
   - **Flow + result** — a complex interaction and the surface that reports its outcome are usually two modules.
   - **End user + internal** — the user-facing and admin-facing sides of one feature are separate modules.
   - **Engine + consumers** — core logic separates from the surfaces that call it.
4. **Map dependencies.** *Hard* — upstream modules that must exist first. *Soft* — modules that enrich this one but can be stubbed.
5. **Order the build.** Foundation (shell, auth) → the core loop that creates the value → layers depending on that loop → surfaces needing real data → conversion and business features → internal tooling. Record the order in `module-index.md`.

## Module outline format

Outlines live in `docs/exec-plans/planned/` as `module-NN-slug.md`. Deliberately lightweight — details are written just-in-time when the module goes active, because a detailed plan written now is stale by the time you reach it.

```markdown
# Module NN: Name

*Status: Planned — outline only*
*Dependencies: Module XX, Module YY*

> **Before executing:** review this plan against the current repo state.
> Verify its assumptions, check for drift from earlier modules, and surface
> conflicts or questions before building.

## Goal
One sentence. No "and".

## Scope
### In
What this module ships.
### Out
Explicit exclusions. Without these, scope grows.

## Key deliverables
Concrete outputs — surfaces, endpoints, entities.

## Acceptance criteria
Binary pass/fail. Not "should be fast" but "p95 under 200ms". Not
"handles errors" but "returns 400 with this error shape".

## Design
Does this need a design pass before implementation? Yes / no, and why.
See `docs/PRE-PLAN.md`.

## Environment
Per-environment notes. New configuration keys.

## References
Links to the spec sections this implements.
```

## The drift header

Every outline carries it:

> **Before executing:** review this plan against the current repo state. Verify its assumptions, check for drift from earlier modules, and surface conflicts or questions before building.

This is load-bearing. Plans are written before the code exists, so by the time module 15 is picked up the codebase may not resemble what module 15 assumed. Reconcile *before* executing, not after — discovering the mismatch halfway through means unwinding work.

## The retrospective

Every module gets a "What actually shipped" section appended before it moves to `completed/`. It is the mirror of the drift header: the drift header reconciles the plan against reality *before* building; the retrospective records the divergence *after* shipping, so the next module's drift check has something concrete to reconcile against.

Cover five things:

1. **What actually shipped** — one paragraph. Dates, links, the surface now available to downstream work.
2. **Phase by phase** — what each phase delivered. Note anything that landed differently than scoped.
3. **Deviations from the plan** — numbered. For each: what changed, why, and the lesson if there is one. **This is the highest-value part.** Patterns hide here, and they are invisible from the code alone.
4. **Deferred elsewhere** — explicit re-routes, naming the receiving module so `module-index.md` gets updated in the same pass.
5. **Outstanding follow-ups** — anything needing a row in `docs/decisions/OPEN.md` or a new outline. If this module *resolved* an existing row, close it in this same change by moving the row to `RESOLVED.md`.

The retrospective is a forcing function, not a writing exercise. Abandoned experiments, implicit deferrals, and "we would do this differently" lessons evaporate into chat history if nobody writes them down at close — and the next agent has no chat history. It has this file.

The harness lint warns when a completed plan has no retrospective. Supporting artifacts alongside a plan (design briefs, interview notes) opt out with `<!-- no-retrospective: reason -->`.

## When to write the full plan

1. Move the outline from `planned/` to `docs/exec-plans/active/`.
2. Expand it: exact contracts, full schema, complete acceptance criteria, test cases.
3. Review it against the current repo state and update before building.
4. On completion: append the retrospective, rename to `YYYY-MM-DD-slug.md`, move to `completed/`, and update `module-index.md`. **This close-out ships in the same change as the module's final phase — never a follow-up.**

Known shortcuts taken deliberately go to `docs/exec-plans/debt/` with what was skipped and what would trigger fixing it.

## One pull request per module

A phased module ships as **one PR** at close-out. Phases are commit-level structure on a single branch, not PR-level structure.

**Why:** a reviewer evaluates the module as one coherent change. Per-phase PRs fragment the review surface — reviewing one logical feature means context-switching across several PRs — and stacked-PR tooling adds overhead disproportionate to a module this size. Per-phase commit messages (`type(module-NN): Phase X — summary`) give the PR an internal narrative a reviewer can scan without leaving it.

**In practice:** finish a phase → commit, do not open a PR. Finish the module → open the single PR with the close-out artifacts in it. If the maintainer explicitly asks for stacked PRs — usually because one phase is independently shippable and time-sensitive — do that instead. One PR is the default.

## Anti-patterns

- **Too big.** "Implement the admin panel." Split into the CRUD surface, the review queue, the analytics view.
- **Layer split.** "Build the UI, then wire the API." One module.
- **No exclusions.** Without *Scope → Out*, scope grows. Always say what the module is not.
- **All plans written upfront.** Plan 18 is stale before you reach it. Outlines now, details just-in-time.
- **Missing drift header.** Plans age. The drift check is the defense against building on stale assumptions.
- **Skipped retrospective.** Moving a plan to `completed/` without recording what shipped. The lessons evaporate and the next drift check has nothing to check against.
- **Close-out in a follow-up.** Moving the plan, writing the retrospective, and updating the index *after* the implementation merged. The close-out is part of the implementing change.
- **Per-phase PRs.** See § One pull request per module.
