# Feature Notes: Restructure tdd-plan to Inline Orchestration

**Created:** 2026-03-01
**Approved:** 2026-03-01T18:45:00-06:00

---

## Overview

Restructure the `/tdd-plan` workflow to move approval and file-writing from the tdd-planner subagent to the main thread. The planner becomes a pure read-only researcher, and the skill runs inline — matching the built-in plan mode pattern and the existing `/tdd-implement` skill.

### Use Cases
- User runs `/tdd-plan <feature>` — main thread orchestrates planner subagent, presents plan, handles approval, writes files
- User chooses "Modify" — main thread resumes planner with feedback, preserving research context
- User chooses "Discard" — main thread stops, no files written

### Context
- Discovered during plugin-dev evaluation session (v1.10.0)
- Core problem: planner subagent was doing main-thread work (approval, file writing) inside a forked context
- AskUserQuestion calls skipped under auto-compaction at 95%+ context usage
- Multiple layers of lock/retry/guard machinery built to compensate

---

## Requirements Analysis

### Functional Requirements
- tdd-plan skill runs inline (no `context: fork`)
- Main thread spawns planner as read-only subagent, handles approval, writes files
- Planner returns structured plan text with full Given/When/Then formatting
- Lock file mechanism entirely eliminated
- validate-plan-output.sh becomes standalone utility
- planner-bash-guard.sh simplified to pure read-only allowlist

### Non-Functional Requirements
- Pattern matches tdd-implement skill structure
- All non-planner hooks and tests unchanged
- shellcheck passes on modified scripts

### Integration Points
- `/tdd-implement` reads `.tdd-progress.md` — format unchanged
- `check-tdd-progress.sh` Stop hook — checks `.tdd-progress.md` — unchanged
- Convention skills auto-loaded by planner agent — unchanged

---

## Implementation Details

### Architectural Approach
**Inline orchestration** — the tdd-plan skill body becomes instructions for the main thread (like tdd-implement). The main thread:
1. Gathers git context
2. Spawns tdd-planner as research subagent via Agent tool
3. Presents returned plan text
4. Calls AskUserQuestion (Approve/Modify/Discard)
5. Writes `.tdd-progress.md` and `planning/` archive after approval

### Design Patterns
- **Inline orchestration** (from tdd-implement): main thread owns user interaction and file I/O
- **Research subagent** (from built-in plan mode): planner is purely read-only, returns text
- **Agent resume** (for Modify flow): preserves planner's research context across revisions

### Planner Output Contract
The planner body contains the full output format specification:
- Convention loading instructions (current SKILL.md steps 0, 5)
- Given/When/Then slice structure template (step 6)
- Self-check requirements (step 7)
- detect-project-context.sh invocation (research step)

The skill body does NOT duplicate these — it passes `$ARGUMENTS` + git context to the planner and receives formatted output.

### File Structure

**Modified files:**
- `skills/tdd-plan/SKILL.md` — inline orchestration (remove fork/agent)
- `agents/tdd-planner.md` — pure researcher (remove approval flow)
- `hooks/planner-bash-guard.sh` — simplified (remove lock gate, rm exception)
- `hooks/validate-plan-output.sh` — standalone validator (remove lock/retry)
- `hooks/hooks.json` — remove planner SubagentStart/SubagentStop
- `CLAUDE.md` — update architecture table and invocation warning
- `docs/plugin-developer-prompt.md` — update architecture description

**New files:**
- `test/skills/tdd_plan_test.sh` — tests for rewritten skill

**Deleted test content:**
- ~50 tests across 5 test files (lock mechanism tests)

### Naming Conventions
- Test files: `snake_case` with `_test.sh` suffix
- Test functions: `test_<unit>_<scenario>_<expected_behavior>`

---

## TDD Approach

### Slice Decomposition
6 slices, ordered by dependency (foundations first):

| Slice | Name | Source | Depends On |
|-------|------|--------|------------|
| 1 | Simplify planner-bash-guard.sh | `hooks/planner-bash-guard.sh` | none |
| 2 | Simplify validate-plan-output.sh | `hooks/validate-plan-output.sh` | none |
| 3 | Remove planner hooks from hooks.json | `hooks/hooks.json` | none |
| 4 | Simplify tdd-planner.md | `agents/tdd-planner.md` | 1, 2, 3 |
| 5 | Rewrite tdd-plan SKILL.md | `skills/tdd-plan/SKILL.md` | 4 |
| 6 | Update documentation | `CLAUDE.md`, `docs/plugin-developer-prompt.md` | 5 |

### Test Framework
- bashunit for unit tests
- shellcheck for static analysis
- jq for JSON validation

See `.tdd-progress.md` for live slice status and detailed test specifications.

---

## Dependencies

### External Packages
- bashunit (test runner)
- shellcheck (static analysis)
- jq (JSON processing)

### Internal Dependencies
- `skills/tdd-implement/SKILL.md` — reference pattern for inline orchestration
- `hooks/check-tdd-progress.sh` — unchanged, reads .tdd-progress.md
- Convention skills — unchanged, auto-loaded by planner

---

## Known Limitations / Trade-offs

### Limitations
- Skill body tests (Slice 5) are keyword-presence checks, not flow validation — bash-level testing of skill orchestration is inherently limited
- The planner's output format depends on prompt-following, not structural enforcement — same limitation as before, but now the planner body owns the format spec directly

### Trade-offs
- **Planner body becomes longer** (absorbs format instructions from SKILL.md) vs **skill body becomes shorter** (pure orchestration) — net complexity reduction
- **Agent resume for Modify flow** requires the Agent tool's resume parameter — this is a system capability dependency
- **validate-plan-output.sh loses hook compatibility** (no stdin JSON parsing) — acceptable since it's no longer used as a hook

---

## Implementation Notes

### Key Decisions
1. Format instructions live in planner body (not duplicated in skill)
2. detect-project-context.sh called by planner (research step, not orchestration step)
3. validate-plan-output.sh repurposed as utility (not a hook)
4. planner-bash-guard.sh allows only /dev/null as redirect target (no planning/ exception)

### What Gets Eliminated
~140 lines of lock/retry/guard machinery:
- .tdd-plan-locked mechanism
- .tdd-plan-approval-retries counter
- validate-plan-output.sh Layers 1-2 (lock checking + retry enforcement)
- SubagentStart/SubagentStop hooks for planner
- Lock gate and rm exception in bash guard
- Compaction guard in agent prompt

---

## References

- **Spec:** `issues/planner-restructure-proposal.md`
- **Reference pattern:** `skills/tdd-implement/SKILL.md`
- **Live status:** `.tdd-progress.md`
- **Related issues:** `issues/001-planner-scope-creep.md`, `planning/20260228_1030_fix_approval_reliability.md`
