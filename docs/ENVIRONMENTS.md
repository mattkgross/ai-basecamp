# Environments

What differs between environments, and where each difference is configured.

This document exists because "it works locally" is the most common false negative in software, and the reason is almost always an environment difference nobody wrote down. The matrix below is the answer to "why does this behave differently there?" — kept in one place so it is a lookup rather than an investigation.

## Matrix

*Replace with your actual environments. Add a row for every axis that genuinely differs — and only those. A row that is identical everywhere is noise.*

| Axis | Local | Preview / staging | Production |
|---|---|---|---|
| Data store | *e.g. local instance, resettable* | *shared non-production* | *live* |
| Third-party services | *test mode / sandbox* | *test mode* | *live keys* |
| Email / notifications | *captured locally, never sent* | *sent to allowlist only* | *sent for real* |
| Scheduled jobs | *not running* | *running, reduced frequency* | *running* |
| Error reporting | *console only* | *reporting, separate project* | *reporting + alerting* |
| Feature gates | *all on* | *matches production* | *controlled rollout* |
| Seed data | *fixtures* | *anonymized subset* | *real* |

## The rule that prevents most environment bugs

**Configuration is validated once, at startup, and fails loudly.** Not read ad hoc where it is needed. An unset value read directly becomes an empty string or a null, silently, and the failure surfaces far from its cause — usually in the one environment you cannot debug interactively.

See `docs/patterns/anti-patterns.md` § Unvalidated configuration.

## Credentials and scoping

Two rules that are boring until they are not:

**Name keys by scope, not by convenience.** A variable named for what it *is* (`ANALYTICS_WRITE_KEY_PRODUCTION`) rather than where it happens to be used prevents the mistake this section exists for: a production credential reaching a non-production environment because both were called the same thing.

**Never reuse a credential across environments.** Beyond the obvious blast-radius argument, this is what makes rotation possible: a key used in exactly one place can be rotated without coordinating anything. A key used in three places gets rotated in one and quietly breaks the other two.

*Record your project's key inventory and which scope each belongs to.*

## Per-environment notes

### Local

*Setup steps, how to reset state, seeded test accounts, what is stubbed and what is real.*

### Preview / staging

*How instances are created, what data they see, what is deliberately different from production, who can reach them.*

### Production

*Deploy path, who can trigger it, rollback procedure, what alerting exists.*

## Adding an environment-affecting knob

When you add configuration that differs between environments, do all of these in the same change — a partial addition is how an environment ends up misconfigured in a way nobody discovers until it matters:

1. Add it to the validated configuration schema, with an explicit required-or-optional decision.
2. Add it to the example environment file, with a comment explaining what it does.
3. Set it in every environment that needs it — including CI, which is an environment and is the one people forget.
4. Add a row to the matrix above if the *value* differs by environment.
5. If it gates behavior rather than supplying a value, note who can change it and what the default is.

Step 3 is the one that bites. A configuration value missing from CI does not fail at commit time — it fails during the build, after the push, in a job whose error message points at page rendering rather than at configuration.
