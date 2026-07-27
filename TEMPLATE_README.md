# Fork Checklist

What to do after cloning this template. Delete this file once you have worked through it — it is scaffolding, not project documentation.

## 1. Detach and set up

```bash
rm -rf .git && git init && git add -A && git commit -m "Initial commit from ai-basecamp"
./scripts/setup.sh
```

`setup.sh` installs the git hooks, creates the `CLAUDE.md` → `AGENTS.md` symlink, and runs the validator.

## 2. Fill in `AGENTS.md`

This is the only auto-loaded doc, so it is the highest-leverage file in the repo. Replace each *italic placeholder*:

- **What this project is** — one paragraph. What it is, who it serves, the load-bearing constraints, and the single most important thing an agent should know first.
- **Repo state** — pre-code, for now.
- **Boundaries** — name your shared-environment commands (the ones an agent must never run against staging or production) and any domain-specific prohibitions.
- **Decision rule** — who decides what, and what needs sign-off.
- **House style** — keep what you agree with, delete the rest. These are preferences, not lessons.

**Leave a placeholder rather than guessing.** A wrong guess here is loaded into every session and treated as fact.

## 3. Write `ARCHITECTURE.md`

Replace the skeleton with your actual design: components with their responsibilities and connections, the data model, and each significant technology choice **with the reasoning**. The reasoning is what you will need in six months when circumstances change and you have to judge whether the choice still holds.

## 4. Record your stack as decision `0002`

Your first real decision record. It gives the project an architectural anchor and starts the record habit while it is still cheap — the habit is hard to start later, because by then there is a backlog of undocumented decisions and writing the first one feels like admitting the debt.

## 5. Wire your stack into the gates

Three places, and they should agree:

- **`scripts/check.sh`** — add your gates to the `CHECKS` array, cheapest first.
- **`.github/workflows/ci.yml`** — replace the placeholder step. Pin the runtime version in a file, not inline.
- **`scripts/hooks/pre-commit`** — add per-file fixers if you use them. Keep them scoped to the staged set.

## 6. Tune the validator's CONFIG block

Only the block at the top of `scripts/lint-docs.sh`:

| Knob | Set it when |
|---|---|
| `REQUIRED_FILES` | A new doc becomes load-bearing |
| `XREF_PREFIXES` | Your docs start citing source paths — add `src/` or your equivalent |
| `SOURCE_DIR`, `SOURCE_EXTENSIONS` | Your layout or language differs from the default |
| `DENY_PATTERNS` | You have content that must never be committed |
| `BANNED_AUTO_COMMANDS` | You have commands that must never run unattended |
| `DEAD_NAME_PATTERNS` | **After your first rename** — not before |
| Budgets | The defaults are wrong for you. They probably are not yet. |

## 7. Take the recipes you need

`docs/harness/recipes.md` holds guards that cannot be stack-neutral — database invariants, package-manager override enforcement, CI configuration coverage, numbered-file uniqueness. Each names the failure it catches. Paste in what applies; ignore the rest.

## 8. Stack-specific ignores

Add your build output, dependency directories, and local config to `.gitignore`.

## 9. Delete what you do not need

Genuinely optional: `docs/specs/` if you plan differently, `docs/ENVIRONMENTS.md` if you have exactly one environment, `docs/process/development-workflow.md` if you already know how you work. Deleting a doc means also removing its routing row — the validator will tell you if you forget, which is the point.

## 10. Verify

```bash
bash scripts/lint-docs.sh
```

Green, or warnings you understand. Fix failures before starting feature work: a harness that ships red teaches everyone to ignore it on day one, and that habit does not reverse.

---

## Feeding learnings back

When you discover something in a project that would have helped from the start, ask: **would I want this on day one of the next project?** If yes, it belongs in the template.

- Universal mechanism → the validator or the harness docs.
- Stack-specific guard → `docs/harness/recipes.md`, **with the bug that motivated it**. The bug is what convinces the next reader not to delete it.
- Process change → `docs/process/development-workflow.md`.

Record it in the template's `CHANGELOG.md` so its evolution stays legible.
