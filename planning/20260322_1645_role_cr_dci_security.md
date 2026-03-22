# Feature Notes: /role-cr DCI Security Boundary Fix

**Created:** 2026-03-22
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Fix the `/role-cr` skill's silent failure when Claude Code blocks `cat` DCI commands targeting paths outside the project directory. Replace the two `cat` DCI invocations with a single `load-role-references.sh` script that resolves paths relative to its own location, following the established pattern from `load-conventions.sh`.

### Use Cases
- User installs the plugin via marketplace and runs `/role-cr` — reference files load correctly regardless of where the plugin cache lives relative to the project
- Developer using `--plugin-dir` also gets correct behavior since the script resolves via `SCRIPT_DIR`

### Context
The `project-conventions` skill already solved this problem with `load-conventions.sh`. The `/role-cr` skill was written before this pattern was established and used raw `cat` DCI commands. Issue 009 brings `/role-cr` in line with the established convention.

---

## Requirements Analysis

### Functional Requirements
1. `scripts/load-role-references.sh` outputs both `cr-role-creator.md` and `role-format.md` content
2. `/role-cr` SKILL.md uses the script via DCI instead of two `cat` commands
3. DCI injection works regardless of project/plugin-cache relative paths

### Non-Functional Requirements
- shellcheck clean on new script
- All existing tests pass (no regressions)
- Follows established `load-conventions.sh` pattern

### Integration Points
- Consumes: `skills/role-init/reference/cr-role-creator.md`, `skills/role-init/reference/role-format.md` (read-only)
- Pattern precedent: `scripts/load-conventions.sh`, `skills/project-conventions/SKILL.md`
- Modified: `skills/role-cr/SKILL.md` (DCI command replacement)

---

## Implementation Details

### Architectural Approach
Simple pattern replication: create a script that resolves its own location (`SCRIPT_DIR`), derives the plugin root, and `cat`s both reference files with a `---` separator. The SKILL.md then invokes this script via DCI instead of using raw `cat` commands.

### Design Patterns
- **SCRIPT_DIR resolution**: `$(cd "$(dirname "$0")" && pwd)` — portable, no dependency on env vars
- **Single DCI invocation**: One script replaces two `cat` commands — simpler and smaller DCI surface
- **Separator convention**: `---` between files, same as used in other multi-file outputs

### File Structure
```
New:
  scripts/load-role-references.sh           # Outputs both reference files
  test/scripts/load_role_references_test.sh  # 7 tests

Modified:
  skills/role-cr/SKILL.md                   # Replace cat DCI with script DCI
  test/skills/role_cr_test.sh               # Update DCI assertion tests
```

### Naming Conventions
- Script: `load-role-references.sh` (kebab-case, matches `load-conventions.sh`)
- Test: `load_role_references_test.sh` (snake_case, mirrors source path)

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
| 1 | load-role-references.sh script | 7 | None |
| 2 | Update /role-cr SKILL.md DCI commands | 6 | Slice 1 |

**Total: 13 tests across 2 test files**

---

## Dependencies

### External Packages
- None required

### Internal Dependencies
- `skills/role-init/reference/cr-role-creator.md` (read-only, stable)
- `skills/role-init/reference/role-format.md` (read-only, stable)
- `scripts/load-conventions.sh` (pattern reference only, not runtime)

---

## Known Limitations / Trade-offs

### Limitations
- The script hardcodes the relative path from `scripts/` to `skills/role-init/reference/` — if the directory structure changes, the script breaks (acceptable: plugin structure is stable)

### Trade-offs Made
- **Single script vs. two scripts**: Chose single script for simplicity. Both files are always needed together by `/role-cr`, so there's no benefit to separate scripts.
- **SCRIPT_DIR vs. CLAUDE_PLUGIN_ROOT**: Chose SCRIPT_DIR for reliability. CLAUDE_PLUGIN_ROOT may not be set in all contexts (e.g., direct script testing).

---

## Implementation Notes

### Key Decisions
- **SCRIPT_DIR pattern**: Resolves paths relative to the script's own location, not CWD or env vars
- **Separator**: `---` between the two file outputs, CR role first, format spec second
- **Descriptive text preserved**: SKILL.md still mentions both filenames in Step 1 headings for human readability

### Future Improvements
- None anticipated — this is a targeted fix with a well-established pattern

---

## References

### Related Code
- `scripts/load-conventions.sh` — pattern being replicated
- `skills/project-conventions/SKILL.md` — DCI script invocation pattern
- `skills/role-cr/SKILL.md` — file being modified
- `test/skills/role_cr_test.sh` — existing tests being updated

### Documentation
- `issues/009-role-cr-dci-security-boundary.md` — issue definition

### Issues / PRs
- Issue 009: /role-cr DCI Security Boundary Fix
- Depends on: Issue 008 (v2.2.0, merged)
