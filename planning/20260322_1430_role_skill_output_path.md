# Feature Notes: Role Skill Output Path (Issue 008)

**Created:** 2026-03-22
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Change generated role files from plain markdown in `context/roles/` to auto-discoverable Claude Code skills at `.claude/skills/role-{code}/SKILL.md`. This makes role files loadable via `/role-{code}` slash commands without any additional plugin configuration, leveraging Claude Code's native skill discovery.

### Use Cases
- User runs `/role-cr` to generate a CA role → file lands at `.claude/skills/role-ca/SKILL.md`
- User (or another session) runs `/role-ca` → Claude Code auto-discovers and loads the role skill
- Role files include `disable-model-invocation: true` so they are only loaded by explicit user invocation, never by model initiative

### Context
Issue 007 (v2.1.0) delivered `/role-cr` with output to `context/roles/`. This was always a provisional path — the issue notes anticipated moving to `.claude/skills/` once the skill format was validated. The validator (`validate-role-output.sh`) already checks frontmatter fields; this change adds conditional validation for skill-specific fields (`description`, `disable-model-invocation`).

---

## Requirements Analysis

### Functional Requirements
1. Validator enforces `description` and `disable-model-invocation: true` when `name` starts with `role-`
2. CR role file references `.claude/skills/role-{code}/SKILL.md` in all path-related sections
3. Format spec documents the new output convention and skill frontmatter fields
4. `/role-cr` skill Step 6 writes to `.claude/skills/role-{code}/SKILL.md`
5. CLAUDE.md and README.md reflect updated path

### Non-Functional Requirements
- All existing tests pass (backward-compatible validator changes)
- shellcheck clean on modified scripts
- No `context/roles/` references remain in active (non-historical) files

### Integration Points
- Validator: additive change — new conditional check, existing checks unchanged
- CR role: path string replacements in Constraints, Startup, Workflow sections
- Format spec: output convention paragraph + frontmatter field documentation
- Skill: Step 6 path + mkdir + frontmatter injection instructions
- Claude Code skill discovery: `.claude/skills/role-{code}/SKILL.md` is auto-discovered

---

## Implementation Details

### Architectural Approach
This is a modification issue, not greenfield. Each slice targets a specific file or file group, updating `context/roles/` references to `.claude/skills/role-{code}/SKILL.md` and adding skill frontmatter requirements where needed. The validator change is additive (conditional on `name` prefix), preserving backward compatibility.

### Design Patterns
- **Conditional validation**: Skill frontmatter fields only enforced when `name` starts with `role-` — traditional role files unaffected
- **Path convention**: `.claude/skills/role-{code}/SKILL.md` follows Claude Code's native skill discovery layout
- **Dual-purpose name field**: `name: role-{code}` serves as both role identifier and skill name

### File Structure
```
Modified:
  scripts/validate-role-output.sh          # Add skill frontmatter validation
  skills/role-init/reference/role-format.md # Update output convention
  skills/role-init/reference/cr-role-creator.md  # Update all path references
  skills/role-cr/SKILL.md                  # Update Step 6 output path
  CLAUDE.md                                # Update /role-cr description
  README.md                                # Update /role-cr description
  CHANGELOG.md                             # Add entry

New tests:
  test/skills/role_format_test.sh          # Format spec tests
  test/skills/cr_role_creator_test.sh      # CR role file tests

Extended tests:
  test/scripts/validate_role_output_test.sh  # Skill frontmatter tests
  test/skills/role_cr_test.sh              # Updated path assertions
```

### Naming Conventions
- Test files: snake_case, mirror source paths
- Skill directories: kebab-case (`role-{code}`)
- Output filename: `SKILL.md` (Claude Code convention)

---

## TDD Approach

### Slice Decomposition

The feature is broken into independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Tests | Dependencies |
|---|-------|-------|-------------|
| 1 | Validator — Skill Frontmatter Validation | 6 | None |
| 2 | Format Spec — Output Convention Update | 5 | None |
| 3 | CR Role File — Path References Update | 5 | Slice 2 |
| 4 | /role-cr SKILL.md — Output Path + Frontmatter Injection | 7 | Slices 1, 2, 3 |
| 5 | CLAUDE.md and Documentation — Path Reference Cleanup | 3 | Slice 4 |

**Total: 26 new tests across 4 test files**

---

## Dependencies

### External Packages
- None required

### Internal Dependencies
- `scripts/validate-role-output.sh` (modified in Slice 1)
- `skills/role-init/reference/role-format.md` (modified in Slice 2)
- `skills/role-init/reference/cr-role-creator.md` (modified in Slice 3)
- `skills/role-cr/SKILL.md` (modified in Slice 4)

---

## Known Limitations / Trade-offs

### Limitations
- Conditional validation triggers on `name` prefix only — a file with `name: role-foo` that is NOT intended as a skill would still be validated for skill fields
- Historical files in `explorations/` and `issues/` retain `context/roles/` references (accurate for their time)

### Trade-offs Made
- **Conditional vs. always-on validation**: Chose conditional (prefix-based) to avoid breaking non-skill role files. Trade-off: slightly more complex validator logic.
- **In-place update vs. new validator flag**: Chose in-place conditional over a `--skill-mode` flag. Simpler API, auto-detection from content.

---

## Implementation Notes

### Key Decisions
- **`name` prefix as trigger**: `role-` prefix in `name` field triggers skill frontmatter validation. This is the same prefix used in the output directory convention.
- **`disable-model-invocation: true` required**: Generated roles are reference/instruction content, not model-invocable. Enforced by validator.
- **Exploration files out of scope**: `context/roles/` references in historical exploration docs are left as-is.

### Scope Boundaries
Out of scope (historical/exploration files with `context/roles/` references):
- `explorations/features/proposed-workflow-diagrams.md`
- `explorations/features/roles/*.md`
- `issues/007-role-creator-skill.md`
- `planning/20260321_2015_role_cr_skill.md`

### Future Improvements
- `/role-ca`, `/role-cp`, `/role-ci` delivery skills that auto-discover generated role files
- `/role-evolve` that reads existing role from `.claude/skills/role-{code}/SKILL.md`

---

## References

### Related Code
- `scripts/validate-role-output.sh` — validator being extended
- `skills/role-cr/SKILL.md` — skill being updated
- `skills/role-init/reference/role-format.md` — format spec being updated
- `skills/role-init/reference/cr-role-creator.md` — CR role being updated

### Documentation
- `issues/008-role-skill-output-path.md` — issue definition
- `issues/007-role-creator-skill.md` — predecessor issue (v2.1.0)

### Issues / PRs
- Issue 008: Role Skill Output Path
- Depends on: Issue 007 (v2.1.0, merged)
- Blocks: `/role-ca`, `/role-cp`, `/role-ci`, `/role-evolve`
