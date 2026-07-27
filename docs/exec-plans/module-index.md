# Module Index

The canonical build order and current status of every module. One row per module, one line each.

This file exists so that "what is built, what is next, and what depends on what" is answerable in a single cheap read. Without it that answer is reconstructed each time by listing four directories and opening plans — which is slow, and which quietly goes wrong when a plan's status and its directory disagree.

**Keep it to one line per module.** The moment a row grows into a paragraph, this file starts competing with the plans it indexes. Detail belongs in the plan; outcomes belong in that plan's retrospective. If the index gets long enough to feel heavy, age shipped rows into a `module-index-history.md` and leave the live table to what is in flight.

## Status vocabulary

| Status | Meaning |
|---|---|
| `Planned` | Outline exists in `planned/`. Not started. |
| `Active` | Plan in `active/`. Being built. |
| `Shipped` | Plan in `completed/` with a retrospective. |
| `Deferred` | Consciously postponed. The reopen trigger lives in `docs/decisions/OPEN.md`. |
| `Debt` | Shipped with a known shortcut recorded in `debt/`. |

## Build order

*Replace with your modules. The order is the dependency graph, not a wish list — a module cannot precede what it depends on. Renumbering after the fact is expensive because plans, commits, and branches reference the numbers, so leave gaps rather than renumbering.*

| # | Module | Status | Depends on | Plan |
|---|---|---|---|---|
| 01 | *Foundation — app shell, configuration, CI* | Planned | — | — |
| 02 | *Authentication* | Planned | 01 | — |
| 03 | *The core loop — the thing that creates the product's value* | Planned | 01, 02 | — |

## Re-routed scope

*When a module defers work to a different module, record it here as well as in the deferring module's retrospective. A deferral recorded in only one place is a deferral that gets lost — the retrospective is read once at close, this table is read whenever someone plans.*

| From | To | What moved | Why |
|---|---|---|---|
