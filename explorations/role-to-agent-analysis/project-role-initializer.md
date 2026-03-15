# `/tdd-init-roles` — Project-Specific Role Initializer

> **Date:** 2026-03-15
> **Extends:** `explorations/role-to-agent-analysis/analysis.md`
> **Motivation:** The prior analysis concluded "keep roles as documentation."
> That conclusion had a blind spot: the generic roles in `docs/dev-roles/`
> must be manually customized for every new project. This document analyzes
> whether to automate that customization as a plugin skill.

---

## 1. The Problem

The tdd-workflow plugin ships three generic role definitions (CA, CP, CI) in
`docs/dev-roles/`. When a developer starts a new project, they must:

1. Create a `context/roles/` directory in the project
2. Ask CA to research the project (tech stack, architecture, dependencies)
3. Have CA write project-specific versions of each role
4. Manually iterate on the content until it reflects the project's reality

This process is **repeated for every new project** and requires significant
context gathering. The user described this as a "procedural hack" — it works,
but it's manual, time-consuming, and the quality depends on how well CA
understands the project at role-creation time.

### Evidence: Three Zenoh Counter Projects

Three sibling projects demonstrate the pattern:

| Project | Tech | CA Customization | CI Customization |
|---------|------|-----------------|-----------------|
| zenoh-counter-dart | Dart, FVM, zenoh FFI | 44 lines: SHM workflow, int64 encoding, cross-repo tracking | 108 lines: 4 code examples, 8 constraints, build commands |
| zenoh-counter-cpp | C++, CMake, GoogleTest | 43 lines: SHM pattern, zenoh-cpp conventions, cross-repo | 88 lines: header/source separation, CLI flags, CMake presets |
| zenoh-counter-flutter | Flutter, Riverpod 3.x, go_router | 73 lines: MVVM layering, 5 dependencies, network topologies | 204 lines: 6 code examples, 15 constraints, MVVM patterns |

Key observations:

1. **Role structure is identical** across projects — same sections (Role,
   Scope, Context, Constraints), same behavioral rules
2. **Role content is heavily customized** — project purpose, architecture,
   code patterns, API references, build commands, cross-repo relationships
3. **CI roles are the most customized** — they contain full code examples
   (ZenohService, SHM pipeline, Riverpod ViewModel, widget test patterns)
4. **CA roles are moderately customized** — project context, what to track,
   cross-repo coordination scope
5. **CP roles are lightly customized** — API surface listing, reference
   examples, project-specific constraints
6. **None of this can be templated** — the code examples, architecture
   descriptions, and API references require understanding the actual codebase

---

## 2. What Changes from the Prior Analysis

The prior analysis (`analysis.md`) concluded:

> "CP should be retired. CA and CI should not become agents. Extract
> procedural functions as skills. Keep roles as documentation."

That conclusion was correct **for the plugin itself** but missed the
**consumption pattern**. The roles aren't just documentation — they're
**project configuration artifacts** that must be generated for each project.

### Revised framing

| Prior analysis asked | This analysis asks |
|---------------------|-------------------|
| Should roles become agents? | Should role *generation* become a skill? |
| Can roles be mechanically enforced? | Can role *customization* be automated? |
| Do roles fit the subagent model? | Does role *initialization* fit the skill model? |

The answer to all three new questions is **yes**.

---

## 3. Skill Design: `/tdd-init-roles`

### 3.1 Concept

A user-invocable skill that researches the current project and generates
project-specific role files through an interactive process with the user.

```
/tdd-init-roles
```

The skill:
1. Detects the project type and tech stack
2. Researches the codebase (structure, architecture, key files)
3. Reads CLAUDE.md for existing project context
4. Asks the user about cross-repo relationships and special requirements
5. Generates three role files to `context/roles/`
6. Generates a `context/README.md` explaining the directory

### 3.2 Why a Skill (not an agent, not a hook)

| Mechanism | Fit | Reason |
|-----------|-----|--------|
| **Skill** | **Best** | User-invoked, one-time per project, produces files, needs interaction |
| Agent | Poor | Not a task to delegate — needs user input for cross-repo context |
| Hook | Poor | Not triggered by a lifecycle event |
| Rule | Poor | Not path-based behavioral guidance |
| `--agent` | Poor | Not a session identity — it's a one-time setup task |

The skill should use `context: fork` with a dedicated agent because:
- The research phase involves many tool calls (Glob, Grep, Read, Bash)
- Forking keeps the main conversation context clean
- The agent can focus on research without conversation history pressure
- AskUserQuestion provides the interactive gates

### 3.3 Frontmatter

```yaml
---
name: tdd-init-roles
description: >
  Generate project-specific role files (CA, CP, CI) for the TDD
  three-session workflow. Researches the codebase, asks about cross-repo
  relationships, and writes customized roles to context/roles/.
  Triggers on: "init roles", "setup roles", "create project roles",
  "customize roles for this project".
disable-model-invocation: true
context: fork
agent: role-initializer
argument-hint: "[optional: related project paths]"
---
```

### 3.4 Agent Definition

```yaml
---
name: role-initializer
description: >
  Researches a project and generates customized TDD session role files.
  Spawned by /tdd-init-roles. Interactive — uses AskUserQuestion for
  user input on cross-repo relationships and special requirements.
tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: opus
color: blue
maxTurns: 40
---
```

**Why opus:** Role generation requires deep codebase understanding and
nuanced writing — the same reasons tdd-planner uses opus.

**Why maxTurns: 40:** Research (15-20 turns) + interaction (5-10 turns) +
file writing (5-10 turns).

**Why no memory:** This is a one-time setup task. No cross-session learning
needed. (The generated role files ARE the durable output.)

### 3.5 Process Flow

```
┌─────────────────────────────────────────────────┐
│ /tdd-init-roles [related-project-paths]         │
└──────────────────────┬──────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │  Phase 1: DETECT        │
          │  - detect-project-context.sh
          │  - Read CLAUDE.md       │
          │  - Glob for key files   │
          │  - Identify tech stack  │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  Phase 2: RESEARCH      │
          │  - Directory structure  │
          │  - Architecture patterns│
          │  - Test framework usage │
          │  - Build system config  │
          │  - Key code patterns    │
          │  - API surface (for CP) │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  Phase 3: ASK           │
          │  - Cross-repo relations │
          │  - Special constraints  │
          │  - Architecture focus   │
          │  - Review priorities    │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  Phase 4: GENERATE      │
          │  - CA role file         │
          │  - CI role file         │
          │  - CP role file         │
          │  - context/README.md    │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  Phase 5: REVIEW        │
          │  - Present summary      │
          │  - User approves/edits  │
          └─────────────────────────┘
```

---

## 4. What Gets Generated

### 4.1 Role File Structure

Each generated role file follows a consistent structure with fixed sections
(same across all projects) and dynamic sections (project-specific):

```markdown
# {ROLE} -- {Title}

You are the {role description} for the {project-name} project.

## Role                        ← FIXED (from generic template)
[behavioral constraints]

## Scope                       ← DYNAMIC (project-specific)
[what this role covers in this project]

## Context                     ← DYNAMIC (project-specific)
[project purpose, architecture, key dependencies]

## What to Track               ← DYNAMIC (CA only)
[architecture-specific review criteria]

## Key Patterns                ← DYNAMIC (CI only)
[code examples extracted from the codebase]

## Build & Test Commands        ← DYNAMIC (CI only)
[project-specific commands]

## Constraints                 ← DYNAMIC (project-specific)
[tech-specific constraints discovered during research]

## Memory                      ← FIXED
[memory management instructions]
```

### 4.2 CA: What Gets Customized

| Section | Source |
|---------|--------|
| Scope | CLAUDE.md + directory structure analysis |
| Context | CLAUDE.md purpose section + dependency analysis |
| Cross-repo coordination | User input via AskUserQuestion |
| What to Track | Architecture analysis + user input |

### 4.3 CI: What Gets Customized

| Section | Source |
|---------|--------|
| Scope | Directory listing of source/test/config directories |
| Context | Architecture summary from CLAUDE.md |
| Key Patterns | Extracted from existing source files (2-4 representative examples) |
| Build & Test Commands | detect-project-context.sh + CLAUDE.md |
| Constraints | Convention skill reference + project-specific gotchas from CLAUDE.md |

**CI is the most complex** because it includes code examples. The agent
must read actual source files and extract representative patterns — not
just list them, but show the specific API usage patterns that CI needs
to follow.

### 4.4 CP: What Gets Customized

| Section | Source |
|---------|--------|
| Context | Project purpose, architecture, key dependencies |
| API Surface | Grep for public classes/functions, dependency analysis |
| Reference Examples | Grep for example files or test patterns |
| Constraints | Convention skill reference + project constraints |

**Note on CP:** The prior analysis concluded CP is redundant with the
plugin's tdd-planner. This remains true for the *behavioral* role. But
the project-specific CP file serves a different purpose: it's a **context
document** that can be loaded into any planning session to provide
project-specific API knowledge. Whether it's loaded as a "role" or as
context is a presentation choice — the content is valuable either way.

---

## 5. Cross-Project Relationships

The zenoh-counter trilogy demonstrates an important pattern: projects
reference each other. The CA role for zenoh-counter-cpp says "Does the
int64 encoding match the Dart counter codec?" The CI role for
zenoh-counter-flutter says "Counter protocol (defined by zenoh-counter-cpp)."

### 5.1 How the Skill Handles This

The skill accepts optional related project paths:

```
/tdd-init-roles ../zenoh-counter-dart ../zenoh-counter-flutter
```

Or via $ARGUMENTS:

```
/tdd-init-roles --related ../zenoh-counter-dart --related ../zenoh-counter-flutter
```

When related projects are provided, the agent:
1. Reads each related project's CLAUDE.md (if it exists)
2. Identifies shared protocols, data formats, API contracts
3. Notes the relationship in each role's Context section
4. Adds cross-repo tracking items to CA's "What to Track" section
5. Adds compatibility constraints to CI's "Constraints" section

### 5.2 The AskUserQuestion Phase

The agent asks the user:

```
I've detected this is a {tech} project with the following structure:
{summary}

Questions about cross-project relationships:
1. Are there related projects that share data formats or protocols?
   [paths provided: ../zenoh-counter-dart, ../zenoh-counter-flutter]
2. What is the shared protocol? (e.g., message format, key expressions)
3. Are there compatibility constraints between projects?

Questions about this project:
4. What are the most important architecture rules to enforce?
5. Are there any "gotchas" that new sessions should know about?
6. Any specific review criteria for CA beyond code quality?
```

This interactive phase captures knowledge that codebase research alone
cannot discover — design intent, past mistakes, team conventions.

---

## 6. Integration with tdd-workflow Plugin

### 6.1 New Components

| Component | Type | Path |
|-----------|------|------|
| `/tdd-init-roles` skill | Skill | `skills/tdd-init-roles/SKILL.md` |
| `role-initializer` agent | Agent | `agents/role-initializer.md` |
| Role templates | Supporting files | `skills/tdd-init-roles/reference/` |

### 6.2 Role Templates

The skill's `reference/` directory would contain the fixed sections of each
role as templates. The agent reads these and fills in the dynamic sections
based on research.

```
skills/tdd-init-roles/
├── SKILL.md
└── reference/
    ├── ca-template.md      # Fixed sections for CA
    ├── ci-template.md      # Fixed sections for CI
    ├── cp-template.md      # Fixed sections for CP
    └── context-readme.md   # Template for context/README.md
```

### 6.3 Relationship to Existing Components

| Existing Component | Interaction |
|-------------------|-------------|
| `detect-project-context.sh` | Called in Phase 1 for tech stack detection |
| Convention skills | Referenced for tech-specific constraints |
| `docs/dev-roles/*.md` | Source for the fixed (behavioral) sections |
| tdd-planner agent | No interaction — different concern |
| `/tdd-plan` skill | No interaction — different lifecycle stage |

### 6.4 Output Location

The skill writes to `context/roles/` in the project directory, matching the
user's existing convention. This keeps role files:
- Committed to VCS (shareable with team)
- Outside `.claude/` (not auto-loaded — explicit reference only)
- Grouped with other context documents (standards, libraries)

The `context/` directory structure matches what the user already uses:

```
context/
├── README.md              # Generated: explains the directory
├── roles/
│   ├── ca-architect.md    # Generated: project-specific CA role
│   ├── ci-implementer.md  # Generated: project-specific CI role
│   └── cp-planner.md      # Generated: project-specific CP role
├── standards/             # User-created: coding standards
├── libraries/             # User-created: library reference docs
└── project/               # User-created: human-only reference
```

### 6.5 Idempotency

If `context/roles/` already exists, the skill should:
1. Read existing role files
2. Ask the user: "Role files already exist. Regenerate from scratch, or
   update with new context?"
3. If regenerate: backup old files to `context/roles/.backup/`, generate new
4. If update: read existing content, research for changes, produce a diff

---

## 7. What Makes This Different from `/init`

Claude Code's built-in `/init` command (E12) bootstraps a generic CLAUDE.md.
`/tdd-init-roles` is different in several ways:

| Aspect | `/init` | `/tdd-init-roles` |
|--------|---------|-------------------|
| Scope | Project-wide CLAUDE.md | Role-specific context files |
| Output | Single file | 4 files (3 roles + README) |
| Interaction | Minimal | Multi-question dialogue |
| Cross-repo | No | Yes (related project analysis) |
| Tech depth | Generic | Deep (code examples, API patterns) |
| Frequency | Once ever | Once per project using TDD workflow |
| Plugin-specific | No | Yes (TDD three-session model) |

They're complementary: `/init` creates CLAUDE.md (project-wide guidance),
`/tdd-init-roles` creates role files (session-specific context).

---

## 8. Should This Exist? The Full Assessment

### Arguments FOR

1. **Real problem, proven pattern.** The user is already doing this manually
   across three projects. The manual process works but is tedious and
   inconsistent.

2. **Clean skill fit.** User-invoked, one-time, interactive, produces files.
   This is exactly what skills are designed for.

3. **High value-to-effort ratio.** The skill itself is ~100 lines of
   SKILL.md + agent definition. The templates are ~50 lines each. The
   research logic is the agent's natural capability — no hook scripts or
   complex orchestration needed.

4. **Improves plugin adoption.** New users get project-specific roles
   automatically instead of figuring out how to customize them manually.

5. **Cross-repo awareness is unique.** No existing Claude Code feature
   handles multi-project relationship mapping for role generation.

6. **Consistent quality.** Manual role creation quality varies with CA's
   context at creation time. The skill follows a structured research process
   every time.

### Arguments AGAINST

1. **One-time use.** The skill runs once per project. Is it worth the plugin
   complexity for a one-time action?

   **Counter:** `/tdd-plan` also runs once per feature. One-time skills are
   valid. And the skill may run again when the project evolves significantly.

2. **AI-generated code examples may be wrong.** The CI role contains code
   patterns extracted from the codebase. If the agent misunderstands the
   architecture, the examples mislead CI sessions.

   **Counter:** The review phase (Phase 5) lets the user catch errors. And
   the role files are committed to VCS — they can be edited post-generation.

3. **Maintenance burden.** If the generic role structure changes, the
   templates need updating.

   **Counter:** The templates are small (~50 lines of fixed sections). And
   changes to role structure are rare.

4. **Context directory is a user convention, not a plugin standard.** The
   plugin doesn't define `context/roles/` — the user does. Making the
   plugin generate into a user-defined directory couples plugin to convention.

   **Counter:** The skill can ask where to write (with `context/roles/` as
   default). And the convention is sensible enough to standardize.

5. **CP is redundant.** Generating a CP role file perpetuates the fiction
   that CP is a distinct role.

   **Counter:** The CP file is useful as a context document even if CP as a
   role is retired. The skill can note this: "This file provides project
   context for planning sessions. It is not a separate role."

### Verdict: **YES, build it**

The arguments for outweigh the arguments against. The skill solves a real,
recurring problem; fits the skill model cleanly; integrates naturally with
existing components; and improves plugin adoption.

---

## 9. Recommended Implementation

### Phase 1: Minimal Viable Skill

1. SKILL.md with `context: fork` + `agent: role-initializer`
2. Agent definition with Read, Write, Glob, Grep, Bash, AskUserQuestion
3. Three role templates in `reference/`
4. Research → Ask → Generate → Review flow
5. Output to `context/roles/` (configurable via AskUserQuestion)

### Phase 2: Enhancements (deferred)

6. Cross-repo analysis when related paths are provided
7. Idempotent update mode (diff existing roles against new research)
8. `context/standards/` scaffolding (tech-specific coding standards)
9. Integration with `context/README.md` generation

### TDD Approach

This feature should itself go through TDD:
- Test the templates (required sections present, no hardcoded project names)
- Test detect-project-context.sh integration
- Test output file structure (correct paths, correct section headings)

Since the core logic is in the agent's prompt (not in scripts), the testable
surface is the templates and any utility scripts.

---

## 10. Draft SKILL.md

```yaml
---
name: tdd-init-roles
description: >
  Generate project-specific role files (CA, CI, CP) for the TDD
  three-session workflow. Researches the codebase, detects tech stack
  and architecture, asks about cross-repo relationships, and writes
  customized roles to context/roles/. Run once per project.
  Triggers on: "init roles", "setup roles", "create project roles",
  "customize roles", "initialize TDD sessions".
disable-model-invocation: true
context: fork
agent: role-initializer
argument-hint: "[related project paths]"
---

# TDD Role Initialization

Generate project-specific session roles for this project.

Related projects (if any): $ARGUMENTS

## Process

### Phase 1: Detect

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/detect-project-context.sh`
2. Read CLAUDE.md (project root and .claude/) for existing context
3. Glob for key project files (sources, tests, configs, docs)
4. Identify the tech stack, build system, test framework

### Phase 2: Research

1. Read directory structure to understand architecture
2. Read 3-5 key source files to extract representative code patterns
3. Read test files to understand test conventions
4. Read build configuration for build/test commands
5. If related project paths are provided, read their CLAUDE.md files
   to understand cross-repo relationships

### Phase 3: Ask

Use AskUserQuestion to gather information that research cannot discover:
1. Cross-project relationships and shared protocols
2. Architecture rules that must be enforced
3. Known gotchas or past mistakes to document
4. Specific review priorities for the architect role
5. Where to write role files (default: context/roles/)

### Phase 4: Generate

Read the role templates from `reference/` and generate three files:
1. `ca-architect.md` — Fixed behavioral sections + project-specific
   context, scope, and review criteria
2. `ci-implementer.md` — Fixed behavioral sections + project-specific
   context, code patterns, build commands, and constraints
3. `cp-planner.md` — Fixed behavioral sections + project-specific
   context, API surface, and planning constraints

Also generate `context/README.md` explaining the directory structure.

### Phase 5: Review

Present a summary of what was generated:
- File count and locations
- Key project-specific content in each role
- Any assumptions that should be verified

## Constraints

- Do NOT modify existing project files (CLAUDE.md, source code, etc.)
- If role files already exist, ask before overwriting
- The generated roles must reference the project's actual file paths,
  build commands, and code patterns — not generic placeholders
- Include code examples in CI role only when they are directly extracted
  from or verified against the actual codebase
- Note CP's status: "This file provides project context for planning
  sessions. The tdd-planner agent handles the behavioral role."
```

---

## 11. Draft Agent Definition

```yaml
---
name: role-initializer
description: >
  Researches a project and generates customized TDD session role files
  (CA architect, CI implementer, CP planner context). Spawned by
  /tdd-init-roles. Interactive via AskUserQuestion.
tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: opus
color: blue
maxTurns: 40
---

You are a project role initializer for the TDD three-session workflow.

Your job is to research a codebase and generate three project-specific role
files that will guide CA (Architect), CI (Implementer), and CP (Planner)
sessions.

## What You Produce

Three role files in the user's chosen output directory (default: context/roles/):

### CA (Architect) Role
- Project context and purpose
- Architecture overview
- Cross-repo relationships
- What to track during reviews
- Project-specific quality criteria

### CI (Implementer) Role
- Source/test directory scope
- 2-4 representative code examples extracted from the codebase
- Build and test commands
- Tech-specific constraints and gotchas
- API usage patterns that CI must follow

### CP (Planner Context) Role
- Project purpose and architecture summary
- Available API surface (public classes, key functions)
- Reference examples (test patterns, existing code)
- Planning constraints (dependencies, tech limitations)
- Note: "This is a context document for planning sessions, not a
  separate behavioral role."

## Research Process

1. Run detect-project-context.sh for tech stack detection
2. Read CLAUDE.md files (root and .claude/) for existing project guidance
3. Glob for source, test, and config files
4. Read 3-5 key source files to extract architecture and code patterns
5. Read test files to understand testing conventions
6. Read build config (CMakeLists.txt, pubspec.yaml, etc.)
7. If related projects are referenced, read their CLAUDE.md files

## Role Template Structure

Read the templates in reference/ for the fixed sections of each role.
Fill in the dynamic sections based on your research.

Fixed sections (same for every project):
- Role (behavioral constraints)
- Memory (memory management instructions)

Dynamic sections (project-specific):
- Scope (what this role covers)
- Context (project purpose, architecture, dependencies)
- What to Track (CA: review criteria)
- Key Patterns (CI: code examples)
- Build & Test Commands (CI: project commands)
- Constraints (tech-specific limitations)
- API Surface (CP: available classes and functions)

## Quality Criteria

- Every file path mentioned must exist in the project
- Every code example must be extracted from or verified against actual source
- Build commands must be correct for the project's build system
- Cross-repo references must include the relationship type (shared protocol,
  dependency, downstream consumer)
- No generic placeholders — everything must be project-specific

## Output

After generating all files, present a summary to the user:
- Files created (paths and sizes)
- Key project-specific content in each role (2-3 bullet points each)
- Assumptions that should be verified
- Suggested next steps (e.g., "Edit ci-implementer.md to add patterns
  I may have missed")
```

---

## 12. Comparison: Before and After

### Before (Manual Process)

```
Developer                    CA Session
   │                            │
   ├── "Create roles for       │
   │    this project"          │
   │                           ├── Read CLAUDE.md
   │                           ├── Explore codebase
   │                           ├── Ask developer questions
   │                           ├── Write ca-architect.md
   │                           ├── Write ci-implementer.md
   │                           ├── Write cp-planner.md
   │                           ├── Write context/README.md
   │                           │
   ├── Review and edit ────────┤
   │                           ├── Revise based on feedback
   │                           │
   └── Approve ────────────────┘
```

**Time:** 15-30 minutes of interactive CA session
**Context cost:** Significant (research fills the context window)
**Quality:** Depends on CA's context at creation time

### After (Skill-Automated Process)

```
Developer                    /tdd-init-roles
   │                            │
   ├── "/tdd-init-roles        │
   │    ../related-project"    │
   │                           ├── [Phase 1: Detect]
   │                           ├── [Phase 2: Research]
   │                           │
   │◄─ Questions ──────────────┤ [Phase 3: Ask]
   ├── Answers ────────────────►│
   │                           │
   │                           ├── [Phase 4: Generate]
   │                           │
   │◄─ Summary ────────────────┤ [Phase 5: Review]
   ├── Approve/Edit ───────────►│
   │                           │
   └── Done                    └── Files written
```

**Time:** 5-10 minutes (structured interaction)
**Context cost:** Isolated (forked context, doesn't pollute CA's session)
**Quality:** Consistent (structured research, template-guided output)

---

## 13. Open Questions

### 13.1 Should the skill also generate `context/standards/` files?

The zenoh-counter-cpp project has a `context/standards/` directory with
11 coding standards documents. These are currently created manually.

**Assessment:** Out of scope for v1. Standards documents are much longer,
more opinionated, and harder to auto-generate correctly. They're also
available via the plugin's convention skills. Consider for v2.

### 13.2 Should generated roles reference CLAUDE.md via `@import`?

If the role files used `@import ../CLAUDE.md`, they'd stay in sync with
project changes. But `@import` only works in CLAUDE.md files, and role
files are loaded manually (pasted into sessions), not auto-loaded.

**Assessment:** Not viable with current Claude Code architecture. Role
files must be self-contained.

### 13.3 Should the skill update roles when the project evolves?

Projects change. The architecture evolves, new dependencies are added,
new patterns emerge. Should `/tdd-init-roles` support an "update" mode?

**Assessment:** Yes, but in v2. The idempotent update mode would:
1. Read existing role files
2. Research current codebase state
3. Produce a diff showing what changed
4. Ask user to approve changes
5. Write updated files

For v1, the user can re-run `/tdd-init-roles` and choose to overwrite.

### 13.4 What about the `context/README.md`?

The zenoh-counter-cpp project has a `context/README.md` that explains the
three subdirectories. Should the skill generate this?

**Assessment:** Yes, include in v1. It's short and explains the directory
structure to new developers. Template it in `reference/context-readme.md`.

### 13.5 How does this interact with `/tdd-status`?

`/tdd-status` (proposed in analysis.md) reports TDD session state.
`/tdd-init-roles` generates role files. They're independent — different
lifecycle stages, no interaction needed.

### 13.6 Version for this feature?

If added to the plugin: MINOR bump (new skill, new agent, no breaking
changes). Could be part of a "v1.14.0 — Project Setup" release alongside
`/tdd-status` and the SessionStart hook.

---

## 14. Summary

| Question | Answer |
|----------|--------|
| Should role generation become a skill? | **Yes** |
| Should it be in the tdd-workflow plugin? | **Yes** — it's specific to the three-role model |
| Should it use a dedicated agent? | **Yes** — `role-initializer` with `context: fork` |
| Should it handle cross-repo? | **Yes** — via optional path arguments |
| Should it be interactive? | **Yes** — AskUserQuestion for context research can't discover |
| Should it generate CP roles? | **Yes** — as context documents, with a note about CP retirement |
| Should it generate standards? | **No** — out of scope for v1 |
| Should it support updates? | **No** — v2 feature; v1 supports overwrite |
| TDD approach? | **Yes** — test templates and utility scripts |
| Estimated effort? | SKILL.md (~80 lines), agent (~60 lines), templates (~150 lines), tests (~40) |
