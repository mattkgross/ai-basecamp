#!/bin/bash
# One-command project setup
# Usage: ./scripts/setup.sh

set -e

echo "🚀 Setting up project..."

# --- Install Git Hooks ---
echo "  📎 Installing git hooks..."
cp scripts/hooks/pre-commit .git/hooks/pre-commit 2>/dev/null && chmod +x .git/hooks/pre-commit && echo "  ✅ pre-commit hook installed" || echo "  ⚠️  No .git directory — init git first"
cp scripts/hooks/pre-push .git/hooks/pre-push 2>/dev/null && chmod +x .git/hooks/pre-push && echo "  ✅ pre-push hook installed" || echo "  ⚠️  No .git directory — init git first"

# --- Check Dependencies ---
echo "  🔍 Checking dependencies..."

if command -v gitleaks &> /dev/null; then
    echo "  ✅ gitleaks installed"
else
    echo "  ⚠️  gitleaks not found — install for secret detection: https://github.com/gitleaks/gitleaks#installing"
fi

# TODO: Add project-specific dependency checks here
# Examples:
#   command -v node && echo "✅ Node.js" || echo "⚠️ Node.js not found"
#   command -v dotnet && echo "✅ .NET" || echo "⚠️ .NET not found"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Update ARCHITECTURE.md with your system design"
echo "  2. Update CLAUDE.md if you have project-specific agent rules"
echo "  3. Add your first feature spec to docs/specs/"
echo "  4. Start building!"
