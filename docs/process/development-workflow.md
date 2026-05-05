# Development Workflow: AI-First Solo Builder
*Created: April 1, 2026 — from deep workflow design session*
*Version: 0.3 (Mobius references removed — standalone doc)*

## Purpose
Defines how Matt builds AI-leveraged side projects using Claude Code. Covers every phase from idea to production, specifying where AI is involved, where human judgment is required, and how quality is enforced. Designed to evolve through use.

## Maturity Tiers

This document describes two tiers. Start with Tier 1 for every project. Graduate to Tier 2 when the product has real users and revenue.

### Tier 1: MVP / Solo Builder (Day One) 🟢
- **Working modes:** Explore → Design → Build → Ship → Maintain (fluid, not gated)
- **Docs:** CLAUDE.md, ARCHITECTURE.md, PATTERNS.md, feature specs. Four docs. Add more when you feel the pain.
- **Review agents:** Pattern reviewer only. Add others when specific problems demand them.
- **Testing:** Layer 1 (spec-driven) + Layer 2 (implementation). No adversarial pass yet.
- **Bug process:** Fix and move on. No formal post-mortems. BUGS.md parking lot if needed.
- **Monitoring:** Uptime check + Sentry. That's it.
- **Hooks:** Pre-commit (lint, format, secrets). Pre-push (build, doc-drift file check, pattern reviewer via `.agents/skills/`). Local agents are the primary enforcement layer.

### Tier 2: Growth / Real Users (Graduate When Ready) 🔶
- All Tier 1, plus:
- **Additional `.agents/skills/`:** Security reviewer (when user accounts exist), architecture reviewer (when codebase is large enough for boundary violations)
- **CI-based review agents** (`.github/review-agents/`) mirroring local agents on PRs
- **Layer 3 adversarial testing** on PRs
- **Mandatory post-mortems** with three outputs (fix, explanation, process change)
- **Additional docs:** LESSONS.md (if PATTERNS.md isn't sufficient), module READMEs (when modules are complex enough), API docs
- **Automated fix pipeline** (Sentry → GitHub Issue → agent PR)
- **Full monitoring:** Analytics, dashboards, structured logging, alerting
- **GitHub Issues** for bug tracking and triage

**Graduation triggers:** Paying users, recurring revenue, bug volume that warrants automation, codebase complexity that warrants additional review agents. Matt decides when — no arbitrary thresholds.

---

## Players

| Player | Role | Where |
|---|---|---|
| **Matt** | Decision-maker, architect, taste layer, Claude Code driver | MacBook |
| **Claude Code** | Implementation partner, test writer, doc updater | MacBook (local) |
| **CI/Agents** | Automated pipelines, specialized review agents, auto-fix | GitHub Actions |
| **Entire.io** | Passive context capture, links agent sessions to commits | Git hooks (local) |
| **AI research partner** | Research, strategy, spec drafting, pipeline setup (advisory — no runtime dependency) | Any AI tool (separate from project) |

**Note on AI research partner:** An AI partner (separate from Claude Code) can contribute to planning, research, and pipeline setup — but projects never depend on any external AI at runtime. Everything contributed during setup (CI, hooks, review agents, docs) lives in the repo and runs independently.

## Core Principles

1. **Projects are self-contained.** All quality gates, review agents, test passes, and enforcement hooks live in the repo. No runtime dependency on any external AI tool, service, or person beyond what's in the repo.
2. **Docs update with every change, no exceptions.** Enforced by hooks and CI, not willpower.
3. **One agent, one job, tight context.** Specialized agents scoped narrowly outperform generalists. Applies to reviewing, testing, and automated pipelines. Implementation sessions (Claude Code) may combine coding + unit tests + doc updates in one session, but each *automated CI agent* has a single focus.
4. **Rules files are executable policy.** PATTERNS.md, CLAUDE.md, review agent prompts aren't documentation — they're what hooks and agents read and enforce. Updating a rule is deploying new enforcement logic.
5. **Every discovery flows back into the system.** Reactive (bug fixes) AND proactive (new patterns, tools, approaches). No silent drops.
6. **Scale-aware design.** Build for today's scale, but make conscious choices that leave the upgrade path clear. "If this 10x'd overnight, what would I need to change?" should be "upgrade the tier," not "rewrite the architecture."
7. **Push enforcement to the cheapest layer.** Local hooks > non-LLM CI checks > LLM-powered CI checks. Only use tokens for things that genuinely need language understanding.
8. **Trust is a ratchet.** Start hands-on, and each solved problem (biased tests, no reuse, no looping) lets you let go a little more. Earn autonomy through demonstrated reliability.

---

## Phase 0: IDEATION & RESEARCH 🟢

**Goal:** Find the right thing to build before building anything.

**Activities:** Brainstorming, market research, user pain research, technical feasibility, competitive analysis, revenue model exploration.

| Activity | Who | Notes |
|---|---|---|
| Idea generation | **Matt + AI** | Matt brings domain instinct, AI brings pattern-matching across markets/trends |
| Market research | **AI-heavy** | Survey competitors, pull data, synthesize. Matt validates if it "feels right" |
| User pain research | **AI gathers, Matt interprets** | Scrape subreddits/reviews/forums. Matt decides what's real pain vs. noise |
| Technical feasibility | **Both** | AI researches tools/APIs/dependencies. Matt decides on stack fit |
| Competitive analysis | **AI-heavy** | Straightforward research. Matt evaluates |
| Revenue model | **Both** | AI researches comparable pricing. Matt decides what fits |
| Final idea selection | **Matt** | His gut, his summer, his money. AI gives honest read. |

**Parallel POCs:** 2-3 ideas can be explored simultaneously. Iterate quickly, kill fast.

**Output per idea:** Problem statement, competitive landscape, technical sketch, revenue hypothesis, risk flags.

**AI automation:** Low. Creative and judgment-heavy. AI accelerates research, humans make decisions.

---

## Phase 1: DESIGN & ARCHITECTURE 🟢

**Goal:** Make all structural decisions before code is written. This is where rushing costs the most.

**Activities:** System architecture, data modeling, API contracts, tech selection, component boundaries, dependency decisions, UX flow.

| Activity | Who | Notes |
|---|---|---|
| Architecture brainstorming | **Both** | AI proposes options with trade-offs, Matt makes structural calls |
| Data modeling | **Matt-heavy (AI reviews)** | Matt's typed-language instincts are strongest here. AI pokes holes |
| API contracts | **Matt-heavy (AI drafts initial)** | Matt thinks in contracts. AI drafts shapes from spec, Matt refines |
| Tech selection | **Both** | AI researches options with pros/cons/gotchas. Matt decides. Document *why* |
| Component boundaries | **Matt (AI asks clarifying questions)** | Pure architecture judgment |
| Dependency evaluation | **AI-heavy** | Research license, maintenance, security, community. Matt makes the call |
| UX flow | **Matt** | The taste layer. AI maps logical flows, Matt judges feel |

**Note on "heavy":** "Matt-heavy" means Matt is the decision-maker, not that he's working alone. AI is always in the room — proposing alternatives, sanity-checking, flagging issues. Matt drives, AI navigates.

**Scale-aware design:** Every architecture decision includes the scaling lever. Not over-engineering, but conscious choices (Postgres over SQLite, clean boundaries, stateless where possible, queue interfaces even if processing inline today).

**Output:**
- ARCHITECTURE.md — maps every component, responsibility, connections, scaling levers, and key tech decisions with rationale (replaces separate DECISIONS.md at Tier 1) 🟢
- DECISIONS.md — separate doc for tech choices and rationale (add at Tier 2 if ARCHITECTURE.md gets too dense) 🔶
- Data model definitions
- API contracts (even rough ones)

**Exit criteria:** Matt can confidently explain the system to someone else. If he can't, the agent can't build it well.

---

## Phase 2: SPEC & ACCEPTANCE CRITERIA 🟢

**Goal:** Produce documents clear enough that Claude Code can execute against them without guessing intent.

| Activity | Who | Notes |
|---|---|---|
| Feature specs | **AI drafts, Matt refines** | Translate Phase 1 architecture into detailed specs. Matt corrects missed intent |
| Acceptance criteria | **Both** | AI proposes from spec, Matt adds edge cases from product instinct |
| Test case definitions | **AI drafts, Matt reviews** | Defined BEFORE code exists. Written against spec, not implementation. Solves biased testing problem |
| API specifications | **AI drafts from Phase 1, Matt approves** | Formalizing existing designs |
| Priority ordering | **Matt** | What matters most, what unblocks what. AI flags dependencies |

**Key disciplines:**
- **Test cases before code.** Non-negotiable. Agent implements to satisfy these, not the other way around. Note: some acceptance criteria may need refinement once implementation reveals constraints — that's OK, but changes go through the spec first, not silently in code.
- **Acceptance criteria are binary.** Not "should be fast" but "P95 < 200ms." Not "handle errors" but "400 with structured error body matching this schema."
- **Specs include what NOT to build.** Explicit exclusions prevent scope creep.

**Output:**
- Per-feature spec docs (in `docs/specs/`)
- Test matrix — every feature mapped to acceptance scenarios
- Prioritized build order

---

## Phase 3: PROJECT SCAFFOLDING 🟢

**Goal:** Set up the development environment, CI pipeline, and all quality gates. This is the foundation of the factory.

| Activity | Who | Notes |
|---|---|---|
| Repo structure | **AI drafts, Matt approves** | Skeleton based on Phase 1-2 decisions |
| CLAUDE.md | **Both** | Agent operating manual. Co-authored. Map, not encyclopedia |
| ARCHITECTURE.md | **AI drafts from Phase 1, Matt reviews** | Must be accurate — agents read this every session |
| CI/CD pipeline design | **AI proposes, both discuss, AI implements** | Not unilateral — trade-offs discussed |
| Hosting/infra | **AI researches options + trade-offs, Matt picks, then provision** | Cost and lock-in require human decision |
| Dev environment | **Matt sets up locally** | Matt's MacBook, his env |
| Entire.io setup | **Matt on MacBook** | Research steps, then run them |
| Tooling config | **AI** | Linter, formatter, pre-commit hooks — mechanical |
| Agent workflow hooks | **AI drafts loop design, both walk through it, then wire it up** | Critical — this is where all enforcement gets implemented |

**Bootstrapped from template repo** (`~/Github/project-template/`). Customize project-specific pieces only.

**Tier 1 scaffolding includes:** 🟢
- Repo structure, CLAUDE.md, ARCHITECTURE.md, PATTERNS.md skeleton
- `.agents/skills/` directory with pattern reviewer agent (local, invokable from Claude Code and hooks)
- Pre-commit hooks (lint, format, secret detection)
- Pre-push hooks (build check, doc-drift file check, pattern reviewer invocation)
- Basic CI (build, test, lint)
- Entire.io integration

**Tier 2 adds:** 🔶
- Additional `.agents/skills/` (security reviewer, architecture reviewer)
- CI-based review agents (`.github/review-agents/`) for PR automation
- Layer 3 adversarial test action
- Auto-fix pipeline workflow
- Advanced CI gates

**Key disciplines:**
- CI must be green before any feature work starts
- Doc-drift check wired in here, not bolted on later
- All hooks and gates functional from day one

**Time investment:** Half a day to a day.

---

## Phase 4: IMPLEMENTATION 🟢

**Goal:** Build features. Matt's assembly phase — the flow state zone.

| Activity | Who | Notes |
|---|---|---|
| Driving Claude Code | **Matt** | In the chair, prompting, watching, steering. Flow state |
| Context preparation | **AI-assisted** | Before each feature: collate relevant spec, acceptance criteria, test cases, ARCHITECTURE.md context, gotchas into a "briefing packet." Can be prepared by any AI tool, by Claude Code reading project docs, or by Matt pulling the relevant files — whatever's fastest. |
| Spec-to-prompt translation | **Matt + Claude Code** | Turn specs into effective prompts. Learn what works over time |
| Entire.io capture | **Automatic** | Passive via git hooks |

**Keeping context in sync:**
- **After pushing:** Anyone reading the repo (future Claude Code sessions, future you) has the full picture — if docs are current.
- **The discipline holds or this breaks:** If docs aren't updated with every change, everything downstream works from stale context.

**Matt's involvement spectrum:**
- **Now:** Interactive (~80% attention). Watching Claude Code, catching mistakes in real time.
- **Goal:** Supervisory (~40% attention). Kick off features, check in, review output.
- **How to get there:** Each solved trust gap = one less thing to watch manually.

**Key disciplines:**
- One feature per Claude Code session. No context-switching across unrelated components.
- Every session starts with: spec, acceptance criteria, test cases, ARCHITECTURE.md. Non-negotiable context.
- Claude Code handles coding + unit tests + doc updates in one session. This is practical, not a "one agent, one job" violation — the "one job" principle applies to *automated CI agents*, not interactive implementation sessions.
- When plan meets reality and something changes: **pause, update the spec first, then continue building.**

---

## Phase 5: TESTING

**Goal:** Solve the biased testing problem with independent layers.

### Layer 1: Spec-Driven Tests (written before code, in Phase 2) 🟢
- Come from acceptance criteria. Exist before implementation.
- Claude Code implements *to satisfy these*, not the other way around.
- Reflect intent, not implementation. Regression backbone.
- **Note:** Some test cases may need refinement when implementation reveals constraints not visible at spec time. That's expected — but the refinement goes through the spec, not silently in the test.

### Layer 2: Implementation Tests (written with code, in Phase 4) 🟢
- Claude Code writes unit tests alongside implementation.
- Supplemental, not primary. Cover internal logic, helpers, edge cases.
- Bias exists here — that's OK because Layer 1 is the real guard.

### Layer 3: Adversarial Test Pass (post-implementation, separate agent) 🔶
- **Add when:** Product has real users and bug prevention justifies the token cost.
- Separate agent context. Sees code but NOT existing tests.
- Asks: "What failure modes aren't covered? What breaks in production?"
- Writes new tests from blank slate. Gaps between layers are real findings.
- **Runs in CI (GitHub Action).** Self-contained.

| Activity | Who | Tier |
|---|---|---|
| Layer 1 definition | Phase 2 (Matt + AI) | 🟢 |
| Layer 2 writing | Claude Code during Phase 4 | 🟢 |
| Layer 3 adversarial | CI (GitHub Action, automated) | 🔶 |
| Test review | Matt spot-checks | 🟢 |
| Coverage metrics | CI (automated threshold) | 🟢 |

**Key disciplines:**
- Layer 1 tests must pass before PR merges. No exceptions.
- 🔶 Layer 3 findings start as recommendations, graduate to gates as trust builds.
- A previously passing test that starts failing is always investigated — never deleted to make CI green.

---

## Phase 6: CODE REVIEW

**Goal:** Catch structural issues, reuse failures, and design drift before code merges.

### Two-Layer Review Agent Architecture:

Review agents exist at two layers, each with different trigger points and contexts:

**Layer A: Local Claude Code Agents (`.agents/skills/`)** 🟢
- Markdown files defining specialized agents that Claude Code invokes directly
- Triggered locally via hooks (pre-push) or manually during interactive sessions
- Fast feedback loop — runs before code leaves the working tree
- Each agent gets narrow context (its relevant docs + changed files)

**Layer B: CI Review Agents (`.github/review-agents/`)** 🔶
- Run in GitHub Actions on PR creation/update
- Automated PR comments with severity labels
- Catches anything that slipped past local hooks (different branch, skipped hooks, etc.)
- Add when PR volume or team size warrants the automation

### Agent Inventory:

| Agent | Focus | Context | Layer A (Local) | Layer B (CI) |
|---|---|---|---|---|
| **Pattern reviewer** | Code reuse, conventions, PATTERNS.md compliance | Diff + PATTERNS.md | 🟢 day one | 🔶 |
| **Security reviewer** | Injection, auth, data exposure, input validation | Diff + security rules | 🔶 when user accounts exist | 🔶 |
| **Architecture reviewer** | Boundaries, dependency direction, structural compliance | Diff + ARCHITECTURE.md | 🔶 when codebase is large enough | 🔶 |
| **Doc drift checker** | Were relevant docs updated | File diff only (no LLM) | 🟢 day one (hook, zero tokens) | 🟢 (CI, zero tokens) |

**Single source of truth:** `.agents/skills/` is the canonical definition for every review agent. CI agents (`.github/review-agents/`) must derive from these — never maintain independent copies. The template repo includes a CI helper that reads agent definitions from `.agents/skills/` at runtime, so updating the prompt in one place updates both layers. If a CI agent needs additional CI-specific wrapping (e.g., PR comment formatting), that wrapping lives in the workflow YAML, not in a duplicated agent file.

### Human Review (Matt) 🟢:
- Not line-by-line correctness — agents and tests cover that.
- Focus: architectural judgment, taste, direction. "Does this make sense?"
- Review agent findings include severity: `nitpick`, `suggestion`, `concern`, `blocker`.

### Active Flagging for Human Intervention 🟢:
- `🚨 HUMAN DECISION` comments on PRs when agent needs human judgment
- `needs-human` label applied, merge blocked until resolved
- Default is blocked, not "hope Matt reads it"

### Agent Config:
- **Canonical definitions:** `.agents/skills/` — version-controlled, each a markdown file with persona + instructions + tool constraints. Single source of truth for both local and CI execution.
- **CI execution (Tier 2):** Workflow YAML reads agent prompts from `.agents/skills/` at runtime. No duplicated `.github/review-agents/` directory. CI-specific wrapping (PR comment formatting, label application, severity parsing) lives in the workflow, not the agent definition.
- Each agent gets narrow context (its docs + diff only), not everything
- Can run in parallel — no wall-clock increase

**Matt's involvement over time:**
- **Early:** Review most PRs meaningfully. Build trust.
- **Later:** Skim agent output, spot-check. Dig deep only on architectural PRs.

---

## Phase 7: CI/CD & DEPLOYMENT

**Goal:** Fully automated backbone. Once working, never touch it.

### Tier 1 Pipeline (every push + PR): 🟢
```
Local (pre-push hooks):
  → Lint + format (pre-commit already caught most)
  → Build check
  → Doc-drift file check (zero tokens)
  → Pattern reviewer via .agents/skills/ (LLM tokens, local)

CI (on PR):
  → Build
  → Layer 1 tests (spec-driven)
  → Layer 2 tests (implementation)
  → Doc drift check (file-diff, no LLM)
  → Coverage threshold
  → All green → ready for human review (if flagged) or merge
```

### Tier 2 Pipeline (adds): 🔶
```
Local (.agents/skills/ additions):
  → Security reviewer (pre-push)
  → Architecture reviewer (pre-push)

CI (additions, all reading from .agents/skills/):
  → Pattern reviewer (catches skipped hooks)
  → Security reviewer
  → Architecture reviewer
  → Layer 3 tests (adversarial)
  → Security scan (CodeQL)
```

### Cost Hierarchy:
| Layer | Cost | Examples |
|---|---|---|
| Local hooks | Zero tokens | Lint, format, build check, doc-drift file check, secret detection |
| Non-LLM CI | Compute only | Tests, coverage, security scan (CodeQL/Dependabot), build |
| LLM-powered CI | Tokens | Review agents, adversarial tests, pattern compliance |

**Deployment:** 🟢
- Staging: auto-deploy on merge to main
- Production: manual promote (one button) for early projects, auto-deploy as confidence grows
- Rollback: auto on health check failure, manual trigger available

**Key disciplines:**
- Pipeline is in the repo (`.github/workflows/`), self-contained
- Pipeline changes go through same review as code
- Red main = stop everything until fixed

---

## Phase 8: SECURITY

**Goal:** Cover the basics from day one. Not retrofitted after launch.

### Automated (always on, zero/low cost): 🟢
| Check | Tool | When |
|---|---|---|
| Dependency vulnerabilities | Dependabot / npm audit / dotnet audit | Auto-PRs on discovery |
| Secret detection | gitleaks (pre-commit hook) | Local, before push |
| HTTPS / headers | Hosting provider config | One-time setup |

### Automated (add with scale): 🔶
| Check | Tool | When |
|---|---|---|
| Static analysis | CodeQL | CI, every PR |
| LLM security review | Specialized reviewer agent | CI, every PR |

### Human (periodic): 🟢
- Threat modeling during Phase 1-2
- Infra review at setup and when adding services
- Privacy decisions (what to collect, retention, compliance)
- 🔶 Penetration testing before launch and periodically after

---

## Phase 9: MONITORING & OBSERVABILITY

### Tier 1 (Phase 3 setup, 30 minutes max): 🟢
- Uptime check (free tier, one URL)
- Error tracking (Sentry free tier, drop in SDK)
- That's it.

### Tier 2 (add when you have real users): 🔶
- Usage analytics (PostHog or custom events)
- Performance metrics
- Dashboard — the "users from a distance" view
- Structured logging
- Detailed alerting

**Principle:** Don't over-instrument before the product is validated.

---

## Phase 10: BUG FIXING & MAINTENANCE

### Tier 1 (MVP): 🟢
- No formal tracking. Fix as found. `BUGS.md` if parking lot needed.
- Matt + Claude Code, directly.
- Every fix includes a regression test. Non-negotiable.
- Quick note in PATTERNS.md if the bug reveals a pattern to avoid.

### Tier 2 (Post-Launch Automated Fix Pipeline): 🔶
```
Sentry detects error
  → Auto-creates GitHub Issue (stack trace, affected users, frequency)
  → GitHub Action triggers on new `bug` label
  → Agent gets: issue + relevant code + ARCHITECTURE.md + PATTERNS.md
  → Agent writes: fix + regression test + doc update
  → Agent opens: PR linked to issue, with root cause explanation
  → Full CI runs on PR
  → If CI fails → agent loops (up to N attempts)
  → If CI passes → PR ready for human review
  → Matt reviews and merges
```

### Tier 2 Post-Mortem (three outputs, every production bug): 🔶
1. **The fix** — bug resolved, regression test added
2. **The explanation** — root cause, captured in PATTERNS.md (or LESSONS.md if that doc exists)
3. **The process change** — the actionable part:
   - New rule in PATTERNS.md or CLAUDE.md
   - New check in review agent prompt
   - New test case in Layer 1 spec-driven tests
   - If no process change needed: explicitly document "one-off, no systemic issue"

### Bug Triage (Tier 2, with volume): 🔶
- `critical` — fix now (auto-fix pipeline)
- `bug` — fix this week (batch in sessions)
- `minor` — fix when convenient

---

## Phase 11: DOCUMENTATION

**Goal:** Living docs that are always current. Enforced, not aspirational.

### Tier 1 Doc Inventory: 🟢
| Document | Lives | Updated When | By Whom |
|---|---|---|---|
| CLAUDE.md | Repo root | New rules, patterns, process changes | Matt + Claude Code |
| ARCHITECTURE.md | Repo root | Any structural change (includes tech decisions at Tier 1) | Claude Code (enforced by CI) |
| PATTERNS.md | `docs/` | New pattern, refinement, or lesson learned | Claude Code proposes, Matt approves |
| Feature specs | `docs/specs/` | Feature changes behavior | Claude Code (enforced by CI) |

### Tier 2 Adds: 🔶
| Document | Lives | Updated When | By Whom |
|---|---|---|---|
| LESSONS.md | `docs/` | Post-mortem produces learning (if PATTERNS.md isn't sufficient) | Claude Code drafts, Matt reviews |
| DECISIONS.md | `docs/` | Tech choices (if ARCHITECTURE.md is too dense) | Matt + Claude Code |
| Module READMEs | Next to code | When modules are complex enough that code isn't self-documenting | Claude Code |
| API docs | Generated or `docs/api/` | API changes | Auto-generated where possible |

### Doc Structure (Tier 1): 🟢
```
CLAUDE.md                      ← Agent operating manual (map, not encyclopedia)
ARCHITECTURE.md                ← System-wide map + tech decisions
docs/
  PATTERNS.md                  ← Code patterns, conventions, lessons learned
  specs/                       ← Feature specs + acceptance criteria
```

### Doc Structure (Tier 2 adds): 🔶
```
docs/
  LESSONS.md                   ← If PATTERNS.md isn't enough
  DECISIONS.md                 ← If ARCHITECTURE.md is too dense
  api/                         ← API documentation
src/
  auth/
    README.md                  ← When module complexity warrants it
```

### Drift Prevention: 🟢
- **Cheap layer (every PR):** File-diff check — changed code but not related docs? Flagged. No tokens.
- 🔶 **Medium layer (flagged PRs):** Agent reads diff + relevant doc, checks accuracy. Small focused context.
- 🔶 **Heavy layer (weekly):** Full audit — read all specs against current code. Scheduled, not per-PR.
- **Source of truth hierarchy:** Code > tests > specs > design docs. When they conflict, the higher-priority source is reality.

### Principles:
- Current state only. Docs describe what IS, not what WAS. Entire.io captures history.
- Docs are treated as code — reviewed, version-controlled, quality-gated.
- No PR merges without doc parity. Structurally enforced.

---

## Phase 12: LEARNING LOOP (Continuous) 🟢

**Goal:** Every discovery — reactive AND proactive — flows back into the system.

### Triggers:

**Reactive (fixing what went wrong):**
- Bug found → fix + regression test + pattern note (Tier 1) or full post-mortem (Tier 2)
- Agent makes recurring mistake → new rule in CLAUDE.md / PATTERNS.md
- Review agent misses something → reviewer prompt updated
- Workflow step causes friction → evaluate: automate, simplify, or remove

**Proactive (capturing what went right):**
- New feature built with clean pattern → capture the pattern
- New tool/library/approach discovered → document decision and why
- Workflow step worked especially well → reinforce in template
- Design conversation produced reusable insight → capture it
- New integration solved common problem → abstract it

### Flow (every single time):
```
Discovery
  → "Project-specific or universal?"
    → Project-specific: update project docs
    → Universal: update project docs AND template repo
  → "Does this change how agents should behave?"
    → Yes: update CLAUDE.md / review agent prompts / CI config
  → "Does this change how I should work?"
    → Yes: update workflow doc
```

### Enforcement:

**Hooks + Local Agents (daily, real-time): 🟢**
- Run on every commit/push/PR
- Pre-commit: lint, format, secret detection (zero tokens)
- Pre-push: build check, doc-drift file check (zero tokens), then invoke `.agents/skills/` reviewers against staged changes (LLM tokens)
- Agents read from: PATTERNS.md, CLAUDE.md, ARCHITECTURE.md (each scoped to its own docs)
- Enforce: patterns followed, docs updated, boundaries respected, tests included
- This is the backbone. No human willpower needed.

**Post-mortems (per production bug): 🔶**
- Mandatory three-output treatment: fix, explanation, process change
- Process changes become new rules that hooks enforce
- The rules get smarter, the hooks enforce the new rules. Closed loop.

**Periodic review (weekly): 🟢**
- 30 minutes: "What did I learn this week that isn't captured anywhere?"
- Scan Claude Code session history, project activity
- Catches slow drift and proactive learnings that weren't bug-triggered
- 🔶 Could be its own specialized agent doing a deep codebase review at Tier 2

### Where Learnings Live (Tier 1): 🟢
| Type | Location |
|---|---|
| Bug patterns | PATTERNS.md |
| Code patterns | PATTERNS.md |
| Process rules | CLAUDE.md |
| Architecture changes | ARCHITECTURE.md |
| Template improvements | Template repo CHANGELOG.md |

### Tier 2 Adds: 🔶
| Type | Location |
|---|---|
| Detailed post-mortems | LESSONS.md |
| Separated tech decisions | DECISIONS.md |

---

## Template Repository

Every project is bootstrapped from a shared template. Every learning feeds back to it.

**Name:** AI Basecamp
**Location:** `~/Github/ai-basecamp/`

### Tier 1 Structure (what ships on day one): 🟢
```
project-template/
  .claude/
    agents/
      pattern-reviewer.md       ← Local Claude Code agent (day one reviewer)
  .github/
    workflows/
      ci.yml                    ← Build, test, lint, doc-drift
    templates/
      pull_request_template.md
  docs/
    PATTERNS.md                 ← Empty structure + examples
    specs/
  scripts/
    setup.sh                    ← One-command bootstrap
    hooks/
      pre-commit                ← Lint, format, secret detection
      pre-push                  ← Build check, doc-drift check, pattern reviewer
  CLAUDE.md                     ← Agent operating manual template
  ARCHITECTURE.md               ← Skeleton with sections
  README.md                     ← Project README skeleton
  .gitignore
  TEMPLATE_README.md            ← How to use this template
```

### Tier 2 Adds (wired in when graduating): 🔶
```
  .claude/
    agents/
      security-reviewer.md      ← Auth, injection, data exposure
      architecture-reviewer.md  ← Boundaries, dependency direction
  .github/
    workflows/
      auto-fix.yml              ← Automated bug fix pipeline
      review.yml                ← CI review: reads agents from .agents/skills/ (no duplicated prompts)
    templates/
      ISSUE_TEMPLATE/
        bug.md
        feature.md
  docs/
    LESSONS.md
    DECISIONS.md
```

**Note:** No `.github/review-agents/` directory. CI workflows read agent definitions directly from `.agents/skills/` — one prompt, two execution contexts. CI-specific behavior (PR comments, labels, severity formatting) is handled in the workflow YAML itself.

### Feedback Loop:
- **Project 1** (template v0.1) → Learn, fix in project + template
- **Project 2** (template v0.5) → Bootstrap instantly, learn more, feed back
- **Project 3+** (template v1.0) → Battle-tested, nearly turnkey

### Rules:
- Stack-agnostic where possible. Stack-specific pieces clearly marked.
- Every process learning: "Would I want this on day one of the next project?" → If yes, update template.
- Template has its own CHANGELOG.md tracking evolution.
- **Potential open-source product** once battle-tested across 2-3 projects.
- **Agent definitions are single-source:** `.agents/skills/` is canonical. CI workflows read from `.agents/skills/` at runtime — no duplicated prompt files in `.github/review-agents/`. CI-specific behavior (comment format, label application) lives in workflow YAML, not in agent definitions.

---

## Tools & Infrastructure

| Tool | Purpose | Cost | Tier |
|---|---|---|---|
| **Claude Code** | Primary implementation partner | Included in Claude Max | 🟢 |
| **Entire.io** | Agent session → git checkpoint capture | Free (open source) | 🟢 |
| **GitHub Actions** | CI/CD, review agents | Free tier for private repos | 🟢 |
| **Sentry** | Error tracking | Free tier | 🟢 |
| **gitleaks** | Pre-commit secret detection | Free (open source) | 🟢 |
| **Uptime monitor** | Basic availability check | Free tier | 🟢 |
| **Dependabot** | Dependency vulnerability scanning | Free | 🟢 |
| **CodeQL** | Static security analysis | Free for public, cheap for private | 🔶 |

---

*This document evolves. Version it, review it, challenge it. If something doesn't work in practice, change it — and update the template.*
