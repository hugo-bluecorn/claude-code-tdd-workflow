# `/tdd-init-roles` — Iterative Lifecycle Concept

> **Date:** 2026-03-15
> **Status:** Concept exploration — needs further refinement
> **Prior documents:**
> - `analysis.md` — roles should not become agents; extract procedural skills
> - `project-role-initializer.md` — initial one-shot skill proposal (superseded by this document)

---

## 1. The Bootstrapping Problem

The initial proposal for `/tdd-init-roles` assumed the skill runs once after
a project has enough structure to research. This has a chicken-and-egg
problem: CA needs project-specific context to write good specs, but the
skill needs a codebase to generate that context.

## 2. Revised Concept: Iterative Refinement

`/tdd-init-roles` runs at multiple natural workflow milestones, producing
progressively richer role files as more project context becomes available.
The skill doesn't need separate "modes" — it researches whatever exists at
invocation time.

### Lifecycle Stages

```
Stage 0: Project Skeleton
  └── flutter create / cpp-template / manual setup
  └── Plugin convention skills provide tech-stack context

Stage 1: Specification
  └── CA + human dialogue → CLAUDE.md, issues/*.md, architecture decisions
  └── /tdd-init-roles [v1] → initial roles from skeleton + spec
      Output: roles reflecting architecture INTENT, tech stack, constraints

Stage 2: Planning
  └── CC runs /tdd-plan → CA reviews → plan approved
  └── .tdd-progress.md + planning/*.md now exist
  └── /tdd-init-roles [v2] → refined roles from skeleton + spec + plan
      Output: CI gets file paths, test patterns, slice structure
      Output: context change suggestions for CA (plan reveals details spec missed)

Stage 3: Implementation
  └── CI runs /tdd-implement → code exists
  └── /tdd-init-roles [v3] → mature roles from full codebase
      Output: CI gets real code examples, discovered patterns, API references
      Output: further context suggestions for CA

Stage N: Evolution
  └── New features added, architecture evolves
  └── /tdd-init-roles [vN] → updated roles reflecting current state
```

### What Each Stage Adds

| Stage | Available Context | Role Quality |
|-------|-------------------|-------------|
| v1 (post-spec) | Skeleton + CLAUDE.md + issues | Tech stack, architecture intent, constraints from spec |
| v2 (post-plan) | + .tdd-progress.md + planning/*.md | File paths, test patterns, slice structure, dependency ordering |
| v3 (post-impl) | + source code + tests + agent memory | Real code examples, API patterns, discovered gotchas |
| vN (evolution) | + multiple features, mature codebase | Full project knowledge, cross-feature patterns |

### Project Skeleton Sources

The plugin already provides context for initial project creation:
- **Flutter:** `flutter create` provides standard project structure; plugin's
  `dart-flutter-conventions` skill provides Dart/Flutter patterns
- **C++:** `https://github.com/hugo-bluecorn/claude-cpp-template` provides
  CMake + GoogleTest starter; plugin's `cpp-testing-conventions` skill
  provides C++ patterns
- **C:** Plugin's `c-conventions` skill provides Unity/CMock patterns
- **Bash:** Plugin's `bash-testing-conventions` skill provides bashunit patterns

## 3. Bidirectional Output

The skill produces two types of output:

### Downward: Role Files

Generated/updated role files in `context/roles/`:
- `ca-architect.md` — project-specific CA context
- `ci-implementer.md` — project-specific CI context

### Upward: Context Change Report

Suggestions for CA based on what the skill discovered:
- "The plan specifies test file paths not mentioned in CLAUDE.md"
- "Cross-repo constraint discovered: payload format must match zenoh-counter-dart"
- "Consider adding API surface listing to CLAUDE.md for planner efficiency"

This feedback loop means the skill doesn't just consume project context —
it improves it.

## 4. Key Design Requirements

### Idempotency

Each invocation must:
1. Read existing role files (if any)
2. Research current project state
3. Produce a diff showing what changed since last run
4. Ask user to approve changes before writing

Not a blind overwrite — incremental refinement.

### Two Output Files (Not Three)

Per Part 1 analysis, CP is retired. The skill generates CA and CI roles only.
Planning context that would have gone into CP should go into CLAUDE.md or
the planner's `memory: project` directory.

### Awareness of Lifecycle Stage

The skill should detect which stage the project is at:
- No source files → v1 (spec-based)
- .tdd-progress.md exists with pending slices → v2 (plan-based)
- .tdd-progress.md exists with completed slices → v3 (implementation-based)
- Multiple planning archives → vN (evolution)

This detection is informational — it tells the user what context is
available and what quality of roles to expect.

## 5. Open Questions (For Future Sessions)

### 5.1 Interaction with `/tdd-status`

`/tdd-status` (proposed in analysis.md) reports session state.
`/tdd-init-roles` generates roles. Should `/tdd-status` report role
file freshness? ("Roles last generated at v1; project is now at v3 stage
— consider running /tdd-init-roles.")

### 5.2 The Upward Feedback Mechanism

How should context change suggestions be delivered?
- Written to a file (`context/suggestions.md`)?
- Presented via AskUserQuestion during the skill run?
- Added as comments in the role files themselves?

### 5.3 Role File Diffing

For idempotent updates, how granular should the diff be?
- Section-level (replace entire "Key Patterns" section)?
- Line-level (surgical edits within sections)?
- Full regeneration with diff preview?

### 5.4 When to Auto-Suggest Running

Should a PostToolUse or Stop hook detect that roles are stale and suggest
running `/tdd-init-roles`? Or is manual invocation sufficient?

### 5.5 Cross-Repo Role Coordination

When `/tdd-init-roles` runs on zenoh-counter-cpp with `--related
../zenoh-counter-dart`, should it also update the Dart project's roles
to reflect the relationship? Or is that a separate invocation?

### 5.6 Integration with Project Scaffolding

The scaffolding plugin idea (from MEMORY.md Future Ideas) would create
new project structures. Should scaffolding automatically run
`/tdd-init-roles` as part of project creation?

## 6. Relationship to Other Proposals

| Proposal | Status | Relationship |
|----------|--------|-------------|
| `/tdd-status` skill | Proposed (analysis.md) | Independent, complementary |
| `/tdd-verify-feature` skill | Proposed (analysis.md) | Independent, complementary |
| SessionStart hook (N4) | Proposed (analysis.md) | Could detect stale roles |
| CP retirement | Decided (analysis.md) | `/tdd-init-roles` generates 2 files, not 3 |
| Project scaffolding plugin | Future idea (MEMORY.md) | Could trigger `/tdd-init-roles` post-scaffold |
| Doc-finalizer redesign | Pending decision (MEMORY.md) | Independent |

---

*This document captures the concept as of 2026-03-15. Further refinement
will happen in subsequent sessions. Workflow modifications deferred.*
