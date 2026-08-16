# Integrations

How this project connects to third-party services — and the discipline for the one class of state the harness **cannot** mechanically verify.

An integration doc is a **mirror**. The real state lives outside the repo: in a provider's dashboard, in DNS, in a webhook registration, in a signing secret pasted into a console. This directory holds a written reflection of that state, so an agent planning a change can see the current config without console access, and a reviewer can tell what the change is meant to make true.

## Why this directory is different

Every other harness guard exists because something failed silently *and a check can catch it* — a broken path, an untracked decision, a duplicate record number. Hosted state has no such check available. `lint-docs.sh` cannot log into a dashboard; CI cannot read a DNS zone or confirm a webhook points where you think it does. For this class, a green suite proves nothing about the outside world.

So the discipline is manual, and it has to be explicit:

> **The doc is the mirror; the PR-body sync-ack is the guard.**

When you change hosted state, you update the mirror doc *in the same PR*, and you put the sync-ack (below) in the PR body. The ack is a human standing in for the check that cannot exist. Reviewing a change to a mirror doc means confirming the hosted side was actually changed to match — because nothing downstream will.

## Integrations

*Add a row per integration as you wire it. `lint-docs.sh` warns when a doc under `docs/` is unreachable from the routing table in `AGENTS.md`, so add the routing row when you add the first one.*

| Integration | Doc |
|---|---|
| *e.g. Payments provider* | *`payments.md`* |
| *e.g. Email / transactional sending* | *`email.md`* |

## Per-integration doc template

Copy this into `docs/integrations/` as `<service>.md`, one file per service. Keep the *External records* section exact — it is the part that drifts.

```markdown
# <Service> — <what it does for us>

**Configured at:** <dashboard URL(s) — where the real state lives>
**Owner:** <who holds console access>

## Environment keys

The variables this integration reads. Names only — values live in the secret
store, never here. Cross-check against docs/ENVIRONMENTS.md.

## External records (the mirror)

The hosted state no CI can see. One row each; keep the values exact.

| Record | Current value / target | Set where |
|---|---|---|
| e.g. Webhook endpoint | https://…/webhooks/x | provider dashboard → Webhooks |
| e.g. DNS / signing selector | … | DNS host / provider console |

## What CI can and cannot verify

State the boundary plainly. e.g. CI checks the endpoint route exists in code;
only the dashboard confirms the provider is actually pointed at it.

## Change discipline

Change the hosted state → update this doc in the same PR → put the
external-state sync-ack in the PR body.
```

## External-state sync-ack

Paste into the PR body of any change that touches a mirror doc:

```markdown
## External-state sync ack
- [ ] Hosted state changed to match this doc (no CI can verify this)
- [ ] Doc updated in the same PR
- [ ] Rollback path noted in the doc
```

## When these docs cross-reference each other

If integration docs grow `§`-section pointers into one another — or you split one into a reference plus a runbook and content moves between them — enable the section-pointer guard (`docs/harness/recipes.md`, recipe 8), scoped to just this set. That is exactly the "content migrates between curated files" case the recipe exists for.
