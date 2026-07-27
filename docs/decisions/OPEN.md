# Open Decisions

Consolidated index of everything across `docs/` still awaiting a choice, a trigger, or a scheduled action. **Pending only** — closed items live in [`RESOLVED.md`](RESOLVED.md), which keeps this file cheap enough to load on every planning pass.

## What earns an entry

Exactly two things:

- **(a) A decision awaiting a human call** — something an agent must not settle unilaterally. Marked 🚧.
- **(b) A deferred follow-up with a concrete reopen trigger** — "revisit when X happens", where X is observable. Marked ⏳.

If the call is obvious, already settled, or a routine code-level TODO, it does not belong here. A tracker that accumulates everything is a tracker nobody reads. When in doubt, leave it out.

## Lifecycle

Add the row in the change that **defers** the work. Close it in the change that **resolves** it, by **moving the row to [`RESOLVED.md`](RESOLVED.md)** with a one-line resolution and a pointer to the decision record or plan that settled it.

Do **not** mark a row resolved and leave it here. That in-place close is the single mechanism by which this file bloats — a resolved row stops being read but never gets deleted, so the file grows monotonically while its signal drops. Progress notes on a still-open row are fine; the resolved marker is the signal to relocate.

**Mechanically enforced** by the harness lint (`scripts/lint-docs.sh`): every 🚧 / ⏳ marker elsewhere in `docs/` must name its source doc here, this file must carry no resolved rows, and a byte budget warns before it drifts back toward bloat. Rationale for each: `docs/harness/README.md`.

## Decisions awaiting a human call (🚧)

*Empty. Add rows as decisions surface.*

| Decision | Source | Notes / recommendation | Status |
|---|---|---|---|

## Deferred, with a reopen trigger (⏳)

*Empty. Every row here needs an observable trigger — not "later".*

| Item | Source | Trigger | Status |
|---|---|---|---|
