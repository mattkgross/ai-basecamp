# Basecamp

An AI-first project template for solo builders. Start here, build anything.

## Quick Start

```bash
# Clone and setup
git clone <repo-url>
cd <project>
./scripts/setup.sh

# Run locally
# TODO: Add run command
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for system design, component map, and tech decisions.

## Development

This project follows an AI-first development workflow. See [CLAUDE.md](CLAUDE.md) for agent operating instructions.

### Key docs:
- **[CLAUDE.md](CLAUDE.md)** — Agent operating manual
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — System design + tech decisions
- **[docs/PATTERNS.md](docs/PATTERNS.md)** — Code conventions + lessons learned
- **[docs/specs/](docs/specs/)** — Feature specifications

### Git hooks

Installed automatically via `./scripts/setup.sh`:
- **pre-commit:** Lint, format, secret detection (gitleaks)
- **pre-push:** Build check, doc-drift warning
