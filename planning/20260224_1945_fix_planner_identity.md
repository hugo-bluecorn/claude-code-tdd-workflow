# Feature Notes: Fix tdd-planner Agent Identity Mismatch

**Created:** 2026-02-24
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose

Fix the misleading identity of the tdd-planner agent, which caused a session (CZ)
to form an incorrect mental model and manually bypass the `/tdd-plan` skill.
The agent's frontmatter says "Codebase research agent... Read-only" but it is
actually an autonomous planner with approval flows, lock-file mechanisms, and
gated Write access.

### Use Cases
- Session reads agent description before invoking to understand capabilities
- Session decides between `/tdd-plan` skill vs. manual Task tool invocation
- Agent self-identifies to caller when invoked outside the expected skill context

### Context

**Incident timeline (2026-02-24):**

1. Session CZ invoked `/tdd-plan` for Phase 2 of a C++ project
2. The skill launched `tdd-workflow:tdd-planner` as a subagent
3. CZ, reading the description "Codebase research agent... Read-only", expected
   the planner to return raw research findings only
4. The planner correctly followed its system prompt: researched, decomposed into
   slices, produced Given/When/Then specs, and attempted AskUserQuestion approval
5. CZ interpreted this as the planner "exceeding its scope"
6. CZ discarded the output, redid research manually, and built the plan itself
7. CZ bypassed the planner's approval flow, hooks, and lock-file mechanism
8. When the user questioned whether this was a bug, CZ said no — reinforcing
   the wrong mental model
9. Session CA analyzed CZ's account and proposed stripping the planner to
   research-only, which would have dismantled the existing architecture
10. Session CB reviewed the actual source files, identified the description
    mismatch as root cause, and proposed the current fix

**Root cause analysis:**

Three contributing factors:

**Factor 1 — Misleading agent description (primary root cause)**

The frontmatter description in `agents/tdd-planner.md` lines 3-6:
```
description: >
  Codebase research agent for TDD planning. Invoked automatically
  when /tdd-plan skill runs. Explores project structure, test patterns,
  and architecture to inform plan creation. Read-only.
```

Contradicts the system prompt at line 29+:
```
Your job is to research a codebase and produce a structured TDD plan.
```

And contradicts the agent's actual capabilities:
- Has `AskUserQuestion` in tools for user-facing approval
- Has approval flow with Approve/Modify/Discard options
- Has `.tdd-plan-locked` gate mechanism for write access
- Has Write permissions after approval (to `planning/` and `.tdd-progress.md`)

**Factor 2 — No invocation guardrail**

The planner is designed for exclusive invocation via `/tdd-plan`, which provides
the structured SKILL.md prompt (steps 0-10). When manually launched via Task tool:
- The SKILL.md process isn't loaded
- The agent falls back to its system prompt alone
- Output quality is lower without the skill's step ordering
- The caller expects research but gets a full plan

**Factor 3 — Incorrect architecture understanding propagated**

CZ told the user the planner is "a read-only research helper" and "an optional
accelerator for the research step." CA's incident report inherited this framing.
Both are factually wrong — the skill config (`agent: tdd-planner`,
`disable-model-invocation: true`) proves the planner IS the full planning process.

---

## Requirements Analysis

### Functional Requirements
1. Agent frontmatter description accurately says "Autonomous TDD planning agent"
2. Agent system prompt has Identity section with invocation detection
3. CLAUDE.md architecture table matches actual capabilities
4. CLAUDE.md has explicit warning against manual Task tool invocation

### Non-Functional Requirements
- All 17 existing tests continue to pass
- shellcheck passes on new test files
- No changes to hook scripts, skill config, or lock-file mechanism

### Integration Points
- `test/hooks/planner_bash_guard_test.sh` checks frontmatter fields — must not break
- `hooks/validate-plan-output.sh` checks plan archive sections — must not break
- `/tdd-implement` reads `.tdd-progress.md` — progress file format unchanged

---

## Implementation Details

### Architectural Approach

This is a labeling and guardrail fix. The planner's actual capabilities are
correct and load-bearing. We change only:
1. The description text that external consumers read
2. The agent's self-awareness of how it should be invoked
3. The documentation that guides human and LLM sessions

### Design Patterns
- **Graceful degradation**: Agent detects manual invocation and falls back to
  research-only mode instead of producing a confused full plan
- **Self-describing identity**: Agent system prompt includes explicit identity
  statement so it can correct misuse

### File Structure
```
agents/tdd-planner.md              # Frontmatter description + new Identity section
CLAUDE.md                          # Architecture table + invocation warning
test/agents/tdd_planner_identity_test.sh  # New test file (18 tests across 3 slices)
```

### Naming Conventions
- Test file: `tdd_planner_identity_test.sh` (snake_case, `_test.sh` suffix)
- Test functions: `test_<unit>_<scenario>_<expected>` per bashunit convention

---

## TDD Approach

### Slice Decomposition

The feature is broken into independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** bashunit test/agents/tdd_planner_identity_test.sh

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | Agent Frontmatter Description Fix | None |
| 2 | Agent System Prompt Identity & Invocation Guard | Slice 1 |
| 3 | CLAUDE.md Documentation Updates | Slice 2 |

---

## Dependencies

### External Packages
- bashunit: test framework (already installed)
- shellcheck: static analysis (already installed)

### Internal Dependencies
- `agents/tdd-planner.md`: primary target file
- `CLAUDE.md`: secondary target file
- `test/hooks/planner_bash_guard_test.sh`: existing tests that must continue passing

---

## Known Limitations / Trade-offs

### Limitations
- The invocation guard is prompt-level, not enforced by tooling. A session can
  still ignore the agent's "invoke via /tdd-plan" instruction. This is acceptable
  because the guard provides graceful degradation (research-only fallback) rather
  than hard blocking.
- The "## Process" marker detection is heuristic. If the skill prompt changes
  significantly, the detection instruction may need updating.

### Trade-offs Made
- **Fix labels vs. restructure architecture**: Chose to fix labels. Restructuring
  (as CA proposed) would require dismantling the approval flow, lock-file mechanism,
  hooks, and skill config — all load-bearing components working as designed.
- **Prompt-level guard vs. hook-level guard**: Chose prompt-level. A hook-based
  guard would add bash script complexity and risk breaking existing hook chains.
  The prompt-level approach is simpler and sufficient for the failure mode observed.

---

## Implementation Notes

### Key Decisions
- **Rejected CA's proposal**: Stripping planner to research-only would break the
  `agent: tdd-planner` + `disable-model-invocation: true` architecture. The planner
  IS the full planning process, not a research helper.
- **Identity section placement**: Before "## Planning Process" so the agent reads
  its identity before any task-specific instructions.
- **Graceful degradation over hard failure**: When manually invoked, the agent
  returns useful research findings instead of refusing to run.

### Future Improvements
- Consider a hook-level guard if manual invocation remains a recurring issue
- Consider adding invocation-origin metadata to the Task tool so agents can
  programmatically detect skill vs. manual invocation

---

## References

### Related Code
- `agents/tdd-planner.md` — agent definition
- `skills/tdd-plan/SKILL.md` — skill that invokes the planner
- `hooks/planner-bash-guard.sh` — command allowlist hook
- `hooks/validate-plan-output.sh` — plan output validation hook
- `test/hooks/planner_bash_guard_test.sh` — existing planner tests (must not break)

### Issues
- `issues/001-planner-scope-creep.md` — CA's incident report (correct symptoms, wrong fix)
- `planning/drafts/fix-planner-identity-prompt-v1.md` — CB's analysis and prompt draft
