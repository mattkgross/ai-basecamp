# Code Patterns & Conventions

How things are done in this codebase. Read by humans, by agents, and by the review skill.

This ships **pre-split** rather than as one file that grows into a split later. The patterns doc is the one most certain to outgrow a single file — every bug and every convention lands here — and splitting a doc that agents already reference means fixing every inbound link. Starting split costs nothing.

## Format

Every entry answers four questions. The fourth is the one people skip and the one that makes a pattern usable:

```
### Pattern name

**When:** The situation this applies to.
**Pattern:** What to do.
**Example:** Concrete code.
**Don't use when:** Where this is the wrong choice.
```

A pattern without a *Don't use when* becomes a rule someone applies where it does not belong. If you cannot name a case where the pattern is wrong, you have probably written a preference rather than a pattern.

## Index — domain → slice

| Domain | File |
|---|---|
| Architecture & organization (boundaries, naming, abstraction) | [architecture.md](architecture.md) |
| Error handling & debugging (fail loud, diagnosis before fix) | [errors.md](errors.md) |
| Quality & process (comments, testing, dependencies, pre-PR gate) | [quality.md](quality.md) |
| Anti-patterns (what not to do, and what it cost to learn) | [anti-patterns.md](anti-patterns.md) |
| Platform parity (keeping a surface behavior-faithful when ported to a second platform) | [platform-parity.md](platform-parity.md) |

*Add a slice when a domain accumulates enough entries to be worth its own file — data access, frontend conventions, API contracts, type safety, AI features, whatever your stack accretes. Add the row here so the slice is reachable.*

Most tasks need exactly one slice. Open that file and find the pattern by name rather than reading the set.

## Review standards

*Tune these to your project. They are what a reviewer — human or agent — is measured against.*

- **Scope:** correctness, pattern compliance, naming, test coverage, accessibility.
- **Blocking issues:** *name the small set of things that always block. Keep it short and absolute — a long list of blockers gets negotiated, which means nothing blocks.*
- **Severity vocabulary:** `nitpick` (style preference, non-blocking) · `suggestion` (improvement, non-blocking) · `concern` (should address before merge) · `blocker` (must fix). Findings without a severity get argued about instead of fixed.
- **Disagreements:** the reviewer states the tradeoff once. The maintainer decides.
