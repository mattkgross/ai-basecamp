---
name: platform-parity-audit
description: Audit behavior parity for one surface ported to a second platform and produce or update its checked-in parity ledger. Use when porting a surface from one platform to another, changing a surface already delivered on the second platform, or when asked to audit or verify behavior-level parity, produce a parity ledger, or find silently-dropped behaviors in a port. Enumerates the SOURCE platform's behaviors exhaustively (the source of truth), verifies each on the target, and classifies ported / deferred / primary-only / secondary-only with file-level evidence — because a target-first audit is structurally blind to absence.
---

# Platform Parity Audit

Audit whether a surface ported to a second platform still *behaves* like the platform it came from, and record the result as a checked-in **parity ledger** — a per-behavior manifest a reviewer can check and a gate can require. The method is deliberately generic: **primary** is the platform that is the source of truth (usually the older or richer one — web is the common case), **secondary** is the port target (a native app, a CLI, an SDK). See `docs/patterns/platform-parity.md` for the policy and the ledger shape.

## When to use

- You are porting a surface to a second platform, or changing one already delivered there.
- You are asked to audit or verify behavior-level parity, produce or update a parity ledger, or hunt for behaviors a port dropped.

**Not for** pixel or visual parity, and not as a replacement for the surface-presence ratchet — this is the *within-surface* behavior layer. And not on a single-platform project: there is no second platform to diverge from.

## The direction is the point

Enumerate from the **primary** platform (the source of truth), then verify on the **secondary**. This is not stylistic — it is the whole method. A secondary-first audit can only inspect what the secondary platform *has*, so it is **structurally blind to absence**: the one thing you most need to find — a behavior the port dropped — is invisible from that side. You find a missing behavior only by listing every primary behavior and checking each against the secondary.

The **ledger is bidirectional even though the audit is not.** After the primary → secondary pass, do a lighter second pass: note any behavior present on the secondary platform with *no primary analogue* (a native-only feature) and record it `secondary-only`. That keeps a deliberate addition from looking like an un-audited gap.

## Method

1. **Identify the surface** and confirm it is delivered on the secondary platform (a key in the delivery map the coverage gate rides). Note the primary and secondary source directories.
2. **Enumerate the primary surface's behaviors exhaustively** by walking the taxonomy below. Be adversarial — assume a behavior is *absent on the secondary platform until proven present*. Read the primary code; do not enumerate from memory or from the secondary happy-path.
3. **Anchor each behavior's primary evidence** with a **stable anchor** — a file path plus a function/symbol name (not a line number, which rots as code moves).
4. **Verify each behavior on the secondary platform.** Present, absent, or present with a different control?
5. **Classify** each behavior — `ported` / `deferred` / `primary-only` / `secondary-only` — filling evidence/tracking/reason so the row *validates* against the ledger schema (which rejects an unclassified, mis-directed, or silently-dropped row).
6. **Second pass (secondary → primary):** record any `secondary-only` native additions with a `reason`.
7. **Write or update the ledger**, giving each behavior a stable, unique kebab `id` so later edits and any regression test can reference it.
8. **Route every gap.** A `deferred` behavior's `tracking` points at a fix plan or a debt note. Emit a consolidated findings list: which gaps, where routed.

## Behavior taxonomy

Walk **every** row for the surface — an omitted row is how absence hides. For each, ask "does the primary surface do this, and does the secondary?"

- **Entry points** — every way the surface is reached or started (buttons, deep links, resume, tab, notification, redirect).
- **User actions** — every interactive affordance (submit, toggle, select, favorite, rate, edit, delete, share, retry).
- **States** — loading, empty, populated, success, and **every error / exhaustion / terminal branch**. Terminal branches are where dropped behaviors hide — the motivating bug lived on an exhausted-input branch the port dead-ended.
- **Branch forks** — feature-flag reads, entitlement/paywall gates, role gates, conditional or A/B flows. A fork present on the primary but hard-coded on the secondary is a divergence.
- **Gestures + keyboard paths** — zoom/pan, pull-to-refresh, swipe, long-press; keyboard and shortcut paths (often source-platform-only → likely `primary-only`).
- **API calls + fields consumed** — every endpoint the primary calls **and which request/response fields it sends or reads**, compared against the secondary's. A field the primary sends that the secondary omits is a concrete, high-signal gap.
- **Terminal / completion states** — how a flow ends, what it records, what the user sees next.
- **Telemetry / analytics events** — events the primary fires; a dropped event is silent analytics drift.

## Classification

| disposition | meaning | required fields |
|---|---|---|
| `ported` | present on both platforms | `primary` **and** `secondary` evidence; `tracking` null. A native-idiom swap of the *same* behavior (action sheet vs. modal) is still `ported` — flag it in `note`. |
| `deferred` | present on one platform, **owed** on the other | `tracking` → fix/debt ref; exactly one of `primary`/`secondary` null (the null side owes it). The gap state. |
| `primary-only` | on the primary platform, intentionally never on the secondary | `primary` evidence, `secondary` null, a `reason`, `tracking` null. The intentional-divergence happy path. |
| `secondary-only` | on the secondary platform, intentionally never on the primary | `secondary` evidence, `primary` null, a `reason`, `tracking` null. The mirror, for native-only features. |

## Honest limit

No mechanism fully auto-diffs behavior between two platforms' implementations. This ledger makes gaps **visible, tracked, and reviewable** and the audit **reproducible** — it does not *prove* parity, and a ledger can be rubber-stamped. The primary-first enumeration and the fixed taxonomy are the mitigation; a wrong or missing row is at least a reviewable, attributable artifact, and behaviors are append-only. State this limit whenever you present a ledger — do not oversell it as proof.

## Constraints

- **Read-only during the audit.** You produce a ledger and a findings list, not code changes.
- **Adversarial.** Assume a behavior is absent until proven present; the happy-path is not the behavior set.
- **Evidence, not assurance.** A stable anchor is a file plus a function/symbol, never a line number.
- **Scratch notes to the scratchpad, never the repo tree.**
- **Portable.** The method and taxonomy work for any primary → secondary port; only the ledger's file location and the delivery-map gate are project-specific, and they degrade gracefully — with no gate wired, the ledger is still a useful reviewable artifact.
