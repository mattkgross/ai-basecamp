# Open Decisions

Consolidated index of every pending decision across `docs/`. Mechanically enforced — `scripts/lint-docs.sh` checks that every 🚧 or ⏳ marker in `docs/` has an entry here.

## How this file works

- A 🚧 marker means **needs human input** — someone with authority must decide.
- A ⏳ marker means **pending** — decided in principle, awaiting an event (e.g., a downstream module shipping).
- A ✅ marker means **resolved** — move the row to the Resolved section below or delete it once the decision lands in an ADR or the affected doc.

Every row points to the source doc where the decision is described. When a decision lands, replace the source doc's marker with a pointer to the ADR.

## Open

*This table starts empty. Add rows as decisions surface during planning or implementation.*

| Decision | Source | Notes / Recommendation | Status |
|---|---|---|---|

## Resolved

*Move resolved rows here for historical context. Delete after they no longer add value (typically after the related code stabilizes).*

| Decision | Resolution | Resolved date |
|---|---|---|
