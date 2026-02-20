# Feature Notes: Fix auto-compaction unapproved plan cascade

**Created:** 2026-02-20
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Fix a cascade of 5 bugs where Claude Code's auto-compaction during `/tdd-plan` causes the planner agent to lose the mandatory approval step, write `.tdd-progress.md` directly, and trigger automatic implementation of an unapproved plan via the stop hook's imperative language.

### Use Cases
- User runs `/tdd-plan` for a large feature requiring 19+ tool uses and ~30k tokens of research
- Auto-compaction fires mid-planning, compressing away the approval instructions
- Planner writes `.tdd-progress.md` via `cat | tee` (bypassing bash guard's `>` redirect check)
- Stop hook fires "Continue implementing." — an imperative treated as instruction
- Continuation session runs `/tdd-implement` on the unapproved plan

### Context
The existing safety mechanisms are entirely behavioral (prompt-based). The compressor optimizes for task completion, not procedural constraints, so prompt-based gates are unreliable after compaction. The fix implements structural gates (filesystem locks + hooks that run fresh per call) as the primary defense, keeping prompt guards as a soft backup layer.

---

## Requirements Analysis

### Functional Requirements
1. Pipe-to-file patterns (`| tee`, `| sponge`) must be blocked by the planner bash guard
2. A `.tdd-plan-locked` file must block all writes to `.tdd-progress.md` until explicit approval
3. `rm .tdd-plan-locked` must be allowed as a targeted exception (prevents deadlock)
4. Lock must be created on SubagentStart and cleaned up unconditionally on SubagentStop
5. Plans without an `Approved:` marker must allow session exit (don't trap user)
6. Stop hook must use non-imperative messaging for all remaining-slices scenarios
7. `tdd-implement` must verify the `Approved:` marker before starting
8. Prompt-based compaction guard must reference the lock file as ground truth

### Non-Functional Requirements
- All hooks pass `shellcheck -S warning`
- All existing tests pass without modification (except checksum updates)
- Defense layers documented in code comments

### Integration Points
- `hooks/planner-bash-guard.sh` — PreToolUse hook for tdd-planner Bash commands
- `hooks/hooks.json` — SubagentStart/SubagentStop hook configuration
- `hooks/validate-plan-output.sh` — SubagentStop hook for tdd-planner
- `hooks/check-tdd-progress.sh` — Stop hook preventing premature session end
- `skills/tdd-plan/SKILL.md` — Planning skill prompt
- `agents/tdd-planner.md` — Planner agent prompt
- `skills/tdd-implement/SKILL.md` — Implementation skill prompt

---

## Implementation Details

### Architectural Approach
The fix follows a "structural over behavioral" principle: filesystem-based gates that survive context compaction are the primary defense. Prompt-based guards are kept as belt-and-suspenders.

The cascade is broken at multiple points:
1. **Pipe bypass** — `| tee` detected and blocked (Bug 1)
2. **Lock gate** — `.tdd-plan-locked` prevents `.tdd-progress.md` writes (Bug 2)
3. **Lock lifecycle** — created on start, cleaned on stop (supports lock gate)
4. **Approval marker** — `Approved:` line in `.tdd-progress.md` for downstream validation (Bug 5)
5. **Messaging** — non-imperative stop hook messages (Bugs 3+4)
6. **Compaction guard** — prompt text referencing lock file as ground truth (soft defense for Bug 2)

### Design Patterns
- **Defense-in-depth**: Multiple independent layers, each sufficient to break the cascade alone
- **Filesystem as ground truth**: Lock file and approval marker persist across compaction
- **Fresh-per-call hooks**: Bash guard and stop hook run as new processes, unaffected by compaction

### File Structure
```
hooks/
  planner-bash-guard.sh     # Modified: pipe bypass + lock gate + rm exception
  hooks.json                # Modified: SubagentStart creates lock
  validate-plan-output.sh   # Modified: cleanup lock on stop
  check-tdd-progress.sh     # Modified: approval check + messaging
skills/
  tdd-plan/SKILL.md         # Modified: compaction guard + lock removal + Approved header
  tdd-implement/SKILL.md    # Modified: Step -1 approval verification
agents/
  tdd-planner.md            # Modified: mirror SKILL.md changes
test/hooks/
  planner_bash_guard_test.sh     # Modified: ~10 new tests + checksum updates
  check_tdd_progress_test.sh     # Modified: ~7 new tests
  validate_plan_output_test.sh   # Modified: ~4 new tests
```

### Naming Conventions
Follows existing project conventions: snake_case for test files, kebab-case for hook scripts, test functions prefixed with `test_`.

---

## TDD Approach

### Slice Decomposition

The feature is broken into 6 independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** bashunit test/hooks/

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | Pipe bypass detection in bash guard | None |
| 2 | Lock-file gate + rm exception in bash guard | Slice 1 |
| 3 | Lock lifecycle — creation and cleanup | Slice 2 |
| 4 | Approval marker + simplified messaging | None |
| 5 | Prompt updates — approval flow | Slices 2, 3 |
| 6 | Update hook checksums | Slices 1-5 |

---

## Dependencies

### External Packages
- bashunit: Test framework (already installed)
- shellcheck: Static analysis (already installed)
- jq: JSON processing in hooks (already a dependency)

### Internal Dependencies
- `hooks/planner-bash-guard.sh`: Modified in Slices 1-2
- `hooks/validate-plan-output.sh`: Modified in Slice 3
- `hooks/check-tdd-progress.sh`: Modified in Slice 4
- `hooks/hooks.json`: Modified in Slice 3

---

## Known Limitations / Trade-offs

### Limitations
- Prompt-based compaction guard (soft defense) does NOT survive compaction — it exists only as belt-and-suspenders alongside the structural gates
- Lock file check uses relative path (`.tdd-plan-locked`) — assumes cwd is project root

### Trade-offs Made
- **Structural gates over simplicity**: Adding filesystem locks increases complexity but provides compaction-proof safety
- **Option A for Slice 4**: Dropped TERMINAL_SLICES sub-branching in favor of using the Approved marker as the sole phase indicator — simpler logic, fewer edge cases, no contradictory messaging
- **rm exception specificity**: Only `rm .tdd-plan-locked` and `rm -f .tdd-plan-locked` are allowed — prevents the rm exception from becoming a general escape hatch

---

## Implementation Notes

### Key Decisions
- **Lock cleanup ordering**: `rm -f .tdd-plan-locked` runs BEFORE the `stop_hook_active` guard in validate-plan-output.sh — placed after would skip cleanup due to early exit
- **Pipe detection**: Checks for `| tee` and `| sponge` patterns — covers the two common pipe-to-file utilities
- **Approval marker format**: `**Approved:** <ISO timestamp>` — bold markdown with flexible value, checked with case-insensitive regex

### Future Improvements
- Could add a `--force` flag to `/tdd-implement` to bypass the approval check for expert users
- Could persist lock file path in a config rather than hardcoding `.tdd-plan-locked`

### Potential Refactoring
- The bash guard's growing complexity (allowlist + redirect check + pipe check + lock gate + rm exception) may warrant extracting into helper functions — left for implementer to decide at implementation time

---

## References

### Related Code
- `hooks/planner-bash-guard.sh` — existing bash command allowlist
- `hooks/check-tdd-progress.sh` — existing stop hook
- `hooks/validate-plan-output.sh` — existing planner stop hook
- `test/hooks/planner_bash_guard_test.sh` — existing guard tests
- `test/hooks/check_tdd_progress_test.sh` — existing stop hook tests
- `test/hooks/validate_plan_output_test.sh` — existing validation tests

### Documentation
- Original plan: `/home/hugo-bluecorn/.claude/plans/misty-giggling-dawn.md`

### Issues / PRs
- None (internal fix)
