# Role Definition Spec — Formal Structure for TDD Workflow Roles

> **Date:** 2026-03-19
> **Status:** Proposal — defines the formal structure for role definitions
> **Informs:** `/tdd-init-roles` skill and `role-initializer` agent
> **Evidence:** Three zenoh-counter projects (`dart`, `cpp`, `flutter`)
> with manually created `context/roles/` directories
> **Related:**
> - `role-definition-spec.md` (this document)
> - `tdd-init-roles.md` — initial skill proposal
> - `tdd-init-roles-lifecycle.md` — iterative lifecycle concept
> - `explorations/assessments/roles-vs-anthropic-framework.md` — Anthropic mapping
> - `explorations/assessments/role-to-agent-analysis.md` — feasibility analysis

---

## 1. What Is a Role?

A **role** is a session identity document that defines who a Claude Code
session is, what it does, what it must not do, and what project-specific
knowledge it carries. Roles are not a Claude Code primitive — they are a
pattern built on top of Anthropic's primitives.

A role has two layers:

| Layer | Provided by | Changes when |
|---|---|---|
| **Role definition** | The plugin (`docs/dev-roles/`) | Plugin is updated |
| **Role context** | `/tdd-init-roles` per project | Project evolves |

The **role definition** is the job description — identical across all
projects. The **role context** is the project-specific knowledge that makes
the role effective — unique to each project and generated from codebase
research.

### Anthropic Primitive Mapping

Roles are not agents, skills, or hooks. They are session identity documents
that a developer activates by one of:

| Activation method | Mechanism |
|---|---|
| Paste the role prompt into a session | CLAUDE.md-like advisory context |
| `claude --agent <role-name>` | System prompt replacement (A25) |
| `/role-ca` or `/role-ci` inline skill | Context injection |
| `agent` setting in `.claude/settings.json` | Persistent session identity (F13) |

The first method (paste) is what we use today. The others are available
but each has tradeoffs (see `roles-vs-anthropic-framework.md`).

---

## 2. Role Definition Schema

Every role definition follows this structure. These sections are
**project-independent** — the plugin provides them.

### 2.1 Session Rationale

Why this role exists as a separate session. Explains the context isolation
benefit.

```markdown
> **Why a separate session?** {One sentence explaining what context this
> session preserves that would be lost to autocompaction in a shared session.}
```

### 2.2 Identity

Who the session is. A short paragraph establishing the role's purpose and
mode of operation.

```markdown
## Identity

You are the **{ROLE_CODE} ({Role Name})** session. {2-3 sentences
describing the role's primary function and relationship to other roles.}
```

### 2.3 Responsibilities

What the session does. Organized by functional area, each with concrete
actions.

```markdown
## Responsibilities

### {Area 1}
- {Specific action with expected output}
- {Specific action with expected output}

### {Area 2}
- ...
```

Responsibilities must be **actionable** — not "understand the architecture"
but "read CLAUDE.md and summarize the project structure."

### 2.4 Constraints

What the session must NOT do. These are advisory (enforced by convention,
not by tool restrictions) unless the role is activated via `--agent` with
a `tools` allowlist.

```markdown
## Constraints

- **{Constraint}.** {Why — what goes wrong if violated.}
- **{Constraint}.** {Why.}
```

Constraints should be few and absolute. "Never write source files" is a
good constraint. "Try to avoid long responses" is not — that's a preference,
not a constraint.

### 2.5 Memory Scope

What the session reads and writes. Defines the role's relationship to
shared state.

```markdown
## Memory

{ROLE_CODE} **{reads/reads and writes}** shared memory.

{Description of what this role's durable outputs are and where they live.}
```

For the tdd-workflow, the three-layer model applies:

| Layer | CA | CP | CI |
|---|---|---|---|
| Shared memory (MEMORY.md) | Reads + writes (sole writer) | Reads | Reads |
| `.tdd-progress.md` | Reads | Reads (agents write on approval) | Reads (agents update) |
| Git | Reads | Reads | Reads + writes (commits, PRs) |

### 2.6 Startup Procedure

What to do on fresh start or recovery after interruption. A numbered
checklist of concrete steps.

```markdown
## Startup Checklist

On fresh start or recovery after interruption:

1. Read `MEMORY.md` for current project state
2. {Role-specific recovery steps}
3. {State assessment}
4. {What to do next or who to wait for}
```

### 2.7 Handoff Patterns

How the session coordinates with other roles. Defines the inputs and
outputs of each interaction.

```markdown
## Handoff Patterns

### To {other role} ({purpose})
{What to provide and in what form.}

### From {other role} ({purpose})
{What to expect and what to do with it.}
```

Handoffs are human-mediated — the developer carries context between
terminals. The handoff pattern documents what to carry.

---

## 3. Role Context Schema

These sections are **project-specific** — `/tdd-init-roles` generates them
from codebase research. They are appended to (or merged with) the role
definition to create a complete role document.

### 3.1 Project Overview

Present in all three roles. Brief project description and tech stack.

```markdown
## Project Context

**Project:** {name}
**Tech stack:** {language, framework, key dependencies}
**Architecture:** {pattern — e.g., MVVM, layered, microservices}
**Build system:** {tool and key commands}
**Test framework:** {tool and key commands}
```

### 3.2 CA-Specific Context

What CA needs to make good architectural decisions for THIS project.

```markdown
### Architecture Notes
- {Key architectural pattern and why it was chosen}
- {Module boundaries and their contracts}
- {Known technical debt or constraints}

### Cross-Repo Relationships
- {Other repos this project depends on or coordinates with}
- {What changes in this project require coordinated changes elsewhere}

### Decision History
- {Key decisions already made and their rationale}
- {Open questions or deferred decisions}

### Verification Focus Areas
- {What to check carefully during verification for this project}
- {Common mistake patterns in this codebase}
```

### 3.3 CP-Specific Context

What CP needs to produce good plans for THIS project. This is the
**project-specific planning strategy** — human knowledge the planner
can't discover on its own.

```markdown
### Decomposition Patterns
- {How features should be sliced for this project}
- {e.g., "Slice by API endpoint, not by layer"}
- {e.g., "Auth features go bottom-up: middleware first, then handlers"}

### Slice Ordering Constraints
- {What must be planned first — shared modules, core abstractions}
- {Dependency chains the planner should respect}

### Test Batching
- {Are integration tests expensive? Group them?}
- {Does the test environment need setup (Docker, databases, services)?}
- {Preferred test granularity for this project}

### Historical Planning Learnings
- {What was underestimated in past plans}
- {What patterns led to scope creep}
- {Slices that looked simple but weren't}

### Cross-Repo Planning
- {Do changes here require coordinated plans in other repos?}
- {What is the coordination protocol?}

### Stakeholder Constraints
- {PR structure preferences (separate API from internal, etc.)}
- {Release cadence or freeze windows}
- {Feature flag requirements}

### API Surface
- {Key APIs/interfaces the planner should know about}
- {Reference examples for test specification quality}
```

### 3.4 CI-Specific Context

What CI needs to implement correctly for THIS project. The most heavily
customized section — contains actual code examples.

```markdown
### Build Commands
- {Full build command with flags}
- {Test command with expected output format}
- {Static analysis command}
- {Formatter command}

### Code Examples (2-4 from actual source)
{Real code snippets showing the project's patterns. These are the most
valuable part of CI context — they show the implementer what "correct"
looks like for THIS project.}

#### Example 1: {pattern name}
```{language}
{Actual code from the project demonstrating a key pattern}
```

#### Example 2: {pattern name}
```{language}
{Another real example}
```

### Implementation Constraints
- {Naming conventions specific to this project}
- {Import ordering rules}
- {Error handling patterns}
- {State management approach}
- {File size limits or organization rules}

### Common Pitfalls
- {Things that look right but break in this project}
- {Platform-specific gotchas}
- {Dependency quirks}
```

---

## 4. The Three Roles

### 4.1 CA — Architect / Reviewer

**Purpose:** Decides WHAT to build. Owns decisions and shared memory.

**Mode:** Conversational. Multi-turn interaction with the developer.
Judgment-based — cannot be fully mechanized.

**Unique value:** Cross-cutting project knowledge, decision authority,
verification quality, memory curation.

**Context heaviest in:** Architecture notes, cross-repo relationships,
decision history, verification focus areas.

### 4.2 CP — Planner

**Purpose:** Carries HOW to decompose. Provides project-specific planning
strategy that shapes `/tdd-plan` execution.

**Mode:** Planning-focused. Executes `/tdd-plan`, iterates on feedback,
ensures plan quality. The session provides context isolation for iterative
planning.

**Unique value:** Project-specific decomposition knowledge, slice ordering
constraints, historical planning learnings, test batching strategy. This
is human knowledge the planner agent can't discover — it's strategic,
not technical.

**Context heaviest in:** Decomposition patterns, slice ordering, test
batching, historical planning learnings, stakeholder constraints.

**Relationship to `/tdd-plan`:** CP is NOT a wrapper around `/tdd-plan`.
CP is the planning domain context that makes `/tdd-plan` effective for a
specific project. The workflow is mechanical (provided by the plugin); the
planning strategy is human knowledge (provided by CP context).

### 4.3 CI — Implementer

**Purpose:** Executes the plan. Owns implementation and release.

**Mode:** Command-driven. Runs `/tdd-implement`, `/tdd-release`,
`/tdd-finalize-docs`, and CA-authorized direct edits.

**Unique value:** Project-specific implementation knowledge — build
commands, code patterns, common pitfalls, real code examples.

**Context heaviest in:** Build commands, code examples (2-4 from actual
source), implementation constraints, common pitfalls.

---

## 5. Evidence: Zenoh Counter Projects

Three sibling projects demonstrate the role context pattern in practice:

| Project | Tech | CA Context | CP Context | CI Context |
|---|---|---|---|---|
| zenoh-counter-dart | Dart, FVM, zenoh FFI | 44 lines: SHM workflow, int64 encoding, cross-repo | Light: API surface, constraints | 108 lines: 4 code examples, 8 constraints, build commands |
| zenoh-counter-cpp | C++, CMake, GoogleTest | 43 lines: SHM pattern, zenoh-cpp conventions, cross-repo | Light: header/source patterns | 88 lines: header/source separation, CLI flags, CMake presets |
| zenoh-counter-flutter | Flutter, Riverpod 3.x, go_router | 73 lines: MVVM layering, 5 dependencies, network topologies | Moderate: widget decomposition, Riverpod patterns | 204 lines: 6 code examples, 15 constraints, MVVM patterns |

**Key observations:**
1. CI context is always the largest (code examples are verbose)
2. CA context is moderate (architecture + cross-repo)
3. CP context is the lightest but contains unique planning strategy
4. Role structure is identical across projects — only content varies
5. None of this content can be templated — it requires codebase research

---

## 6. Output Structure

`/tdd-init-roles` generates files in the consuming project:

```
context/
└── roles/
    ├── README.md           # How to use these roles
    ├── ca-architect.md     # Role definition + project context
    ├── cp-planner.md       # Role definition + project context
    └── ci-implementer.md   # Role definition + project context
```

Each file contains the full role definition (from the plugin's template)
merged with project-specific context (from codebase research). The files
are self-contained — a developer can paste any one into a session and have
a complete role identity.

### File Format

```markdown
# {ROLE_CODE} — {Role Name}

> **Why a separate session?** {rationale}
> **Project:** {name}
> **Generated:** {date} by /tdd-init-roles (stage {N})

## Identity
{role definition — from plugin template}

## Responsibilities
{role definition — from plugin template}

## Constraints
{role definition — from plugin template}

## Memory
{role definition — from plugin template}

## Project Context
{project-specific — generated by /tdd-init-roles}

## Startup Checklist
{role definition — from plugin template, with project-specific additions}

## Handoff Patterns
{role definition — from plugin template}

## {Role-specific sections}
{e.g., Quality Checklist for CP, Error Handling for CI,
Verification Summary Format for CA}
```

---

## 7. Open Questions

### 7.1 Should role definitions be subagent files?

If roles are placed in `.claude/agents/` instead of `context/roles/`, they
can be activated with `--agent`. This enables persistent identity (F13) and
tool restrictions but loses the default system prompt.

**The system prompt replacement problem:** `--agent` replaces Claude Code's
default system prompt entirely — the built-in instructions about tool usage,
output formatting, git workflows, safety guidelines, etc. are gone. There
are four approaches, none ideal:

| Approach | Default prompt | Role identity | Enforcement |
|---|---|---|---|
| `context/roles/` + paste | Kept | Advisory (conversational context) | None |
| `--agent role-name` | **Replaced** | System prompt (strongest) | `tools`/`disallowedTools` |
| `--append-system-prompt "..."` | Kept | Appended to default | None (CLI flag only) |
| `--agent` + recreated default | Recreated (fragile) | System prompt | `tools`/`disallowedTools` |

Key details:
- **`--append-system-prompt`** keeps the default prompt and appends role
  instructions, but it's a CLI flag — not a reusable file-based definition.
  There is no equivalent frontmatter field for subagent files.
- **Recreating the default prompt** is theoretically possible (Claude Code
  is open source) but fragile — the default prompt changes with every
  Claude Code release. Copying it into role definitions couples them to a
  specific version and creates a maintenance burden.
- **CLAUDE.md still loads** even with `--agent` (as user messages, not
  system prompt), so project context survives. But the built-in behavioral
  instructions do not.

Decision deferred — the role definition schema works for both `context/roles/`
(plain markdown) and `.claude/agents/` (subagent frontmatter) formats. The
choice is about delivery mechanism, not content structure. If Anthropic adds
an `--append-system-prompt` equivalent to agent frontmatter in the future,
this becomes a non-issue.

### 7.2 How much of the role definition should the plugin template?

**Decision: full template with override path.**

The plugin ships complete role definitions (identity, responsibilities,
constraints, handoffs, memory scope, startup) as the default. The
`/tdd-init-roles` skill fills in project context sections only. This
preserves the plugin author's design intent and ensures consistency
across projects.

However, the generated roles are not immutable. Two override paths exist:

- **Claude suggests changes** — during generation, the skill may identify
  mismatches between the template and the project reality (e.g., "this
  project doesn't use cross-repo coordination — I'd suggest removing that
  from CA context" or "this project has no separate planning phase — CP
  may not be needed")
- **Human requests changes** — the developer can say "I want CI to also
  own documentation updates" or "CA should not manage memory in this
  project" and the skill adjusts accordingly

The template is the starting point, not a straitjacket. It provides
consistency and preserves intent; the override mechanism provides
flexibility for projects that don't fit the standard mold.

**Example invocation:**

```
/tdd-init-roles This is a Rust project therefore each role must be
experts in Rust programming in particular as how Rust is used in
ROS 2 applications
```

The skill uses the full template (responsibilities, constraints, handoffs
unchanged) but shapes all project context sections around the human's
domain instruction combined with codebase research:

- **CA context** gains architecture notes about Rust ownership semantics
  in ROS 2 node lifecycle, `rclrs` bindings, real-time constraints
- **CP context** gains decomposition patterns by node/topic/service
  boundaries, knowledge that integration tests need a running ROS graph,
  that message types must be defined before subscribers
- **CI context** gains Rust build commands (`cargo build`, `cargo test`,
  `colcon` for ROS 2 workspace), idiomatic Rust publisher/subscriber
  examples, `clippy` as the static analysis tool

The skill doesn't need to know Rust or ROS 2 in advance — the human's
input plus codebase research fill that gap.

**Evidence:** The zenoh-counter projects confirm this approach — role
structure is identical across all three projects, only project context
varies. No project needed to modify the core role responsibilities or
constraints.
