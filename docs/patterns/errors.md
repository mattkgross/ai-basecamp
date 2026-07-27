# Error Handling & Debugging

*Slice of [docs/patterns/](README.md). Fail loud, diagnose before fixing.*

## Fail loud

**When:** Anywhere something can go wrong.
**Pattern:** Let errors propagate to a central handler. Catch locally only to *add* context and re-throw, or because you have a genuine recovery path. A silent failure is worse than a crash: a crash tells you where and when, while a silent failure tells you nothing and surfaces later as corrupted state.
**Example:** Catch a database error to attach the query's purpose, then re-throw. Do not catch it, log at debug level, and return an empty list — every caller downstream now believes there is no data.
**Don't use when:** The failure genuinely does not matter to the caller and you can say why in a comment. Best-effort telemetry is the canonical case; that comment is what stops the next reader from "fixing" your intentional swallow.

## Errors carry context, not just type

**When:** Throwing or wrapping an error.
**Pattern:** Include what was being attempted and with what inputs — not the raw values of anything sensitive, but enough to reproduce. An error whose message is `"Invalid input"` costs an hour; one that says which field, which value shape, and which operation costs a minute.
**Example:** `Failed to parse webhook payload for event type 'invoice.paid': missing 'amount'` beats `ValidationError`.
**Don't use when:** The context would contain secrets, credentials, tokens, or regulated personal data. Log an identifier you can correlate instead of the payload.

## Diagnose before fixing

**When:** Any bug, test failure, or unexpected behavior.
**Pattern:** Establish what is actually happening before changing anything. Read the error, reproduce it, inspect real values at the failure point — a debugger, a breakpoint, a targeted log. Form a hypothesis that explains *all* the evidence, then test that hypothesis. Only then edit.
**Example:** A test fails intermittently. The fix is not a retry or a longer timeout — those hide it. Find the shared state or the ordering dependency that makes it intermittent, because that same race is in production.
**Don't use when:** Never. The tempting shortcut — change something plausible and re-run — is how a symptom gets suppressed while the cause survives, and it burns more time than it saves because you learn nothing from each attempt.

## A previously passing test that starts failing is evidence

**When:** A test that used to pass goes red.
**Pattern:** Investigate it. Either the code broke or the test encoded an assumption that is no longer true — both are findings worth knowing. Deleting or skipping the test to get to green destroys the only signal you had.
**Example:** A serialization test fails after a refactor. If the new output is correct, update the expectation *and* note why the shape changed. If it is not, you just caught the regression the test existed for.
**Don't use when:** The test was genuinely testing the wrong thing. Then delete it deliberately, say so in the commit message, and replace it with one that tests the right thing.

*Add your project's conventions here: logging interface, error-reporting service, retry policy, structured error shapes, which failures page a human.*
