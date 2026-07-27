# Development Workflow

How this harness expects work to move from idea to production, and which parts to add when.

Every quality gate, review agent, and enforcement hook lives **in the repo**. No runtime dependency on any external service, tool, or person beyond what is checked in. A fork should work on a machine that has never seen the original.

## Maturity tiers

Start at Tier 1 for every project. Graduate when the product has real users and the cost of a bug exceeds the cost of the automation. Nobody needs to decide this by a threshold — you will feel it.

### Tier 1 — day one

- **Modes:** explore → design → build → ship → maintain. Fluid, not gated.
- **Docs:** the agent guide, architecture, patterns, and per-feature specs. Four. Add more when you feel the absence.
- **Review:** one reviewer, focused on patterns and reuse. Add others when a specific problem demands one.
- **Testing:** specification tests plus implementation tests. No adversarial pass yet.
- **Bugs:** fix and move on. A regression test every time; no formal post-mortem.
- **Monitoring:** an uptime check and error reporting. That is all.
- **Enforcement:** local hooks (secrets, formatting, harness lint) and the aggregate gate before pushing. Local is the primary layer.

### Tier 2 — real users

Everything above, plus:

- **More reviewers** — security review once accounts and user data exist; architecture review once the codebase is large enough for boundary violations to be non-obvious.
- **CI-side review** mirroring the local reviewers, catching what bypassed hooks.
- **Adversarial test pass** on changes.
- **Post-mortems** with three required outputs (below).
- **More docs** — a lessons file if patterns is not enough, module-level notes, generated API docs.
- **Automated triage** — error report to issue to draft fix.
- **Fuller observability** — analytics, performance metrics, structured logging, alerting.

**Graduation triggers:** paying users, recurring revenue, bug volume that justifies automation, or a codebase large enough that structural drift stops being visible by eye.

## Core principles

1. **The repo is self-contained.** Gates, agents, and hooks are checked in. A fork inherits the whole factory.
2. **Docs update with the change.** Enforced by hooks and CI, not by willpower — willpower fails silently.
3. **One agent, one job, tight context.** A narrowly-scoped reviewer beats a generalist. This applies to *automated* reviewers; an interactive implementation session reasonably combines code, tests, and docs.
4. **Rules files are executable policy.** The patterns docs and agent guide are not documentation — they are what hooks and reviewers read. Editing a rule deploys new enforcement.
5. **Every discovery flows back.** Reactively from bugs and proactively from things that went well. Nothing gets dropped silently.
6. **Build for today, leave the upgrade path visible.** For each significant choice, know the answer to "what changes if this grows ten times?" It should be "upgrade the tier", not "rewrite it".
7. **Push enforcement to the cheapest layer.** Local hooks, then non-model CI, then model-powered review. Spend tokens only on what genuinely needs language understanding.
8. **Trust is a ratchet.** Start hands-on. Each solved failure mode — biased tests, no reuse, no self-correction — earns a little more autonomy. Autonomy is granted against demonstrated reliability, not assumed.

## Phases

### 0 — Ideation

Find the right thing before building anything. Problem statement, competitive landscape, technical sketch, revenue hypothesis, risk flags. Judgment-heavy: research accelerates, humans decide. Explore two or three ideas in parallel and kill fast.

### 1 — Design and architecture

Make the structural decisions before code exists. This is where rushing is most expensive, because these are the decisions that are hardest to reverse later.

Covers system structure, data modeling, API contracts, technology selection, module boundaries, dependency choices, and interaction flow. Every significant choice records *why* — the alternatives and the constraint that eliminated them. That is the part that matters in six months, and it goes in a decision record.

**Output:** `ARCHITECTURE.md` mapping components, responsibilities, connections, and scaling levers; the data model; API contracts, even rough ones.

**Exit criteria:** you can explain the system to someone else without hedging. If you cannot, an agent cannot build it well — an agent's output quality is bounded by the clarity of what it was given.

### 2 — Specs and acceptance criteria

Produce documents precise enough to execute against without guessing at intent.

- **Test cases before code.** Written against the spec, not the implementation. This is what solves biased testing: a test written after the code asserts what the code *does*.
- **Acceptance criteria are binary.** Not "should be fast" but "p95 under 200ms". Not "handles errors" but "returns 400 with this error shape".
- **Specs say what *not* to build.** Explicit exclusions are the only thing that prevents scope growth.

Refinement is expected once implementation reveals a constraint the spec could not see — but the refinement goes through the spec, not silently into the code.

### 3 — Scaffolding

Set up the environment, pipeline, and every quality gate. This is the factory, and it is built once.

Repo structure, agent guide, architecture doc, patterns skeleton, reviewer definitions, pre-commit and pre-push hooks, basic CI (build, test, lint, harness). CI must be green before feature work starts, and the doc-drift check gets wired here rather than bolted on later — a gate added after the habit has formed is a gate that gets argued with.

### 4 — Implementation

One feature per session. No context-switching across unrelated components: an agent's output degrades as the context broadens, and so does a reviewer's.

Every session starts with the same non-negotiable context: the spec, the acceptance criteria, the test cases, and the architecture doc. When the plan meets reality and something has to change, **pause, update the spec, then continue** — a silent divergence means every later reader is working from a document that is now fiction.

### 5 — Testing

Three layers with independent failure modes. See `docs/TESTS.md` for the full treatment.

Specification tests must pass before merge, without exception. Adversarial findings start as recommendations and graduate to gates as trust builds. A previously passing test that starts failing is always investigated, never deleted to reach green.

### 6 — Review

Reviewers are defined once, in `.agents/skills/`, and run from two places: locally against the working tree, and in CI against a pull request. **One definition, two execution contexts** — never two copies of the same prompt, because they drift and then the two layers disagree.

| Reviewer | Focus | Tier |
|---|---|---|
| Patterns | Reuse, conventions, compliance with the patterns docs | Day one |
| Security | Injection, authorization, data exposure, input validation | When accounts exist |
| Architecture | Boundaries, dependency direction, structural drift | When the codebase is large |
| Doc drift | Were the relevant docs updated (file diff, no model) | Day one, free |

Findings carry a severity — `nitpick`, `suggestion`, `concern`, `blocker` — because a finding without one gets argued about instead of fixed. Anything needing human judgment is flagged explicitly and blocks by default, rather than relying on someone noticing it.

Human review is not line-by-line correctness; reviewers and tests cover that. It is architectural judgment, taste, and direction.

### 7 — Delivery

The pipeline is in the repo and changes to it go through the same review as code. Non-production deploys automatically on merge; production is a deliberate promote until confidence justifies otherwise. A red default branch stops everything until it is green.

### 8 — Security

From day one, cheaply: dependency vulnerability scanning, secret detection in the pre-commit hook, HTTPS and security headers from the host. Add static analysis and model-powered security review with scale. Threat modeling happens during design, not after launch.

### 9 — Observability

Tier 1 is an uptime check and error reporting — thirty minutes of setup. Resist instrumenting further before the product is validated; you will measure the wrong things and then trust them.

Tier 2 adds usage analytics, performance metrics, structured logging, and real alerting.

**Prefer the vendor's own controls.** If a service already offers the cap, quota, or alert you need, configure it there rather than building a parallel mechanism in application code. A home-grown version is one more thing to maintain, and it fails in ways the vendor's does not.

### 10 — Maintenance

Tier 1: fix as found, regression test every time, and a note in the anti-patterns doc when the bug reveals a *class* of mistake rather than a typo.

Tier 2 post-mortems produce three things, and the third is the point:

1. **The fix** — resolved, with a regression test.
2. **The explanation** — root cause, written down.
3. **The process change** — a new rule, a new check, or a new test case. If none is warranted, record explicitly that this was a one-off. Skipping this step is how the same bug arrives twice wearing different clothes.

### 11 — Documentation

Docs describe what **is**, not what was. Version control holds the history; a doc that hedges between present and past state is useless for both.

| Document | Updated when |
|---|---|
| Agent guide | New rules, boundaries, or process changes |
| `ARCHITECTURE.md` | Any structural change |
| `docs/patterns/` | A new convention or a lesson from a bug |
| Feature specs | Behavior changes |

**Drift prevention, cheapest first:** a file-diff check on every change (free); a model reading the diff against the relevant doc on flagged changes (small context); a periodic full audit (scheduled, never per-change).

**Source-of-truth order when they disagree:** code, then tests, then specs, then design docs. The higher one is reality; the lower one is a bug report against itself.

## The learning loop

Every discovery flows back into the system. Reactive *and* proactive — a pattern that worked is as valuable as a bug that did not.

```
Discovery
  → Project-specific, or universal?
      project-specific → update the project docs
      universal        → update the project docs AND the template
  → Does this change how agents should behave?
      yes → update the agent guide, a reviewer definition, or a lint check
  → Does this change how humans should work?
      yes → update this document
```

Enforcement is what closes the loop. Process changes become rules; rules become checks; checks run on every commit without anyone remembering. The rules get smarter and the hooks enforce the new rules — see `docs/harness/README.md`.

A short periodic review catches what no bug triggered: "what did I learn recently that is not written down anywhere?" Slow drift and proactive lessons both hide from event-driven capture, because nothing failed to prompt them.

## Feeding the template back

Every process learning gets one question: **would I want this on day one of the next project?** If yes, it belongs in the template, not only in this project. Track the change in the template's changelog so its evolution is legible.

Keep the template stack-agnostic where possible and mark stack-specific pieces clearly. Guards that cannot be neutral go in `docs/harness/recipes.md` with the bug that motivated them, so the knowledge survives even where the code cannot be reused.
