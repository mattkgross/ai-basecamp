# Anti-patterns

*Slice of [docs/patterns/](README.md). What not to do, and what it cost to learn.*

This file's value comes from **your** entries. The four below are starters chosen because they are language-agnostic and because each one costs real time when it recurs — but a bug from your own codebase is worth more than any of them, because your team will recognize it.

Add an entry when a bug reveals a class of mistake rather than a one-off typo. Name the concrete incident and the date. "We got this wrong on the invoice importer in March" is what makes a rule stick; an abstract prohibition gets argued with.

## Swallowed errors

**When:** Writing an error handler.
**Don't:** Catch an error and do nothing with it. Every caught error must be re-thrown with more context, logged somewhere a human will see, or surfaced to the user. An empty handler converts a loud failure into corrupted state that surfaces somewhere unrelated, hours later.
**Do:** If the failure genuinely does not matter, say why in a comment at the catch site. That comment is what stops the next reader from either propagating the swallow to somewhere it matters or "fixing" your deliberate one.

## Unvalidated configuration

**When:** Reading an environment variable or config value at runtime.
**Don't:** Read it directly wherever you happen to need it. An unset variable becomes an empty string or `undefined`, silently, and the failure appears far from the cause — usually in production, usually as something that looks like a logic bug.
**Do:** Validate all configuration once, at startup, in one place, and fail immediately with the name of what is missing. Everything else reads the validated result. Starting the process is the only correct time to discover that configuration is wrong.

## Premature abstraction

**When:** You see the same code twice and want to extract it.
**Don't:** Abstract at two. Two occurrences do not tell you which part varies, so the abstraction encodes a guess — and a wrong abstraction is worse than duplication, because it couples unrelated callers and every future change has to fight it. Duplication is cheap to fix; the wrong shared interface is not.
**Do:** Wait for the third. See [architecture.md](architecture.md) § Abstraction — the rule of three, including the exception for correctness-critical logic.

## Escape hatches without a reason

**When:** Reaching for the thing that turns off the type checker, silences the linter, or suppresses the framework warning.
**Don't:** Use it bare. An unexplained suppression is indistinguishable from a mistake, so nobody can ever safely remove it — and it multiplies, because the next author sees precedent.
**Do:** Every suppression is scoped to the narrowest possible target and carries an inline comment naming the specific cause. "I could not work out where this came from" is not a cause; an unexplained warning is yours to diagnose. Maintain a short list of sanctioned uses here so a reviewer can tell the deliberate ones from the lazy ones.

## Silently reverting unexpected file state

**When:** A file's contents differ from what you remember — a line you removed is back, text you wrote is gone, a comment looks unfamiliar.
**Don't:** Re-apply your expected version. Someone edited the file between your turns, another agent committed in parallel, or a tool you did not run touched the tree. Silent reversion destroys real work and is very hard for the person you took it from to notice, because the diff looks like yours.
**Do:** Check git first — `git log -p -1 -- <file>` and `git status` distinguish uncommitted human work from a recent commit from a genuine accident. Correct it only after confirming the divergence was unintentional. When in doubt, ask: "this file changed since my last edit — keep your version or restore mine?"

*This entry is about agents specifically. Most anti-patterns describe code; this one describes a workflow failure that only exists when more than one author edits the same tree asynchronously. If your project has agents working in parallel, you will hit it.*
