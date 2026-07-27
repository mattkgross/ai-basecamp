---
name: review-changes
description: Review the current branch locally for doc drift, pattern compliance, security, test coverage, and decision consistency. Read-only — reports findings with severities and does not auto-fix. Use when asked to review the current branch or pull request before pushing.
---

# Review Changes

Review the current branch against the project's own documented standards. Runs locally, before the change leaves the working tree.

**Read-only.** Report findings; do not fix them. The separation matters: a reviewer that edits as it goes produces a diff nobody reviewed, and the author loses the chance to disagree — which is where the useful conversations happen.

## Steps

### 1. Run the mechanical checks first

```bash
bash scripts/lint-docs.sh
```

If it fails, report the failures and stop. Mechanical issues should be fixed before spending attention on judgment calls — and a broken cross-reference may be the whole finding.

### 2. Identify what changed

`git diff` against the default branch. If nothing changed, say so and exit.

### 3. Load the standards

Read these before reviewing. You are checking the change against **the project's** documented standards, not against your own preferences — a finding that cannot be traced to something written down is a preference, and should be labeled `nitpick` if it is reported at all.

- `ARCHITECTURE.md` — structure, boundaries, data model
- `docs/patterns/README.md` and the relevant slices
- `docs/TESTS.md` — what this change owes in tests
- `docs/decisions/OPEN.md` — what is still undecided
- Any project-specific standards in the routing table (security, legal, compliance)

### 4. Doc drift

Does the change need a doc update it did not get? Judgment, not a rule — most changes need none.

- Source changed: does it affect architecture, an API contract, the data model, or a convention? Those need the corresponding doc.
- New doc added: is it in the routing table? An unrouted doc is unreachable.
- Plan finished: was it closed out — retrospective written, renamed, moved to `completed/` — in *this* change rather than deferred to a follow-up?

### 5. Pattern compliance

Check against the patterns docs. Flag deviations, and flag *new* patterns that should be written down — a good approach used once and never documented gets reinvented differently next time.

### 6. Security

Adapt to the project's standards. The generally applicable questions:

- Are new endpoints behind the authorization the equivalent existing ones use?
- Is user input validated at the boundary, before it reaches logic?
- Do new data-access paths carry the same access control as their neighbors?
- Are secrets absent from the diff, including test fixtures and example config?
- Do error messages and logs avoid leaking credentials or personal data?

### 7. Test coverage

New logic needs tests. A bug fix needs a regression test that fails before the fix — if it would pass without the fix, it is not testing the fix. Do not demand tests for copy, config, or styling changes.

### 8. Decision consistency

Does the change implement something still marked as undecided? If it settles an open question, that row should move to `RESOLVED.md` in this same change, and a significant choice should have a decision record.

## Output

One line per finding:

```
**[severity]** path:line — what is wrong, and what to do about it
```

Severities: `nitpick` (preference, non-blocking) · `suggestion` (improvement, non-blocking) · `concern` (address before merge) · `blocker` (must fix).

Close with a count by severity and a recommendation: approve, or request changes.

## Constraints

- **Read-only.** No edits.
- **Be specific.** "Consider improving error handling" is not actionable. Name the file, the line, and the change.
- **Severity is load-bearing.** Only block on real problems. Inflating severity to force attention destroys the vocabulary, and then everything gets negotiated.
- **No findings is a valid result.** Say so briefly and stop. Manufacturing findings to look thorough trains the author to skim your output.
