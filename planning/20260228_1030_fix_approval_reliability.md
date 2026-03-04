# Feature Notes: Fix tdd-planner AskUserQuestion Approval Reliability

**Created:** 2026-02-28
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Fix the unreliable AskUserQuestion approval call in the tdd-planner agent. After large research sessions (36+ tool uses, 66k+ tokens), auto-compaction strips the instruction to call AskUserQuestion. The agent outputs text asking for approval instead of using the tool, breaking the approval flow.

### Use Cases
- User runs `/tdd-plan` for a large feature requiring extensive codebase research
- Auto-compaction fires at ~95% context capacity, compressing away step 9's AskUserQuestion instruction
- Agent outputs text "Do you approve?" instead of calling the AskUserQuestion tool
- Parent agent resumes the planner, but `.tdd-plan-locked` was already destroyed by the stop hook
- Resumed agent again outputs text (0 tool uses) — cycle repeats with no recovery

### Context
The existing safety mechanisms from the Feb 20 "compaction cascade" fix are entirely behavioral (prompt-based compaction guard) or structural but flawed (lock file that's unconditionally removed). The compressor optimizes for task completion, not procedural constraints, so prompt-based gates are unreliable after compaction. The stop hook destroys the lock file (the "ground truth") before it can be used for enforcement.

---

## Requirements Analysis

### Functional Requirements
1. Stop hook must detect when agent stops without AskUserQuestion approval and block with actionable feedback
2. Retry counter must prevent infinite blocking (max 2 retries before cleanup)
3. Lock file must be preserved during retries so bash guard continues enforcement
4. Discard path must remove lock file to distinguish "user chose Discard" from "agent forgot AskUserQuestion"
5. Post-compaction reminder must instruct agent to use AskUserQuestion tool (not text output)

### Non-Functional Requirements
- All existing tests pass (with updates for changed behavior)
- shellcheck passes on modified hook scripts
- Post-compaction reminder is concise (minimal token overhead per user feedback)
- `.tdd-plan-approval-retries` artifact tracked in .gitignore

### Integration Points
- `hooks/validate-plan-output.sh` — SubagentStop hook for tdd-planner (primary fix target)
- `hooks/hooks.json` — SubagentStart hook configuration (retry counter cleanup)
- `skills/tdd-plan/SKILL.md` — Planning skill prompt (Discard path fix)
- `agents/tdd-planner.md` — Agent system prompt (Discard fix + reminder)
- `test/hooks/validate_plan_output_test.sh` — Test file (updates + new tests)

---

## Implementation Details

### Architectural Approach
The fix follows the plugin's "structural over behavioral" principle established in the Feb 20 cascade fix:

1. **Structural gate (Slice 1)**: `validate-plan-output.sh` checks if `.tdd-plan-locked` exists when the agent stops. If it does, the agent stopped without completing the approval flow → block stop with clear AskUserQuestion feedback. A retry counter (`.tdd-plan-approval-retries`) prevents infinite blocking (max 2 retries).

2. **Discard disambiguation (Slice 2)**: The Discard path in both SKILL.md and tdd-planner.md now removes `.tdd-plan-locked`. This means lock-present at stop time reliably indicates a failure case (not a legitimate discard).

3. **Compaction resilience (Slice 2)**: A concise (2-3 line) post-compaction reminder at the END of the agent prompt reminds to use AskUserQuestion. Positioned last to maximize survival through compaction. This is belt-and-suspenders — the structural fix in Slice 1 is what actually solves the problem.

### Design Patterns
- **Defense-in-depth**: Multiple independent layers, each sufficient to catch the failure
- **Filesystem as ground truth**: Lock file and retry counter persist across compaction
- **Fresh-per-call hooks**: Stop hook runs as a new process, unaffected by compaction
- **Retry with safety valve**: Finite retries prevent infinite loops

### File Structure
```
hooks/
  validate-plan-output.sh     # Modified: lock-conditional logic + retry counter
  hooks.json                  # Modified: SubagentStart retry counter cleanup
skills/
  tdd-plan/SKILL.md           # Modified: Discard path lock removal
agents/
  tdd-planner.md              # Modified: Discard lock removal + post-compaction reminder
test/hooks/
  validate_plan_output_test.sh # Modified: updated + ~10 new tests
```

### Naming Conventions
Follows existing project conventions: snake_case for test files, kebab-case for hook scripts, test functions prefixed with `test_`.

---

## TDD Approach

### Slice Decomposition

The feature is broken into 3 independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** ./lib/bashunit test/hooks/validate_plan_output_test.sh

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | validate-plan-output.sh — Approval Enforcement Gate | None |
| 2 | Prompt Updates — Discard Lock Removal + AskUserQuestion Reminder | Slice 1 |
| 3 | hooks.json Update + Checksum Update + Full Regression | Slices 1, 2 |

---

## Dependencies

### External Packages
- bashunit: Test framework (already installed at `lib/bashunit`)
- shellcheck: Static analysis (already installed)
- jq: JSON processing in hooks (already a dependency)

### Internal Dependencies
- `hooks/validate-plan-output.sh`: Primary fix target (Slice 1)
- `hooks/hooks.json`: SubagentStart config (Slice 3)
- `skills/tdd-plan/SKILL.md`: Discard path (Slice 2)
- `agents/tdd-planner.md`: Discard path + reminder (Slice 2)

---

## Known Limitations / Trade-offs

### Limitations
- Prompt-based post-compaction reminder (behavioral layer) does NOT survive compaction — it exists only as belt-and-suspenders alongside the structural gate
- Retry counter uses relative path (`.tdd-plan-approval-retries`) — assumes cwd is project root (same assumption as `.tdd-plan-locked`)
- Max 2 retries is a heuristic — after 2 failed retries, the agent is unlikely to recover

### Trade-offs Made
- **Retry counter (2 retries) over infinite blocking**: After 2 attempts, the agent likely cannot recover from compaction. Better to allow cleanup than trap the user.
- **Concise reminder over comprehensive prompt**: Per user feedback, keep the post-compaction reminder to 2-3 lines to minimize token overhead on every planner invocation.
- **Lock removal in Discard path**: Requires prompt change (behavioral), but makes the structural gate reliable by eliminating ambiguity.

---

## Implementation Notes

### Key Decisions
- **Lock check ordering**: `stop_hook_active` checked first (prevents infinite loops), then lock existence, then normal validation
- **Retry counter as file**: Simple, persists across subagent restarts, cleaned up by SubagentStart for fresh sessions
- **No SubagentStop hook type change**: Keeping `command` type (not `prompt`) — stderr output from exit 2 is shown to agent as feedback

### Future Improvements
- Could add a `PreCompact` hook to inject AskUserQuestion reminder before compaction (if Claude Code adds per-agent PreCompact support)
- Could track which step the agent reached via breadcrumb files (e.g., `.tdd-plan-step`) for more targeted stop hook feedback

### Potential Refactoring
- The validate-plan-output.sh script's growing complexity (lock check + retry counter + plan validation + section check + refactoring leak) may warrant extracting into helper functions — left for implementer to decide

---

## References

### Related Code
- `hooks/validate-plan-output.sh` — current stop hook (primary fix target)
- `hooks/planner-bash-guard.sh` — bash guard (NOT modified, but referenced for understanding)
- `hooks/hooks.json` — hook configuration
- `test/hooks/validate_plan_output_test.sh` — existing 30 tests
- `planning/20260220_1200_fix_compaction_unapproved_plan_cascade.md` — prior fix (established structural-over-behavioral principle)

### Documentation
- Field test output showing the failure (provided in user's bug report)
- CLAUDE.md Plugin Architecture table

### Issues / PRs
- None (internal fix)
