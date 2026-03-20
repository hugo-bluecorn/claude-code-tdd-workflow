# Multi-Session Claude Code Paradigm: Community Survey

**Date:** 2026-03-20
**Scope:** Comprehensive survey of how the community uses multiple Claude Code sessions
**Method:** Web research across GitHub, blogs, Hacker News, Medium, Substack, official docs

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [The Dual-Instance / Multi-Session Guides](#2-the-dual-instance--multi-session-guides)
3. [Community Tools for Multi-Session](#3-community-tools-for-multi-session)
4. [Developer Experiences (First-Person Accounts)](#4-developer-experiences-first-person-accounts)
5. [TDD + Multiple Sessions](#5-tdd--multiple-sessions)
6. [Agent Teams Real-World Usage](#6-agent-teams-real-world-usage)
7. [Role/Identity in Multi-Session Context](#7-roleidentity-in-multi-session-context)
8. [Coordination Patterns Deep Dive](#8-coordination-patterns-deep-dive)
9. [Problems and Anti-Patterns](#9-problems-and-anti-patterns)
10. [Key Findings for TDD Workflow Plugin](#10-key-findings-for-tdd-workflow-plugin)

---

## 1. Executive Summary

The multi-session Claude Code paradigm has exploded in Q1 2026. Anthropic reports 78% of
Claude Code sessions now involve multi-file edits (up from 34% a year prior), and
multi-agent tools ship weekly. The community has converged on a few key patterns:

**What exists:**
- Dozens of orchestration tools (Conductor, IttyBitty, Claude Squad, ccmux, parallel-cc, etc.)
- Well-documented dual-instance planning (FlorianBruniaux guide, Boris Tane's workflow)
- The SJRamblings four-agent pattern (Architect/Builder/Validator/Scribe)
- Official Agent Teams with TeammateTool (experimental, 13 operations)
- Anthropic's own 16-agent C compiler case study

**What does NOT exist:**
- **No one has formalized session role definitions in a structured, reusable format.**
- No standard role definition schema (personality, constraints, deliverables, tool boundaries).
- No lifecycle management for roles (roles that evolve as a project progresses).
- No TDD-specific multi-session workflow outside our plugin.

This is the gap our plugin uniquely fills.

---

## 2. The Dual-Instance / Multi-Session Guides

### 2.1 FlorianBruniaux/claude-code-ultimate-guide

**Source:** [GitHub](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/workflows/dual-instance-planning.md)

The most complete written guide for dual-instance workflows.

**Two Roles:**
- **Claude Zero (Planner):** Explores codebase, interviews user, writes plans to
  `.claude/plans/Review/`. Never edits code or commits.
- **Claude One (Implementer):** Reads approved plans from `.claude/plans/Active/`,
  implements sequentially, commits after each step. Never creates plans.

**Directory-Based Coordination:**
```
.claude/plans/
  Review/     <- Claude Zero writes here
  Active/     <- Human moves approved plans here
  Completed/  <- Archived after implementation
```

**Five Workflow Phases:**
1. Planning (Claude Zero explores, writes plan)
2. Review (Human approves, moves to Active/)
3. Implementation (Claude One executes plan)
4. Verification (Claude Zero reviews completed work)
5. Archive (Plans move to Completed/)

**Role Enforcement:** Via CLAUDE.md instructions in each session. No structured schema--
just natural language rules like "never edit code" and "never create plans."

**Cost Analysis:** Medium complexity features cost ~$24 dual-instance vs ~$35 single-instance
(saves correction loops). Best for solo devs at $100-300/month.

**Anti-pattern identified:** Context pollution--never share context between the two sessions.

### 2.2 FlorianBruniaux Agent Teams Guide

**Source:** [GitHub](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/workflows/agent-teams.md)

The most comprehensive Agent Teams reference found. Key contributions:

**Spawn Templates:**
```
"Spawn 3 agents:
- Agent [Role]: [Scope with file boundaries]
- Agent [Role]: [Scope with file boundaries]
- Agent [Role]: [Scope with file boundaries]
Coordinate via shared interfaces."
```

**Five Orchestration Patterns:**
1. Fan-Out / Fan-In (distribute, collect, synthesize)
2. Hierarchical Delegation (lead spawns sub-leads who spawn workers)
3. Interface-First (define types/APIs before parallel work)
4. Sequential Phases with Parallelization
5. Parallel Hypothesis Testing

**Anti-Patterns Cataloged:**
- Over-delegation (>5 agents = coordination overhead exceeds gains)
- Premature automation (automating workflows not yet mastered manually)
- Too many agents on small tasks (<5 files = overkill)
- Circular dependencies
- Ignoring context overflow
- Skipping human review

**Cost:** Agent teams use ~1.7x-3x single-agent tokens. 7x when teammates run in plan mode.

### 2.3 SJRamblings Four-Agent Pattern

**Source:** [sjramblings.io](https://sjramblings.io/multi-agent-orchestration-claude-code-when-ai-teams-beat-solo-acts/)

Four VS Code terminal tabs, one shared document.

| Agent | Role |
|-------|------|
| Architect | System exploration, architecture plans, maintains MULTI_AGENT_PLAN.md |
| Builder | Core implementation based on Architect's specs |
| Validator | Test suites, edge cases, QA, debugging |
| Scribe | Documentation, code refinement, usage guides |

**Coordination:** Single shared `MULTI_AGENT_PLAN.md` with task entries:
```
## Task: Implement User Authentication
- **Assigned To**: Builder
- **Status**: In Progress
- **Notes**: [specific coordination details]
- **Last Updated**: [timestamp] by [Agent name]
```

**Git branches:** `agent1/planning`, `agent2/implementation`, `agent3/testing`, `agent4/documentation`

**Sync cadence:** Agents check the planning document every 30 minutes.

**Real-world result:** Supplement-medication interaction checker completed in 2 days
instead of estimated 1 week.

**Assessment:** Elegantly simple. No tooling required. But coordination is manual and
role enforcement is purely honor-system (natural language instructions in each terminal).

---

## 3. Community Tools for Multi-Session

### 3.1 Conductor (conductor.build)

**Type:** Mac desktop app (free)
**Coordination model:** Git worktree isolation with visual management
**How it works:**
- Creates a new git worktree and branch per Claude session in one click
- Visual UI shows all agents, what they are working on, status
- Uses existing Claude Code login (Pro/Max plan)
- No role definitions--each agent is a general-purpose implementer

**Developer quote:** "Git worktrees are a huge pain to manage manually. Conductor just
makes it really easy."

**Limitation:** Mac-only. Windows on roadmap. No role concept.

### 3.2 IttyBitty

**Source:** [adamwulf.me](https://adamwulf.me/2026/01/itty-bitty-ai-agent-orchestrator/)
**Type:** Bash-based CLI orchestrator
**Coordination model:** Manager/Worker hierarchy with tmux + git worktrees

**Key architecture:**
- **Managers:** Can spawn other agents (including other managers)
- **Workers:** Cannot spawn additional agents
- Each agent runs in isolated git worktree at `.ittybitty/agents/[agent-id]/repo`

**Safety mechanisms:**
- PreToolUse hook validates file paths--agents cannot access parent repo or siblings
- Stop hook monitors for completion phrases ("WAITING" or "I HAVE COMPLETED THE GOAL")
- System-wide agent cap prevents fork bombs
- `ib nuke` emergency shutdown

**Inter-agent communication:**
- `ib send [agent-id] [message]` injects input into target tmux session
- Completion auto-notifies the agent's manager
- Agents can discover peers via `ib list`

**Assessment:** Most sophisticated open-source tool. Manager/Worker is the closest
thing to formalized roles, but roles are implicit (defined by the initial prompt),
not structured.

### 3.3 Claude Squad

**Source:** [github.com/smtg-ai/claude-squad](https://github.com/smtg-ai/claude-squad)
**Type:** Terminal TUI app
**Coordination model:** Independent sessions with tmux + git worktrees
**How it works:** Manages multiple Claude Code, Codex, Aider sessions in separate
workspaces. Visual overview of all sessions. Supports profiles for different configurations.
**No role definitions.** Pure parallel task execution.

### 3.4 ccmux

**Source:** [PyPI](https://libraries.io/pypi/ccmux)
**Type:** tmux wrapper (Python)
**Coordination model:** Visual sidebar + worktree isolation
**How it works:** `ccmux` auto-creates session for current directory. Visual sidebar
shows all sessions with red highlights when Claude needs attention. Supports
`ccmux.toml` for post-worktree-creation commands.
**No role definitions.**

### 3.5 parallel-cc

**Source:** [github.com/frankbria/parallel-cc](https://github.com/frankbria/parallel-cc)
**Type:** CLI tool
**Coordination model:** SQLite session tracking + git worktrees + E2B sandboxes
**How it works:** Auto-detects parallel sessions, creates isolated worktrees,
SQLite tracks session heartbeats. Supports autonomous 1-hour execution in cloud VMs.
Plan-driven: Claude follows PLAN.md step-by-step.
**No role definitions.** Sessions are task-scoped, not role-scoped.

### 3.6 obra/claude-session-driver

**Source:** [github.com/obra/claude-session-driver](https://github.com/obra/claude-session-driver)
**Type:** Claude Code plugin (bash)
**Coordination model:** Controller/Worker with lifecycle hooks

**Orchestration patterns:**
- Delegate and wait (launch worker, assign task, read result)
- Fan out (launch several workers, wait for all)
- Pipeline (chain workers sequentially)
- Supervise (multi-turn conversation with worker, reviewing each response)

**Lifecycle events:** Written to JSONL file--session start, prompt submitted, tool use,
stop, session end. PreToolUse hook pauses before every tool call for controller approval.

**Assessment:** Plugin architecture closest to our TDD workflow model. Controller has
explicit supervisory role. Workers are task-scoped.

### 3.7 andynu tmux gist -- Mission Control Pattern

**Source:** [GitHub gist](https://gist.github.com/andynu/13e362f7a5e69a9f083e7bca9f83f60a)
**Type:** Shell scripts
**Coordination model:** Central dispatcher + isolated child sessions

Two tools:
- `tmx-claude -d ~/work/src/myapp "Fix the flaky test"` -- quick dispatch
- `tmx-worktree -b feature-auth "Implement OAuth login"` -- isolated feature work

**Communication:** Sessions operate independently. Cross-session coordination through:
- Parent directory's beads database (issue tracking)
- Git remotes and branch sharing
- File system (worktrees visible as siblings)

**Decision matrix:**
| Scenario | Tool | Rationale |
|----------|------|-----------|
| Quick fix | tmx-claude | No isolation needed |
| Deep work | tmx-worktree | Prevents context pollution |
| Investigation | tmx-claude | Temporary, reversible |
| Risky refactor | tmx-worktree | Easy cleanup if abandoned |
| PR review mid-task | tmx-claude -d | Non-destructive parallel examination |

### 3.8 GitButler

**Source:** [blog.gitbutler.com](https://blog.gitbutler.com/parallel-claude-code)
**Type:** Desktop app + CLI with Claude Code hooks
**Coordination model:** Virtual branch separation (no worktrees needed)

**How it works:** Claude Code lifecycle hooks notify GitButler when files are edited.
GitButler assigns changes to virtual branches by session ID. One commit per chat round,
one branch per session. Multiple sessions can edit the same working directory--GitButler
spatially separates the changes into different virtual branches.

**Unique advantage:** No worktrees required. Works in a single working directory.

### 3.9 ComposioHQ/agent-orchestrator

**Source:** [github.com/ComposioHQ/agent-orchestrator](https://github.com/ComposioHQ/agent-orchestrator)
**Type:** TypeScript orchestration framework
**Coordination model:** AI orchestrator decomposes features, spawns workers, manages lifecycle

**Key differentiator:** The orchestrator itself is an AI agent that reads your codebase,
understands your backlog, decides how to decompose, assigns tasks, monitors progress,
and makes decisions. Handles CI failures, review comments, and merge automatically.
40,000 lines of TypeScript, 3,288 tests, built in 8 days mostly by the agents themselves.

### 3.10 Ruflo (formerly claude-flow)

**Source:** [github.com/ruvnet/ruflo](https://github.com/ruvnet/ruflo)
**Type:** Full orchestration platform
**Coordination model:** Hive Mind with queen-led hierarchical coordination

Uses SQLite-based persistent memory at `.swarm/memory.db`. Queen agents direct
specialized workers through collective decision-making and shared memory. Stores
successful patterns in vector memory, builds knowledge graphs, learns from outcomes.

**Assessment:** Most ambitious framework. Over-engineered for most use cases but
demonstrates where multi-agent coordination could go.

### Tool Comparison Summary

| Tool | Isolation | Roles | Communication | Complexity |
|------|-----------|-------|---------------|------------|
| Conductor | Worktrees | None | None | Low |
| IttyBitty | Worktrees | Manager/Worker | Direct messaging | Medium |
| Claude Squad | Worktrees | None | None | Low |
| ccmux | Worktrees | None | Visual sidebar | Low |
| parallel-cc | Worktrees + E2B | None | SQLite tracking | Medium |
| session-driver | Worktrees | Controller/Worker | JSONL + hooks | Medium |
| GitButler | Virtual branches | None | Hooks | Low |
| Agent Orchestrator | Worktrees | AI-decided | AI orchestrator | High |
| Ruflo | Worktrees | Queen/Worker | SQLite + memory | High |

**Key observation:** Only IttyBitty and session-driver have even implicit role concepts.
No tool has formalized, structured role definitions.

---

## 4. Developer Experiences (First-Person Accounts)

### 4.1 Boris Cherny (Claude Code Creator)

**Source:** [Twitter/Threads](https://x.com/bcherny/status/2007179832300581177)

- Runs **5 Claudes in parallel** in terminal (numbered tabs 1-5)
- Additionally runs **5-10 Claudes on claude.ai** in browser
- Uses iTerm2 system notifications when a session finishes or needs input
- "Teleport" command to hand off sessions between web and local
- Starts sessions from his phone every morning
- Ships **20-30 PRs per day**
- **No role definitions.** Each session does plan-then-implement independently.
- Core principle: "Once there is a good plan, it will one-shot the implementation
  almost every time."

### 4.2 Boris Tane (Developer)

**Source:** [boristane.com](https://boristane.com/blog/how-i-use-claude-code/)

- Runs research, planning, and implementation in a **single long session**
- Core principle: "Never let Claude write code until you've reviewed and approved
  a written plan."
- The plan document survives compaction in full fidelity
- Does NOT split across sessions--contrary to the multi-session trend

### 4.3 incident.io Team

**Source:** [incident.io/blog](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees)

- Went from zero Claude Code to **4-5 simultaneous agents** per developer
- Custom bash function `w myproject new-feature claude` for instant worktree + Claude
- Voice-first input (SuperWhisper dictation) into Claude sessions
- **No role definitions.** Each session handles a different feature independently.
- Problem: Resource contention (databases, ports) when running multiple local envs
- CTO encouraged adoption via a usage leaderboard

### 4.4 WorksForNow Developer

**Source:** [worksfornow.pika.page](https://worksfornow.pika.page/posts/note-to-a-friend-how-i-run-claude-code-agents-in-parallel)

- Custom `/delegate [task IDs]` slash command spawns parallel agents
- Sessions named after task IDs (`tmux attach -t agent-8.3`)
- Tasks must be "independent--plan ahead so it's easy to split them cleanly"
- **No automated coordination** between sessions
- Key insight: "Mindset shift from micromanager to delegator"
- Problem: No notifications for completion or blockers. High cognitive load.

### 4.5 Hacker News Comments (conductor.build thread)

**Source:** [HN item #44594584](https://news.ycombinator.com/item?id=44594584)

Real developer experiences:
- "I run about four claude-codes at once" using git worktrees
- One developer uses "two full screen iTerm windows of four panes each" for legacy
  C modernization, coordinating via a STOP file signal
- Skeptic: "Getting Claude Code working properly two days in a row is still a challenge.
  Let it running in parallel unwatched will end up with nothing but a pile of code
  that will have to be re-written."
- Skeptic: "The bottleneck was never the AI not being able to write 10 different POCs
  but the human factor--needing to carefully review what AI produced."
- Problem: Worktrees don't include untracked files (.env), require additional setup
- Problem: Worktrees "simply do not work with submodules"

### 4.6 Hacker News Comments (Agent Teams thread)

**Source:** [HN item #46902368](https://news.ycombinator.com/item?id=46902368)

- FastAPI developer (50k LOC): 4 agents across 6 tasks in ~6 minutes vs 18-20 minutes
  sequential. Critical constraint: "Agents editing the same file leads to overwrites.
  Break the work so each teammate owns a different set of files."
- "Agent teams are sprinters, not marathon runners"
- Senior engineer: "I absolutely cannot trust Claude code to independently work on
  large tasks" without design guidance
- "LLMs to be significantly better in the 'review' stage than the implementation stage"
- "Orchestration is mostly a waste. Validation is the bottleneck."
- Successful pattern: Adversarial approach--one agent implements, another critiques

### 4.7 Pedro Sant'Anna (Academic)

**Source:** [psantanna.com](https://psantanna.com/claude-code-my-workflow/workflow-guide.html)

Academic workflow with multi-agent review: domain-reviewer template with 5 lenses,
22 skills for LaTeX/Beamer/R tasks. Corrections tagged with `[LEARN:tag]` and persisted
in MEMORY.md. Not parallel sessions per se, but structured skill-based delegation.

### 4.8 HAMY (9 Parallel Review Agents)

**Source:** [hamy.xyz](https://hamy.xyz/blog/2026-02_code-reviews-claude-subagents)

Nine parallel subagents for code review, each focused on a specific aspect:
Linter, Code Reviewer, Security Reviewer, Quality & Style Reviewer, etc.
Main agent synthesizes results into prioritized summary with verdict:
Ready to Merge / Needs Attention / Needs Work.

Run via `/code-review` slash command. This is subagent-based (within one session),
not multi-session, but demonstrates role specialization.

---

## 5. TDD + Multiple Sessions

### 5.1 alexop.dev -- Agentic Red-Green-Refactor Loop

**Source:** [alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)

The most directly comparable approach to our TDD workflow plugin.

**Three subagents, each in separate context windows:**
1. `tdd-test-writer` (RED) -- writes failing integration tests
2. `tdd-implementer` (GREEN) -- implements minimal code to pass
3. `tdd-refactorer` (REFACTOR) -- evaluates and improves

**Context isolation rationale:** "When everything runs in one context window, the LLM
cannot truly follow TDD because the test writer's detailed analysis bleeds into the
implementer's thinking."

**Enforcement:** Orchestrating skill (`.claude/skills/tdd-integration/skill.md`)
enforces sequential progression. UserPromptSubmit hook increases skill activation
from ~20% to ~84%.

**Comparison to our plugin:**
- Similar concept (separate agents per TDD phase)
- Uses subagents (within one session) rather than separate terminal sessions
- No planner agent (test specs come from human, not a planning phase)
- No verifier agent (test runner is built into each phase)
- No release or documentation agents
- No progress tracking file (.tdd-progress.md equivalent)

### 5.2 TDD Guard (nizos)

**Source:** [github.com/nizos/tdd-guard](https://github.com/nizos/tdd-guard)

Hook-based TDD enforcement (not a multi-agent system).
- PreToolUse hook blocks file modifications that violate TDD rules
- **Invokes a separate Claude Code session** to validate TDD adherence
- Persists context data to files between phases
- Blocks: implementation without failing tests, over-implementation, multiple
  simultaneous tests

**Key insight:** Uses a separate Claude session as a verifier--similar to our
tdd-verifier agent concept, but implemented as a hook rather than an explicit agent.

### 5.3 Matt Pocock TDD Skill

**Source:** [aihero.dev](https://www.aihero.dev/skill-test-driven-development-claude-code)

Single-session constraint-based approach. Forces ONE test -> ONE implementation -> repeat.
Not multi-agent. Prevents "cheating" by enforcing sequential cycles.
Install: `npx skills add mattpocock/skills/tdd`

### 5.4 Nathan Fox -- TDD in CLAUDE.md

**Source:** [nathanfox.net](https://www.nathanfox.net/p/taming-genai-agents-like-claude-code)

Embeds TDD rules directly in CLAUDE.md for consistency across sessions.
Single-session approach. No role separation.

### 5.5 FlorianBruniaux TDD Guide

**Source:** [GitHub](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/workflows/tdd-with-claude.md)

Recommends parallelizing where possible: parallel test writing, concurrent
implementation, batch refactoring. But within a single agent teams context,
not separate manual sessions.

### TDD Multi-Session Gap Analysis

**No one in the community combines TDD with formalized multi-session roles.**

Existing approaches:
- alexop.dev uses subagents (not separate sessions) for TDD phases
- TDD Guard uses a separate session as a validator hook
- Most TDD approaches are single-session with CLAUDE.md constraints

Our plugin's unique contribution:
- Separate agents (planner, implementer, verifier, releaser, doc-finalizer)
- Each with defined roles, tool access, and model assignments
- Progress tracking across sessions (.tdd-progress.md)
- Planning archive (planning/ directory)
- Convention loading (project-conventions skill)
- Release pipeline (CHANGELOG, push, PR)

---

## 6. Agent Teams Real-World Usage

### 6.1 Anthropic's C Compiler (16 agents)

**Source:** [anthropic.com/engineering](https://www.anthropic.com/engineering/building-c-compiler)

The definitive multi-agent case study:
- 16 agents, ~2,000 sessions, $20,000 API cost
- 100,000-line Rust-based C compiler that builds Linux 6.9
- **No message bus or task queue.** Coordination through Git.
- Lock files at `current_tasks/` for task claiming
- Pull-merge-push pattern for synchronization

**Coordination failures:**
- Linux kernel compilation = monolithic task. All 16 agents hit same bug, fixed it,
  overwrote each other. Solution: GCC as oracle + binary search.
- Agents must "maintain extensive READMEs and progress files updated frequently"

**Specialization emerged naturally:**
- Core compiler implementation
- Code deduplication
- Performance optimization
- Documentation maintenance

**Key lessons:**
- Write extremely high quality tests
- Test harness should not print thousands of useless bytes
- Progress reporting must be concise (context window constraints)
- Parallelism only helps when tasks are truly independent

### 6.2 ZeroFutureTech -- Two Days with Agent Teams

**Source:** [zerofuturetech.substack.com](https://zerofuturetech.substack.com/p/i-spent-two-days-with-claude-agent)

**What worked:** Five-agent council for multi-perspective analysis:
- Tech Optimist, Risk Analyst, End-User Advocate, Business Strategist, Ethics Critic
- Key instruction: "Each role must hold a committed position--contradiction between
  roles is expected and encouraged."
- Agents developed "genuinely different perspectives because each agent runs in its
  own context window with its own reasoning chain."

**What failed:** Complex software development (ERP system):
- "Team lead would get excited about a particular feature and dive deep into
  implementation details while completely forgetting to sync with the PM or designer"
- ~100K+ tokens burned with partial specs, incomplete backend, no working demo
- Agent independence became a liability for sequential dependencies

**Core insight:** Agent Teams excel when "context independence itself is valuable"--
for diverse thinking, not coordinated execution.

### 6.3 ClaudeFast Builder-Validator Pattern

**Source:** [claudefa.st](https://claudefa.st/blog/guide/agents/team-orchestration)

Formalized two-agent pattern:
- **Builder:** Creates code, runs tests, marks task complete. Cannot modify test files.
- **Validator:** Reads all builder output, checks acceptance criteria, runs tests,
  reports findings. **Cannot modify any source files.**

Coordination via TaskCreate with `addBlockedBy` parameter:
```
TaskCreate(subject="Build auth middleware")
TaskCreate(subject="Validate auth middleware")
TaskUpdate(taskId="2", addBlockedBy=["1"])
```

Validator tool enforcement: `disallowedTools` prevents Edit/Write access entirely.

When validators find issues: create new task -> route to builder -> chain new validator.
Mirrors human code review workflows.

### 6.4 Kieran Klaassen Swarm Guide

**Source:** [GitHub gist](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)

Most detailed TeammateTool reference. 13 operations across:
- Team management (spawnTeam, discoverTeams, requestJoin/approve/reject)
- Communication (write, broadcast)
- Workflow control (requestShutdown/approve/reject, approvePlan/rejectPlan)
- Lifecycle (cleanup)

Five orchestration patterns:
1. Parallel Specialists (simultaneous review perspectives)
2. Sequential Pipelines (auto-unblocking via task dependencies)
3. Self-Organizing Swarms (workers claim tasks from pools)
4. Research-Guided Implementation (research findings embedded in agent prompts)
5. Plan Approval Workflows (specialists submit plans requiring leader approval)

**Environment variables for spawned teammates:**
```
CLAUDE_CODE_TEAM_NAME
CLAUDE_CODE_AGENT_ID
CLAUDE_CODE_AGENT_NAME
CLAUDE_CODE_AGENT_TYPE
CLAUDE_CODE_AGENT_COLOR
CLAUDE_CODE_PLAN_MODE_REQUIRED
CLAUDE_CODE_PARENT_SESSION_ID
```

---

## 7. Role/Identity in Multi-Session Context

### The Central Question: Does Anyone Formalize Session Roles?

**Answer: Almost no one, and never in a structured schema.**

#### What exists:

1. **Natural language role prompts in CLAUDE.md or terminal instructions:**
   - FlorianBruniaux: "Claude Zero never edits code" / "Claude One never creates plans"
   - SJRamblings: "You are the Architect. Your job is system exploration and planning."
   - All are ad-hoc, prose-format instructions

2. **Agent markdown files (.claude/agents/*.md):**
   - Community collections exist (awesome-claude-code-subagents, 100+ agents)
   - Each defines: description, role, MUST/MUST NOT rules, tools
   - Format: unstructured markdown with conventions, not a formal schema
   - Examples: `architect-reviewer.md`, `senior-code-reviewer.md`
   - These are subagent definitions (spawned within a session), not session role definitions

3. **TeammateTool spawn prompts:**
   - Contain role instructions: "You are a security reviewer. Check for vulnerabilities."
   - Passed as plain text in the spawn command
   - No persistent role definition file

4. **Implicit roles from tool restrictions:**
   - Builder-Validator pattern uses `disallowedTools` for enforcement
   - IttyBitty Manager/Worker distinction is structural (can/cannot spawn)
   - TDD Guard blocks implementation before tests (enforcement, not identity)

#### What does NOT exist:

1. **No structured role definition schema**
   - No one has a formal spec with: role name, personality, MUST rules, MUST NOT rules,
     tool access, model assignment, deliverables, success criteria, communication protocols
   - Our `explorations/features/role-definition-spec.md` appears to be unique

2. **No role lifecycle management**
   - No concept of roles that evolve across project phases
   - No post-spec / post-plan / post-impl role adaptation
   - Our phased planning concept is unique

3. **No "become X" pattern**
   - No one writes persistent role files that a session reads to assume identity
   - Closest: CLAUDE.md instructions, but these apply to ALL sessions, not per-session

4. **No role coordination protocols**
   - No structured format for how Role A communicates with Role B
   - Closest: SJRamblings' MULTI_AGENT_PLAN.md, but it's a task list, not a protocol

5. **No session role persistence**
   - When a session ends and resumes, the role must be re-established manually
   - No mechanism for "this session was the Architect; restore that identity"

### Assessment

The community has converged on the IDEA of roles (Architect/Builder/Validator/etc.)
but implements them entirely through ad-hoc natural language instructions. No one has
built a structured role definition layer. This is exactly what our
`explorations/features/role-definition-spec.md` proposes and what `/tdd-init-roles`
would generate.

---

## 8. Coordination Patterns Deep Dive

### 8.1 Shared Files

| File/Pattern | Used By | Format |
|-------------|---------|--------|
| MULTI_AGENT_PLAN.md | SJRamblings | Task list with status, assignee, notes |
| .claude/plans/{Review,Active,Completed}/ | FlorianBruniaux | Plan documents as markdown |
| PLAN.md / PROGRESS.md | Many (generic) | Checklist-style progress tracking |
| HANDOFF.md | Community pattern | What was tried, what worked, what didn't |
| .tdd-progress.md | Our plugin | Structured TDD slice tracking |
| current_tasks/*.txt | Anthropic C compiler | Lock files for task claiming |
| .claude/tasks/{team}/N.json | Agent Teams | JSON task objects with dependencies |
| ~/.claude/teams/{name}/inboxes/ | Agent Teams | Per-agent message files |
| STOP file | HN developer | Signal file for shared resource coordination |
| .swarm/memory.db | Ruflo | SQLite persistent memory |
| JSONL event log | session-driver | Lifecycle events for monitoring |

### 8.2 Git-Based Coordination

| Pattern | Used By | How |
|---------|---------|-----|
| Separate worktrees | Most tools | Each agent in isolated worktree |
| Branch per session | GitButler | Virtual branch separation |
| Named branches | SJRamblings | agent1/planning, agent2/implementation |
| Lock files via git | Anthropic | current_tasks/ directory |
| Pull-merge-push | Anthropic, general | Continuous integration pattern |
| Redis-based locks | bredmond1019 | File locking with 300s timeout |

### 8.3 Messaging/Communication

| Pattern | Used By | Mechanism |
|---------|---------|-----------|
| No communication | Conductor, Squad, most | Fully independent sessions |
| Direct messaging | IttyBitty | tmux send-keys injection |
| Peer-to-peer mailbox | Agent Teams | File-based inbox per agent |
| Broadcast | Agent Teams | Multi-agent message (expensive) |
| JSONL event stream | session-driver | Structured lifecycle events |
| WebSocket status | bredmond1019 | Real-time dashboard updates |
| SQLite shared memory | Ruflo, parallel-cc | Database-mediated coordination |
| Shared planning doc | SJRamblings | Periodic check-in (every 30 min) |

### 8.4 Human as Message Bus

The most common coordination pattern is the human developer manually:
- Reviewing output from session A
- Copy-pasting relevant context into session B
- Making architectural decisions that affect multiple sessions
- Moving files between directories (Review -> Active -> Completed)
- Running git merge between agent branches

Boris Cherny exemplifies this: 5-15 sessions, no automation, human dispatches and reviews.

### 8.5 Handoff Documents

Community-standard handoff format:
```markdown
# [Task Title]
Generated: [timestamp] | Branch: [branch-name]

## Goal
[What we're trying to accomplish]

## Completed
- [x] Finished item 1
- [x] Finished item 2

## Not Yet Done
- [ ] Remaining item 1
- [ ] Remaining item 2

## Failed Approaches
- Tried X, didn't work because Y
- Tried Z, failed with error: [exact message]
```

Critical elements: failed approaches (saves hours), actual code signatures,
test steps with expected outcomes, exact error messages.

---

## 9. Problems and Anti-Patterns

### 9.1 Context Drift

- Sessions gradually lose awareness of what other sessions have done
- Progress files help but require discipline to update
- Anthropic C compiler: "maintain extensive READMEs and progress files"
- No automated solution exists; all require manual diligence

### 9.2 Conflicting Changes

- Multiple agents editing the same file leads to overwrites
- Critical constraint: "Break the work so each teammate owns a different set of files"
- Redis locks, git lock files, and virtual branches are workarounds
- Fundamentally unsolved for tightly-coupled code

### 9.3 Session Forgetting Its Role

- No persistence mechanism for session identity
- After context compaction, sessions may drift from their assigned role
- FlorianBruniaux mitigates with CLAUDE.md per-session instructions
- Hook-based enforcement (TDD Guard, IttyBitty) is more reliable than prompt-based

### 9.4 Coordination Overhead

- Agent Teams use ~1.7x-3x tokens vs single session
- 7x when teammates use plan mode
- "5-7 concurrent agents" is the practical ceiling before rate limits and review
  bottleneck eat the gains
- HN: "Orchestration is mostly a waste. Validation is the bottleneck."

### 9.5 The Review Bottleneck

- "The bottleneck shifted from 'the AI is too slow' to 'I can only review so fast'"
- "Code review at scale becomes nearly impossible. Copious amounts of code harder
  to review than small snippets."
- Google DORA Report: 90% AI adoption increase correlates with 91% increase in code
  review time and 154% increase in PR size

### 9.6 When Multi-Session Is NOT Worth It

- Simple tasks (<5 files)
- Sequential dependencies (agent B needs agent A's output)
- Same-file heavy edits
- Tight deadlines (setup overhead)
- Budget-constrained projects
- Small codebases with tight interdependencies
- Debugging complex race conditions (need deep single-focus)

### 9.7 Infrastructure Problems

- Worktrees don't include untracked files (.env, etc.)
- Worktrees don't work with git submodules
- Dependency installation required per worktree
- Resource contention (databases, ports) with multiple local envs
- Rate limit hits with parallel sessions on Pro plan

---

## 10. Key Findings for TDD Workflow Plugin

### 10.1 What We Do That No One Else Does

1. **Structured role definitions** for TDD sessions (planner, implementer, verifier,
   releaser, doc-finalizer) with explicit tool access and model assignments
2. **Planning as a first-class agent** (tdd-planner) -- most workflows start with
   human-written plans, not AI-generated decomposition
3. **Verifier as a separate agent** that runs the COMPLETE test suite, not just new tests
4. **Convention loading** (project-conventions skill with DCI) -- no other TDD tool
   has language-aware convention injection
5. **Release pipeline** (CHANGELOG, versioning, PR creation) as part of the TDD cycle
6. **Progress tracking** (.tdd-progress.md) that persists across sessions
7. **Three-human-session model** (CA/CP/CI) with explicit role definitions -- unique
   in the entire ecosystem

### 10.2 What the Community Validates

1. **Separation of planning and implementation works.** FlorianBruniaux, Boris Cherny,
   and the Builder-Validator pattern all confirm this.
2. **Context isolation between TDD phases matters.** alexop.dev demonstrates that
   "when everything runs in one context window, the LLM cannot truly follow TDD."
3. **File-based coordination is sufficient.** The Anthropic C compiler used lock files
   and progress documents. No message bus needed.
4. **Roles need enforcement, not just instructions.** Hook-based enforcement (TDD Guard,
   IttyBitty) is more reliable than natural language role prompts.
5. **The human review bottleneck is real.** Our verifier agent partially addresses
   this by automating the verification step.
6. **3-5 agents is the sweet spot.** We have 6 agents, which is at the upper bound
   but justified by their distinct lifecycle stages.

### 10.3 Opportunities Identified

1. **Formalized role definitions** -- The `/tdd-init-roles` concept from
   `explorations/features/role-definition-spec.md` would be first-of-its-kind.
   No one in the community has structured role schemas.

2. **Phase-aware role evolution** -- Roles that adapt per project phase
   (post-spec, post-plan, post-impl) would be unique. The community's roles are
   static; ours could be dynamic.

3. **Builder-Validator pattern integration** -- The ClaudeFast pattern
   (builder writes, validator reads-only) directly maps to our
   implementer/verifier separation. We already do this.

4. **Handoff document standardization** -- Our `.tdd-progress.md` is more structured
   than anything in the community. Could become a reference format.

5. **Convention-aware planning** -- No other planning approach loads language-specific
   conventions before decomposition. This is our v2.0.0 superpower.

### 10.4 Risks to Monitor

1. **Agent Teams maturation** -- As the official TeammateTool matures, it may absorb
   patterns our plugin provides. But it lacks TDD discipline, conventions, and release
   pipeline, so our value-add remains distinct.

2. **Tooling commoditization** -- Worktree management is becoming trivial (Conductor,
   Squad, `--worktree` flag). Our value is in the workflow, not the infrastructure.

3. **Token cost** -- Multi-agent workflows cost 1.7x-3x more. Our model assignment
   strategy (opus for planner, haiku for verifier) helps manage this.

---

## Sources

### Guides and Documentation
- [FlorianBruniaux Dual-Instance Planning](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/workflows/dual-instance-planning.md)
- [FlorianBruniaux Agent Teams Guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/workflows/agent-teams.md)
- [SJRamblings Multi-Agent Orchestration](https://sjramblings.io/multi-agent-orchestration-claude-code-when-ai-teams-beat-solo-acts/)
- [ClaudeFast Builder-Validator Pattern](https://claudefa.st/blog/guide/agents/team-orchestration)
- [ClaudeFast Agent Teams Complete Guide](https://claudefa.st/blog/guide/agents/agent-teams)
- [Kieran Klaassen Swarm Orchestration Gist](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [Anthropic Official Agent Teams Docs](https://code.claude.com/docs/en/agent-teams)

### Tools
- [Conductor](https://www.conductor.build/)
- [IttyBitty](https://adamwulf.me/2026/01/itty-bitty-ai-agent-orchestrator/)
- [Claude Squad](https://github.com/smtg-ai/claude-squad)
- [ccmux](https://libraries.io/pypi/ccmux)
- [parallel-cc](https://github.com/frankbria/parallel-cc)
- [claude-session-driver](https://github.com/obra/claude-session-driver)
- [andynu tmux gist](https://gist.github.com/andynu/13e362f7a5e69a9f083e7bca9f83f60a)
- [GitButler Parallel Claude Code](https://blog.gitbutler.com/parallel-claude-code)
- [ComposioHQ Agent Orchestrator](https://github.com/ComposioHQ/agent-orchestrator)
- [Ruflo (claude-flow)](https://github.com/ruvnet/ruflo)
- [ccswitch](https://ccswitch.dev/)
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)

### Developer Experiences
- [Boris Cherny (Claude Code Creator)](https://x.com/bcherny/status/2007179832300581177)
- [Boris Tane](https://boristane.com/blog/how-i-use-claude-code/)
- [incident.io](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees)
- [WorksForNow](https://worksfornow.pika.page/posts/note-to-a-friend-how-i-run-claude-code-agents-in-parallel)
- [HN: Conductor Discussion](https://news.ycombinator.com/item?id=44594584)
- [HN: Agent Teams Discussion](https://news.ycombinator.com/item?id=46902368)
- [ZeroFutureTech: Two Days with Agent Teams](https://zerofuturetech.substack.com/p/i-spent-two-days-with-claude-agent)
- [bredmond1019: 10+ Claude Instances](https://dev.to/bredmond1019/multi-agent-orchestration-running-10-claude-instances-in-parallel-part-3-29da)

### TDD + Multi-Agent
- [alexop.dev: Agentic Red-Green-Refactor](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)
- [TDD Guard](https://github.com/nizos/tdd-guard)
- [Matt Pocock TDD Skill](https://www.aihero.dev/skill-test-driven-development-claude-code)
- [Nathan Fox: Taming GenAI Agents](https://www.nathanfox.net/p/taming-genai-agents-like-claude-code)

### Case Studies
- [Anthropic: Building a C Compiler](https://www.anthropic.com/engineering/building-c-compiler)
- [HAMY: 9 Parallel Review Agents](https://hamy.xyz/blog/2026-02_code-reviews-claude-subagents)
- [Pedro Sant'Anna Academic Workflow](https://psantanna.com/claude-code-my-workflow/workflow-guide.html)

### Analysis
- [Addy Osmani: Conductors to Orchestrators](https://addyo.substack.com/p/conductors-to-orchestrators-the-future)
- [Mike Mason: Coherence Through Orchestration](https://mikemason.ca/writing/ai-coding-agents-jan-2026/)
- [Agentmaxxing](https://vibecoding.app/blog/agentmaxxing)
- [Tessl: Parallelizing AI Coding Agents](https://tessl.io/blog/how-to-parallelize-ai-coding-agents/)
