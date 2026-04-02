# AI Basecamp — How to Use This Template

## Quick Start

1. Copy this template into a new repo (or use GitHub's "Use this template" feature)
2. Run `./scripts/setup.sh` to install git hooks
3. Replace `ARCHITECTURE.md` with your actual system design
4. Customize `CLAUDE.md` with project-specific agent rules
5. Add lint/format/build commands to the hook scripts and CI workflow
6. Start building

## What's Included (Tier 1)

```
CLAUDE.md                              ← Agent operating manual
ARCHITECTURE.md                        ← System design skeleton
docs/
  PATTERNS.md                          ← Code conventions (starts empty)
  specs/                               ← Feature specs go here
.github/
  review-agents/
    pattern-reviewer.md                ← CI review agent prompt
  templates/
    pull_request_template.md           ← PR checklist
scripts/
  setup.sh                            ← One-command project setup
  hooks/
    pre-commit                         ← Lint, format, secrets
    pre-push                           ← Build, doc-drift check
```

## What to Customize

- **Hook scripts:** Add your lint/format/build commands (marked with TODO)
- **CI workflow:** Add a `.github/workflows/ci.yml` for your stack
- **Doc-drift mappings:** Update `pre-push` hook with your source→doc mappings
- **.gitignore:** Add stack-specific ignores

## Tier 2 (Add When Growing)

When the project has real users and revenue, consider adding:
- Security reviewer (`.github/review-agents/security-reviewer.md`)
- Architecture reviewer (`.github/review-agents/architecture-reviewer.md`)
- Auto-fix pipeline (`.github/workflows/auto-fix.yml`)
- LESSONS.md, DECISIONS.md, module READMEs
- Layer 3 adversarial testing in CI

See `research/development-workflow.md` for the full methodology.

## Feedback Loop

Every process learning from any project should flow back here:
- "Would I want this on day one of the next project?" → Update this template
- Track changes in CHANGELOG.md
