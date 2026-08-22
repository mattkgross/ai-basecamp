---
name: audit-loop
description: Adversarially audit one specific change (a refactor, migration, or security/architecture-sensitive change) with a sequential loop of scope-owning subagents — each owns one scope, its focus set by the previous loop's findings, and the loop stops when an agent surfaces no practical feedback and every important scope has been covered. Use when asked to loop-check, adversarially audit, or deeply review a large or sensitive change with agents (not a whole-codebase pass).
---

# Audit Loop

Deeply audit **one change** — a refactor, a migration, an architectural or security-sensitive change — by running a _loop_ of adversarial subagents. Each loop spawns one fresh agent that owns a single scope and tries hard to break the change; the next loop's focus is chosen from what the last one found. You apply the practical fixes between loops and stop when the loop converges.

This is **not** a whole-codebase review — for the standards pass use the project's review skill (`review-pr` / `review-changes`). This is a focused, adversarial, multi-pass audit of a specific change that is too important to trust to a single read: where a missed bug is expensive or hard to reverse, independent perspectives plus feed-forward find what one pass misses.

## When to use

- A large or sensitive change: an auth/security change, a data migration, a shared-contract or cross-cutting refactor — anything a bug in would be costly or hard to undo.
- The user asks to "loop-check", "adversarially audit", or "deeply review this with agents".

For an ordinary change, the standards pass is enough — don't spin up a loop for a small diff.

## How the loop works

1. **Scope the change.** `git diff` against the base branch for the exact file/surface list. The audit covers **this diff**, not the whole repo. Name the change's important scopes up front (see below) — you'll cover each before stopping.

2. **One loop = one adversarial agent owning one scope.** Spawn a subagent — **read-only: it reports, it does not edit** — charged to break the change within its scope. Give it: the diff/file list, its single scope, what prior loops already found and fixed (so it doesn't re-report and can go deeper or adjacent), and the adversarial contract below. Run loops **sequentially** — each one's focus depends on the last one's results, so they can't be parallelized.

3. **Act on the findings, then loop again.** For each _practical_ finding, apply the fix yourself (test-first when it's a code change), verify (tests + typecheck/build), and commit that loop's fixes with a clear message before spawning the next agent. Easy ancillary fixes you notice along the way are fine. For a finding you won't act on, say why — not every finding is practical.

4. **Choose the next scope from what you just learned.** If a loop found bugs a scope's tests passed over, the next loop audits the tests. If it extended a contract, the next audits that contract's docs. Keep going until every important scope has had an owning agent.

5. **Stop when the loop converges.** Make the **final loop a completeness + regression sweep**, charged to either find what the scoped loops missed OR confirm — _with evidence_ — that nothing practical remains. A clean sweep is a stop signal only when it's auditable: the agent must list what it traced, not shrug. Stop when a loop returns no practical feedback **and** all important scopes are covered.

6. **Record it.** Add a short "adversarial audit" note to the change's record (PR description / retrospective): each loop, its scope, and its outcome — so the audit is legible to the next reader.

## Scopes to cover

Pick the scopes the change actually has. A typical set for a substantial change:

- **Correctness & security of the core mechanism** — does it actually do what it claims? Trace the load-bearing invariant to ground truth (installed dependency source, a real run against a real service), never to the code's own comments.
- **Behavior / fidelity vs. what it replaced** — does the new path reproduce the old one where it must? Dropped or mangled data, a resilience or edge-case regression, a divergence from the surface it mirrors.
- **Test rigor & mock realism** — do the tests prove behavior or just run lines? Do mocks match the real shapes they stand in for? What could break without a test failing? (High coverage hides shallow assertions — hunt those.)
- **Docs, policy & conventions** — does the change's documentation match what shipped, and does the code follow the project's written standards? Does any doc overclaim or describe pre-change behavior?
- **Cross-cutting completeness & regression** — the final sweep: the seams _between_ the scoped audits, consumers not yet checked, regressions to existing behavior, performance.

This is a starting set, not a fixed checklist — a migration's scopes differ from an auth change's. The rule: every scope where a bug would matter gets an owning agent before you stop.

## The adversarial contract (put this in every agent's prompt)

- **Assume there are defects; hunt them.** Do not be agreeable. A finding without a concrete failure path (inputs → wrong outcome) is noise — don't pad.
- **Own one scope.** Stay in it; other loops cover the rest. Explicitly tell it which prior scopes are done.
- **Read-only.** Report findings; do not modify files. (You, the orchestrator, apply and verify the fixes — a reviewer that edits as it goes produces a diff nobody reviewed, and the author loses the chance to disagree.)
- **Verify, and mark confidence.** Trace each finding in the code and with read-only checks (grep, a build, a targeted test run). Mark CONFIRMED (traced) vs PLAUSIBLE (needs checking).
- **List what you ruled out.** Negative results must be auditable: say what you checked and found solid, so "nothing here" is evidence, not a shrug.
- **Feed-forward.** Tell it what prior loops found and fixed, so it doesn't re-report and can go deeper or adjacent.
- **Rank by severity**, cite `file:line`, and give a suggested fix.

## Constraints

- **Audit the change, not the codebase.** Scope every agent to the diff. This is not a full-site audit.
- **Sequential, not parallel.** Each loop's focus comes from the last loop's results; parallel agents can't feed forward.
- **You stay in the loop.** Agents find; you decide, fix, verify, and commit — per loop, so the audit trail stays clean and each fix is proven before the next agent runs.
- **Scale to the change.** A contained change may converge in two loops; a large or sensitive one may take four to six. Stop on convergence, not a fixed count.
