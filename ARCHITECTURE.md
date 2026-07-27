# Architecture

> Replace this skeleton with your actual design. Agents read this file every session that touches structure, so an inaccurate architecture doc is worse than none — it produces confidently wrong work.
>
> Describe what **is**, not what was or what is planned. Version control holds the history; planned work lives in `docs/exec-plans/`.

## System overview

<!-- What this system does and how it is shaped, in a paragraph or two. Enough
     that a new contributor can hold the whole thing in their head before
     reading any component detail. -->

## Components

<!-- One subsection per component. The last field is the one people skip and the
     one that matters most later:

### Component name

- **Responsibility:** what it does — one sentence, no "and"
- **Connects to:** what it talks to, and in which direction
- **Key files:** where it lives
- **Scaling lever:** what changes if this has to handle ten times the load

     The scaling lever is not a plan to build now. It is proof you know where
     the ceiling is. "Add a read replica" is a fine answer; "rewrite it" means
     the boundary is in the wrong place, and that is worth knowing today.
-->

## Data model

<!-- Entities, their relationships, and where each lives. Note anything
     denormalized and why — a denormalization whose reason is undocumented
     eventually gets "cleaned up" by someone who reads it as an accident. -->

## Interfaces and contracts

<!-- Endpoint or interface overview, the authorization model, request/response
     shapes, error conventions. Detailed per-feature specs live in docs/specs/. -->

## Technology choices

<!-- For each significant choice: what was chosen, what was considered, and WHY
     — specifically which constraint eliminated the alternatives.

     The "why" is the entire value of this section. What you chose is visible
     from the dependency manifest; why you rejected the obvious alternative is
     not, and that is exactly what you need when someone proposes switching.

     A choice with reasoning worth more than a paragraph should be a decision
     record in docs/decisions/, with a one-line pointer from here. -->

## Boundaries and dependency direction

<!-- Which parts must not depend on which. Dependencies point toward the stable
     core and away from volatile edges — business logic should not import the
     transport layer, the interface, or a vendor SDK.

     Writing these down is what makes a violation reviewable. Unwritten
     boundaries are not boundaries; they are preferences that erode. -->

## Known constraints

<!-- Deliberate limits: things this architecture does not support, and why that
     is currently the right call. Naming them stops each one being rediscovered
     as a bug. -->
