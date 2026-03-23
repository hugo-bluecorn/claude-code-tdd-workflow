# Feature Notes: Split /role-cr into Skill + Agent (Issue 010)

**Created:** 2026-03-23
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Eliminate DCI permission prompts that break the `/role-cr` procedural chain by splitting the monolithic inline skill into a thin orchestration skill + a read-only `role-creator` agent. The agent reads reference files via Bash `cat ${CLAUDE_PLUGIN_ROOT}/...` (which resolves the env var at execution time), while the skill handles only conversational input and approval.

### Use Cases
- User runs `/role-cr` → skill gathers input conversationally → spawns role-creator agent → agent researches, generates, validates → skill presents output → user approves → skill writes to `.claude/skills/role-{code}/SKILL.md`
- User requests modifications → skill re-spawns agent with feedback → iterate until approved or rejected
- Agent handles all mechanical work (read references, research project, critique, generate, validate) without any permission prompts

### Context
Issues 007-009 iteratively built `/role-cr`: inline skill (007), output path change (008), DCI security fix (009). Despite Issue 009's fix, DCI still causes permission prompts in some configurations. This issue eliminates DCI entirely by moving to the proven skill+agent pattern used by `/tdd-plan` + `tdd-planner`. The key insight from CA: `${CLAUDE_PLUGIN_ROOT}` only resolves in Bash commands, not in Read tool paths or agent body text.

---

## Requirements Analysis

### Functional Requirements
1. New `agents/role-creator.md` with Read, Bash, Glob, Grep, WebSearch, WebFetch tools (no Write/Edit)
2. Agent reads references via `Bash: cat ${CLAUDE_PLUGIN_ROOT}/...` (not Read tool, not DCI)
3. Agent runs `validate-role-output.sh` via Bash and returns only validated content
4. Rewritten `skills/role-cr/SKILL.md` with zero DCI commands
5. Skill orchestrates: gather input → spawn agent → present → approve/modify/reject → write on approve
6. CLAUDE.md documents the new agent in the architecture table

### Non-Functional Requirements
- All existing tests pass (no regressions)
- shellcheck clean
- No permission prompts from skill or agent

### Integration Points
- Agent reads: `skills/role-init/reference/cr-role-creator.md`, `skills/role-init/reference/role-format.md` (via Bash cat)
- Agent runs: `scripts/validate-role-output.sh` (via Bash)
- Skill spawns: `role-creator` agent (via Agent tool)
- Skill writes: `.claude/skills/role-{code}/SKILL.md` (after approval)
- `load-role-references.sh` becomes unused (out of scope to remove)

---

## Implementation Details

### Architectural Approach
Direct replication of the `/tdd-plan` + `tdd-planner` pattern:

1. **Thin skill** (`skills/role-cr/SKILL.md`): Gathers developer input conversationally, spawns the agent with a structured prompt, presents output, runs approval gate, writes to disk on approve.

2. **Read-only agent** (`agents/role-creator.md`): Reads CR role definition and format spec via Bash `cat`, researches the target project, generates a role file following the spec, self-critiques, validates via `validate-role-output.sh`, returns the validated content as text.

### Design Patterns
- **Skill+Agent split**: Same as tdd-plan/tdd-planner — skill owns conversation, agent owns procedure
- **Bash for env var resolution**: `${CLAUDE_PLUGIN_ROOT}` only resolves in Bash commands, so reference files must be read via `cat`, not Read tool
- **No DCI**: Eliminates the root cause of permission prompts entirely
- **Read-only agent**: Tools allowlist (no Write/Edit) mechanically prevents the agent from writing files

### File Structure
```
New:
  agents/role-creator.md                    # Read-only agent definition
  test/agents/role_creator_test.sh          # 22 tests (slices 1, 2, 5)

Rewritten:
  skills/role-cr/SKILL.md                   # Thin orchestration skill
  test/skills/role_cr_test.sh               # 20 tests (slices 3, 4)

Updated:
  CLAUDE.md                                 # Architecture table + command docs
```

### Naming Conventions
- Agent: `role-creator` (kebab-case, matches `tdd-planner`, `tdd-implementer` pattern)
- Test: `role_creator_test.sh` (snake_case, mirrors source path)

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
| 1 | Agent frontmatter | 11 | None |
| 2 | Agent body content | 11 | Slice 1 |
| 3 | Skill frontmatter + DCI removal | 7 | None |
| 4 | Skill orchestration body | 13 | Slices 1, 2, 3 |
| 5 | CLAUDE.md documentation | 6 | Slices 1, 4 |

**Total: 48 tests across 2 test files**

---

## Dependencies

### External Packages
- None required

### Internal Dependencies
- `skills/role-init/reference/cr-role-creator.md` (read by agent, unchanged)
- `skills/role-init/reference/role-format.md` (read by agent, unchanged)
- `scripts/validate-role-output.sh` (invoked by agent, unchanged)

---

## Known Limitations / Trade-offs

### Limitations
- `load-role-references.sh` becomes dead code after this change (out of scope to remove — separate cleanup)
- Agent uses Bash `cat` instead of Read tool for reference files due to env var resolution constraint

### Trade-offs Made
- **Bash cat vs. Read tool for references**: Chose Bash cat because `${CLAUDE_PLUGIN_ROOT}` only resolves in shell commands. Read tool would receive the literal string `${CLAUDE_PLUGIN_ROOT}` unexpanded.
- **Agent has WebSearch/WebFetch**: CR workflow step 4 (RTFM research) requires web access. This differs from tdd-planner which is offline-only. Acceptable because the agent is still read-only (no Write/Edit).
- **No memory on agent**: Role creation is a one-shot task, not a learning workflow. No agent memory needed.

---

## Implementation Notes

### Key Decisions
- **CLAUDE_PLUGIN_ROOT resolution**: Only resolves in Bash commands. This is why the agent uses `cat ${CLAUDE_PLUGIN_ROOT}/...` instead of Read tool. Critical architectural constraint discovered during Issue 009/010 planning.
- **Approval gate ownership**: Skill owns approval (AskUserQuestion). Agent never sees the approval flow — it returns text and the skill decides what to do with it.
- **Validation ownership**: Agent runs `validate-role-output.sh` and only returns content that passes validation. Skill trusts the agent's output.
- **Generator field**: Agent sets `generator: /role-cr` in the role frontmatter. Skill does not modify the content.

### Future Improvements
- Remove `load-role-references.sh` (dead code cleanup)
- Consider agent memory if role creation patterns need to be learned across sessions

---

## References

### Related Code
- `skills/tdd-plan/SKILL.md` — orchestration skill pattern (lines 28-31 show Agent tool spawning)
- `agents/tdd-planner.md` — read-only agent pattern (frontmatter, tools, body structure)
- `skills/role-cr/SKILL.md` — file being rewritten
- `scripts/validate-role-output.sh` — invoked by agent (unchanged)
- `scripts/load-role-references.sh` — becomes unused (not removed)

### Documentation
- `issues/010-role-cr-skill-agent-split.md` — issue definition
- `docs/reference/` — agent development patterns

### Issues / PRs
- Issue 010: Split /role-cr into Skill + Agent
- Depends on: Issue 009 (v2.3.0, merged)
- Blocks: none
