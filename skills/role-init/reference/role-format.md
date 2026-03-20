# Role File Format v2.0

> Reference for the `role-initializer` agent. Every generated role file
> must conform to this format. Templates and instances are both valid
> role files — templates have placeholder markers, instances have content.

---

## Format

```
┌─────────────────────────────────┐
│  YAML Frontmatter (metadata)    │  ← machine-readable, validates structure
├─────────────────────────────────┤
│  Title + Rationale              │  ← first thing the session reads
├─────────────────────────────────┤
│  FIXED sections                 │  ← from plugin templates, never project-specific
│  (Identity, Responsibilities,   │
│   Constraints, Memory)          │
├─────────────────────────────────┤
│  HYBRID sections                │  ← fixed structure + dynamic content
│  (Startup, Workflow)            │
├─────────────────────────────────┤
│  DYNAMIC sections               │  ← entirely from research, project-specific
│  (Context, role-specific)       │
├─────────────────────────────────┤
│  FIXED section                  │  ← Coordination (last — references other roles)
└─────────────────────────────────┘
```

---

## 1. YAML Frontmatter

```yaml
---
role: XX                          # 2-letter code (CA, CI, CP, CR, etc.)
name: "Human-Readable Role Name"
type: session                     # session (full role) | context (CP only)
version: 1                        # increments on /role-evolve updates
project: "project-name"           # from codebase research
stack: "language, framework"      # from detect-project-context.sh
stage: v1                         # v1 | v2 | v3 | vN (lifecycle stage)
generated: "2026-03-20T14:00:00Z" # ISO-8601
generator: /role-init             # or "manual" for hand-authored
---
```

**Required fields:** `role`, `name`, `type`
**Generated fields:** `version`, `project`, `stack`, `stage`, `generated`, `generator`

---

## 2. Title Block

Immediately after frontmatter. Sets the session's identity anchor.

**For session roles (CA, CI, CR, etc.):**

```markdown
# {role} — {name}

> **Why a separate session?** {one sentence — the context isolation benefit}
> **Project:** {project} | **Stack:** {stack} | **Stage:** {stage}
```

**For context documents (CP):**

```markdown
# CP — Planning Context

> This file provides project-specific planning context. The tdd-planner
> agent handles the behavioral role. Load this into any planning session
> to improve plan quality.
> **Project:** {project} | **Stack:** {stack} | **Stage:** {stage}
```

---

## 3. Section Definitions

### Section types

| Type | Source | /role-init writes | /role-evolve modifies |
|---|---|---|---|
| FIXED | Plugin template | Copies verbatim | Never |
| HYBRID | Template structure + research content | Merges both | Dynamic content only |
| DYNAMIC | Codebase research + human input | Generates freely | Freely |

### FIXED: Identity

```markdown
## Identity

You are the **{role} ({name})** session for the {project} project.
{2-3 sentences: primary function, mode of operation, relationship to other roles}
```

**Rules:**
- Must state the role code and name
- Must describe HOW this session operates (conversational, command-driven, etc.)
- Must reference at least one other role

### FIXED: Responsibilities

```markdown
## Responsibilities

### {Functional Area}
- {Specific action} → {visible output}
- {Specific action} → {visible output}
```

**Rules:**
- Grouped by functional area
- Each item is actionable: verb + object + output
- Never "understand X" — always "read X and produce Y"

### FIXED: Constraints

```markdown
## Constraints

- **{What is forbidden}.** {What breaks if violated.}
```

**Rules:**
- Maximum 5 constraints
- Each must be absolute (not a preference)
- Each must explain WHY — the consequence of violation
- Phrased as "Never X" or "Do not X", not "Try to avoid X"

### FIXED: Memory

```markdown
## Memory

{role} **{reads | reads and writes}** shared memory.

| Layer | Access | What lives here |
|---|---|---|
| Auto-memory (MEMORY.md) | {read/write} | {purpose} |
| Agent memory (.claude/agent-memory/) | {read} | {purpose} |
| .tdd-progress.md | {read} | {purpose} |
| Git | {read/write} | {purpose} |
```

**Rules:**
- Must cover all four layers
- Access level must be explicit per layer
- CA is the sole auto-memory writer (convention, not enforced)

### HYBRID: Startup

```markdown
## Startup

On fresh start or recovery after interruption:

1. Read `MEMORY.md` for current project state
2. Read `.tdd-progress.md` if it exists (active TDD session)
3. Check `git log --oneline -10` and `git branch` for recent activity
4. {project-specific: what to check next}
5. {project-specific: state assessment}
6. {project-specific: what to do or who to wait for}
```

**Rules:**
- Steps 1-3 are always identical (FIXED)
- Steps 4+ are project-specific (DYNAMIC)
- Every step must be idempotent (safe to re-run)
- Last step must say what to do next or who to wait for

### HYBRID: Workflow

```markdown
## Workflow

### {Procedure Name}
Before {triggering event}:
1. {concrete step with file path or command}
2. {concrete step}
3. {concrete step}
```

**Rules:**
- Procedure names are fixed (from template)
- Step content includes project-specific paths, commands, conventions
- Each procedure is a checklist the session follows WITHOUT human prompting
- Must encode patterns the developer would otherwise repeat manually
- Convention paths must be DISCOVERED, not placeholder

### DYNAMIC: Context

```markdown
## Context

**Project:** {name}
**Tech stack:** {language}, {framework}, {key dependencies}
**Architecture:** {pattern — e.g., MVVM, layered, microservices}
**Build:** `{build_command}`
**Test:** `{test_command}`
**Analyze:** `{analyze_command}`
**Format:** `{format_command}`
```

**Rules:**
- Every value must come from actual project research
- No placeholders — if unknown, omit the field
- Commands must be verified against project configuration

### DYNAMIC: Role-Specific Sections

Each role has additional sections after Context. See §4 for the
complete composition per role.

**Rules for all DYNAMIC sections:**
- Content sourced from: codebase, CLAUDE.md, agent memory, user input, conventions
- File paths must exist on disk
- Code examples must be extracted from actual source (CI only)
- When sources conflict: user input > codebase > CLAUDE.md > agent memory > conventions

### FIXED: Coordination

```markdown
## Coordination

### To {other role} ({purpose})
Provide: {what to hand off and in what form}

### From {other role} ({purpose})
Expect: {what to receive and what to do with it}
```

**Rules:**
- Coordination is human-mediated (developer carries context between terminals)
- Must define both directions for each relationship
- Must specify the FORMAT of the handoff (file path, verbal, paste)

---

## 4. Role Compositions

### CA — Architect / Reviewer (`type: session`)

| # | Section | Type | Content focus |
|---|---|---|---|
| 1 | Identity | FIXED | Conversational, judgment-based, decision authority |
| 2 | Responsibilities | FIXED | Decisions, issues, prompts, verification, memory |
| 3 | Constraints | FIXED | Read-only for code, never merge, never implement |
| 4 | Memory | FIXED | Sole auto-memory writer |
| 5 | Startup | HYBRID | + cross-check memory vs progress state |
| 6 | Workflow | HYBRID | Plan Review procedure, Verification procedure |
| 7 | Context | DYNAMIC | Project overview |
| 8 | Architecture | DYNAMIC | Patterns, boundaries, technical debt |
| 9 | Cross-Repo | DYNAMIC | Related projects (optional) |
| 10 | Decisions | DYNAMIC | Key decisions, open questions |
| 11 | Verification Focus | DYNAMIC | What to check, common mistakes |
| 12 | Conventions | DYNAMIC | Paths to convention docs, key patterns |
| 13 | Coordination | FIXED | To/from CP, CI |

### CI — Implementer (`type: session`)

| # | Section | Type | Content focus |
|---|---|---|---|
| 1 | Identity | FIXED | Command-driven, executes plan |
| 2 | Responsibilities | FIXED | Implement, release, docs, direct edits, PR merge |
| 3 | Constraints | FIXED | Never plan, never decide architecture, follow plan |
| 4 | Memory | FIXED | Reads only, never writes auto-memory |
| 5 | Startup | HYBRID | + check git status for uncommitted changes |
| 6 | Workflow | HYBRID | Implementation Prep procedure, Post-Impl Report |
| 7 | Context | DYNAMIC | Project overview |
| 8 | Build Commands | DYNAMIC | Build, test, analyze, format with flags |
| 9 | Code Examples | DYNAMIC | 2-4 from actual source, cited |
| 10 | Constraints (impl) | DYNAMIC | Naming, imports, error handling patterns |
| 11 | Pitfalls | DYNAMIC | Things that look right but break |
| 12 | Coordination | FIXED | To/from CA |

### CP — Planning Context (`type: context`)

| # | Section | Type | Content focus |
|---|---|---|---|
| 1 | Context | DYNAMIC | Project overview |
| 2 | Decomposition | DYNAMIC | How to slice features for THIS project |
| 3 | Slice Ordering | DYNAMIC | Dependency chains, what comes first |
| 4 | Test Strategy | DYNAMIC | Granularity, environment, batching |
| 5 | Learnings | DYNAMIC | Past underestimates, scope creep (v2+, optional) |
| 6 | API Surface | DYNAMIC | Key public classes and functions |
| 7 | Conventions | DYNAMIC | Paths to convention docs, key patterns |

---

## 5. Validation

A generated role file is valid when:

- [ ] YAML frontmatter has all required fields
- [ ] Title block matches the type (session vs context)
- [ ] Sections appear in composition order (§4)
- [ ] All required sections present
- [ ] No placeholders (`{...}`, `TODO`, `TBD`)
- [ ] No invented file paths — every path exists on disk
- [ ] No invented code — examples extracted from actual source
- [ ] FIXED sections match plugin templates exactly
- [ ] Constraints have reasons
- [ ] Under 400 lines (prefer under 300)

---

## 6. Lifecycle

| Event | What happens |
|---|---|
| `/role-init` | Generates fresh role files from templates + research |
| `/role-evolve` | Updates DYNAMIC content from agent memory + MEMORY.md |
| `/role-ca` (or cp, ci) | Loads role file + conventions via DCI into session |
| `/role-ca` mid-session | Re-anchors session identity (drift correction) |
| `/clear` + `/role-ca` | Full reset for new feature |
| Manual edit | Developer modifies role file directly (preserved by evolve) |
