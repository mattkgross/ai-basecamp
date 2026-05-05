# ADR 0001 — Record architectural decisions

*Date: project start*
*Status: Accepted*

## Context

A growing project accumulates decisions: which framework, which database, which auth flow, what the access tier model is, whether a feature is in or out of MVP. If those decisions live only in chat history or someone's head, future contributors (human or agent) re-litigate them every time, often without the context that made the original decision correct.

Architectural Decision Records (ADRs) capture significant decisions in append-only form. Each ADR is a single Markdown file that records what was decided, why, and what the consequences are. Future readers can see the reasoning without having to reconstruct it.

## Decision

We record significant architectural decisions as ADRs in `docs/decisions/NNNN-slug.md`.

### Format

Each ADR uses this structure:

```markdown
# ADR NNNN — Title

*Date: YYYY-MM-DD*
*Status: Proposed | Accepted | Superseded by ADR NNNN | Deprecated*

## Context

What is the situation? What forces are at play? What problem are we solving?

## Decision

What did we decide? Be specific. Include the chosen option and (briefly) the alternatives considered.

## Consequences

What becomes easier? What becomes harder? What new obligations does this create?

## References (optional)

Links to related code, other ADRs, external docs.
```

### What qualifies as significant

A decision is ADR-worthy when at least one of these is true:

- **It locks in a technical choice** that future work will assume (framework, datastore, auth model, deployment target).
- **It defines a tier, role, or boundary** that other decisions will reference (access tiers, environment shape, public/private API split).
- **It rejects an alternative** that future contributors might re-propose without the original context.
- **It documents a workaround** that should not be mistaken for the desired state (technical-debt entries also belong in `docs/exec-plans/debt/`).

Trivial choices (variable names, small refactors, single-bug fixes) don't need ADRs — the commit message is sufficient.

### Numbering

ADRs are numbered sequentially. `0001` is this decision. The next is `0002`, regardless of topic. Don't try to group by topic via numbering — the sequence is purely chronological. Use the slug for topic clarity.

### Updating an ADR

ADRs are append-only history. If a decision changes:

1. Write a new ADR documenting the new decision.
2. Set the original ADR's status to `Superseded by ADR NNNN`.
3. Don't edit the original's content. The historical record stands.

## Consequences

- New contributors (human or agent) can see why the project is the way it is by reading `docs/decisions/`.
- A `🚧` or `⏳` marker in any doc must have a matching row in `docs/decisions/OPEN.md` — `scripts/lint-docs.sh` enforces the sync.
- ADRs add a small overhead per decision; the value compounds as the project ages and decisions accumulate.

## References

- The "Architecture Decision Records" pattern, popularized by Michael Nygard's 2011 essay and adopted widely since.
- `docs/decisions/OPEN.md` — the consolidated open-decisions tracker.
