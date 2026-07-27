# Quality & Process

*Slice of [docs/patterns/](README.md). Comments, testing, dependencies, the pre-PR gate.*

## Comments explain why

**When:** Documenting code.
**Pattern:** Docstrings on exported functions and types — what it does, its parameters, what it returns. Inline comments only where the *reason* is non-obvious. Never restate the code.
**Example:** `// Bypass the cache here: a stale read would let a revoked session through.` is worth writing. `// Increment the counter` above `counter++` is noise that will one day be a lie.
**Don't use when:** The code says it already. `const isVisible = !isHidden;` needs nothing.

## Tests ship with the code

**When:** Any change.
**Pattern:** Unit tests for logic, transforms, and utilities. Integration tests for anything crossing a boundary. Every bug fix carries a regression test that fails before the fix and passes after — writing it first is how you prove you found the actual cause rather than a nearby one.
**Example:** A null-handling fix adds a test with the exact input that crashed.
**Don't use when:** Purely cosmetic changes with no logic. Full conventions and the decision tree for what deserves a test: `docs/TESTS.md`.

## The pre-PR gate

**When:** Before pushing to a branch that a reviewer will see.
**Pattern:** Run `bash scripts/check.sh` and confirm it is green locally *first*. The gate exists to catch the failure at your desk instead of spending a push, a CI wait, a fix, and a re-push. Say the gate passed in the PR body so nobody re-litigates whether it did.
**Example:** A red gate is the signal to fix, not to push and hope CI disagrees.
**Don't use when:** A pre-commit hook already ran the same gate on the same commit — skip the duplicate. Spike branches that will never become PRs are exempt, until the moment one does.

## Dependency hygiene

**When:** Considering a new dependency.
**Pattern:** Judge it on maintenance signals — recent releases, responsive maintainers, real adoption — and on how much you would have to write yourself. Pin versions so a debugging session is reproducible. Audit periodically for what you stopped using.
**Example:** A date library earns its place. A package that provides `isEven` does not.
**Don't use when:** You can do it in a few lines you fully understand. Every dependency is a supply-chain surface and a future upgrade obligation.

## Design before markup

**When:** Shipping any user-visible surface with genuinely open design space — a new screen, flow, or component whose visual language is not already determined.
**Pattern:** Settle the visual direction before an agent writes markup or design tokens. Agents produce competent, generic, interchangeable UI from a written spec, because a written spec is exactly what a generic layout satisfies. Non-visual work — schema, server logic, refactors — proceeds in parallel; work that produces visible markup waits.
**Example:** *Name your prototyping tool and where its output gets committed.*
**Don't use when:** There is no visible surface, or the surface is structurally locked and every open question has one obviously-correct answer — a new field in an existing row with fixed typography, a fourth item matching three siblings. Gut-check: if existing constraints determine most of the shape and the rest has defensible defaults, skip it and note each default at review time.

## Cross-author feedback belongs in the review tool

**When:** Leaving actionable feedback on someone else's change.
**Pattern:** Post it as a line-anchored review comment in your code-review tool. It threads with the discussion, notifies the author, and resolves when addressed.
**Example:** A review comment on the line in question.
**Don't use when:** Never do the alternative — `// NOTE for someone:` / `// TODO @person:` lines committed into source are invisible to the review UI, ship to the default branch if the change merges, and become orphaned breadcrumbs the next reader has to triage. Open questions are conversation. Settled answers move into code, docs, or a decision record once the conversation closes.
