# TDD Workflow Roles — Synthesis

> **Date:** 2026-03-20
> **Plugin version:** 2.0.0 (647 tests, 941 assertions)
> **Purpose:** Single authoritative reference for the roles feature, synthesized
> from 5 exploration documents. Use this to create the implementation issue.
> **Source documents:** See [Section 9](#9-source-documents) for full list.

---

## 1. What Roles Are

A **role** encodes the repeated workflow patterns, knowledge references, and
behavioral constraints that a developer would otherwise have to manually
provide at the start of every session and repeat throughout it. Roles are
not a Claude Code primitive — they are a pattern we invented on top of
Anthropic's primitives.

A role answers three questions:
1. **Who is this session?** — identity, responsibilities, constraints
2. **What does this session know?** — project context, convention references,
   architecture notes, cross-repo relationships
3. **How does this session work?** — startup procedures, review checklists,
   handoff protocols, plan review steps, verification procedures

The third question is the most valuable. Without a role file, the developer
repeats instructions like "read relevant memory, context files, and
conventions before reviewing this plan" every time. With a role file, these
workflow patterns are encoded once and followed automatically.

**Why roles exist:** Context window management. As conversations grow,
earlier context receives diminishing model attention — role constraints and
conventions drift, and the model may confabulate forgotten details rather
than re-reading them. Each TDD workflow session (architect, planner,
implementer) stays focused on one concern, keeping role instructions
prominent and preventing autocompaction from discarding critical context.
The developer runs three Claude Code terminals and activates the appropriate
role in each.

**The same principle operates at three levels:**

| Level | Mechanism | Resets when | What it prevents |
|---|---|---|---|
| **Agent** | Fresh context per invocation | Every task (slice, verification, release) | Task-level drift within a feature |
| **Session** | `/clear` + `/role-*` reactivation | Every new feature | Feature-level drift from stale plan/test context |
| **Terminal** | Three separate sessions (CA, CP, CI) | Always isolated by concern | Cross-concern drift (architecture vs. implementation) |

Each plugin agent starts with a clean, focused context — its system prompt,
preloaded skills, the specific task, and injected context from hooks and
memory. No prior conversation history, no accumulated drift. The agent is
purpose-built for one mission from the first token.

Between features, the developer clears CP and CI sessions (`/clear`) and
reactivates the role (`/role-cp`, `/role-ci`). This discards stale context
from the completed feature and loads fresh, relevant context for the next
one. The role delivery skills make this a one-command operation rather than
a manual re-setup.

**Mid-session refresh.** The role delivery skills also serve as a drift
correction mechanism. Invoking `/role-ca` without `/clear` injects role
instructions near the END of the context window — where they receive the
most model attention — re-anchoring the session to its identity without
losing conversation history:

| Pattern | When | Effect |
|---|---|---|
| `/clear` + `/role-ca` | New feature, stale context | Full reset — clean slate |
| `/role-ca` alone | Mid-session, noticing drift | Refresh — re-anchor without losing history |

The second pattern is valuable during long sessions (multi-step reviews,
extended analysis) where the developer notices drift from role constraints.
A quick `/role-ca` pulls the session back on track while preserving the
conversation history needed for ongoing work.

**Anthropic has no "role" concept.** Their primitives (`--agent`, `tools`,
`skills`, hooks, CLAUDE.md) can compose into roles, but they don't name the
pattern. Our roles diverge from their model in three ways:

| Aspect | Anthropic's Model | Our Model |
|---|---|---|
| Session architecture | One orchestrator + delegated subagents | Three peer sessions with human mediation |
| Memory ownership | Per-agent isolated scopes | Single shared MEMORY.md across all roles and agents — common flow memory for the active TDD workflow, with CA as sole writer |
| Constraint philosophy | Hard enforcement via tool restrictions | Convention-based trust via role prompts |

---

## 2. Key Decisions (Settled)

These decisions were reached across the five exploration documents and are
not open for revisitation unless new evidence emerges.

### 2.1 Roles are optional — the core TDD workflow must NEVER depend on them

**This is the foundational constraint for all roles work.** The plugin's
core value is the TDD workflow: plan → implement → verify → release. This
workflow must function identically whether or not role files exist, whether
or not `/role-*` skills are used, and whether or not the developer uses the
three-session model. Roles are an enhancement layer for developers who want
multi-session coordination, context management, and workflow encoding. They
are never a prerequisite.

No agent, skill, hook, or script in the core workflow may check for,
reference, or depend on role files. The `/role-init`, `/role-ca`,
`/role-cp`, `/role-ci`, and `/role-evolve` features are self-contained
additions that compose with the core workflow but do not modify it.

**Naming convention enforces the boundary:**

| Prefix | System | Optional? |
|---|---|---|
| `tdd-*` | Core workflow (plan, implement, release, verify, etc.) | No — this IS the plugin |
| `role-*` | Role management (init, evolve, ca, cp, ci) | Yes — enhancement layer |

### 2.2 Roles should NOT become agents

Roles are conversational session identities. Subagents are fire-and-forget
delegated tasks. The architectural mismatch is fundamental:

- Subagents can't have multi-turn conversations with the user
- Subagents can't invoke skills or spawn other subagents (A18)
- `--agent` replaces the default system prompt entirely, losing built-in
  Claude Code behaviors
- Plugin agent restrictions (A27/D27) silently strip hooks and permissionMode

**Evidence:** Issue 004/005 showed that enforcing constraints on plugin agents
required 7 slices, 74 tests, and a production bug — for agents whose `tools`
allowlists already provided correct restrictions. Role-agents with path-based
write guards would be significantly more complex.

### 2.3 Role GENERATION should become a skill

The manual process of creating project-specific role files is repeated for
every new project, requires significant context gathering, and produces
inconsistent quality. `/role-init` automates this as a skill + forked
agent, matching the proven pattern of `/tdd-plan` + `tdd-planner`.

### 2.4 Three roles, two layers

Every role has two layers:

| Layer | Provided by | Changes when |
|---|---|---|
| **Role definition** | The plugin (templates in `reference/`) | Plugin is updated |
| **Role context** | `/role-init` per project | Project evolves |

The role definition is the job description — identical across projects.
The role context is the project-specific knowledge — unique to each project,
generated from codebase research.

### 2.5 Two skills, one lifecycle

The role lifecycle splits into two distinct operations with different
triggers, mechanisms, and complexity:

| Skill | Purpose | Trigger | Core input | Ships in |
|---|---|---|---|---|
| `/role-init` | First-time generation | New project or fresh start | Codebase + CLAUDE.md + human input | v2.1 (next) |
| `/role-evolve` | Memory-driven refinement | Project has grown, roles are stale | **Agent memory + MEMORY.md** + codebase delta | v2.2+ (future) |

**Why two skills, not one:**
- Different mental models: creation vs. refinement
- Different core inputs: codebase research vs. accumulated memory
- Different operations: Write (fresh files) vs. Edit (preserve human changes)
- Different complexity: init is well-specified; evolve has unsolved design
  problems (diffing, merge preservation, bidirectional output)
- **Init ships now, evolve ships later** — informed by real usage

#### The lifecycle stages

```
v1 (post-spec):  /role-init  → generate from codebase + human input
v2 (post-plan):  /role-evolve → enrich from planner memory + MEMORY.md
v3 (post-impl):  /role-evolve → enrich from all agent memories + MEMORY.md
vN (evolution):  /role-evolve → keep roles current as memory accumulates
```

#### Role evolution is memory-driven

`/role-evolve` is NOT primarily about detecting codebase changes — it's
about **synthesizing what agents and CA learned into updated role context**.
Each role's evolution has a clear memory source:

| Role | Memory sources | What evolve synthesizes |
|---|---|---|
| CA | MEMORY.md (decisions, architecture evolution, cross-repo findings) | Updated verification focus, new architecture notes, revised decision history |
| CP | MEMORY.md (planning learnings) + planner memory (decomposition patterns, naming conventions, architecture findings) | Updated decomposition strategy, revised slice ordering, new planning learnings |
| CI | MEMORY.md (implementation decisions) + implementer memory (test fixtures, assertion styles, edge cases) + verifier memory (test runner quirks, failure patterns, flaky tests) + doc-finalizer memory* (documentation patterns, which files to update) | Updated code examples, new build quirks, revised common pitfalls, documentation update patterns |

*\* Doc-finalizer memory requires adding `memory: project` to doc-finalizer
agent — part of the deferred doc-finalizer redesign, not this feature.*

The role-evolver **translates** coordination state (MEMORY.md) and
machine-learned knowledge (agent memory) into human-readable role context.
It's a synthesis layer: memory in → role context out.

Evolve can't produce value until there IS meaningful memory — which is why
it only becomes useful at v2+ lifecycle stages, and why init must exist
separately for v1.

For this implementation: **build `/role-init` only.** `/role-evolve`
is a separate future issue, designed after learning from real init usage.

### 2.6 Memory is the coordination backbone

Without inter-session communication (Anthropic provides none outside
experimental agent teams), memory is how the three roles stay in sync.
The handoff patterns documented in role files are ALL mediated through
shared state.

#### The Four-Layer Memory Model

| Layer | What it stores | Who writes | Who reads | Lifetime |
|---|---|---|---|---|
| **Auto-memory** (MEMORY.md + topic files) | Project state, decisions, open questions, cross-session context | CA (sole writer) | All roles, all agents | Project lifetime — CA curates |
| **Agent memory** (`.claude/agent-memory/<name>/`) | Per-agent learnings: patterns discovered, quirks encountered, naming conventions | Each agent writes its own | Same agent on next invocation | Accumulates over project lifetime |
| **`.tdd-progress.md`** | Operational state: which slices, what status | Plugin agents (planner creates, implementer updates) | All roles, all agents | One feature lifecycle — archived on release |
| **Git** | Implementation ground truth: code, commits, branches | CI (via agents) | All roles | Permanent |

**Key insight:** Auto-memory and agent memory serve fundamentally different
purposes. Auto-memory is **coordination state** (human decisions flowing to
all participants). Agent memory is **learned knowledge** (each agent
remembering what worked for next time). Both contribute to role effectiveness
but through different mechanisms.

#### Current Agent Memory Allocation

Four of six agents have `memory: project`:

| Agent | Memory | What it accumulates |
|---|---|---|
| `tdd-planner` | `project` | Architecture findings, naming conventions, test framework patterns |
| `tdd-implementer` | `project` | Test fixtures, assertion styles, edge case patterns |
| `tdd-verifier` | `project` | Test runner commands, failure patterns, flaky tests, static analysis quirks |
| `context-updater` | `project` | Framework version findings |
| `tdd-releaser` | None | Each release is independent |
| `tdd-doc-finalizer` | None | Each release is independent |

Agent memory files live in `.claude/agent-memory/<name>/MEMORY.md` in the
consuming project. They persist across invocations, meaning the planner
gets smarter about a project over time — it remembers architectural patterns
it discovered, naming conventions it learned, test framework quirks it
encountered.

**Known gap: doc-finalizer has no memory.** Currently "each release is
independent" — but documentation is cumulative and project-specific. A
doc-finalizer with `memory: project` would learn which files to update,
documentation style conventions, section structure, and project-specific
quirks. This connects to the deferred doc-finalizer redesign and to role
evolution — doc-finalizer memory would enrich CI role context (documentation
patterns) and CA role context (documentation quality focus areas). Adding
memory to doc-finalizer is NOT part of this feature — it belongs in the
doc-finalizer redesign issue — but it strengthens the overall memory
architecture when implemented.

#### How Memory Relates to Roles

Role files and memory are complementary inputs that serve different agents:

```
Human knowledge (role context)     Machine knowledge (agent memory)
         │                                    │
         ▼                                    ▼
┌──────────────────┐              ┌──────────────────┐
│ CA role file     │              │ planner memory   │
│ "Architecture is │              │ "Tests use       │
│  MVVM with 3     │              │  mockito, files  │
│  layers"         │              │  are snake_case" │
└────────┬─────────┘              └────────┬─────────┘
         │                                 │
         ▼                                 ▼
   Human reads and                  Agent reads at
   pastes into session              startup automatically
```

- **Role context** (from `/role-init`) provides what humans know:
  architecture intent, cross-repo relationships, decomposition strategy,
  stakeholder constraints. This is knowledge that research alone can't
  discover.
- **Agent memory** (from `memory: project`) provides what agents learned:
  test patterns that work, naming conventions in use, build quirks. This
  is knowledge accumulated through doing.

Neither replaces the other. A planner with good memory but no role context
will plan mechanically well but miss strategic constraints. A planner with
good role context but no memory will understand strategy but rediscover
basic patterns every time.

#### Memory Implications for `/role-init`

The role-initializer agent can **read** agent memory files as a research
input. At v3 (post-implementation), agent memory contains valuable
project-specific knowledge:

| Agent Memory | What it tells role-initializer | Enriches which role |
|---|---|---|
| Planner memory | Architecture patterns, naming conventions discovered | CA (verification focus), CP (planning learnings) |
| Implementer memory | Test fixtures, assertion styles, edge cases | CI (code examples, common pitfalls) |
| Verifier memory | Test runner quirks, flaky tests, analysis issues | CI (build commands, pitfalls), CA (verification focus) |

This means Phase 2 (RESEARCH) should include reading
`.claude/agent-memory/*/MEMORY.md` when the files exist. The agent memory
becomes an input source alongside source code, tests, and CLAUDE.md.

**Should role-initializer have its own `memory: project`?**
- **v1: No.** The generated role files ARE the durable output. The agent
  can read existing role files if they exist (for idempotency) without
  needing its own memory.
- **v2 (incremental updates): Consider.** Memory could track what changed
  between regenerations, what the user modified manually (don't overwrite),
  and cross-repo relationships discovered via AskUserQuestion.

### 2.7 Mechanical constraint enforcement is overkill (for now)

For a single-developer workflow, the risk of a session accidentally running
the wrong command is near zero. The constraints that matter most ("don't make
architectural decisions") are judgment calls that can't be expressed as tool
restrictions. Convention-based trust via role prompts is sufficient.

**Exception:** If the plugin is used by a multi-developer team or automated
pipeline, enforcement becomes valuable. That's a future consideration.

### 2.8 Role delivery skills are the composition layer

`/role-ca`, `/role-cp`, and `/role-ci` are **inline skills** (not agents)
that serve as the single entry point for session activation. They compose three context
sources via DCI:

```
/role-ca                                    /role-cp
  ├── Role content (ca-architect.md)          ├── Planning context (cp-planner.md)
  ├── Convention context (DCI)                ├── Convention context (DCI)
  ├── External skills (auto-invoked)          ├── External skills (auto-invoked)
  └── Startup: read memory, report state      └── Startup: read memory, check for
                                                   existing plan, report state
/role-ci
  ├── Role content (ci-implementer.md)
  ├── Convention context (DCI)
  ├── External skills (auto-invoked)
  └── Startup: read memory, check branch,
       check .tdd-progress.md, report state
```

**Why this matters:** The convention loading mechanism (`load-conventions.sh`
+ `tdd-conventions.json`) is already extensible — any configured convention
source gets detected and loaded automatically. As new convention packages
appear (Serverpod, ROS 2, etc.), they flow through `/role-ca` without
changes to the role skill. The developer's session setup collapses from a
multi-step manual process to one command.

**Integration with external context skills:** The workflow is further
enhanced by external context skills installed in `.claude/skills/` (e.g.,
Flutter testing patterns, Serverpod model docs, refactoring guides). These
skills use `user-invocable: false` — the user can't invoke them directly,
but Claude CAN auto-invoke them when conversation context matches their
descriptions. When `/role-ca` loads role content mentioning specific
frameworks (e.g., "Serverpod models", "Flutter testing"), Claude's skill
matching triggers relevant installed skills, loading additional framework
context into the session automatically.

```
/role-ca or /role-cp or /role-ci (user invokes)
  → loads role content: "Flutter/Serverpod project with spy.yaml models..."
  → loads conventions: Dart/Flutter patterns (DCI)
  → Claude processes loaded content
    → matches "Serverpod models" → auto-invokes serverpod-models skill
    → matches "Flutter testing" → auto-invokes flutter-testing-apps skill
    → framework-specific context loads into session
```

This works because external context skills use `user-invocable: false`
(user can't type `/serverpod-models`) but do NOT set
`disable-model-invocation: true` — so Claude CAN auto-invoke them when
conversation context matches their descriptions.

**Prerequisite:** External context skills must be installed in `.claude/skills/`
BEFORE invoking the role delivery skills. Without `/role-evolve` (future),
there is no mechanism to discover or recommend which skills to install —
the developer manages this manually. A future `/role-evolve` could
detect framework usage and recommend missing skills.

**The three features compose into a complete workflow:**

| Feature | What it does | When it runs |
|---|---|---|
| `/role-init` | Generates project-specific role content | Once per project (or on major changes) |
| `/role-ca`, `/role-cp`, `/role-ci` | Delivers role + conventions + startup into session | Every session start |
| `/role-evolve` | Updates role content from accumulated memory | As project matures |

`/role-ca`, `/role-cp`, and `/role-ci` are **not optional convenience
wrappers** — they are the delivery mechanism that unifies role context and
convention loading. Without them, the developer manually pastes role
content and instructs Claude to load conventions every session.

**`/role-cp` and the CP question:** Even though CP's behavioral role is
absorbed by the plugin (the planner agent handles planning mechanics),
the CP session still exists as a separate terminal for planning iteration.
`/role-cp` loads the planning context document + conventions, giving the
developer the same knowledge the planner agent has — so they can evaluate
and iterate on plan quality effectively.

**Implementation note:** These are inline skills with `disable-model-invocation: true`.
No `context: fork`, no agent spawn, no system prompt replacement. Content
loads directly into the main thread's conversation context.

### 2.9 Other proposed utility features

The roles analysis also identified utility features that serve all sessions
but are independent of the role system:

| Component | Type | Purpose | Status |
|---|---|---|---|
| `/tdd-status` | Skill | Report TDD session state | **Proposed, not yet built** |
| SessionStart hook | Hook | Detect active TDD sessions | **Proposed (N2 in audit)** |
| `/tdd-verify-feature` | Skill | Produce verification summaries | **Proposed, not yet built** |

These may be bundled into the same release or implemented independently.

---

## 3. The CP Question (Resolved)

**CP as a behavioral role is retired.** The plugin has absorbed everything CP
does — `tdd-planner` agent + `/tdd-plan` skill + validation hooks provide the
complete planning workflow. A developer running `/tdd-plan` in any session
gets the full CP workflow mechanically.

**CP as a planning context document is valuable.** Project-specific planning
strategy — decomposition patterns, slice ordering, test batching, historical
failures, stakeholder constraints — is human knowledge the planner can't
discover. This context makes `/tdd-plan` more effective for a specific project.

**Resolution:** `/role-init` generates three files:

| File | Purpose | Content weight |
|---|---|---|
| `ca-architect.md` | Session identity + project architecture context | Moderate (architecture, cross-repo, decisions) |
| `ci-implementer.md` | Session identity + project implementation context | Heavy (code examples, build commands, constraints) |
| `cp-planner.md` | **Planning context document** (not a session identity) | Light (decomposition patterns, ordering, API surface) |

The CP file carries a header note: *"This file provides project-specific
planning context. The tdd-planner agent handles the behavioral role. Load this
into any planning session to improve plan quality."*

---

## 4. Role Schema

Every role file follows this structure. Sections marked FIXED come from the
plugin template; sections marked DYNAMIC are generated from codebase research.

### 4.1 Role Definition Sections (FIXED)

| Section | Purpose | Present in |
|---|---|---|
| Session Rationale | Why this session exists separately | CA, CI |
| Identity | Who the session is (2-3 sentences) | CA, CI |
| Responsibilities | What the session does (actionable items) | CA, CI |
| Constraints | What the session must NOT do (few, absolute) | CA, CI |
| Memory Scope | What the session reads/writes | CA, CI |
| Startup Checklist | Recovery procedure on fresh start | CA, CI |
| Workflow Procedures | Encoded patterns for repeated tasks (plan review, verification, implementation cycle) | CA, CI |
| Handoff Patterns | How to coordinate with other roles | CA, CI |

**Workflow Procedures** is the highest-value section. It encodes the
instructions the developer would otherwise repeat manually every session:

- **CA:** "Before reviewing a plan: read MEMORY.md, read the issue file,
  read convention docs for this project, read .tdd-progress.md, then
  evaluate." — Without this, the developer types this instruction every time.
- **CI:** "Before implementing: read MEMORY.md, check git status for
  uncommitted changes, confirm correct branch, read .tdd-progress.md for
  pending slices." — Without this, the developer reminds CI every time.
- **CP:** "The planner agent has conventions loaded. For your own reference
  when evaluating plan quality, read [convention paths]." — Without this,
  the developer has to explain what context is available.

### 4.2 Role Context Sections (DYNAMIC)

| Section | Source | Present in |
|---|---|---|
| Project Overview | CLAUDE.md + tech stack detection | CA, CI, CP |
| Architecture Notes | Source analysis + CLAUDE.md | CA |
| Cross-Repo Relationships | User input via AskUserQuestion | CA |
| Decision History | CLAUDE.md + issues/ | CA |
| Verification Focus Areas | Architecture analysis | CA |
| Build Commands | Build config + detect-project-context.sh | CI |
| Code Examples (2-4) | Extracted from actual source files | CI |
| Implementation Constraints | Convention detection + CLAUDE.md | CI |
| Common Pitfalls | User input + codebase research | CI |
| Plan Review Procedure | Convention paths + memory references + issue file patterns | CA |
| Verification Procedure | Test commands + static analysis + CHANGELOG check | CA, CI |
| Convention References | Discovered convention doc paths + key pattern summary | CA, CP |
| Decomposition Patterns | User input + architecture analysis | CP |
| Slice Ordering Constraints | Dependency analysis | CP |
| Test Batching | Test framework detection | CP |
| Historical Planning Learnings | User input | CP |
| API Surface | Public class/function grep | CP |

### 4.3 Output Structure

Generated in the consuming project (not the plugin):

```
context/
  roles/
    README.md           # How to use these roles
    ca-architect.md     # Role definition + project context
    ci-implementer.md   # Role definition + project context
    cp-planner.md       # Planning context document
```

### 4.4 Evidence

Three zenoh-counter projects demonstrate the pattern:

| Project | Tech | CA Context | CI Context | CP Context |
|---|---|---|---|---|
| zenoh-counter-dart | Dart, FVM, zenoh FFI | 44 lines | 108 lines (4 examples) | Light |
| zenoh-counter-cpp | C++, CMake, GoogleTest | 43 lines | 88 lines | Light |
| zenoh-counter-flutter | Flutter, Riverpod 3.x | 73 lines | 204 lines (6 examples) | Moderate |

CI context is always the largest (code examples are verbose). Role structure
is identical across projects — only content varies.

---

## 5. `/role-init` Specification

### 5.1 Skill Definition

```yaml
---
name: role-init
description: >
  Generate project-specific role files (CA, CI, CP) for the TDD
  three-session workflow. Researches the codebase, detects tech stack
  and architecture, asks about cross-repo relationships, and writes
  customized roles to context/roles/. Run once per project, rerun as
  project evolves.
  Triggers on: "init roles", "setup roles", "create project roles",
  "customize roles", "initialize TDD sessions".
disable-model-invocation: true
context: fork
agent: role-initializer
argument-hint: "[optional human context or related project paths]"
---
```

### 5.2 Agent Definition

```yaml
---
name: role-initializer
description: >
  Researches a project and generates customized TDD session role files
  (CA architect, CI implementer, CP planner context). Spawned by
  /role-init. Interactive via AskUserQuestion.
tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: opus
color: blue
maxTurns: 40
---
```

**Design rationale:**
- `opus` because deep codebase understanding + nuanced writing (same logic
  as tdd-planner)
- `maxTurns: 40` for research (15-20) + interaction (5-10) + writing (5-10)
- No `memory` — one-time task; the generated files ARE the durable output.
  The agent READS other agents' memory files (`.claude/agent-memory/*/MEMORY.md`)
  as research input but does not maintain its own persistent memory.
  Reconsider for v2 when incremental updates need change tracking
- No `skills` — role-initializer does its own detection, doesn't need
  convention loading
- No `hooks` — not needed for this agent
- No `permissionMode` — needs Write for generating files

### 5.3 Process Flow

```
Phase 1: DETECT
  Run detect-project-context.sh
  Read CLAUDE.md (root and .claude/)
  Glob for key project files
  Identify tech stack, build system, test framework
  Discover convention doc locations (tdd-conventions.json, cached conventions)

Phase 2: RESEARCH
  Read directory structure (architecture)
  Read 3-5 key source files (extract code patterns)
  Read test files (test conventions)
  Read build configuration (build/test commands)
  Read agent memory files (.claude/agent-memory/*/MEMORY.md) if they exist
    — planner memory: architecture patterns, naming conventions
    — implementer memory: test fixtures, assertion styles, edge cases
    — verifier memory: test runner quirks, failure patterns
  If related projects referenced, read their CLAUDE.md files

Phase 3: ASK (via AskUserQuestion)
  Cross-project relationships and shared protocols
  Architecture rules to enforce
  Known gotchas or past mistakes
  Review priorities for architect role
  Output directory confirmation (default: context/roles/)

Phase 4: GENERATE
  Read templates from reference/
  Merge fixed sections (from templates) with dynamic sections (from research)
  Embed convention references in workflow procedures (CA: what to read
    before plan review; CP: where conventions live for reference)
  Write ca-architect.md, ci-implementer.md, cp-planner.md
  Write context/README.md

Phase 5: REVIEW
  Present summary: files, key content, assumptions to verify
```

### 5.4 Plugin File Structure

```
skills/role-init/
  SKILL.md
  reference/
    ca-template.md       # Fixed sections for CA
    ci-template.md       # Fixed sections for CI
    cp-template.md       # Fixed sections for CP (context doc)
    context-readme.md    # Template for context/README.md

agents/
  role-initializer.md
```

### 5.5 Invocation Examples

```bash
# Basic — research current project
/role-init

# With human domain context
/role-init This is a Rust project for ROS 2 applications

# With related project paths
/role-init ../zenoh-counter-dart ../zenoh-counter-flutter

# Combined
/role-init Rust ROS 2 project, related to ../zenoh-counter-dart
```

### 5.6 Idempotency (v1)

If `context/roles/` already exists, the agent asks:
- "Role files already exist. Regenerate from scratch or keep existing?"
- If regenerate: backup to `context/roles/.backup/`, generate fresh
- If keep: abort with no changes

Full diff-based incremental update mode is deferred to v2.

---

## 6. Impact Analysis

### 6.1 New Components

| Component | Type | Files | Conflict Risk |
|---|---|---|---|
| `/role-init` | Skill | `skills/role-init/SKILL.md` | None |
| Role templates | Reference | `skills/role-init/reference/` (4 files) | None |
| `role-initializer` | Agent | `agents/role-initializer.md` | None |

### 6.2 Integration with Existing Components

| Existing Component | Interaction | Assessment |
|---|---|---|
| `detect-project-context.sh` | **Shared.** Role-initializer calls it in Phase 1 for tech stack detection. Same script used by `/tdd-plan`. | No conflict. Script is read-only and stateless. May need minor extension for broader language detection. |
| `project-conventions` skill | **Complementary.** Conventions provides language rules for agents; role-initializer provides project context for humans. Both detect project type but for different purposes. | No overlap. Role-initializer does NOT need `skills: [project-conventions]`. |
| `docs/dev-roles/*.md` | **Inspiration, not source.** Current dev-roles are plugin-development roles. Templates in `reference/` are consuming-project roles. Similar structure, different content. | No conflict. Dev-roles remain unchanged. |
| `hooks.json` | **No changes needed.** Role-initializer is a straightforward writer — no enforcement hooks required. | Clean. If SubagentStop quality validation is desired later, add it then. |
| `.tdd-progress.md` | **No interaction.** Role initialization happens before/after TDD sessions, not during. | Clean separation. |
| Convention loading flow | **Independent.** `fetch-conventions.sh` (SessionStart) and `load-conventions.sh` (DCI) operate on convention content. Role-initializer operates on role templates. | No overlap. |
| Agent memory files | **Read-only input.** Role-initializer reads `.claude/agent-memory/*/MEMORY.md` during Phase 2 to extract agent-learned patterns (architecture, test fixtures, build quirks). Never writes to agent memory. | Complementary — agent memory provides machine-learned knowledge; role context provides human knowledge. Available at v2+ lifecycle stages when agents have run. |
| Auto-memory (MEMORY.md) | **Read-only input.** Role-initializer reads shared MEMORY.md for project state and decisions during Phase 1/2. Never writes to auto-memory. | No conflict. CA remains sole writer. |
| Skill budget (B23) | Current: 6 skills. Adding 1. Total: 7. | Well within 2% char budget. |
| `plugin.json` | Version bump. | MINOR bump (new feature, no breaking changes). |

### 6.3 What Does NOT Change

- All 6 existing agents (planner, implementer, verifier, releaser, doc-finalizer, context-updater)
- All 5 existing workflow skills (/tdd-plan, /tdd-implement, /tdd-release, /tdd-finalize-docs, /tdd-update-context)
- The `project-conventions` skill
- All hook scripts and `hooks.json` entries
- All utility scripts (`detect-project-context.sh`, `detect-doc-context.sh`, `bump-version.sh`)

---

## 7. Audit Validation

Checked against the extensibility audit (v3.0 inventory, v2.0.0 assessment).

### 7.1 Agent Correctness (role-initializer)

| Field | Value | Audit Ref | Valid? |
|---|---|---|---|
| `name` | `role-initializer` | A1 | Yes |
| `description` | Trigger phrases included | A2 | Yes |
| `tools` | Read, Write, Glob, Grep, Bash, AskUserQuestion | A3 | Yes — minimal set for research + writing + interaction |
| `disallowedTools` | None | A4 | Acceptable — agent's task is to write files |
| `model` | `opus` | A5 | Yes — deep research + nuanced writing |
| `permissionMode` | Default | A6 | Correct — needs Write access. **Note:** would be silently ignored anyway (A27) |
| `maxTurns` | 40 | A7 | Yes — research + interaction + writing |
| `skills` | None | A8 | Correct — does its own detection |
| `memory` | None | A9 | Correct — one-time task, output is the generated files. Agent READS other agents' memory as research input but doesn't need its own persistent state. Reconsider for v2 incremental updates |
| `hooks` | None | A11 | Correct — no enforcement needed. **Note:** would be silently ignored anyway (A27) |

### 7.2 Skill Correctness (/role-init)

| Field | Value | Audit Ref | Valid? |
|---|---|---|---|
| `name` | `role-init` | B1 | Yes |
| `description` | Trigger phrases included | B2 | Yes |
| `argument-hint` | `[optional human context or related project paths]` | B3 | Yes |
| `disable-model-invocation` | `true` | B4 | Yes — user-only invocation |
| `context: fork` | Set | B8 | Yes — isolates research from main context |
| `agent` | `role-initializer` | B9 | Yes |

### 7.3 A27/D27 Check (Plugin Agent Restrictions)

Role-initializer is a plugin agent, so:
- `hooks` in frontmatter would be silently ignored — **we don't use any** (correct)
- `mcpServers` would be silently ignored — **we don't use any** (correct)
- `permissionMode` would be silently ignored — **we don't set one** (correct)
- `tools` and `disallowedTools` survive — **our tools allowlist works** (correct)

**Verdict:** No A27/D27 concerns. The agent's design avoids all restricted fields.

### 7.4 Hook Requirements

Role-initializer does not need hooks. However, for completeness:

| Hook Type | Needed? | Rationale |
|---|---|---|
| SubagentStart | No | Agent can run `git` commands itself; no context injection needed |
| SubagentStop | Optional | Quality validation of generated files. Defer to v2 |
| PreToolUse | No | Agent should be able to write freely |
| PostToolUse | No | No test suite to auto-run for generated markdown |

### 7.5 Remaining Audit Items Affected

| Audit Item | Impact |
|---|---|
| N1 (Notification hooks) | Not affected |
| N2 (SessionStart hook) | Not affected — separate feature |
| N3 (Manifest metadata) | Not affected — can be addressed separately |

---

## 8. Deferred Work

### 8.1 Not in scope for this implementation

| Item | Reason for deferral |
|---|---|
| `/role-evolve` skill | Separate feature — memory-driven role refinement. Needs design work on diffing, merge preservation, bidirectional output. Build after learning from `/role-init` usage |
| Idempotent update mode (within init) | Init does full regeneration; incremental updates belong to evolve |
| Cross-repo analysis | v1 reads related CLAUDE.md files; deep cross-repo research is v2 |
| `/tdd-status` skill | Separate feature from Architecture E analysis |
| `/tdd-verify-feature` skill | Separate feature from Architecture E analysis |
| SessionStart hook (N2) | Separate feature |
| `/role-ca`, `/role-cp`, `/role-ci` delivery skills | **Moved to planned** — see §2.7. Companion feature to `/role-init` |
| Mechanical constraint enforcement | Overkill for single-developer workflow |
| Phased planning (`/tdd-decompose`) | Blocked by `.tdd-progress.md` lifecycle changes |
| `context/standards/` generation | Out of scope — standards are longer and more opinionated |

### 8.2 Design notes for later revisitation

- **Role files vs. CLAUDE.md separation.** Both contain project context.
  CLAUDE.md is auto-loaded into every session (what everyone needs); role
  files are loaded via `/role-*` (what that role specifically needs). The
  role-initializer must be aware of CLAUDE.md to avoid restating what's
  already there. Some users may want the core TDD workflow without roles
  — they may have their own roles or use a single session. See §2.1.

### 8.3 Future considerations

- **`/role-evolve`:** The primary follow-up feature. Synthesizes agent
  memory + MEMORY.md into role context updates. Design questions to resolve:
  how to detect generated vs. human-modified sections, how to produce
  meaningful diffs, how to handle the bidirectional output (updates down,
  context suggestions up to CA). Could also detect framework usage and
  recommend missing external context skills ("Your project uses Serverpod
  but no Serverpod skills are installed"). Separate `role-evolver` agent
  (Edit-focused, diff-driven, preservation-aware) or shared agent with
  mode flag. Create issue after real `/role-init` usage provides
  design input.
- **Agent teams:** When Anthropic stabilizes agent teams, they could replace
  the manual three-terminal pattern. The "team lead" maps to CA, teammates to
  CI. Monitor for stability.
- **`--append-system-prompt` in agent files:** If Anthropic adds this as a
  frontmatter field, roles-as-agents becomes viable without losing the default
  system prompt. Currently CLI-flag only.
- **`--agent` + `agent` setting (F13):** Persists across resumes, making
  role-as-agent more practical. Still loses default system prompt. Monitor.

---

## 9. Source Documents

These exploration documents contain the detailed reasoning behind the
decisions in this synthesis. They are historical artifacts — consult them
for "why" questions, but use this synthesis as the authoritative "what."

| Document | Date | Key Contribution |
|---|---|---|
| `role-to-agent-analysis.md` | 2026-03-15 (rev. 2026-03-19) | Roles should not become agents; Architecture E recommended; draft specs for /tdd-status, /tdd-verify-feature |
| `tdd-init-roles.md` | 2026-03-15 | `/role-init` skill proposal; draft SKILL.md and agent definition; cross-repo support |
| `tdd-init-roles-lifecycle.md` | 2026-03-15 | Iterative lifecycle (v1/v2/v3 stages); bidirectional output; stage detection |
| `roles-vs-anthropic-framework.md` | 2026-03-19 | Anthropic primitive mapping; system prompt gotchas; divergence points |
| `role-definition-spec.md` | 2026-03-19 | Formal role schema; CP reinstated as context; zenoh-counter evidence |

---

## 10. Implementation Readiness

### What's defined:
- Skill frontmatter and process flow
- Agent definition with tools, model, maxTurns
- Role schema (7 fixed sections + 14 dynamic sections)
- Output structure (`context/roles/` with 4 files)
- Template file locations (`skills/role-init/reference/`)

### What needs TDD planning:
- Template content (the actual fixed sections for CA, CI, CP)
- Agent system prompt (the full role-initializer instructions)
- `detect-project-context.sh` extensions (if needed for broader detection)
- SKILL.md content beyond frontmatter
- Integration tests (template validation, output structure verification)

### Estimated scope:
- 1 new skill, 1 new agent, 4 template files
- No existing files modified (except plugin.json version, CLAUDE.md docs)
- No hooks added or changed
- MINOR version bump

### TDD approach:
Since the core logic is in the agent's prompt (not scripts), the testable
surface is:
- Templates (required sections present, no hardcoded project names)
- `detect-project-context.sh` (if extended)
- Output file structure validation (correct paths, section headings)
- Agent frontmatter correctness

The agent's research and writing quality is validated through the interactive
approval flow (Phase 5: Review), not through automated tests.
