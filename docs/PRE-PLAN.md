# Pre-plan Checklist

Read this **before drafting any plan**. Short by design — keep it that way.

This exists because plans fail in a small number of predictable ways, and all of them are cheaper to prevent than to unwind. Each section below is here because it was skipped and cost something.

**Not applicable outside planning.** Ordinary implementation work — even multi-file refactors and doc sweeps — does not need this checklist or a plan artifact. The design-first rule still applies to visible surfaces, but the brief can live in the conversation. See `AGENTS.md` § Harness invariants for what counts as plan-scale work.

## 1. Visible surfaces get their design settled first

If the work includes any user-visible surface — a screen, a modal, a component, a placement decision — even one described as "simple", **the first phase of the plan is the design pass**, not implementation.

Agents produce competent, generic, interchangeable interfaces from a written spec. That is not a failure of the agent: a written spec is exactly the input a generic layout satisfies. Design direction has to come from somewhere the spec cannot supply.

Non-visual phases — schema, server logic, configuration, refactors — proceed in parallel. Phases producing visible markup wait.

Canonical rule: `docs/patterns/quality.md` § Design before markup.

## 2. Know what the plan settles and what it does not

The plan **settles**: data shape, status workflows, access-control shape, endpoint-versus-action choices, denormalization, validation rules, cross-field constraints, file layout, test approach, and API surface drift from the spec.

The plan does **not** pre-decide: control placement, layout, list columns, filter affordances, badge styling, color, copy tone, empty-state treatment.

If you catch yourself writing "render this at the foot of the block" or "filter chips in a horizontal row", stop. Those are design calls arriving in an implementation document, and once written down they get built without ever being decided.

## 3. Temporary infrastructure and new access surfaces need three answers

If the plan introduces temporary infrastructure or any new way in — an admin route, a role-gated view, a bypass for a pre-launch gate, scaffolding meant to exist only until some milestone — answer all three **in the plan body, before asking for approval**:

1. **Lifecycle.** Is this permanent product or disposable scaffolding? If scaffolding, name where its deletion is tracked. Distinguish the durable parts from the temporary ones — they are rarely the same.
2. **Bootstrap.** How does the first instance come to exist, concretely? Environments do not share state, so an account or record created in one does not exist in another. Spell out the seeding path.
3. **Security surface.** What exactly is exposed, and what is the blast radius? "Authenticate-only, restricted to pre-seeded accounts" and "can enumerate or create accounts" are very different answers.

These three questions get asked at every approval review. Answering them upfront saves the round-trip; more importantly, writing them down is often what reveals that the scaffolding has no deletion plan at all.

## 4. Consult before drafting

- `AGENTS.md` — boundaries, harness invariants, quality gates, decision rule
- `docs/exec-plans/PLANNING.md` — decomposition, outline format, retrospective requirements
- `docs/exec-plans/module-index.md` — build order and what is already shipped
- `docs/patterns/README.md` — conventions this plan must not contradict
- `docs/decisions/OPEN.md` — open decisions that may constrain scope
- `docs/TESTS.md` — what this work will owe in tests
- Any agent-specific memory your runtime exposes

## 5. Decisions that are not yours to make

Per `AGENTS.md` § Decision rule, some choices need human sign-off. When you are unsure whether a call in your plan qualifies, surface it *before* deciding. A decision buried inside an approved plan reads as approved, which is how a call nobody intended to make becomes settled.
