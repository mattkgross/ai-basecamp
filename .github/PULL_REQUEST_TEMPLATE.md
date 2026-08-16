<!--
This file must live at .github/PULL_REQUEST_TEMPLATE.md (or .github/pull_request_template.md,
or the repo root, or docs/). GitHub does not look anywhere else — a template in a
subdirectory like .github/templates/ is silently never used.
-->

## Summary

<!-- One or two sentences. Link the decision record, plan, or issue. -->

## Changes

<!-- Grouped by area — data model / API / interface / docs. Not a file list; the diff is already the file list. -->

## Risks

<!-- Migrations, signature changes, behavior shifts, anything hard to reverse. "None" is a valid answer. -->

## Test plan

<!-- Replace with your project's gates. Keep it to things a reviewer would otherwise have to ask about. -->

- [ ] `bash scripts/check.sh` green
- [ ] Tests added or updated for the behavior change
- [ ] Manual verification: <what you actually exercised, or N/A>

## Docs

- [ ] Architecture, patterns, or spec updated if this changed any of them
- [ ] New doc added to the routing table in `AGENTS.md`
- [ ] External-state sync ack in the PR body if this touched a doc under `docs/integrations/` (or any other mirror of hosted state) — see `docs/integrations/README.md`
- [ ] Plan closed out — retrospective, rename, moved to `completed/` — if this finishes one

## Out of scope

<!-- Deferred items and where they are tracked. Delete if none. An untracked deferral is a dropped one. -->
