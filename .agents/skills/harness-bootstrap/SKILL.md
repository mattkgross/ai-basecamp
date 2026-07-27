---
name: harness-bootstrap
description: Scaffold the harness structure — agent guide, routing table, lint validator, decision records, plan directories, session hooks — for a new project. Use when starting a fresh repo from this template, or retrofitting a project that has none of these pieces. For a project that already has some harness and needs restructuring, use harness-ingest instead.
argument-hint: "[project-name]"
---

# Harness Bootstrap

Scaffold the harness for a fresh project, or audit one that already has it.

## Mode detection

Check whether `AGENTS.md` exists in the working directory:

- **Absent** → scaffold mode (below).
- **Present** → audit mode. Run `bash scripts/lint-docs.sh`, report what is missing or drifting, and offer to fill gaps. For a substantive restructure, redirect to `harness-ingest`.

## Scaffold mode

Work in order. **Stop and ask before anything requiring project-specific judgment** — a scaffolded guide full of confidently wrong guesses is worse than one with visible placeholders, because nobody knows to correct it.

### 1. Directory skeleton

```
docs/exec-plans/{active,completed,planned,debt}/
docs/decisions/
docs/patterns/
docs/harness/
docs/specs/
.agents/skills/
.claude/commands/
.github/workflows/
scripts/
```

Add `.gitkeep` to anything that may be empty. `bash scripts/lint-docs.sh --fix` creates the required subset.

### 2. `AGENTS.md`

The routing table plus the universal rules. Ask the user for:

- One paragraph: what the project is, who it serves, the load-bearing constraints.
- Repo state — pre-code, MVP, or scaling?
- Project-specific boundaries the agent must respect (security, content, legal, regulatory).
- Decision authority — who decides what, and what needs sign-off.

**Leave anything they cannot answer as a visible italic placeholder.** Guessing here is the worst outcome: the guide is auto-loaded on every session, so a wrong guess gets treated as fact indefinitely.

Then symlink the aliases so they cannot drift:

```bash
ln -s AGENTS.md CLAUDE.md
```

On Windows without symlink support, keep a real `CLAUDE.md` that is a pointer *only* — a couple of lines saying "read AGENTS.md" — never a copy.

### 3. `docs/patterns/`

Copy the pre-split shape: `README.md` as the routing index, plus a slice per domain. Start with `architecture.md`, `errors.md`, `quality.md`, `anti-patterns.md`. Patterns accumulate as the codebase teaches them; the anti-patterns file is worth the most and starts nearly empty.

### 4. `docs/decisions/`

Three files: `OPEN.md` (pending only), `RESOLVED.md` (closed rows), and `0001-record-decisions.md` (the seed record establishing the practice, including the numbering rule and the append-only rule).

### 5. `scripts/lint-docs.sh`

Copy it and tune **only the CONFIG block at the top**:

- `REQUIRED_FILES` — add project docs as they land.
- `XREF_PREFIXES` — add the source directory once docs cite source paths.
- `DENY_PATTERNS` — content that must never be committed.
- `BANNED_AUTO_COMMANDS` — commands that must never run unattended.
- `DEAD_NAME_PATTERNS` — populate after the first rename, not before.
- Budgets — leave the defaults until they are wrong.

`chmod +x scripts/lint-docs.sh`.

### 6. `scripts/check.sh`

Add the project's gates to the `CHECKS` array, cheapest first. This becomes the pre-PR gate and the body of the CI job, so it should be the single answer to "is this ready?"

### 7. Session hooks

`.claude/settings.json` and `.codex/hooks.json`, both running `bash scripts/lint-docs.sh --session-start`. Create the file for every agent runtime the project uses — the harness should not depend on which one someone opens.

### 8. `scripts/hooks/` and `.github/`

Install the pre-commit and pre-push hooks via `bash scripts/setup.sh`. Add the pull request template at `.github/PULL_REQUEST_TEMPLATE.md` — **that exact path**. GitHub reads only that file, the lowercase variant, the repo root, or a docs directory; a template tucked into a `.github` subdirectory is silently never used, and nothing tells you. Add `dependabot.yml` and a CI workflow that at minimum runs the harness lint.

### 9. Verify

`bash scripts/lint-docs.sh` should pass with at most warnings. Fix every failure before declaring the scaffold complete — a harness that ships red teaches everyone to ignore it on day one.

### 10. Report

Tell the user what was created, which placeholders still need filling, and that their first decision record after `0001` should be the stack choice — it gives the project an early architectural anchor and gets the record habit started while it is cheap.

## Audit mode

1. Run `bash scripts/lint-docs.sh` and report.
2. Confirm each piece exists: routing table, `docs/decisions/OPEN.md`, plan directories, session hook, patterns index, pull request template *at the path GitHub reads*.
3. Report findings and offer to create what is missing.

If the repo has some harness but is structurally divergent — monolithic docs, no decision tracking, ad-hoc plans — redirect to `harness-ingest` for a phased plan.

## Reciprocity

When a project evolves a useful harness pattern — a new lint check, a doc split that worked, a convention that stuck — port it back to the template. Ask one question: **would I want this on day one of the next project?** If the pattern is stack-specific, add it to `docs/harness/recipes.md` with the bug that motivated it rather than dropping it.
