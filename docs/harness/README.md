# The Harness

What the harness is, why each check exists, and how to extend it.

A **harness** is the set of mechanical guards that keep documentation, decisions, and plans honest without depending on anyone remembering. Every check here exists because something failed silently — that is the bar for adding one, and it is why the check bodies carry the incident in a comment rather than just the rule.

## The premise

Documentation rots. Not through negligence but through ordinary work: a file is renamed and eight prose references still point at the old path; a decision gets made in a conversation and never written down; a plan ships and nobody records what actually changed. Each of these is individually trivial and collectively fatal, because an agent starting a fresh session has nothing *but* the docs. It cannot ask what happened last week.

Willpower does not fix this — the failures are invisible, so there is nothing to feel bad about. Mechanism fixes it.

## Design principles

**Push enforcement to the cheapest layer.** A file-existence check costs microseconds. A test suite costs seconds. Asking a language model costs tokens and latency. Spend at the cheapest layer that can actually detect the problem:

| Layer | Cost | Catches |
|---|---|---|
| Local hook | Free | Broken paths, secrets, formatting, missing files |
| Non-model CI | Compute | Tests, builds, coverage, dependency audits |
| Model-powered review | Tokens | Whether a doc is *accurate*, whether an abstraction is *right* |

Only the third layer needs language understanding. Most drift does not.

**A guard nobody can bypass gets bypassed anyway.** Every check either warns or fails, and the choice matters. Fail for things that are unambiguously wrong: a broken path, a duplicate identifier. Warn for things that need judgment: a doc over its length budget might be legitimately long. Making a judgment call a hard failure trains everyone to reach for `--no-verify`, and a bypassed gate enforces nothing at all.

**Scope per-commit gates to the commit.** The pre-commit hook enforces only what the commit touches. A whole-repo gate punishes an author for pre-existing issues they did not introduce — which is the fastest route to the bypass habit. Repo-wide health belongs in CI, where it blocks a merge rather than a keystroke.

**Every guard needs a visible escape hatch.** Guards have false positives. Without a documented override, the response to one is to delete the guard. This harness uses an inline marker at the violation site — `<!-- no-retrospective: reason -->` is the example that ships — so the exception is visible to the next reader *and* to review, instead of buried in a config file.

**New guards apply forward, not retroactively.** When you add a check to an existing codebase, grandfather what predates it — a numeric baseline, a date, an explicit allowlist. Otherwise adopting the guard means a repo-wide cleanup before anything ships, so the guard does not get adopted.

## The checks

Run the full suite with `/harness-check` or `bash scripts/lint-docs.sh`. Every knob lives in the CONFIG block at the top of that file.

| # | Check | Level | Why it exists |
|---|---|---|---|
| 1 | Required files exist | fail | The routing table promises these. A missing one is a dead end. |
| 1.5 | Agent-guide aliasing | warn | `CLAUDE.md` as a real file duplicates `AGENTS.md`, and duplicates drift because nothing compares them. A symlink makes drift impossible. Warn-only: Windows checkouts cannot always make symlinks. |
| 2 | Required directories exist | fail | An absent `debt/` means shortcuts get recorded nowhere. `--fix` creates them. |
| 3 | Cross-references resolve | fail | The highest-value check. Stale paths are how an agent gets sent to a file that no longer exists, and prose accumulates them invisibly because no compiler reads prose. |
| 4 | Decision sync | warn | Every open-decision marker is discoverable from one file, so "what is still undecided" is one read instead of a repo-wide grep. |
| 4.5 | Tracker hygiene | warn | Resolved rows left in place are how the tracker bloats — a resolved row stops being read but never gets deleted. Budgeted in bytes, because each row is one long line and a line cap sees nothing. |
| 4.6 | Decision-record numbers unique | fail | Two branches each take "the next number" and collide silently: differing slugs mean no merge conflict, and both files existing means every other check passes. |
| 5 | Agent-guide budget | warn | This file loads on every session — the one cost paid unconditionally. |
| 5.5 | Doc length budget | warn | Over budget is a signal to split or archive, not to write less. |
| 6 | Content violations | fail | Project-specific: content that must never be committed. Empty by default. |
| 6.5 | Banned commands in automated paths | fail | A "never run this" rule applies to execution, not to the docs that teach it. Scanning only CI files and task manifests is what keeps this from fighting your own documentation. |
| 7 | Dead-name drift | fail | After a rename, prose mentions of the old name survive without a backticked path for Check 3 to catch. |
| 7.5 | Routing-table completeness | warn | A doc absent from the routing table is unreachable in practice. It exists; no agent finds it. |
| 7.6 | Completed-plan retrospectives | warn | The most valuable paragraph in the repo and the easiest to skip, because by the time a plan is done everyone has moved on. |
| 8 | Tests alongside source | fail | Source with no test suite anywhere is a structural gap, not a style choice. |
| 9 | Branch hygiene | warn | Stray uncommitted work and a stale base are the two surprises that reliably cost a session. Both are invisible unless something says so at the start. |

### Why bytes and not just lines

This lesson recurs, which is why it appears in three checks. A line cap is blind to long-line bloat: a doc that packs each entry into one dense line reads green at 150 lines while costing thousands of tokens. Byte count is a better proxy for what an agent actually pays. Roughly four bytes per token.

### Why the scans include untracked files

`git grep` and `git ls-files` see only **tracked** files by default. Left that way, a brand-new doc is invisible to every check until it is committed — you write it, run the lint, get green, commit, and CI fails on a broken reference you could have fixed in place seconds earlier.

The green run is the real damage. It does not mean "this file is fine"; it means "this file was not examined", and nothing distinguishes the two. Both scan wrappers therefore pass the untracked flags. Standard excludes still apply, so build output and dependencies stay out.

**The general form of this mistake:** a tool that reports success on input it never looked at. Whenever you scope a check — by path, by file type, by git status — confirm that a violation *inside* the scope is actually caught, by planting one. A check that cannot fail is indistinguishable from a check that passes, and this one shipped that way until a fork test caught it.

### The session-start fast path

`--session-start` runs only branch hygiene and the context-budget line, then exits. Two reasons. The heavy checks are repo health, and repo health is already gated in CI and pre-commit, so re-running it every session is redundant. And it is slow where it hurts: the per-line post-processing loops fork several subprocesses per match, so a few thousand matches becomes minutes of wall time on some platforms — long enough that a session appears to hang.

## Extending the harness

**Add a check when something failed silently.** Not when something *could* fail — when it did, and nothing caught it. That standard keeps the suite trustworthy: a green run means something because every red run has historically meant something.

When you add one:

1. **Write the incident in a comment.** Not the rule — the rule is obvious from the code. Write what broke, when, and why nothing else caught it. That is the part that stops a future maintainer from deleting a guard whose purpose is no longer apparent.
2. **Pick warn or fail deliberately.** See § Design principles.
3. **Give it an escape hatch** and document the marker.
4. **Baseline it** if the repo has existing violations.
5. **Test the guard itself if it parses anything.** A parser-based check that silently stops matching is worse than no check, because it reports success. Keep a small script that deliberately introduces a violation, asserts the guard fires, and restores the file — worth doing for anything with a state machine in it. See [recipes.md](recipes.md) § 10 for the shape.

**Hoist the knob into CONFIG.** If a check has a project-specific value, it belongs in the CONFIG block, not inline. The difference between a fork taking an afternoon and taking a week is whether the tunable parts are in one place.

## Stack-specific guards

The most valuable guards are often the least portable — database migration invariants, package-manager behavior, CI environment coverage. Those cannot run in a stack-neutral template, but the knowledge is expensive to rediscover, so they are written up as copy-paste recipes in [recipes.md](recipes.md) with the bug that motivated each one. Take the ones your stack needs.
