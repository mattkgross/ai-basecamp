---
name: harness-bootstrap
description: Scaffold the harness-engineering structure (AGENTS.md routing, CLAUDE.md invariants, lint-docs.sh validator, decision-record system, exec-plan workflow, skill scaffolding) for a new project. Use when starting a fresh repo from this template, or when retrofitting a project that has none of the harness pieces yet. For audit/restructure of an existing project that already has *some* harness, use `harness-ingest` instead.
argument-hint: "[project-name]"
---

# Harness Bootstrap

Scaffold the full harness-engineering structure for a fresh project. Detects whether the repo already has a harness; runs in **scaffold mode** if not, **audit mode** if so.

## Mode detection

Check whether `AGENTS.md` exists in the working directory:

- **No `AGENTS.md`** → scaffold mode (this skill's main path).
- **`AGENTS.md` exists** → audit mode. Run `bash scripts/lint-docs.sh` and report what's missing or drifting. For substantive restructure of an existing repo, redirect the user to `harness-ingest`.

## Scaffold mode — step-by-step

Execute in order. Stop and ask the user before doing anything that requires project-specific judgment.

### 1. Create the directory skeleton

```
docs/exec-plans/active/
docs/exec-plans/completed/
docs/exec-plans/debt/
docs/exec-plans/planned/
docs/decisions/
docs/specs/                # optional — for per-feature spec files
.agents/skills/
.claude/                    # for settings.json (SessionStart hook)
.github/templates/          # PR template lives here
scripts/
```

Add `.gitkeep` to every directory that may be empty (`docs/exec-plans/{active,completed,debt,planned}/`, `docs/decisions/`, `docs/specs/`, `.agents/skills/`, `.github/templates/`).

### 2. Create `AGENTS.md`

Pattern: a routing table (`## Where to look`), 3-5 core beliefs, a do-not list, a decision rule, and a pointer at `docs/decisions/OPEN.md`. Stay under 100 lines.

Ask the user for:
- One paragraph: what the project is, who it serves, the load-bearing constraints.
- Repo state — pre-code? MVP? scaling?
- Any project-specific boundaries (security, content, legal) the agent must respect.
- Decision authority — who decides what.

Use the ai-basecamp template's `AGENTS.md` as the structural model.

### 3. Create `CLAUDE.md`

Thin (under 60 lines) pointer at AGENTS.md plus four numbered harness invariants:

1. **Plans are artifacts.** Active work has a plan in `docs/exec-plans/active/`.
2. **Decisions are tracked.** Every 🚧 / ⏳ in `docs/` must have a row in `docs/decisions/OPEN.md`.
3. **Cross-refs resolve.** Every backtick-quoted file path in any `.md` must point to a real file.
4. **Docs stay lean.** `AGENTS.md` and `CLAUDE.md` under 100 lines; reachable docs under ~400. When a doc grows past 400, split it into `docs/<topic>/{README.md,slice.md,...}` with the README as the routing target.

Plus a "Quality gates" section (pre-code: doc completeness, cross-ref integrity, decision record. Post-code: tests ship with code, lint passes).

### 4. Seed `docs/PATTERNS.md`

Empty template with the canonical pattern format (When / Pattern / Example / Don't-use-when / Added). Patterns get added as the codebase teaches them.

### 5. Seed `docs/decisions/OPEN.md` and `docs/decisions/0001-record-decisions.md`

`OPEN.md`: header explaining what this file is, empty Open table, empty Resolved table.

`0001-record-decisions.md`: the seed ADR establishing the practice. Document format: Date, Status, Context, Decision, Consequences. Numbering rule: sequential, slug for topic clarity, append-only history.

### 6. Copy `scripts/lint-docs.sh` from this template

Includes Checks 1-8 plus the budget diagnostic and SessionStart summary. Tune project-specific bits:

- **Check 1** `REQUIRED_FILES` — add project-specific required files (e.g., `docs/DESIGN.md`, `docs/PRODUCT.md`) once they exist.
- **Check 6** `DENY_PATTERNS` — add deny patterns that suggest copied / pasted / externally-sourced content.
- **Check 6.5** `BANNED_PATTERNS` — pipe-separated regex of commands that must never run in CI or as npm scripts (destructive shared-environment ops, hook bypasses).
- **Check 7** `DEAD_NAME_PATTERNS` — stale doc names that occasionally re-appear in prose after a rename.

Make it executable: `chmod +x scripts/lint-docs.sh`.

### 7. Create `.claude/settings.json` with the SessionStart hook

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "bash scripts/lint-docs.sh --quiet" }
        ]
      }
    ]
  }
}
```

This makes the harness self-validate at every session start. The summary line ("harness OK · N auto-load lines") gives the agent an immediate context-budget cue.

### 8. Create `.github/templates/pull_request_template.md`

Slim — What / Why / Changes / Test plan. Don't bake in language-specific checklists; let projects extend.

### 9. Run `bash scripts/lint-docs.sh`

Should pass with at most warnings. Fix any failures before declaring scaffold complete.

### 10. Print a summary and next steps

Tell the user:
- What was created (path list).
- What needs project-specific filling-in (the placeholder paragraphs in AGENTS.md).
- Suggested first ADR after 0001 (the chosen tech stack — gives the project an early architectural anchor).
- Pointer at `harness-bootstrap`'s sibling skill `harness-ingest` for porting other repos.

## Audit mode — short

If `AGENTS.md` already exists:

1. Run `bash scripts/lint-docs.sh` and report.
2. Check that `.agents/skills/`, `docs/decisions/OPEN.md`, exec-plan directories, and a SessionStart hook all exist.
3. Report findings; offer to create any missing pieces.

If the repo has *some* harness but it's structurally divergent (e.g., docs are large monoliths, no decision tracker, ad-hoc plans), redirect the user to `harness-ingest` for a phased restructure plan.

## Reciprocity convention

When PrepDVM (or any consuming project) evolves a useful harness pattern — splitting a big doc, adding a lint check, codifying a new convention — port the change back to this template in a paired commit. Keeps the template and consuming projects converging instead of diverging.
