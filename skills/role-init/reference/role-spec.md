# Role File Specification v1.0

> The `role-initializer` agent reads this as its primary reference.
> Templates are instances of this spec. Generated role files must conform to it.
> Supersedes: `role-dsl.md` (retained as historical exploration).

---

## 1. File Format

Role files are **Markdown (CommonMark)** with a **YAML frontmatter** header.
Target length: under 300 lines. Hard limit: 400 lines.

Two variants exist:

| Variant | Used by | Identity section? | Minimum sections |
|---|---|---|---|
| **Role file** | CA, CI | Yes — full session identity | 6 |
| **Context file** | CP | No — planning context document | 3 |

---

## 2. Header

### Role file header (CA, CI)

```yaml
---
role: CA                    # CA or CI
name: Architect / Reviewer  # human-readable role name
project: project-name       # from codebase research
tech_stack: Dart, Flutter, Riverpod  # from detect-project-context.sh
generated: 2026-03-20T14:00:00Z     # ISO-8601
stage: v1                   # v1, v2, v3, or vN
generator: /role-init
---
```

Followed by:

```markdown
# CA — Architect / Reviewer

> **Why a separate session?** {one sentence explaining context isolation benefit}
> **Project:** {project-name}
> **Generated:** {date} by /role-init (stage {stage})
```

### Context file header (CP)

```yaml
---
role: CP
name: Planning Context
project: project-name
tech_stack: Dart, Flutter, Riverpod
generated: 2026-03-20T14:00:00Z
stage: v1
generator: /role-init
---
```

Followed by:

```markdown
# CP — Planning Context

> This file provides project-specific planning context. The tdd-planner
> agent handles the behavioral role. Load this into any planning session
> to improve plan quality.
```

---

## 3. Section Types

Every section in a role file is one of three types:

| Type | Source | Written by | Modified by /role-evolve |
|---|---|---|---|
| **FIXED** | Plugin templates — identical across all projects | role-initializer copies verbatim | Never |
| **DYNAMIC** | Codebase research + human input | role-initializer generates | Freely |
| **HYBRID** | Fixed structure from templates + dynamic content from research | role-initializer merges | Dynamic content only |

---

## 4. Section Definitions

### FIXED Sections

These come from the plugin templates verbatim. The role-initializer copies
them without modification. `/role-evolve` must never change them.

#### Identity
- **Scope:** CA, CI
- **Purpose:** 2-3 sentences establishing WHO this session is and HOW it operates
- **Must:** Reference relationship to other roles

#### Responsibilities
- **Scope:** CA, CI
- **Purpose:** What the session does, organized by functional area
- **Must:** Be actionable — not "understand X" but "read X and summarize Y"
- **Must:** Each responsibility produces a visible output

#### Constraints
- **Scope:** CA, CI
- **Purpose:** What the session must NOT do
- **Must:** Be few (maximum 5) and absolute — not preferences
- **Must:** Each constraint explains WHY (what breaks if violated)

#### Memory Scope
- **Scope:** CA, CI
- **Purpose:** What the session reads/writes across the four memory layers
- **Must:** Cover: auto-memory, agent memory, .tdd-progress.md, git

#### Handoff Patterns
- **Scope:** CA, CI
- **Purpose:** How to coordinate with other roles
- **Must:** Define inputs and outputs of each inter-role interaction
- **Must:** Note that handoffs are human-mediated

### HYBRID Sections

Fixed structure from templates, dynamic content filled by research.

#### Startup Checklist
- **Scope:** CA, CI
- **Structure (fixed):** Numbered checklist. Steps 1-3 are always:
  1. Read MEMORY.md for current project state
  2. Read .tdd-progress.md if it exists
  3. Check git log and branch for recent activity
- **Content (dynamic):** Steps 4+ are project-specific recovery steps
- **Rule:** Steps must be concrete and idempotent (safe to re-run)

#### Workflow Procedures
- **Scope:** CA, CI (different content per role)
- **Structure (fixed):** Named procedures with numbered steps
- **Content (dynamic):** Convention paths, file references, project-specific commands
- **Rule:** Encodes REPEATED instructions the developer would otherwise type manually
- **Rule:** Each procedure is a checklist the session follows WITHOUT prompting

**CA procedures:**
- Plan Review — what to read before analyzing a plan (memory, issue, conventions, progress)
- Verification — what to check after implementation (tests, analysis, commit messages)

**CI procedures:**
- Implementation Preparation — what to check before /tdd-implement (memory, git status, branch, progress)
- Post-Implementation Report — what to report to CA after completion

### DYNAMIC Sections

Entirely generated from research. No template content. `/role-evolve` freely
updates these.

#### Project Context
- **Scope:** CA, CI, CP
- **Sources:** codebase, CLAUDE.md, detect-project-context.sh
- **Content:** Project name, tech stack, architecture pattern, build/test/analysis commands
- **Rule:** Must reference ACTUAL project values, never placeholders

#### Architecture Notes (CA only)
- **Sources:** codebase, CLAUDE.md, user input
- **Content:** Key patterns and rationale, module boundaries, technical debt

#### Cross-Repo Relationships (CA only, optional)
- **Sources:** user input, codebase
- **Content:** Related projects with relationship type (shared protocol, dependency, consumer)
- **Rule:** Only present if related projects exist

#### Decision History (CA only)
- **Sources:** CLAUDE.md, auto-memory, user input
- **Content:** Key decisions with rationale, open questions

#### Verification Focus (CA only)
- **Sources:** codebase, agent memory (verifier), user input
- **Content:** What to check carefully, common mistake patterns

#### Convention References (CA, CP)
- **Sources:** convention cache, detect-project-context.sh
- **Content:** Paths to convention docs, 3-5 key pattern summaries
- **Rule:** Points to WHERE to find detail, not the detail itself

#### Build Commands (CI only)
- **Sources:** detect-project-context.sh, codebase
- **Content:** Build, test, analyze, format commands with full flags
- **Rule:** All four commands must be present

#### Code Examples (CI only)
- **Sources:** codebase (extracted from actual files)
- **Content:** 2-4 representative examples demonstrating key patterns
- **Rule:** Never invented — must cite the source file
- **Rule:** Each example demonstrates a pattern the implementer must follow

#### Implementation Constraints (CI only)
- **Sources:** codebase, CLAUDE.md, convention cache
- **Content:** Naming conventions, import ordering, error handling patterns

#### Common Pitfalls (CI only)
- **Sources:** user input, agent memory (implementer, verifier)
- **Content:** Things that look right but break in THIS project

#### Decomposition Patterns (CP only)
- **Sources:** user input, codebase
- **Content:** How features should be sliced for this project
- **Rule:** This is HUMAN knowledge the planner can't discover

#### Slice Ordering (CP only)
- **Sources:** user input, codebase
- **Content:** What must be planned first, dependency chains

#### Test Strategy (CP only)
- **Sources:** detect-project-context.sh, user input
- **Content:** Test granularity preference, environment setup requirements

#### Planning Learnings (CP only, optional)
- **Sources:** user input, agent memory (planner)
- **Content:** Past underestimates, scope creep patterns
- **Rule:** Only present at v2+ lifecycle stages

#### API Surface (CP only)
- **Sources:** codebase
- **Content:** Key public classes, functions, interfaces

---

## 5. Role Composition

Which sections compose into which role file, in order:

### CA — Architect / Reviewer

| # | Section | Type |
|---|---|---|
| 1 | Identity | FIXED |
| 2 | Responsibilities | FIXED |
| 3 | Constraints | FIXED |
| 4 | Memory Scope | FIXED |
| 5 | Startup Checklist | HYBRID |
| 6 | Workflow Procedures | HYBRID |
| 7 | Project Context | DYNAMIC |
| 8 | Handoff Patterns | FIXED |
| 9 | Architecture Notes | DYNAMIC |
| 10 | Cross-Repo Relationships | DYNAMIC (optional) |
| 11 | Decision History | DYNAMIC |
| 12 | Verification Focus | DYNAMIC |
| 13 | Convention References | DYNAMIC |

### CI — Implementer

| # | Section | Type |
|---|---|---|
| 1 | Identity | FIXED |
| 2 | Responsibilities | FIXED |
| 3 | Constraints | FIXED |
| 4 | Memory Scope | FIXED |
| 5 | Startup Checklist | HYBRID |
| 6 | Workflow Procedures | HYBRID |
| 7 | Project Context | DYNAMIC |
| 8 | Handoff Patterns | FIXED |
| 9 | Build Commands | DYNAMIC |
| 10 | Code Examples | DYNAMIC |
| 11 | Implementation Constraints | DYNAMIC |
| 12 | Common Pitfalls | DYNAMIC |

### CP — Planning Context

| # | Section | Type |
|---|---|---|
| 1 | Project Context | DYNAMIC |
| 2 | Decomposition Patterns | DYNAMIC |
| 3 | Slice Ordering | DYNAMIC |
| 4 | Test Strategy | DYNAMIC |
| 5 | Planning Learnings | DYNAMIC (optional) |
| 6 | API Surface | DYNAMIC |
| 7 | Convention References | DYNAMIC |

---

## 6. Content Sources

Where the role-initializer gets content from, in priority order.
When sources conflict, higher priority wins.

| Priority | Source | How to access |
|---|---|---|
| 1 | User input | AskUserQuestion during Phase 3 |
| 2 | Codebase | Glob, Grep, Read of project files |
| 3 | CLAUDE.md | Read project root and .claude/ |
| 4 | Agent memory | Read .claude/agent-memory/*/MEMORY.md |
| 5 | Convention cache | Discovered via tdd-conventions.json |
| 6 | Detection script | Run detect-project-context.sh |
| 7 | Plugin templates | Read from reference/ directory |

---

## 7. Validation Checklist

A generated role file is valid when:

### Structure
- [ ] YAML frontmatter present with all required fields
- [ ] Sections appear in the order specified in §5
- [ ] All required sections present (optional sections may be absent)
- [ ] File is under 400 lines (under 300 preferred)

### Content quality
- [ ] No placeholder text (`{placeholder}`, `TODO`, `TBD`)
- [ ] No invented file paths — every mentioned path exists on disk
- [ ] No invented code examples — every example extracted from actual source
- [ ] Code examples cite their source file
- [ ] Build commands verified against project configuration
- [ ] Constraints have reasons (what breaks if violated)

### FIXED section integrity
- [ ] FIXED sections match the plugin templates exactly
- [ ] No project-specific content leaked into FIXED sections

### DYNAMIC section sourcing
- [ ] Every DYNAMIC section cites where its content came from
- [ ] Convention references point to discovered paths, not placeholders

---

## 8. Lifecycle Rules

| Operation | FIXED sections | HYBRID sections | DYNAMIC sections |
|---|---|---|---|
| `/role-init` | Copy from template | Merge template structure + research content | Generate from research |
| `/role-evolve` | Never modify | Update dynamic content only | Regenerate or patch from memory |
| `/role-ca` (deliver) | Load as-is | Load as-is | Load as-is |
| `/clear` + `/role-ca` | Reload fresh | Reload fresh | Reload fresh |
