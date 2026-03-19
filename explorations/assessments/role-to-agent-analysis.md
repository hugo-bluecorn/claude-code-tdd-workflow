# Dev Roles as Claude Code Agents/Skills — Feasibility Analysis

> **Date:** 2026-03-15 (revised 2026-03-19)
> **Plugin version:** 1.14.1
> **Extensibility inventory:** extensibility-audit-prompt.md v3.0
> **Scope:** Should the three dev roles (CA, CP, CI) be converted to
> formal Claude Code agents, skills, or some hybrid? How would they
> integrate into the tdd-workflow plugin?

---

## Table of Contents

1. [What the Roles Are Today](#1-what-the-roles-are-today)
2. [The Conversion Question: Three Dimensions](#2-the-conversion-question)
3. [Role-by-Role Deep Analysis](#3-role-by-role-deep-analysis)
4. [The Fundamental Tensions](#4-the-fundamental-tensions)
5. [Viable Architectures](#5-viable-architectures)
6. [Recommendation Matrix](#6-recommendation-matrix)
7. [Draft Specifications](#7-draft-specifications)
8. [What NOT to Convert (and Why)](#8-what-not-to-convert)
9. [Integration Impact on tdd-workflow](#9-integration-impact)
10. [Open Questions](#10-open-questions)

---

## 1. What the Roles Are Today

The three roles exist as **prompt files** in `docs/dev-roles/`:

| Role | File | Purpose |
|------|------|---------|
| **CA** (Architect) | `ca-architect.md` | Decisions, issues, prompts, verification, memory |
| **CP** (Planner) | `cp-planner.md` | Executes `/tdd-plan` only |
| **CI** (Implementer) | `ci-implementer.md` | `/tdd-implement`, `/tdd-release`, `/tdd-finalize-docs`, direct edits, PR merges |

**Current usage model:** A human developer opens three separate Claude Code
sessions and pastes (or references) the appropriate role prompt into each one.
The roles define behavioral constraints, startup procedures, and handoff
protocols. The three-session model exists primarily to manage **context window
pressure** — each session stays focused on one concern, preventing
autocompaction from discarding critical context.

**Key observation:** These are *session identity documents*, not task
specifications. They define *who the session is* across many interactions,
not *what to do right now*.

---

## 2. The Conversion Question: Three Dimensions

The question "should roles become agents/skills?" actually contains three
distinct sub-questions:

### 2.1 Mechanization: Can the role's constraints be enforced?

Today, constraints like "CA never writes code" or "CI never runs `/tdd-plan`"
are enforced by convention — the developer follows the prompt. Claude Code
offers multiple mechanisms to make enforcement mechanical:

| Mechanism | Enforcement Type | Granularity | Plugin-safe? |
|-----------|-----------------|-------------|--------------|
| Agent `tools` allowlist (A3) | Hard — tool unavailable | Per-agent | Yes |
| Agent `disallowedTools` (A4) | Hard — tool blocked | Per-agent | Yes |
| `permissions.deny` (F2) | Hard — permission denied | Per-session/project | Yes |
| `permissionMode` (A6) | Hard — read-only modes | Per-agent | **No** — silently ignored for plugin agents (A27/D27) |
| PreToolUse hooks (C4) | Soft — can block with exit 2 | Per-tool pattern | Only via `hooks.json` with `agent_type` guard |
| Skill `disable-model-invocation` (B4) | Soft — Claude won't auto-invoke | Per-skill | Yes |

> **Lesson from Issue 004/005 (v1.14.0–v1.14.1):** Plugin agent restrictions
> (A27/D27) silently strip `hooks`, `mcpServers`, and `permissionMode` from
> plugin agent frontmatter. The tdd-workflow plugin learned this the hard way:
> Issue 004 required 7 slices and 74 tests to implement `agent_type` guard
> enforcement via `hooks.json`. Issue 005 then found the guard logic blocked
> the main thread when `agent_type` was absent — a subtle bug requiring
> another fix. Frontmatter hooks are now confirmed dead code; `hooks.json`
> is the **sole delivery path**. Any hypothetical role-agent enforcement
> would face the same complexity.

### 2.2 Formalization: Should the role become a first-class plugin component?

Roles could be formalized as:
- **Agents** (`agents/*.md`) — full subagent definitions with frontmatter
- **Skills** (`skills/*/SKILL.md`) — context injection with optional fork
- **Rules** (`.claude/rules/*.md`) — always-loaded behavioral constraints
- **Session configs** — CLAUDE.local.md or `--agent` flag usage
- **Hybrid** — some combination of the above

### 2.3 Integration: How would the converted role interact with existing
tdd-workflow components?

The plugin already has four agents (planner, implementer, verifier, releaser),
one post-release agent (doc-finalizer), one utility agent (context-updater),
and three orchestration skills (tdd-plan, tdd-implement, tdd-release). Any
role conversion must compose with — not duplicate or conflict with — these
existing components.

---

## 3. Role-by-Role Deep Analysis

### 3.1 CA (Architect) — The Conversationalist

**Nature of the role:** CA is fundamentally *interactive and conversational*.
It reviews plans, makes judgment calls, writes issues, manages memory, and
provides verification summaries. Its work products are text artifacts (issues,
memory entries, verification text) rather than code.

**What CA does in a typical session:**

```
1. Startup: read MEMORY.md, .tdd-progress.md, git log → assess state
2. Authoring: write issue file with requirements
3. Prompt crafting: compose /tdd-plan prompt for CP
4. Review: evaluate plan from CP, provide feedback
5. Approval: green-light CI to implement
6. Verification: review completed implementation, write verification summary
7. Memory: update MEMORY.md with decisions and outcomes
```

#### CA as Subagent? **NO**

The subagent model (A1-A21) is designed for **delegated tasks**: spawn,
execute, return result. Subagents cannot:
- Have multi-turn conversations with the user (they run autonomously)
- Span multiple user interactions (each invocation is one task)
- Invoke skills (no Skill tool available to subagents)
- Spawn other subagents (A18: no-nesting constraint)

CA's job is to *be the conversation partner*. It decides, reviews, and
iterates over multiple exchanges. This is the antithesis of a fire-and-forget
subagent.

**Extensibility features that confirm this:**
- A18 (no-nesting) prevents CA from spawning planner/implementer/verifier
- A19 (background execution) prevents CA from monitoring ongoing work
- Subagents lack AskUserQuestion in most configurations
- No mechanism for a subagent to "be" the session

#### CA as `--agent` Main Thread? **MAYBE — stronger case since v3.0**

The `--agent` flag (A25) and `agent` setting (F13) run Claude Code *as* a
specific agent. This replaces the default system prompt with the agent's
definition. Unlike subagents, an `--agent` session:
- IS the main thread — full conversational capability
- CAN spawn subagents via the Agent tool
- CAN use skills via the Skill tool
- Has full user interaction

This is the only mechanism that matches CA's conversational nature.

**v3.0 update:** The `agent` setting (F13) now persists across session
resumes. This makes role-as-agent significantly more practical: set it once
and every `claude --resume` preserves the role identity. This addresses the
original concern that `--agent` was only for headless/SDK use — it is now a
first-class interactive session feature.

**What it would look like:**

```yaml
# agents/ca-architect.md
---
name: ca-architect
description: >
  Architect/reviewer session for tdd-workflow. Makes decisions, writes
  issues, crafts planner prompts, verifies implementations, manages
  memory. Read-only for code — never writes source, test, or script files.
tools: Read, Glob, Grep, Bash, Write, Edit, Agent, Skill, AskUserQuestion
model: opus
color: red
memory: project
---
```

> **Note (v1.14.1):** Plugin agent frontmatter `hooks` are silently ignored
> (A27/D27). Write-path enforcement for CA would require a `hooks.json`
> entry with an `agent_type` guard filtering on `ca-architect`, following the
> same pattern established for Issue 004. The `ca-write-guard.sh` hook would
> go in `hooks.json`, not in the agent frontmatter.

The `ca-write-guard.sh` hook would allow writes only to:
- `issues/*.md`
- `memory/*.md`
- `MEMORY.md`
- `docs/dev-roles/*.md`
- `explorations/**/*.md`

And block writes to:
- `agents/*.md`, `skills/**`, `hooks/**`, `scripts/**`
- `lib/**`, `src/**`, `test/**`
- Any `.dart`, `.cpp`, `.c`, `.sh`, `.py` source files

**Problems with this approach:**

1. **System prompt replacement.** The agent's system prompt *replaces*
   Claude's default, which means losing built-in behaviors (auto-memory,
   status line, etc.) unless explicitly re-added. ~~The `--agent` flag was
   designed for headless/SDK use~~ — the `agent` setting (F13) now makes
   this a supported interactive pattern, but the system prompt loss remains.

2. **Tool restriction is too blunt.** The `tools` allowlist would need to
   include Agent and Skill (so CA can delegate to CP and CI) but there's no
   way to say "allow Agent but only for research, not implementation." The
   hook-based guard is the right answer, but it adds complexity — and must
   go in `hooks.json` with `agent_type` filtering (A27/D27 constraint).

3. **Session isolation is lost.** If CA, CP, and CI become agents invocable
   from a single session, the context window pressure problem returns. The
   whole point of three sessions was to keep each focused.

4. **The three-session model becomes a role-switching model.** Instead of
   three terminals, you'd have one terminal doing `claude --agent ca-architect`,
   then separately `claude --agent ci-implementer`. This is functionally
   identical to the current model (paste prompt into each session) but with
   mechanical enforcement. The `agent` setting persistence (F13) makes this
   smoother — resume always restores the role — but doesn't change the
   fundamental equivalence.

#### CA as Skill? **PARTIALLY — specific functions only**

While CA-as-a-whole doesn't fit a skill, specific CA functions do:

| CA Function | Skill Candidate? | Rationale |
|-------------|------------------|-----------|
| Startup checklist | **Yes** → `/tdd-status` | Procedural: read files, assess state, report |
| Issue authoring | No | Conversational, requires context and judgment |
| Prompt crafting | No | Requires understanding of feature + codebase |
| Plan review | No | Requires reading plan + applying judgment |
| Verification summary | **Yes** → `/tdd-verify-feature` | Procedural: read progress, check tests, format report |
| Memory management | No | Integrated with all other CA activities |

Two clear skill candidates emerge, covered in Section 7.

#### CA as SessionStart Hook? **YES — startup checklist only**

CA's startup checklist is a perfect fit for a SessionStart hook (C1):

```
On session start:
1. Read MEMORY.md
2. Read .tdd-progress.md if it exists
3. Check git log and branch
4. Report state summary
```

This is deterministic, read-only, and benefits every session regardless of
role. It's currently listed as N4 in the extensibility audit (nice-to-have).

Converting CA's startup to a hook doesn't replace CA — it mechanizes one
small part of CA's workflow that benefits all sessions.

---

### 3.2 CP (Planner) — The Already-Converted

**Nature of the role:** CP's only job is to execute `/tdd-plan`. CP exists
to provide a dedicated context window for planning iterations, so feedback
from CA doesn't get compacted away during long planning sessions.

**What CP does in a typical session:**

```
1. Read MEMORY.md for context
2. Receive /tdd-plan prompt from CA
3. Execute /tdd-plan
4. Review planner output, possibly reject and re-run
5. Report results to CA
```

#### CP is redundant with the existing plugin

The tdd-workflow plugin already provides:
- **tdd-planner agent** — the actual planning engine
- **`/tdd-plan` skill** — the orchestration wrapper with approval flow
- **Planner hooks** — bash-guard, validate-plan-output, SubagentStop

CP adds two things beyond the plugin:
1. **Quality self-review** — checking the plan before showing CA
2. **Iteration memory** — keeping feedback history in the session

But:
1. Quality review is already enforced by `validate-plan-output.sh` (hook M2)
   and the planner's Stop hook. The plugin's mechanical checks catch missing
   sections, refactoring leaks, and incomplete formats.
2. Iteration memory is handled by the `/tdd-plan` skill's Step 3 (Modify
   path), which resumes the planner subagent with user feedback using
   agent resumption (A14).

**Conclusion:** CP as a separate role is an artifact of the pre-plugin era
when planning happened in a raw Claude session without orchestration. The
plugin has absorbed everything CP does. A developer running `/tdd-plan` in
any session gets the full CP workflow.

#### Should CP become an agent? **NO — it already IS one (tdd-planner)**

The tdd-planner agent IS the mechanized CP. Converting the CP role document
to another agent would create a wrapper around a wrapper:

```
User → /tdd-plan (skill) → tdd-planner (agent) ← this is CP, mechanized
        ↑ this is the orchestration layer
```

Adding a cp-planner agent between the skill and tdd-planner would:
- Violate A18 (no-nesting) — cp-planner couldn't spawn tdd-planner
- Duplicate orchestration logic already in the `/tdd-plan` skill
- Add latency and token cost for zero functional benefit

#### Should CP become a skill? **NO — `/tdd-plan` already exists**

The `/tdd-plan` skill already encapsulates the complete CP workflow.

#### What should happen to CP?

**For plugin development:** CP should be retired as a role. The plugin's
own dev-roles (`docs/dev-roles/cp-planner.md`) can be updated with a
deprecation notice: "This role has been absorbed by the `/tdd-plan` skill
and tdd-planner agent." The CP prompt template in CA memory remains useful
as a handoff pattern, but the role definition itself adds nothing beyond
what the plugin provides.

**For projects using the plugin:** The CP *session pattern* remains
valuable. A dedicated planning session provides context isolation for
iterative planning — keeping planner research, CA feedback loops, and
plan revision history out of the CA and CI context windows. Any session
running `/tdd-plan` is effectively CP, but projects with complex features
benefit from designating a session for it. The `/tdd-init-roles` concept
(see `explorations/features/tdd-init-roles.md`) correctly generates only
CA + CI roles, leaving the CP session pattern as implicit guidance rather
than a formal role document.

---

### 3.3 CI (Implementer) — The Orchestrator

**Nature of the role:** CI is an orchestration role that chains multiple
plugin commands in sequence. It runs `/tdd-implement`, waits for CA
verification, runs `/tdd-release`, and runs `/tdd-finalize-docs`. It also
makes direct edits when CA authorizes small changes outside TDD.

**What CI does in a typical session:**

```
1. Read MEMORY.md and .tdd-progress.md
2. Receive instruction from CA ("proceed with /tdd-implement")
3. Execute /tdd-implement (spawns implementer + verifier per slice)
4. Report results to CA and wait for verification
5. Receive instruction from CA ("proceed with /tdd-release")
6. Execute /tdd-release (spawns releaser)
7. Report PR URL to CA
8. Receive instruction from CA ("proceed with /tdd-finalize-docs")
9. Execute /tdd-finalize-docs
10. Direct edits as instructed by CA
11. PR merge when CA approves
```

#### CI as Subagent? **NO**

Same fundamental problems as CA:
- Multi-step workflow spanning multiple user interactions
- Needs to invoke skills (`/tdd-implement`, `/tdd-release`)
- Needs to spawn subagents (Agent tool)
- Subagents can't do either (no Skill tool, A18 no-nesting)

#### CI as `--agent` Main Thread? **MAYBE — strongest case of the three**

Unlike CA, CI's constraints are *mechanically enforceable*:

| Constraint | Enforcement Mechanism |
|------------|----------------------|
| Never run `/tdd-plan` | `permissions.deny: ["Skill(tdd-plan)"]` or PreToolUse hook on Skill |
| Never make arch decisions | Prompt instruction (not mechanically enforceable) |
| Never skip TDD | Prompt instruction + check-tdd-progress.sh Stop hook already exists |
| Never modify .tdd-progress.md | PreToolUse hook blocking Edit on that path |
| Follow the plan | Prompt instruction + verifier enforcement |

A `ci-implementer` agent definition:

```yaml
---
name: ci-implementer
description: >
  Implementation session for tdd-workflow. Executes TDD slices, releases,
  documentation updates, and CA-authorized direct edits. Never plans or
  makes architectural decisions.
tools: Read, Write, Edit, MultiEdit, Bash, Glob, Grep, Agent, Skill, AskUserQuestion
model: opus
color: green
memory: project
---
```

**But this adds nothing the plugin doesn't already provide.** The existing
`/tdd-implement`, `/tdd-release`, and `/tdd-finalize-docs` skills already
orchestrate the agents. A CI-as-agent definition would just be the role
prompt in frontmatter form — same text, different format, no new capability.

The only thing CI-as-agent adds is **mechanical constraint enforcement**
(blocking `/tdd-plan`). But in practice, why would a session accidentally
invoke `/tdd-plan`? The risk is near zero, and the enforcement adds
complexity for no real safety benefit.

#### CI as Skill? **YES — the full lifecycle as a single command**

The most interesting conversion for CI isn't the role itself, but the
*orchestration pattern* it represents. Today, a developer manually runs:

```
/tdd-implement   → wait → /tdd-release   → wait → /tdd-finalize-docs
```

This could be a single skill: `/tdd-full-cycle`:

```
/tdd-full-cycle → implement all slices → verify → release → finalize docs
```

This doesn't replace CI as a role (CI still handles direct edits and PR
merges), but it mechanizes the most common CI workflow.

**Key concern:** The full cycle has human approval gates:
- After implementation: CA verifies before release
- During release: user approves CHANGELOG and PR text
- After docs: CA reviews documentation

A `/tdd-full-cycle` skill would need to preserve these gates. It can't skip
straight from implement to release without CA's blessing. This means the
skill would either:
1. Stop after implementation and tell the user to run `/tdd-release` later
   (which is what we already have)
2. Include AskUserQuestion gates between stages (making it a very long
   interactive skill)

Option 1 is the status quo. Option 2 is viable but would be a very long
skill invocation — potentially spanning hours for large features.

**Alternative: `/tdd-implement-and-report`** — a skill that runs
`/tdd-implement` and then produces a verification-ready summary for CA.
This mechanizes the "report results to CA" part of CI's workflow.

---

## 4. The Fundamental Tensions

### 4.1 Sessions vs. Agents: The Context Window Problem

The three-session model exists because of context window limits. Each session
maintains focused context for one concern:

| Session | Context Focus |
|---------|---------------|
| CA | Decisions, issues, verification criteria, memory state |
| CP | Plan iterations, feedback history, codebase research |
| CI | Implementation state, test results, slice progress |

Converting roles to agents doesn't solve this. Agents share the main
thread's context (for inline skills) or get their own smaller context (for
forked skills). Neither eliminates the pressure — they just move it.

The only solution to context pressure is **multiple sessions**, which is what
the current model already provides. The mechanism (role prompts vs. agent
definitions) is orthogonal to the problem.

### 4.2 Conversational vs. Procedural Work

Claude Code's extensibility model (agents, skills, hooks) is optimized for
**procedural work**: defined inputs, defined outputs, deterministic steps.
The three roles split unevenly:

| Work Type | CA | CP | CI |
|-----------|-----|-----|-----|
| Procedural | Startup, verification | 100% (run /tdd-plan) | 90% (run commands) |
| Conversational | Decision-making, review, issue authoring | 0% | 10% (direct edits, ambiguity resolution) |

CP is 100% procedural — and it's already been mechanized. CI is 90%
procedural — and most of that is already mechanized through skills. CA is
the outlier: its most valuable functions (decisions, judgment, review) are
inherently conversational and resist mechanization.

### 4.3 Enforcement vs. Trust

The roles define constraints ("CA never writes code", "CI never runs
/tdd-plan"). Should these be mechanically enforced?

**Arguments for enforcement:**
- Prevents accidents (wrong session runs wrong command)
- Makes the model robust to new team members
- Documents constraints as code, not prose

**Arguments against enforcement:**
- Adds complexity (hooks, guards, permission rules)
- The risk of violation is low (developer chooses which session to use)
- Enforcement can't catch the important constraints ("don't make arch
  decisions" — this is a judgment call, not a tool call)
- Over-restriction prevents legitimate flexibility (what if CA needs to
  make a quick direct edit for testing?)

**Empirical evidence (Issue 004/005):** The plugin's own experience with
enforcement is instructive. Adding `agent_type`-based hook enforcement for
6 existing agents required 7 implementation slices and 74 new tests (Issue
004). The guard logic then introduced a subtle bug — blocking the main
thread when `agent_type` was absent — requiring a follow-up fix (Issue 005,
net -8 tests after removing dead frontmatter hooks). Total cost: ~80 tests,
two releases, and a production bug, just to enforce constraints on agents
that were *already designed with correct tool restrictions*. Enforcement for
hypothetical role-agents (which have broader tool access and need
path-based write guards) would be significantly more complex.

**Assessment:** Mechanical enforcement is overkill for a single-developer
workflow, and the empirical cost from Issue 004/005 confirms this — the
complexity-to-risk ratio is unfavorable. Enforcement becomes valuable if
the plugin is used by a team where different developers operate different
roles, or in an automated pipeline where agents operate unsupervised.

### 4.4 The Naming Collision Problem

If roles become agents, the naming gets confusing:

```
Current agents:
  tdd-planner       ← does the actual planning work
  tdd-implementer   ← implements a single slice
  tdd-verifier      ← verifies a single slice
  tdd-releaser      ← runs the release workflow
  tdd-doc-finalizer ← updates documentation

Role agents (hypothetical):
  ca-architect      ← decides what to plan, reviews results
  cp-planner        ← runs /tdd-plan (which spawns tdd-planner)
  ci-implementer    ← runs /tdd-implement (which spawns tdd-implementer)
```

The role agents are *meta-agents* — they orchestrate the work agents. But
Claude Code's subagent model doesn't support nesting (A18). A role-agent
can't spawn a work-agent. Only the main thread can spawn agents.

This means role-agents can only work as `--agent` main thread sessions, not
as subagents. This limits their utility: they can't be composed, delegated
to, or run in the background.

---

## 5. Viable Architectures

After analyzing the tensions, five viable architectures emerge:

### Architecture A: Status Quo + Targeted Skills

**Convert nothing. Add utility skills that serve all roles.**

- Keep role prompts as documentation (`docs/dev-roles/*.md`)
- Add `/tdd-status` skill (CA's startup checklist for everyone)
- Add `/tdd-verify-feature` skill (CA's verification summary)
- Add SessionStart hook (N4) for TDD session detection

**Pros:** Minimal disruption, no naming confusion, additive
**Cons:** Constraints remain convention-based, roles remain prose

### Architecture B: Roles as Rules Files

**Convert roles to `.claude/rules/*.md` files.**

```
.claude/rules/
  ca-architect.md       # paths: ["issues/**", "memory/**"]
  ci-implementer.md     # paths: ["**/*.dart", "**/*.sh", "**/*.cpp"]
```

Rules files (E3, E9) support path-based activation. When CA reads/writes
issue files, the CA rule auto-activates. When CI works on source files,
the CI rule auto-activates.

**Pros:** Automatic context injection, no manual role selection
**Cons:** Path-based activation is too coarse (CA reads source files too,
for review), rules don't enforce constraints (they inject context, not
restrictions), consuming projects would need to adopt these files

### Architecture C: Roles as `--agent` / `agent` Sessions

**Convert CA and CI to `--agent` definitions. Retire CP.**

```bash
# CA session
claude --agent tdd-workflow:ca-architect

# CI session
claude --agent tdd-workflow:ci-implementer

# Planning session (any session)
/tdd-plan <feature>
```

The `agent` setting (F13) persists across resumes, so role identity survives
session interruptions. @-mention invocation (A24) lets users delegate to
specific agents within a session.

**Pros:** Mechanical enforcement, clear session identity, role is the
session's DNA rather than a pasted prompt, `agent` setting persists across
resumes (F13)
**Cons:** `--agent` replaces default system prompt (loses built-in
behaviors), adds two new agent files that look like but are fundamentally
different from the existing four work agents, plugin agent restrictions
(A27/D27) mean frontmatter hooks don't work — enforcement must go through
`hooks.json` with `agent_type` guards

### Architecture D: Roles as Inline Skills (Role Injection)

**Convert roles to user-invocable inline skills: `/role-ca`, `/role-ci`.**

```yaml
# skills/role-ca/SKILL.md
---
name: role-ca
description: >
  Activate the Architect/Reviewer role for this session. Injects CA
  behavioral constraints and startup procedures.
disable-model-invocation: true
---

# CA — Architect / Reviewer

You are the CA session. [full role text]

Read MEMORY.md and .tdd-progress.md now and report the current state.
```

The developer starts a session and types `/role-ca` to inject the role
identity. The skill runs inline (no fork), injecting the role text into
the conversation context.

**Pros:** User explicitly selects role, context injection is immediate,
no constraint enforcement complexity, works with existing plugin
**Cons:** Role text inflates context, no mechanical enforcement,
developer must remember to invoke `/role-ca` at session start

### Architecture E: Hybrid — Skills + SessionStart Hook

**The most pragmatic architecture. Combine A and D.**

1. **SessionStart hook** detects whether `.tdd-progress.md` exists and
   reports TDD session state (from N4 audit item)
2. **`/tdd-status`** skill provides on-demand state assessment
3. **`/tdd-verify-feature`** skill produces verification summaries
4. **Role prompts remain as documentation** for human reference
5. **Optional: `/role-ca` and `/role-ci` skills** for explicit role
   injection if the developer wants mechanical context injection

This adds utility without disruption. The role documents become reference
material; the skills become the actionable tools.

---

## 6. Recommendation Matrix

| Role | Convert to Agent? | Convert to Skill? | Convert to Hook? | Convert to Rule? | Recommended Action |
|------|-------|-------|------|------|-------|
| **CA** | No (conversational) | Partially (/tdd-status, /tdd-verify-feature) | Yes (SessionStart) | No (path matching too coarse) | Extract procedural functions as skills; keep role as documentation |
| **CP** | No (redundant with tdd-planner) | No (/tdd-plan exists) | N/A | N/A | **Retire.** Plugin has absorbed this role entirely |
| **CI** | No (needs main thread, adds nothing) | Partially (/tdd-full-cycle or /tdd-implement-and-report) | N/A | No | Extract orchestration pattern as skill; keep role as documentation |

### Overall Recommendation: **Architecture E (Hybrid)**

**Definitely do:**
1. Add `/tdd-status` skill — procedural, high value, serves all roles
2. Add SessionStart hook (N4) — detects TDD sessions automatically
3. Update CP role document to note it's been absorbed by the plugin

**Consider doing:**
4. Add `/tdd-verify-feature` skill — procedural, moderate value
5. Add `/role-ca` and `/role-ci` inline skills — convenience, low effort

**Do not do:**
6. Convert any role to a subagent — architectural mismatch
7. Convert any role to an `--agent` definition — adds complexity for
   minimal enforcement benefit
8. Add a `/tdd-full-cycle` skill — approval gates between stages make
   this impractical as a single invocation

---

## 7. Draft Specifications

### 7.1 `/tdd-status` Skill

Mechanizes CA's startup checklist. Useful for any role.

```yaml
# skills/tdd-status/SKILL.md
---
name: tdd-status
description: >
  Report the current TDD session state. Reads MEMORY.md,
  .tdd-progress.md, and git status to produce a state summary.
  Use at session start or when resuming interrupted work.
  Triggers on: "TDD status", "session state", "where was I".
disable-model-invocation: true
argument-hint: ""
---

# TDD Session Status

Produce a concise status report by gathering information from these sources:

## Step 1: Memory State

Read `MEMORY.md` (in the auto-memory directory). Summarize:
- Current version and recent changes
- Open issues or pending decisions
- Active work items

If MEMORY.md doesn't exist, note "No shared memory found."

## Step 2: TDD Progress

Read `.tdd-progress.md` in the project root. If it exists:
- Count slices by status (pending, in-progress, done/pass, fail, skip)
- Report the feature name and creation date
- Identify the next slice to work on
- Check if the plan has an `**Approved:**` timestamp

If `.tdd-progress.md` doesn't exist, note "No active TDD session."

## Step 3: Git State

Run these commands and summarize:
- `git branch --show-current` — current branch
- `git log --oneline -5` — recent commits
- `git status --porcelain | wc -l` — dirty file count
- `git stash list` — any stashed changes

## Step 4: Report

Present a structured summary:

```
## TDD Session Status

**Version:** <from MEMORY.md>
**Branch:** <current branch>
**TDD Session:** <active/none>
  - Feature: <name>
  - Progress: <N/M slices complete>
  - Next slice: <name> (status: <status>)
  - Plan approved: <yes/no>
**Dirty files:** <count>
**Recent activity:** <last 3 commits, one line each>
**Pending decisions:** <from MEMORY.md, if any>
```

## Constraints

- Read-only — do not modify any files
- Do not start implementation or planning
- If the state looks inconsistent (MEMORY.md says "in progress" but
  no .tdd-progress.md), flag the inconsistency explicitly
```

### 7.2 SessionStart Hook (N4)

Auto-detects TDD sessions on startup.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "if [ -f .tdd-progress.md ]; then PENDING=$(grep -c 'Status.*pending' .tdd-progress.md 2>/dev/null || echo 0); DONE=$(grep -cE 'Status.*(done|pass|complete)' .tdd-progress.md 2>/dev/null || echo 0); FEATURE=$(head -5 .tdd-progress.md | grep -oP '(?<=^# ).*' || echo 'unknown'); echo \"{\\\"additionalContext\\\": \\\"TDD SESSION ACTIVE: Feature '$FEATURE' — $DONE slices done, $PENDING pending. Run /tdd-status for full details or /tdd-implement to resume.\\\"}\"; fi",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### 7.3 `/tdd-verify-feature` Skill

Mechanizes CA's verification summary for PR body text.

```yaml
# skills/tdd-verify-feature/SKILL.md
---
name: tdd-verify-feature
description: >
  Produce a feature verification summary for a completed TDD feature.
  Reads .tdd-progress.md, runs the test suite, and generates a structured
  report suitable for PR body text. Use after all slices are done.
  Triggers on: "verify feature", "verification summary", "PR review".
disable-model-invocation: true
---

# TDD Feature Verification

<!-- ultrathink -->

Produce a comprehensive verification summary for the completed TDD feature.

## Step 1: Read the Plan

Read `.tdd-progress.md` and extract:
- Feature name and description
- Total slice count
- Each slice: name, status, planned test count vs actual
- Any slices that were skipped or failed

If any slices are still pending, warn the user and ask whether to proceed
with a partial verification.

## Step 2: Run Quality Gates

Run the full test suite and static analysis:
- Detect project type (Dart, C++, C, Bash) and run appropriate commands
- Capture total test count and assertion count
- Capture static analysis results
- If FVM is detected (`.fvmrc` exists and `fvm` on PATH), use `fvm` prefix

## Step 3: Compare Against Baseline

Check git log for the test count before this feature:
- `git log --all --oneline | head -20` to find the feature branch base
- Look for test count mentions in prior CHANGELOG entries or commits

If a baseline can't be determined, note it and report absolute counts only.

## Step 4: Generate Summary

Produce this format:

```
## Verification Summary

**Feature:** <name>
**Branch:** <branch>
**Slices:** <completed>/<total> (<skipped> skipped, <failed> failed)

### Test Delta
- Before: <N> tests, <M> assertions
- After: <N'> tests, <M'> assertions
- Delta: +<X> tests, +<Y> assertions

### Slice Status
| # | Slice | Status | Tests (planned → actual) |
|---|-------|--------|--------------------------|
| 1 | ... | done | 5 → 7 |

### Quality Gates
- Test suite: PASS (X passed, 0 failed)
- Static analysis: CLEAN (0 issues)
- Formatter: CLEAN

### Key Implementation Decisions
<extracted from commit messages and .tdd-progress.md>

### Deviations from Plan
<any slices with more/fewer tests than planned, or changed scope>

### Acceptance Criteria
- [ ] All planned slices completed
- [ ] Full test suite passes
- [ ] Static analysis clean
- [ ] No regressions in existing tests
```

## Constraints

- Read-only — do not modify any files
- Do not fix failing tests — only report them
- If the feature is incomplete, produce a partial report and flag it
```

### 7.4 Optional: `/role-ca` Inline Skill

For developers who want explicit role injection.

```yaml
# skills/role-ca/SKILL.md
---
name: role-ca
description: >
  Activate the Architect/Reviewer role. Injects CA behavioral constraints,
  startup procedures, and handoff protocols. Use at the start of a CA session.
disable-model-invocation: true
---

# Role: CA — Architect / Reviewer

You are operating as the **CA (Code Architect)** for this session.

## Your Responsibilities
- Make architectural decisions (approach, scope, inclusions/exclusions)
- Author issues (`issues/*.md`) with requirements and acceptance criteria
- Write `/tdd-plan` prompts for planning sessions
- Review and approve plans
- Verify completed implementations
- Manage shared memory (MEMORY.md)

## Your Constraints
- **Read-only for code.** Never write source, test, or script files.
- **Never run `/tdd-implement`, `/tdd-release`, or `/tdd-finalize-docs`.**
- **Never merge PRs.** Implementation sessions handle that.
- **You may write:** issue files, memory files, exploration docs, dev-role prompts.

## Handoff Patterns
- **To planner:** Provide issue file path + `/tdd-plan` prompt text
- **To implementer:** Say "proceed with `/tdd-implement`" after approving plan
- **From implementer:** Review PR, write verification summary

## Now: Assess Current State

Run `/tdd-status` to report the current TDD session state, then wait for
instructions.
```

### 7.5 Optional: `/role-ci` Inline Skill

```yaml
# skills/role-ci/SKILL.md
---
name: role-ci
description: >
  Activate the Implementer role. Injects CI behavioral constraints,
  startup procedures, and handoff protocols. Use at the start of a CI session.
disable-model-invocation: true
---

# Role: CI — Implementer

You are operating as the **CI (Code Implementer)** for this session.

## Your Responsibilities
- Execute `/tdd-implement` for pending slices
- Execute `/tdd-release` after CA verification
- Execute `/tdd-finalize-docs` after release
- Make direct edits when CA authorizes them
- Merge PRs after CA verification

## Your Constraints
- **Never run `/tdd-plan`.** Planning belongs to the planner.
- **Never make architectural decisions.** Report ambiguities to CA.
- **Never skip TDD for features.** Only CA can authorize direct edits.
- **Never modify `.tdd-progress.md` manually.** Plugin agents manage it.

## Startup Checklist

1. Read `MEMORY.md` for current project state
2. Read `.tdd-progress.md` for pending slices
3. Check `git status` for uncommitted changes from prior sessions
4. Check `git branch` to confirm correct feature branch
5. Wait for CA's instruction

## Now: Assess Current State

Run `/tdd-status` to report the current TDD session state, then wait for
instructions from CA.
```

---

## 8. What NOT to Convert (and Why)

### 8.1 Do Not Create a `cp-planner` Agent

**Why:** CP is entirely redundant with `/tdd-plan` + `tdd-planner`. Creating
a cp-planner agent would either:
- Duplicate the tdd-planner (pointless)
- Wrap the tdd-planner (impossible — A18 no-nesting)
- Replace the tdd-planner (breaking existing workflow)

### 8.2 Do Not Create `--agent` Main Thread Definitions (reassessed v3.0)

**Why:** The `--agent` flag replaces Claude's default system prompt, losing
built-in behaviors (auto-memory, status line, etc.). The enforcement benefit
(blocking wrong commands) doesn't justify the loss. The risk of a developer
accidentally running `/tdd-plan` in a CI session is near zero — they chose
to use that session for implementation.

**v3.0 reassessment:** The `agent` setting (F13) now persists across session
resumes, making `--agent` a first-class interactive feature rather than a
headless/SDK-only pattern. This weakens the original objection but doesn't
eliminate it — the system prompt replacement concern remains, and plugin
agent restrictions (A27/D27) mean frontmatter hooks are silently ignored,
so any constraint enforcement must go through `hooks.json` with `agent_type`
guards. The recommendation remains "do not" for the current single-developer
workflow, but this is closer to "not yet" than "never."

### 8.3 Do Not Create a `/tdd-full-cycle` Skill

**Why:** The full TDD lifecycle (implement → verify → release → finalize
docs) has mandatory human approval gates between stages. CA must verify
implementation before release. The user must approve CHANGELOG and PR text
during release. These gates can't be removed, and a single skill invocation
that pauses multiple times over hours is worse UX than three explicit
commands.

### 8.4 Do Not Use Rules Files for Roles

**Why:** Rules files (`.claude/rules/*.md`) use `paths:` frontmatter for
activation — they load when Claude reads files matching the glob pattern.
Roles aren't path-based. CA reads source files for review, CI reads source
files for implementation, and both read the same paths. Path-based
activation would inject the wrong role context constantly.

### 8.5 Do Not Add Mechanical Constraint Enforcement

**Why:** The constraints that matter most ("don't make architectural
decisions", "follow the plan") are judgment calls that can't be expressed
as tool restrictions or hook guards. The constraints that CAN be mechanized
("don't write code", "don't run /tdd-plan") address near-zero-risk
scenarios. The complexity of hooks, guards, and permission rules outweighs
the benefit.

**Reinforced by Issue 004/005:** The plugin's experience adding enforcement
for its own 6 work-agents demonstrates the true cost: 7 slices, 74 tests,
a production bug (main-thread blocking from absent `agent_type`), and a
follow-up hotfix. All for agents whose `tools` allowlists already provided
correct restrictions. Role-agents would need *path-based* write guards
(allow `issues/*.md` but block `agents/*.md`) — significantly more complex
than the tool-name guards in Issue 004. The guard scripts would need to
parse file paths from `tool_input`, handle edge cases (relative vs absolute
paths, symlinks, new directories), and go through `hooks.json` with
`agent_type` filtering (frontmatter hooks are dead code per A27/D27).

Exception: if the plugin is used in a **multi-developer team** or
**automated pipeline** where different people/systems operate different
roles, enforcement becomes valuable. But that's a future consideration,
not the current use case.

---

## 9. Integration Impact on tdd-workflow

### 9.1 New Components (if Architecture E is adopted)

| Component | Type | Files | Impact |
|-----------|------|-------|--------|
| `/tdd-status` | Skill | `skills/tdd-status/SKILL.md` | New. No conflicts |
| SessionStart hook | Hook | `hooks/hooks.json` addition | New event. No conflicts |
| `/tdd-verify-feature` | Skill | `skills/tdd-verify-feature/SKILL.md` | New. No conflicts |
| `/role-ca` | Skill (optional) | `skills/role-ca/SKILL.md` | New. No conflicts |
| `/role-ci` | Skill (optional) | `skills/role-ci/SKILL.md` | New. No conflicts |

### 9.2 Updated Components

| Component | Change |
|-----------|--------|
| `hooks/hooks.json` | Add `SessionStart` event |
| `docs/dev-roles/cp-planner.md` | Add deprecation notice |
| `CLAUDE.md` | Add new skills to Available Commands |
| `README.md` | Update component tables |
| Plugin manifest | Increment version |

### 9.3 No Changes Required

- Existing agents (planner, implementer, verifier, releaser, doc-finalizer)
- Existing skills (/tdd-plan, /tdd-implement, /tdd-release)
- Existing hooks (all current hooks remain unchanged)
- Convention skills (dart-flutter, cpp, bash, c)

### 9.4 Test Count Impact

The new skills are documentation/reporting tools — they don't contain
testable logic beyond the SessionStart hook. Estimated test additions:

| Component | New Tests | Rationale |
|-----------|-----------|-----------|
| SessionStart hook | 8-12 | Input parsing, state detection, output format |
| Skills | 0 | Skills are prompt text, not testable scripts |
| Total | 8-12 | |

### 9.5 CLAUDE.md Updates

The Available Commands table would gain:

| Command | Purpose |
|---------|---------|
| `/tdd-status` | Report TDD session state |
| `/tdd-verify-feature` | Produce feature verification summary |
| `/role-ca` | Inject CA role context (optional) |
| `/role-ci` | Inject CI role context (optional) |

The Session Roles section of CLAUDE.md would need to reference the skills
and note CP's retirement.

### 9.6 Skill Budget Impact (B23)

Current skills: 6 (tdd-plan, tdd-implement, tdd-release, tdd-finalize-docs,
tdd-update-context + 4 convention skills = 9 total descriptions in context).

Adding 2-4 more skills keeps us well within the 2% budget (B23). Each skill
description is ~2-3 lines. Total description text would be ~400-500 chars,
far under the 16k char default budget.

---

## 10. Open Questions

### 10.1 Should `/role-ca` and `/role-ci` be included in v1 of this change?

**Arguments for:** Low effort (just SKILL.md files), provides explicit role
injection for developers who want it, documents roles as code rather than
prose.

**Arguments against:** Roles are already documented in `docs/dev-roles/`.
Adding skill versions creates two sources of truth. If the role document
is updated, the skill must be updated too. The skill adds context pressure
(full role text injected into conversation).

**Suggestion:** Defer. Add them later if the startup hook + status skill
aren't sufficient. The role documents work fine as-is.

### 10.2 Should CP's role document be archived or deleted?

**Options:**
- **Archive:** Move to `docs/dev-roles/archive/cp-planner.md` with a
  deprecation header
- **Update:** Keep in place, add "Absorbed by plugin" notice
- **Delete:** Remove entirely

**Suggestion:** Update with a deprecation notice. The document has
historical value and explains why the three-session model exists.

### 10.3 Should `/tdd-status` use `context: fork`?

Running in a forked context would protect the main conversation from
the status-gathering tool calls. But the status report is short and the
tool calls are lightweight (read files, run git commands). Inline execution
is simpler and the user sees the status immediately.

**Suggestion:** Run inline (no fork). The context cost is minimal.

### 10.4 Should `/tdd-verify-feature` use `context: fork`?

Verification runs the test suite and produces a long report. Forking would
keep the main context clean but requires an agent definition.

**Suggestion:** Fork with a lightweight agent. The verification process
involves Bash (running tests), Read (reading progress file), and Grep/Glob
(finding files). A simple agent with these tools suffices.

### 10.5 Version number for this change?

If only `/tdd-status` and the SessionStart hook are added: **MINOR bump**
(new feature, no breaking changes). If role skills are also added: still
MINOR. If CP is formally deprecated: document in CHANGELOG but no version
impact (deprecation of a non-plugin component).

---

## Appendix: Extensibility Features Referenced

| Feature | ID | Relevance to Role Conversion |
|---------|-----|-----|
| Agent `tools` allowlist | A3 | Could enforce CA/CI constraints |
| Agent `disallowedTools` | A4 | Could block specific tools per role |
| Agent `permissionMode` | A6 | Could make CA read-only |
| Subagent resumption | A14 | Planner iteration via feedback loop |
| No-nesting constraint | A18 | Prevents role-agents from spawning work-agents |
| @-mention invocation | A24 | Users can delegate to specific agents |
| `--agent` / `agent` setting | A25, F13 | Could make roles into session identities. `agent` setting persists across resumes (v3.0) |
| Plugin agent restrictions | A27 | **Resolved v1.14.0.** Frontmatter hooks silently ignored; enforcement must use hooks.json with `agent_type` guards |
| Skill `disable-model-invocation` | B4 | Prevents Claude from auto-loading role skills |
| Skill `context: fork` | B8 | Could isolate role context |
| SessionStart hook | C1 | Mechanizes startup checklist |
| PreToolUse hooks | C4 | Could enforce write restrictions |
| Plugin `settings.json` | D26 | Could ship default `agent` setting (only `agent` field supported) |
| Plugin agent restrictions | D27 | Same as A27 — hooks.json sole delivery path |
| `permissions.deny` | F2 | Could block specific skills per role |
| `agent` setting | F13 | Persists agent mode across resumes; makes `--agent` a first-class interactive feature |
| Rules files with `paths:` | E3, E9 | Path-based role activation (rejected) |
| Auto-memory | E7 | Role-specific memory scopes |

---

## Revision History

| Date | Changes |
|------|---------|
| 2026-03-19 | **v2 — Updated to inventory v3.0 and plugin v1.14.1.** Feature IDs renumbered throughout (A12→A14, A13→A25, A16→A18, A17→A19, B22→B23, C3→C4). Substantive changes: (1) `agent` setting (F13) makes `--agent` a first-class interactive feature — strengthens Architecture C case, revised §3.1 and §8.2 assessments from "designed for headless/SDK" to "supported interactive pattern, but system prompt replacement concern remains." (2) A27/D27 plugin agent restrictions resolved in v1.14.0 — agent frontmatter hooks are dead code, all enforcement must use hooks.json with `agent_type` guards. Updated §3.1 CA agent spec to remove frontmatter hooks, added note about hooks.json requirement. (3) Issue 004/005 empirical evidence integrated into §2.1 (enforcement mechanisms table gains Plugin-safe? column + blockquote), §4.3 (enforcement cost data), and §8.5 (path-based guard complexity). The 7-slice, 74-test, one-bug cost of enforcing constraints on well-restricted agents strengthens the "enforcement is overkill" assessment. (4) Added A24, A27, D26, D27, F13 to appendix. Overall recommendation unchanged: Architecture E (Hybrid) remains correct. |
| 2026-03-15 | v1 — Original analysis against inventory v2.1, plugin v1.13.0. |
