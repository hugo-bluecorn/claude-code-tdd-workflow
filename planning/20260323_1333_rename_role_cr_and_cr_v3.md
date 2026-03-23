# Feature Notes: Rename /role-cr to /role-create and Update CR Definition to v3

**Created:** 2026-03-23
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
The `/role-cr` skill name violates the established `prefix-verb` naming convention for skills (§2.2 of the validation report). Skills should use verbs (`tdd-plan`, `tdd-implement`), while agents use nouns (`tdd-planner`, `tdd-implementer`). `/role-cr` is an abbreviation, not a verb. The correct name is `/role-create`.

Additionally, the CR role definition at `skills/role-init/reference/cr-role-creator.md` is v2 (hand-refined). Experiment A of the self-compilation study produced a v3 that is measurably better on 6 of 9 evaluation criteria.

### Use Cases
- Developer invokes `/role-create` to generate a role file (renamed from `/role-cr`)
- Developer reads documentation and finds consistent naming throughout
- Future role generator improvements build on v3's improved structure

### Context
The `/role-cr` skill was introduced in Issue 010 (v2.3.0). It spawns the `role-creator` agent to generate role files. The agent name (`role-creator`, a noun) already follows convention — only the skill name needs updating. The v3 CR definition was validated in the self-compilation experiment (Experiment A) and is available on the `experiment/cr-v3-definition` branch.

---

## Requirements Analysis

### Functional Requirements
1. Rename `skills/role-cr/` directory to `skills/role-create/`
2. Update SKILL.md frontmatter `name:` field to `role-create`
3. Replace `cr-role-creator.md` content with v3 from experiment branch
4. Update `agents/role-creator.md` references from `/role-cr` to `/role-create`
5. Update all documentation files (CLAUDE.md, README.md, user-guide.md)
6. Update all test files referencing old paths/names
7. Update `scripts/load-role-references.sh` comments
8. Ensure generated roles use `generator: /role-create`

### Non-Functional Requirements
- shellcheck clean on all modified scripts
- All 757+ existing tests pass
- No stale `/role-cr` references in non-historical files

### Integration Points
- Skill invocation: `/role-create` replaces `/role-cr` as the user-facing command
- Agent spawning: `role-creator` agent is spawned by the renamed skill
- Role output: generated role files will have `generator: /role-create` in frontmatter
- Reference loading: `load-role-references.sh` loads the v3 CR definition

---

## Implementation Details

### Architectural Approach
This is a rename-and-update task, not a new feature. The approach is:
1. Rename the skill directory and update its frontmatter
2. Replace the CR definition content with v3
3. Update all references across the codebase
4. Update all tests to match new paths/names

The key constraint is that historical files (issues/, planning/, docs/experimental-results/) must NOT be modified — they are accurate for their time period.

### Design Patterns
- **Convention compliance**: `prefix-verb` for skills, `prefix-noun` for agents
- **Version progression**: CR definition v2 → v3 with measurable improvements

### File Structure
```
skills/
├── role-create/           ← renamed from role-cr/
│   └── SKILL.md           ← name: role-create
└── role-init/
    └── reference/
        └── cr-role-creator.md  ← v3 content

agents/
└── role-creator.md        ← references /role-create

test/
├── skills/
│   ├── role_create_test.sh    ← renamed from role_cr_test.sh
│   ├── role_docs_test.sh      ← updated references
│   └── cr_role_creator_test.sh ← updated for v3 content
├── agents/
│   └── role_creator_test.sh   ← updated references
└── scripts/
    └── load_role_references_test.sh ← updated references
```

### Naming Conventions
- Skill directories: kebab-case (`role-create`)
- Test files: snake_case (`role_create_test.sh`)
- Source files mirror in test directory structure

---

## TDD Approach

### Slice Decomposition

The feature is broken into independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit (`./lib/bashunit test/`)
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | Skill Directory Rename and SKILL.md Update | None |
| 2 | CR Definition v3 Content Update | None |
| 3 | Agent Body and Script Comment Updates | Slice 1, 2 |
| 4 | Documentation Updates (CLAUDE.md, README.md, user-guide.md) | Slice 1 |
| 5 | Test File Updates and Sweep | Slice 1, 2, 3, 4 |

---

## Dependencies

### External Packages
- None required

### Internal Dependencies
- Content from `experiment/cr-v3-definition` branch for v3 CR definition
- Existing test infrastructure (bashunit, shellcheck)

---

## Known Limitations / Trade-offs

### Limitations
- Cohort role files (role-ca, role-ci, role-cp) still reference `/role-cr` in their `generator:` field — regeneration is a separate step after this ships
- Historical documentation files retain `/role-cr` references — this is intentional

### Trade-offs Made
- **Rename test file vs. update in place**: Chose to rename `role_cr_test.sh` to `role_create_test.sh` for consistency with the convention of mirroring source names, even though updating in place would be simpler
- **v3 content from experiment branch**: Taking the experiment branch content as-is (with `generator:` field update) rather than re-running the CR to generate fresh v3 content

---

## Implementation Notes

### Key Decisions
- **Historical file exclusion**: Files in `issues/`, `planning/`, `docs/experimental-results/`, and `explorations/` are not modified — they are accurate for the time they were written
- **Generator field update**: The v3 content from the experiment branch has `generator: /role-cr` which must be changed to `generator: /role-create`
- **validate-role-output.sh**: Has no `/role-cr` references — no changes needed
- **load-role-references.sh**: Only comments reference `/role-cr`, not logic — comment update only

### Future Improvements
- Regenerate cohort roles (role-ca, role-ci, role-cp) with `/role-create` after this ships
- Consider `/role-evolve` for memory-driven role refinement (backlog item)

### Potential Refactoring
- Left for implementer to decide at implementation time per TDD rules

---

## References

### Related Code
- `skills/role-cr/SKILL.md` — current skill file (to be renamed)
- `skills/role-init/reference/cr-role-creator.md` — current v2 CR definition
- `agents/role-creator.md` — agent that the skill spawns
- `scripts/load-role-references.sh` — loads CR definition and format spec

### Documentation
- `docs/experimental-results/role-cr-self-compilation.md` — self-compilation study with v3 results
- `issues/011-rename-role-cr-and-update-cr-v3.md` — issue specification

### Issues / PRs
- Issue 011: Rename /role-cr → /role-create + Update CR Definition to v3
- Depends on: `experiment/cr-v3-definition` branch
- Blocks: Cohort role regeneration (separate step)
