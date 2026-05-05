---
name: harness-ingest
description: Audit an existing repo and propose a phased plan to retrofit the ai-basecamp harness pattern (AGENTS.md routing, CLAUDE.md invariants, lint-docs.sh validator, decision records, exec plans, skill scaffolding). Use when an established project wants to adopt the harness without breaking existing workflows. For greenfield projects, use `harness-bootstrap` instead.
argument-hint: "[path-to-target-repo]"
---

# Harness Ingest

Adapt an existing repo to the harness pattern in **phased, reversible** steps. The output is a plan file the user reviews and approves before any structural change lands.

This skill never makes destructive moves on the first pass. It produces a plan; the user executes the plan tier-by-tier with confirmations at decision points.

## Inputs

- `$ARGUMENTS` — path to the target repo (defaults to current working directory).
- The skill operates entirely on the target repo. It does not modify the ai-basecamp template.

## Step 1 — Inventory

Read enough of the repo to classify each harness piece as **present**, **partial**, or **absent**. Specifically:

| Harness piece | What to look for |
|---|---|
| Top-level routing | `AGENTS.md` with a "Where to look" table |
| Agent invariants | `CLAUDE.md` with harness invariants section |
| Code patterns | `docs/PATTERNS.md` or equivalent |
| Architecture doc | `ARCHITECTURE.md`, `docs/DESIGN.md`, or equivalent |
| Decision records | `docs/decisions/` with ADRs |
| Open-decision tracker | `docs/decisions/OPEN.md` (or similar) |
| Exec-plan dirs | `docs/exec-plans/{active,completed,debt,planned}/` |
| Planning methodology | `docs/exec-plans/PLANNING.md` |
| Lint validator | `scripts/lint-docs.sh` or similar |
| SessionStart hook | `.claude/settings.json` with SessionStart |
| Skills | `.agents/skills/*/SKILL.md` or `.claude/commands/*.md` |
| PR template | `.github/templates/pull_request_template.md` |
| Doc-length sanity | All `docs/**/*.md` under ~400 lines |

For each row: present / partial / absent, with a one-line note on what was found.

## Step 2 — Diagnose oversized docs

Run an equivalent of:

```bash
git ls-files 'docs/**/*.md' | xargs -I{} wc -l {} | sort -rn | head -10
```

Any doc over ~400 lines is a split candidate. For each: identify the natural seams (top-level H2 sections) and propose the slice file layout (`docs/<topic>/README.md` index + slice files keyed on the H2 sections).

## Step 3 — Identify routing gaps

For every `docs/*.md` and `docs/<topic>/README.md` in the target repo, check whether it appears in the existing routing surface (AGENTS.md, README.md, or the dominant nav). Anything not reachable from the entrypoint is an orphan or a hidden doc.

## Step 4 — Surface anti-patterns

Flag any of these if you see them:

- **"Convenience copies"** — summary docs, FAQ files, forwarding caches that aren't mechanically synced with their sources. These go stale first; recommend deletion in favor of making the source small enough to traverse directly.
- **Backticked references to non-existent paths** — common drift symptom. List them.
- **TODO / FIXME without a corresponding 🚧 / ⏳ marker** — un-tracked decisions. Recommend either elevating to a marker + OPEN.md row or closing as not-going-to-happen.
- **Docs in `completed/` that lack retrospectives** — the "what actually shipped" pattern is load-bearing for institutional memory; flag for backfill.
- **Section anchors (`§ NN.M`) that no longer match heading numbers after silent edits** — a brittleness symptom.

## Step 5 — Produce `docs/HARNESS_INGEST_PLAN.md`

Write a plan file in the **target repo** at `docs/HARNESS_INGEST_PLAN.md`, structured as:

1. **Context** — why this restructure is being proposed; what the user gets.
2. **Inventory table** — the present/partial/absent matrix from Step 1.
3. **Splits** — proposed split layout for each oversized doc, with file paths, approximate line counts, and the slice index design.
4. **Sequencing** — 4-6 tiers, ordered low-blast-radius first. Each tier is independently shippable as a single commit.
5. **Risks & reversibility** — what breaks during each tier, what the lint will catch, how to revert.
6. **Verification** — how to confirm each tier landed cleanly (`bash scripts/lint-docs.sh`, end-to-end skill invocation, etc.).
7. **Critical files** — exact paths the user will touch.

Use PrepDVM's harness restructure (recorded in `docs/exec-plans/completed/` of the PrepDVM repo and via the ai-basecamp template) as a reference shape. The PrepDVM session split DB.md, CATEGORIES.md, QUESTION_RULES.md, PATTERNS.md, and PRODUCT.md across 5 tiers, with decision-sync and AGENTS-index lint patches in T1; skill drift fixes in T5; same pattern transplants here.

## Step 6 — Stop and wait

Do NOT execute the plan after writing it. Hand the file back to the user with a one-paragraph summary and let them decide:

- Approve the plan as-is.
- Edit the plan file and re-invoke this skill (which will re-read and proceed).
- Reject specific tiers and execute the rest.

Each tier executes as its own session. The user runs `/harness-bootstrap` (audit mode) after each tier to confirm the lint stays green.

## Constraints

- **Never delete anything in the target repo without an orphan audit.** If the plan calls for deleting a redundant doc, the audit step (mapping each section to its replacement home) is mandatory and must run *before* the delete.
- **Never edit the target repo's history.** Splits and renames preserve git history via `git mv`. Direct file rewrites lose the trail.
- **Respect the target repo's existing conventions when they don't conflict with the harness.** If the project already has `docs/architecture.md` instead of `ARCHITECTURE.md`, leave it; the harness pattern is shape-of-doc, not exact filename.
- **Stop if the project owner hasn't approved a destructive step.** Even in auto mode. The harness is supposed to make destructive actions safer, not faster.

## Reciprocity

When this skill discovers a useful pattern in a target repo that the ai-basecamp template doesn't yet capture (a new lint check, a decision-tracker convention, a useful skill), record it in `docs/decisions/OPEN.md` of the ai-basecamp repo as a "candidate to port back" item. The template should learn from every ingest.
