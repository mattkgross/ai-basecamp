Run the full harness validation:

```bash
bash scripts/lint-docs.sh
```

If the user passes `--budget` (e.g. `/harness-check --budget`), run the context-budget diagnostic instead:

```bash
bash scripts/lint-docs.sh --budget
```

Report the output verbatim. After a successful run, suggest fixes for any warnings or failures, ordered by impact (failures first, length-cap warnings next, retrospective gaps last).
