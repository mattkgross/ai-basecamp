# Resolved Decisions

Where rows from [`OPEN.md`](OPEN.md) go when they close. Append-only.

Why this file exists rather than deleting closed rows: "we considered that and chose otherwise" is the answer to a question that gets re-asked, and without a record the same debate runs again from scratch. But keeping those rows in `OPEN.md` makes the always-loaded tracker grow forever. Splitting them separates the two access patterns — `OPEN.md` is read constantly and must stay small; this file is read occasionally, on purpose, when someone asks "didn't we look at this?"

Each row records what was decided and where the reasoning lives. The reasoning itself belongs in a decision record (`NNNN-slug.md`), not here — this is an index.

| Decision | Resolution | Where the reasoning lives | Resolved |
|---|---|---|---|
