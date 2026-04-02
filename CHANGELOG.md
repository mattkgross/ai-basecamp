# Template Changelog

## v0.1 (2026-04-01)

Initial template based on AI-First Solo Builder workflow design.

### Included
- CLAUDE.md — agent operating manual with doc boundary definitions
- ARCHITECTURE.md — skeleton with sections for components, data model, tech decisions
- docs/PATTERNS.md — empty structure with pattern format guide
- docs/specs/ — directory for feature specs
- .github/review-agents/pattern-reviewer.md — single review agent (Tier 1)
- .github/templates/pull_request_template.md — PR checklist
- scripts/setup.sh — one-command project setup
- scripts/hooks/pre-commit — lint, format, gitleaks secret detection
- scripts/hooks/pre-push — build check, doc-drift warning
- .gitignore — common ignores
- README.md — project readme skeleton
- TEMPLATE_README.md — how to use this template

### Not Yet Included (Tier 2 / future)
- CI workflow (stack-specific — add per project)
- Security reviewer agent
- Architecture reviewer agent
- Auto-fix pipeline
- LESSONS.md, DECISIONS.md templates
- Layer 3 adversarial test action
