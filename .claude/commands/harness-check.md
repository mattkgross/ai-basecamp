Run the full harness validation.

If the user passed `--budget`, run only the context-budget diagnostic and report it verbatim:

```bash
bash scripts/lint-docs.sh --budget
```

Otherwise:

1. Run `bash scripts/lint-docs.sh` (full output — not `--quiet`, not `--session-start`).
2. Read `docs/decisions/OPEN.md` and cross-check it against the 🚧 / ⏳ markers in `docs/` **in both directions**. The lint only catches markers missing from the tracker; it cannot see the reverse — a tracker row whose underlying marker is gone, or whose reopen trigger has already fired. Report both.
3. Summarize: failures first, then budget/length warnings, then routing and retrospective gaps.
4. For each finding, suggest a concrete fix. Order by impact, not by check number.

Report the lint output as-is rather than paraphrasing — the messages carry their own remediation pointers.
