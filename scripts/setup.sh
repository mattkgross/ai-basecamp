#!/usr/bin/env bash
# setup.sh — One-command harness setup. Idempotent; safe to re-run.
#
# Usage: ./scripts/setup.sh

set -e

cd "$(dirname "$0")/.."

echo "Setting up the harness..."
echo ""

# ── Git hooks ──────────────────────────────────────────────────────────────
# Copied rather than symlinked so a hook edit is a deliberate act (copy again)
# instead of an accident. If your stack already manages hooks (husky, pre-commit,
# lefthook), skip this and call scripts/lint-docs.sh from that tool instead.
if [ -d .git ]; then
  echo "Installing git hooks..."
  for hook in pre-commit pre-push; do
    if [ -f "scripts/hooks/$hook" ]; then
      cp "scripts/hooks/$hook" ".git/hooks/$hook"
      chmod +x ".git/hooks/$hook"
      echo "  ✓ $hook installed"
    fi
  done
else
  echo "  ⚠ No .git directory — run 'git init' first, then re-run this script"
fi
echo ""

# ── Agent-guide alias ──────────────────────────────────────────────────────
# Agent runtimes look for different filenames. A symlink means one file, so the
# two names cannot drift apart.
echo "Checking the agent-guide alias..."
if [ -L CLAUDE.md ]; then
  echo "  ✓ CLAUDE.md → $(readlink CLAUDE.md)"
elif [ -f CLAUDE.md ]; then
  echo "  ⚠ CLAUDE.md is a regular file — it can drift from AGENTS.md."
  echo "    To link them: rm CLAUDE.md && ln -s AGENTS.md CLAUDE.md"
elif [ -f AGENTS.md ]; then
  ln -s AGENTS.md CLAUDE.md
  echo "  ✓ CLAUDE.md → AGENTS.md (created)"
fi
echo ""

# ── Optional tooling ───────────────────────────────────────────────────────
echo "Checking optional tooling..."
if command -v gitleaks >/dev/null 2>&1; then
  echo "  ✓ gitleaks (pre-commit secret detection)"
else
  echo "  ⚠ gitleaks not found — the pre-commit hook will skip secret detection"
  echo "    Install: https://github.com/gitleaks/gitleaks#installing"
fi
echo ""

# ── Harness validation ─────────────────────────────────────────────────────
echo "Validating the harness..."
bash scripts/lint-docs.sh --fix || true
echo ""

cat <<'EOF'
Setup complete. Next:

  1. Fill in AGENTS.md — the placeholder sections marked in italics.
  2. Replace ARCHITECTURE.md with your actual system design.
  3. Add your stack's gates to the CHECKS array in scripts/check.sh.
  4. Tune the CONFIG block at the top of scripts/lint-docs.sh.
  5. Record your stack choice as docs/decisions/0002-<slug>.md.

Full fork checklist: TEMPLATE_README.md
EOF
