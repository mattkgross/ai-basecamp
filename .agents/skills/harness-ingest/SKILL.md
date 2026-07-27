---
name: harness-ingest
description: Audit an existing repo and produce a phased, reversible plan to retrofit the harness — routing table, lint validator, decision records, plan directories, doc splits. Use when an established project wants to adopt the harness without disrupting existing workflows. For greenfield projects use harness-bootstrap instead.
argument-hint: "[path-to-target-repo]"
---

# Harness Ingest

Adapt an existing repo to the harness in **phased, reversible** steps.

The output is a plan the user reviews before any structural change lands. This skill never makes destructive moves on the first pass — retrofitting a harness into a working repo means touching files people rely on, and the failure mode is a helpful-looking restructure that breaks someone's mental map of their own project.

## Inputs

`$ARGUMENTS` — path to the target repo, defaulting to the working directory. This skill operates only on the target and never modifies the template.

## Step 1 — Inventory

Classify each piece as **present**, **partial**, or **absent**, with a one-line note on what was found:

| Piece | Look for |
|---|---|
| Routing table | An agent guide with a "where to look" table |
| Agent-guide aliasing | Whether the runtime-specific filenames are symlinked or duplicated |
| Code patterns | A patterns doc, split or monolithic |
| Architecture doc | Any current description of system structure |
| Decision records | A directory of numbered records |
| Open-decision tracker | A single place listing undecided things |
| Plan directories | Active / completed / planned / debt separation |
| Planning methodology | Written decomposition and retrospective rules |
| Lint validator | Any mechanical doc-health check |
| Session hook | Anything running at agent session start |
| Skills | Reusable agent procedures |
| Pull request template | **At the path the platform actually reads** |
| Doc sizing | Whether any doc exceeds a sane token budget |

## Step 2 — Size the docs

```bash
git ls-files 'docs/*.md' 'docs/**/*.md' | xargs -I{} wc -c {} | sort -rn | head -10
```

Measure **bytes**, not lines. A line count is blind to long-line bloat, and the docs most in need of splitting are frequently the ones that read fine by line count — dense tables and packed status entries are exactly where the tokens hide.

For each oversized doc, identify the natural seams (usually top-level headings) and propose the slice layout: `docs/<topic>/README.md` as the routing index plus one file per seam.

## Step 3 — Find routing gaps

For every doc, check whether it is reachable from the entry point. Anything unreachable is effectively invisible — it exists, and no agent will ever open it. List them.

## Step 4 — Surface anti-patterns

Flag any of these:

- **Convenience copies** — summary docs, FAQ files, or forwarding caches not mechanically synced with their source. These go stale first and are believed longest, because they read as authoritative. Recommend deleting them in favor of making the source small enough to traverse directly.
- **Backticked paths that do not resolve** — the most common drift symptom. List every one.
- **`TODO` / `FIXME` standing in for a decision** — untracked open questions. Either elevate to a tracker row or close as not-happening.
- **Completed plans with no retrospective** — the institutional memory is already gone; flag for backfill while anyone still remembers.
- **Duplicated agent guides** — two runtime-specific files with overlapping content. Check whether they have already drifted; they usually have, and neither is marked as authoritative.
- **Section references that no longer resolve** — pointers into headings that were renamed or moved.

## Step 5 — Write the plan

Write to the **target repo** as a plan file, structured as:

1. **Context** — why this restructure, what the user gets.
2. **Inventory** — the matrix from Step 1.
3. **Splits** — proposed layout per oversized doc, with paths, sizes, and index design.
4. **Sequencing** — four to six tiers, lowest blast radius first, each independently shippable as one commit. Lint and hook wiring go in the first tier, so every later tier is verified by mechanism rather than by eye.
5. **Risks and reversibility** — what breaks during each tier, what the lint catches, how to revert.
6. **Verification** — how to confirm each tier landed.
7. **Files touched** — exact paths.

## Step 6 — Stop

Do **not** execute the plan. Hand it back with a one-paragraph summary and let the user approve as-is, edit and re-invoke, or reject specific tiers.

Each tier runs as its own session, with the lint re-run after each to confirm it stayed green.

## Constraints

- **Never delete without an orphan audit.** If the plan removes a doc, first map every section to its replacement home. That audit is mandatory and runs *before* the delete — it is also how you discover the one section that had no replacement.
- **Preserve history.** Splits and renames use `git mv`. A rewrite-and-delete loses the trail, which is exactly the trail someone needs when the split turns out wrong.
- **Respect existing conventions that do not conflict.** If the project keeps its architecture doc at a lowercase path under its docs directory rather than at the repo root, leave it there. The harness is a shape, not a set of filenames; renaming for conformity spends the user's goodwill on nothing.
- **Stop at any destructive step the owner has not approved.** Even when told to proceed autonomously. The harness exists to make destructive actions safer, not faster.

## Reciprocity

When an ingest finds a pattern in a target repo that the template lacks — a lint check, a tracker convention, a useful skill — record it as a candidate to port back. The template should learn from every ingest; otherwise each one re-derives the same lessons.
