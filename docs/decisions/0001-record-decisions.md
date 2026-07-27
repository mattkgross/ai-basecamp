# 0001 — Record significant decisions

**Date:** *fill in when you fork*
**Status:** Accepted
**Deciders:** *who*

## Context

Decisions made in conversation disappear. Decisions buried in a long document cannot be found. Both failures have the same consequence: six months later someone — a new contributor, a coding agent, or the original author — re-opens a settled question, cannot find why it was settled, and either re-litigates it or quietly reverses it.

The expensive part is never the decision. It is the *reasoning*: the alternatives considered, the constraint that ruled them out, the tradeoff accepted. That is what evaporates, and it is exactly what you need when circumstances change and you have to judge whether the decision still holds.

## Decision

Keep lightweight decision records in `docs/decisions/`, one per significant choice, using this format:

```
# NNNN — Title

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Superseded by NNNN
**Deciders:** Who was involved

## Context
What forced a decision. The constraints in play.

## Decision
What was chosen.

## Consequences
What follows — tradeoffs accepted, things to watch, what this makes harder.
```

Conventions:

- **Numbering is sequential and permanent.** `NNNN` is four digits; the slug describes the topic. Numbers are never reused, and the lint enforces uniqueness — two branches independently taking "the next number" produces a silent collision, because differing slugs mean the files merge with no conflict.
- **Records are append-only.** A decision that stops being right is **superseded**, never edited or deleted: set its status to `Superseded by NNNN` and write the new one. The old reasoning is why the old choice was correct at the time, and that context is what tells you whether the new one is an improvement or a repeat of a mistake.
- **Open questions are not records.** Anything still undecided gets a row in [`OPEN.md`](OPEN.md) with a 🚧 or ⏳ marker. A record is written when the choice is made.
- **Write one when the reasoning will matter later.** Architectural direction, a vendor or dependency you would find painful to replace, a schema shape, a policy with legal or financial consequences. Not for choices whose reasoning is self-evident from the code.

## Consequences

- Every open-decision marker in `docs/` must appear in `OPEN.md` — enforced by the harness lint, so the set of undecided things stays discoverable in one read.
- Record numbers stay unique — enforced.
- Records accumulate. That is the point: the directory becomes a readable history of how the architecture came to be, in the order it happened.
- There is a small tax on genuinely significant choices and none at all on ordinary ones. If writing a record feels heavy, the decision may not need one.
