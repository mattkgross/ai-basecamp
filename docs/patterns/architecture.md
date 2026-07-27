# Architecture & Organization

*Slice of [docs/patterns/](README.md). Boundaries, naming, abstraction.*

## Abstraction — the rule of three

**When:** You see the same code a second time and want to extract it.
**Pattern:** Wait for the third occurrence. Two instances are a coincidence; three is a pattern, and only the third tells you which parts genuinely vary. Extracting at two means guessing at the shape of the variation, and the guess is usually wrong.
**Example:** Two request handlers both parse a date header. Leave them. When a third appears and all three differ in *which* header, the parameter you needed is now obvious — it was the header name, not the parsing.
**Don't use when:** The duplication is a correctness risk rather than a tidiness one. Two copies of a security check, a tax calculation, or a validation rule can silently diverge into a bug; unify those immediately. The rule of three is about shape, not about safety.

## One unit, one purpose

**When:** Deciding where new code goes, or noticing a file has grown large.
**Pattern:** Each module should answer three questions cleanly: what does it do, how do you use it, what does it depend on? If you cannot describe it without "and", it is doing two things. Size is a proxy signal, not the rule — a large file with one purpose is fine, and a small file with three is not.
**Example:** A `notifications` module that sends notifications is one purpose. One that sends notifications *and* owns the user-preference schema is two, and the second will be the reason you cannot test the first.
**Don't use when:** Splitting would create a module that exists only to be called from one place and has no independent meaning. That is indirection, not decomposition.

## Naming — describe the thing, not its type

**When:** Naming anything.
**Pattern:** Pick names from the domain, not the implementation. Be consistent within a codebase over being clever in one spot. Prefer the boring name a newcomer would guess.
**Example:** `pendingInvoices` over `invoiceArray2`. `retryWithBackoff` over `helper`. A name that repeats the type (`userObject`, `configMap`) adds characters without adding information.
**Don't use when:** An established convention in your language or framework says otherwise. Consistency with the ecosystem beats internal purity.

## Dependency direction

**When:** Adding an import between two areas of the codebase.
**Pattern:** Dependencies point one way — toward the stable core, away from the volatile edges. Business logic should not import from the transport layer, the UI, or a vendor SDK. When you need the reverse, invert it with an interface the core owns.
**Example:** A pricing calculator should not import your HTTP framework. Pass it the numbers it needs and let the handler do the translating; then the calculator is testable without a server.
**Don't use when:** The indirection costs more than the coupling it prevents. A single-file script does not need a ports-and-adapters layer.

*Add your project's structural conventions here as they settle: directory layout, route grouping, module boundaries, path aliases, where shared code lives.*
