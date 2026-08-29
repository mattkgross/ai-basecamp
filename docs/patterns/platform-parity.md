# Platform Parity

*Slice of [docs/patterns/](README.md). Keeping a surface ported to a second platform behavior-faithful to the platform it came from.*

**Opt-in, and dormant until you have a second platform.** Everything here keys off one map — the surfaces *delivered on the secondary platform*. A single-platform project leaves that map empty, so nothing is required and nothing fires: zero ledgers, zero ceremony. It costs something only when a second platform ships its first surface, and then only one cheap ledger for that one surface. Adopt it the day a port begins, not before.

**The blind spot it closes.** A surface can *exist* on the second platform and still have quietly dropped a behavior the original performs. Presence checks — "is there a screen file for this surface?" — are blind to that: they answer *does the surface exist*, never *what does it do*. In the source project a ported practice surface shipped without one of its terminal-branch behaviors (a caught-up learner who hit Start with nothing due should have auto-originated a dedicated re-review session; the port dead-ended that branch instead), and every surface-presence guard stayed green. The gap surfaced only in a later hand-audit. Behavior-level parity closes that blind spot with a checked-in evidence artifact — the *ledger*.

## Behavior-level parity — the ledger

**When:** You port a surface from one platform to another (web → a native app is the common case, but the mechanism is platform-agnostic) and you need "parity" to mean *behavior* parity, enforced with evidence rather than promised.

**Pattern:** For each surface *delivered* on the secondary platform, keep a **parity ledger** — a per-behavior manifest listing every behavior of the *primary* surface and its disposition on the secondary one. Four dispositions, each with a required-fields contract a schema enforces, so an unclassified, mis-directed, or silently-dropped behavior cannot validate:

| disposition | meaning | required fields |
|---|---|---|
| `ported` | present on both platforms | `primary` **and** `secondary` evidence; `tracking` null, `reason` null. A native-idiom swap of the *same* behavior (an action sheet for a modal) stays `ported` — flag the control swap in `note`. |
| `deferred` | present on one platform, **owed** on the other | exactly one of `primary`/`secondary` evidence is null (the null side owes it); a `tracking` ref to the fix or debt note. The gap state. |
| `primary-only` | on the primary platform, intentionally never on the secondary | `primary` evidence, `secondary` null, a `reason`; `tracking` null. The intentional-divergence happy path. |
| `secondary-only` | on the secondary platform, intentionally never on the primary | the mirror — `secondary` evidence, `primary` null, a `reason`; `tracking` null. For features native to the second platform (a pull-to-refresh with no original analogue). |

The load-bearing rule is a biconditional: **`deferred` iff a `tracking` ref, and iff exactly one side is null.** It mirrors, one level down, whatever `deferred ⟺ tracking` rule a surface-level registry already uses. Because the schema requires the evidence/tracking/reason per disposition, a row cannot sit unclassified or point the wrong way.

**Example:** the shape, with an empty registry and an empty delivery map — the default state (placeholder surface keys shown commented):

```ts
// The four dispositions.
type Disposition = "ported" | "deferred" | "primary-only" | "secondary-only";

// One behavior of a surface, and where it lives on each platform. `primary` /
// `secondary` are stable anchors (a file path + a function/symbol name, never a
// line number) or null when the behavior is absent there — whichever side is
// null is the platform that lacks it. A schema refinement ties `disposition` to
// (primary, secondary, tracking, reason):
//   ported         -> both set;                     tracking null; reason null
//   deferred       -> exactly one null (XOR);       tracking set;  reason null
//   primary-only   -> primary set, secondary null;  reason set;    tracking null
//   secondary-only -> secondary set, primary null;  reason set;    tracking null
interface Behavior {
  id: string;              // stable kebab slug, unique within the surface
  description: string;
  primary: string | null;
  secondary: string | null;
  disposition: Disposition;
  tracking: string | null;
  reason: string | null;
  note: string | null;
}
interface Ledger { surface: string; behaviors: Behavior[] } // >= 1 behavior

// The registry of ledgers, keyed by surface. EMPTY by default.
const PARITY_LEDGERS: Record<string, Ledger> = {
  // "some-surface": { surface: "some-surface", behaviors: [ /* ... */ ] },
};

// The secondary-platform delivery map: surface -> screen file(s) that must
// exist. EMPTY by default — this is what keeps the harness dormant. A port adds
// its key here (and its ledger above) in the same change.
const SECONDARY_DELIVERY: Record<string, readonly string[]> = {
  // "some-surface": ["src/features/some/Screen.tsx"],
};
```

The runnable schema (the per-disposition refinement) and the coverage test that binds the two maps together live in the harness recipes ([docs/harness/recipes.md](../harness/recipes.md)) — stack-specific, with the production bug that motivated them.

**Don't use when:** the project is single-platform (leave it dormant — the default, which costs nothing); the risk is already covered by a surface-presence check (behavior parity is the *within-surface* layer, not a replacement for the presence ratchet); or you are chasing *pixel* parity rather than *behavior* parity — a native-idiom control swap is `ported`, not a divergence.

## Direction — enumerate from the primary platform

The audit that fills a ledger runs **primary → secondary**, and the direction is the whole method, not a style choice. A secondary-first audit can only inspect what the secondary platform *has*, so it is **structurally blind to absence** — the one thing you most need to find, a behavior the port dropped, is invisible from that side. You find a missing behavior only by enumerating every behavior of the primary surface (the source of truth) and checking each against the secondary one. The reproducible method and its behavior taxonomy are the [`platform-parity-audit`](../../.agents/skills/platform-parity-audit/SKILL.md) skill.

The **ledger is bidirectional even though the audit is not.** `secondary-only` (and a direction-agnostic `deferred`) give a secondary → primary divergence a first-class, reviewable home the moment a native-only feature appears, so a deliberate addition never reads as an un-audited gap.

## Enforcement rides the delivery map

The coverage gate keys off `SECONDARY_DELIVERY`, nothing else. Every surface in that map must carry a ledger, no ledger may exist for a surface not in it, and each ledger's `surface` field must match its key. Three consequences:

- **Auto-enrollment, zero per-surface wiring.** The same change that marks a surface delivered must add its ledger, or the gate fails. Nobody has to remember to opt a new port in.
- **The enforcement unit is the delivered surface, not the module that shipped it.** A surface delivered as a side effect of other work still owes a ledger; a primary-only surface with no secondary delivery owes nothing.
- **Single-platform pays nothing.** Empty map → empty required-ledger set → the gate is a no-op.

This is a **code-time** concern — does the second platform's code implement the first's behavior — so the gate lives with your route/screen ratchets, next to the code, not in the docs linter. Match a gate's lane to its concern's granularity: a plan-time gate reads outlines, a code-time gate reads code.

## Honest limit

No mechanism fully auto-diffs behavior between two platforms' implementations. The ledger makes gaps **visible, tracked, and reviewable** and the audit **reproducible** — it does not *prove* parity, and a ledger can be rubber-stamped. The primary-first enumeration plus the fixed taxonomy are the mitigation; a wrong or missing row is at least a reviewable, attributable artifact, and behaviors are append-only (a later reader adds a row they spot; none are silently removed). State this limit whenever you present a ledger — do not oversell it as proof.
