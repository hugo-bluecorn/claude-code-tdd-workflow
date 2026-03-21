# Role File Format v2.1

> Reference for CR and the `role-initializer` agent. Every generated role
> file must conform to this format. CR selects sections from the menu
> below based on the developer's workflow and project needs.

---

## Format

```
┌─────────────────────────────────┐
│  YAML Frontmatter (metadata)    │  ← machine-readable, validates structure
├─────────────────────────────────┤
│  Title + Rationale              │  ← first thing the session reads
├─────────────────────────────────┤
│  Core sections                  │  ← Identity, Responsibilities, Constraints
│  (almost always needed)         │
├─────────────────────────────────┤
│  Optional sections              │  ← Memory, Startup, Workflow, Context, etc.
│  (CR picks what fits)           │
├─────────────────────────────────┤
│  Custom sections                │  ← developer-defined, project-specific
│  (anything the role needs)      │
├─────────────────────────────────┤
│  Coordination                   │  ← only when multiple roles exist
│  (last section, if present)     │
└─────────────────────────────────┘
```

---

## 1. YAML Frontmatter

```yaml
---
role: XX                          # 2-letter code (unique per project)
name: "Human-Readable Role Name"
type: session                     # session (full role) | context (supplemental doc)
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

**Output convention:** Role files live in `context/roles/` at the project root.
Filename: `{role-code}-{short-name}.md` (lowercase, e.g., `rv-reviewer.md`).
This directory is project-owned, version-controlled, and outside `.claude/`
to avoid namespace collisions with Claude Code internals.

---

## 2. Title Block

Immediately after frontmatter. Sets the session's identity anchor.

**For session roles:**

```markdown
# {role} — {name}

> **Why a separate session?** {one sentence — the context isolation benefit}
> **Project:** {project} | **Stack:** {stack} | **Stage:** {stage}
```

**For context documents:**

```markdown
# {role} — {name}

> This file provides project-specific context for {purpose}.
> Load this into any relevant session to improve quality.
> **Project:** {project} | **Stack:** {stack} | **Stage:** {stage}
```

---

## 3. Section Menu

CR selects sections based on the developer's workflow. Not all sections
are needed for every role. The only hard requirement is Identity.

### Core Sections

These are almost always needed. Omit only with good reason.

#### Identity

```markdown
## Identity

You are the **{role} ({name})** session for the {project} project.
{2-3 sentences: primary function, mode of operation}
```

**Rules:**
- Must state the role code and name
- Must describe HOW this session operates (conversational, command-driven, guided, etc.)
- If other roles exist, reference them. If this is the only role, omit role references.

#### Responsibilities

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

#### Constraints

```markdown
## Constraints

- **{What is forbidden}.** {What breaks if violated.}
```

**Rules:**
- Maximum 5 constraints
- Each must be absolute (not a preference)
- Each must explain WHY — the consequence of violation
- Phrased as "Never X" or "Do not X", not "Try to avoid X"

### Optional Sections

Include when relevant to the role's workflow.

#### Memory

Include when the role interacts with shared state (auto-memory, progress
files, git). Omit for single-session setups with no persistence needs.

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
- Only include layers the role actually uses
- Access level must be explicit per layer

#### Startup

Include when the role needs a defined recovery/orientation procedure.

```markdown
## Startup

On fresh start or recovery after interruption:

1. {first orientation step}
2. {next step}
3. {what to do next or who to wait for}
```

**Rules:**
- Every step must be idempotent (safe to re-run)
- Last step must say what to do next
- Include only steps relevant to this role's responsibilities

#### Workflow

Include when the role follows repeatable procedures that would otherwise
need to be explained every time.

```markdown
## Workflow

### {Procedure Name}
Before {triggering event}:
1. {concrete step with file path or command}
2. {concrete step}
3. {concrete step}
```

**Rules:**
- Each procedure is a checklist the session follows WITHOUT human prompting
- Must encode patterns the developer would otherwise repeat manually
- Paths and commands must be verified against project configuration

#### Context

Include when the role needs project-specific technical context.

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

#### Coordination

Include only when multiple roles exist and need to hand off work.

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

### Custom Sections

Developers may define sections not listed above. Custom sections:

- Go after optional sections, before Coordination (if present)
- Follow the same quality rules: no placeholders, no invented paths
- Should have a clear heading and a brief description of purpose
- CR validates them the same way as any other section
- Examples: `## Level Design Patterns`, `## Pipeline Topology`, `## API Contracts`

---

## 4. Validation

A generated role file is valid when:

- [ ] YAML frontmatter has all required fields (`role`, `name`, `type`)
- [ ] Title block matches the type (session vs context)
- [ ] Identity section is present
- [ ] Sections follow the general flow: Core → Optional → Custom → Coordination
- [ ] No placeholders (`{...}`, `TODO`, `TBD`)
- [ ] No invented file paths — every path exists on disk
- [ ] No invented code — examples extracted from actual source
- [ ] Constraints have reasons (if Constraints section is present)
- [ ] Under 400 lines (prefer under 300)

---

## 5. Lifecycle

| Event | What happens |
|---|---|
| `/role-init` | CR researches the project and developer workflow, generates role files |
| `/role-evolve` | Updates content from agent memory + MEMORY.md |
| `/role-*` | Loads role file + conventions via DCI into session |
| `/role-*` mid-session | Re-anchors session identity (drift correction) |
| `/clear` + `/role-*` | Full reset for new feature |
| Manual edit | Developer modifies role file directly (preserved by evolve) |
