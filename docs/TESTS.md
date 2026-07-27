# Testing Rules & Conventions

What to test, what not to, and the conventions that keep the suite trustworthy.

A test suite has one job: tell you the truth about whether the code works. Most suites fail at this not by having too few tests but by having tests nobody believes — flaky ones, ones asserting implementation details, ones written to raise a coverage number. This document is about keeping the suite worth listening to.

## Format

```
### Rule name

**When:** The situation.
**Rule:** What to do.
**Example:** Concrete code.
**Exception:** Where the rule does not hold.
```

## Decision tree

### Write a test when

- The code contains **logic** — branching, transformation, calculation, parsing, validation.
- It **crosses a boundary** — a network call, a database write, a queue, a filesystem.
- You are **fixing a bug**. The regression test fails before the fix and passes after; writing it first is how you prove you found the actual cause and not a nearby one.
- The behavior is **load-bearing for correctness** — money, permissions, data integrity. These get tests even when the code looks trivial, because "looks trivial" is where the expensive bugs live.

### Do not write a test when

- It only asserts that the framework works. Testing that a component renders its own props tests the framework.
- It restates the implementation. A test that breaks on every refactor while the behavior is unchanged is a maintenance tax with no signal.
- It asserts a value the test itself computed the same way the code does. That passes regardless of whether either is right.
- The change is purely cosmetic with no logic.

### Sanctioned skips

Skipping a test is sometimes correct — an unavailable dependency, a platform-specific path, a genuine upstream bug. Every skip carries a comment naming the reason and the condition under which it should be re-enabled.

An unexplained skip is indistinguishable from an abandoned test, so nobody ever removes it, and the coverage it implies is fiction.

*List your project's sanctioned skips here so a reviewer can tell the deliberate ones from the forgotten ones.*

## Test layers

Three layers with different jobs. The distinction matters because they fail differently.

**Specification tests** — written from acceptance criteria, ideally *before* the implementation. They encode intent, so they survive refactors and form the regression backbone. Written first, they also solve the bias problem: a test written after the code tends to assert what the code does rather than what it should do.

**Implementation tests** — written alongside the code. They cover internal logic, helpers, and edge cases the author discovered while building. Some bias toward the implementation is inevitable here, and acceptable, because the specification layer is the real guard.

**Adversarial tests** — written by someone (or something) that has seen the code but *not* the existing tests, asking "what is not covered? What breaks in production?" The gaps this finds between the other two layers are real findings. Worth adding once the cost of a production bug exceeds the cost of the pass.

## Conventions

### Mirror the source tree

**When:** Placing a test file.
**Rule:** Test location mirrors source location, so finding a file's tests requires no search. Pick one shape — a parallel `tests/` tree or co-located test files — and hold to it.
**Exception:** Integration and end-to-end tests, which usually belong grouped by scenario rather than by source file.

### Real time by default

**When:** Testing anything time-dependent.
**Rule:** Use real timers unless the test would otherwise be slow or non-deterministic. Fake timers leak between tests and produce failures that look like race conditions in unrelated files.
**Exception:** Debounce, throttle, retry backoff, and scheduling — where waiting real time makes the suite unusably slow. Restore real timers explicitly afterward.

### Isolate shared state

**When:** Any test touching a module-level value, a global, a cache, or a database.
**Rule:** Each test sets up and tears down its own state. A test that passes alone and fails in the suite, or that only passes in a particular order, is reporting a real problem — usually the same shared-state bug your production code has.
**Exception:** Genuinely immutable fixtures.

### Assert on behavior, not on shape

**When:** Choosing what to assert.
**Rule:** Assert the outcome a caller cares about. Snapshot assertions over dynamic content — timestamps, generated identifiers, ordering that is not guaranteed — fail for reasons unrelated to correctness, and the reflex becomes to regenerate the snapshot, which means the test no longer asserts anything.
**Exception:** Genuinely static output where a snapshot is the clearest expression of intent.

*Add your project's conventions here: mocking approach, fixture strategy, integration gating, DOM environment, which failures block a merge.*

## Coverage

Pick a floor and treat it as a **regression guard**, not a goal. Its job is to catch a change that removes tests, not to be maximized.

Chasing a high number produces tests written to touch lines rather than to verify behavior, which lowers the suite's real value while raising its apparent value — the worst combination, because it also raises confidence. Read coverage by asking which *branches* of important logic are unvisited, not by watching the percentage.

*Record your floor and how to read the report here.*

## Anti-patterns

- **Chasing 100%.** Produces line-touching tests and hides real gaps behind a good number.
- **Deleting a newly-failing test to get green.** That test just did its only job. Investigate; if it was testing the wrong thing, replace it deliberately and say so.
- **Retrying to fix flakiness.** A retry hides a race that is still in production. Find the shared state or the ordering dependency.
- **Testing generated or trivial code.** Barrel files, plain type declarations, and pass-through wrappers cost maintenance and return nothing.
- **Fragile literal identifiers.** Hard-coded generated IDs and full-string matches on messages break on unrelated changes. Assert the property that matters.
