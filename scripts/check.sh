#!/usr/bin/env bash
# check.sh — Run every local quality gate in one command.
#
# Runs ALL checks even when one fails, so you see the full picture in a single
# pass instead of fixing-and-rerunning down a chain. Exits non-zero if anything
# failed.
#
# Wire this to your task runner (`npm run check`, `make check`, `just check`) and
# run it before opening or refreshing a PR. Catching a failure at your desk costs
# seconds; catching it in CI costs a push, a wait, a fix, and a re-push.

set -u

# ═══════════════════════════════════════════════════════════════════════════
# CONFIG — add your stack's gates here, cheapest first.
#
# Each entry is "Label|command to run". The harness lint is stack-neutral and
# always runs; everything else is yours to fill in. Examples:
#
#   "TypeScript|npx tsc --noEmit"
#   "ESLint|npm run lint"
#   "Prettier|npm run format:check"
#   "Tests|npm test"
#   "Ruff|ruff check ."
#   "Pytest|pytest -q"
#   "Cargo|cargo clippy -- -D warnings"
#   "Build|make build"
# ═══════════════════════════════════════════════════════════════════════════
CHECKS=(
  "Docs lint|bash scripts/lint-docs.sh --quiet"
)
# ═══════════════════════════════════════════════════════════════════════════

cd "$(dirname "$0")/.." || exit 1

failed=()

for entry in "${CHECKS[@]}"; do
  label="${entry%%|*}"
  command="${entry#*|}"
  echo ""
  echo "── $label ─────────────────────────────────────"
  if eval "$command"; then
    echo "✓ $label"
  else
    echo "✗ $label"
    failed+=("$label")
  fi
done

echo ""
if [ ${#failed[@]} -eq 0 ]; then
  echo "== All checks passed =="
  exit 0
else
  echo "== FAILED: ${failed[*]} =="
  exit 1
fi
