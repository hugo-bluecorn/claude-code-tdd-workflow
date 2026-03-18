# Feature Notes: Plugin Agent Hook Mitigation (Issue 004)

**Created:** 2026-03-18
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Plugin agents installed from any marketplace (including local) silently lose their
frontmatter `hooks` and `permissionMode`. This breaks critical enforcement:
planner Bash guard, implementer test-first ordering, implementer auto-test-running,
and all agent Stop hooks. This issue adds dual delivery — session-level hooks.json
entries that fire regardless of installation method, with agent_type guards to
prevent cross-agent interference.

### Use Cases
- Plugin installed from marketplace: hooks.json entries fire, agent_type guards scope them correctly
- Plugin installed from local path (dev mode): both frontmatter and hooks.json fire, Claude Code deduplicates
- Main thread execution: empty agent_type falls through to original behavior (no change)

### Context
Empirically verified 2026-03-18: planner's Bash guard does not fire from marketplace
install. The `agent_type` field in PreToolUse hook input enables agent-scoped filtering
from session-level hooks (e.g., `"tdd-workflow:tdd-planner"`). Claude Code deduplicates
identical command hooks, so frontmatter and hooks.json coexist safely.

---

## Requirements Analysis

### Functional Requirements
1. Three hook scripts (`planner-bash-guard.sh`, `validate-tdd-order.sh`, `auto-run-tests.sh`) get agent_type guards
2. hooks.json gets PreToolUse (2), PostToolUse (1), SubagentStop (2 new), SubagentStart (1 new) entries
3. Agent frontmatter hooks remain unchanged (dual delivery, not migration)

### Non-Functional Requirements
- All 617+ existing tests continue passing
- shellcheck clean on all modified scripts
- hooks.json remains valid JSON

### Integration Points
- hooks.json is read by Claude Code at session start and plugin install
- Agent frontmatter hooks are read when agents spawn (but ignored from marketplace)
- `${CLAUDE_PLUGIN_ROOT}` variable resolves script paths in hooks.json entries

---

## Implementation Details

### Architectural Approach
**Guard pattern (identical in all 3 scripts):**
1. Extract `agent_type` from JSON input via `jq -r '.agent_type // ""'`
2. If non-empty AND doesn't match target agent (namespaced or plain), exit 0
3. If empty, fall through to original logic (backward compatible)

This is inserted after the existing `INPUT=$(cat)` line in each script.

### Design Patterns
- **Dual delivery:** Both frontmatter hooks and hooks.json entries exist. Claude Code deduplicates identical command hooks at runtime.
- **Agent-scoped filtering:** hooks.json entries fire for all agents; the guard in each script filters by `agent_type` field.
- **Backward compatibility:** Empty `agent_type` (main thread or frontmatter invocation) preserves original behavior.

### File Structure
```
hooks/
├── planner-bash-guard.sh     (modified: +agent_type guard)
├── validate-tdd-order.sh     (modified: +agent_type guard)
├── auto-run-tests.sh         (modified: +agent_type guard)
└── hooks.json                (modified: +PreToolUse, +PostToolUse, +SubagentStop, +SubagentStart)

agents/                       (read-only, verified unchanged)
├── tdd-planner.md
├── tdd-implementer.md
├── tdd-verifier.md
└── context-updater.md

test/hooks/
├── planner_bash_guard_test.sh           (modified: +agent_type tests)
├── validate_tdd_order_test.sh           (modified: +agent_type tests)
├── auto_run_tests_test.sh               (modified: +agent_type tests)
├── hooks_json_pretooluse_test.sh        (new)
├── hooks_json_subagent_stop_new_test.sh (new)
├── hooks_json_subagent_start_planner_test.sh (new)
└── agent_frontmatter_preservation_test.sh    (new)
```

### Naming Conventions
- Test files: snake_case, mirror source structure in `test/`
- Hook JSON keys: camelCase (Claude Code convention)
- Agent matchers: exact match on tool name or agent name

---

## TDD Approach

### Slice Decomposition

The feature is broken into 7 independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit (`./lib/bashunit test/`)
**Static Analysis:** shellcheck

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | planner-bash-guard.sh agent_type guard | None |
| 2 | validate-tdd-order.sh agent_type guard | None |
| 3 | auto-run-tests.sh agent_type guard | None |
| 4 | hooks.json PreToolUse + PostToolUse | None |
| 5 | hooks.json SubagentStop additions | None |
| 6 | hooks.json SubagentStart for planner | Slices 4, 5 |
| 7 | Agent frontmatter preservation | Slices 1-6 |

---

## Dependencies

### External Packages
- jq: already used by all hook scripts, no version constraint change

### Internal Dependencies
- `${CLAUDE_PLUGIN_ROOT}` variable: used in hooks.json command paths
- Existing hook scripts: guard is additive, no API change
- hooks.json schema: follows existing SubagentStop/SubagentStart patterns

---

## Known Limitations / Trade-offs

### Limitations
- **PreToolUse agent-scoped hooks cannot be fully replicated in hooks.json:** hooks.json matchers match tool names, not agent names. The agent_type guard in the script compensates.
- **Deduplication relies on Claude Code behavior:** If Claude Code changes deduplication logic, dual delivery could cause double execution. Low risk — documented behavior.

### Trade-offs Made
- **Dual delivery over migration:** Keeping frontmatter hooks means they work in non-marketplace installs without hooks.json. Trade-off: slight complexity from two delivery paths, but simpler than requiring users to run setup scripts.
- **Guard in script over guard in hooks.json:** hooks.json has no agent_type filtering syntax. Putting the guard in the script is the only option and keeps logic in one place.

---

## Implementation Notes

### Key Decisions
- **Guard pattern is identical across all scripts:** Simplifies implementation and testing. Same 4 lines, different target agent name.
- **SubagentStop prompts mirror frontmatter Stop hooks:** Content should match the intent of the agent's own Stop hook, since that hook won't fire from marketplace install.
- **SubagentStart for planner provides git context:** Branch, last commit, dirty file count — same as what the tdd-plan skill currently gathers manually.

### hooks.json Entry Counts (post-change)
- SubagentStart: 2 (context-updater + tdd-planner)
- SubagentStop: 5 (implementer + releaser + doc-finalizer + verifier + context-updater)
- Stop: 1 (unchanged)
- PreToolUse: 2 (Bash guard + validate-tdd-order)
- PostToolUse: 1 (auto-run-tests)

### Future Improvements
- If Claude Code adds agent_type filtering to hooks.json matchers, the script-level guards could be removed
- If Claude Code fixes marketplace frontmatter hook support, dual delivery becomes redundant (but harmless)

---

## References

### Related Code
- `hooks/planner-bash-guard.sh` — planner Bash command allowlist
- `hooks/validate-tdd-order.sh` — implementer test-first enforcement
- `hooks/auto-run-tests.sh` — implementer post-write auto-test
- `hooks/hooks.json` — session-level hook configuration
- `agents/tdd-planner.md` — planner agent with PreToolUse frontmatter hook
- `agents/tdd-implementer.md` — implementer agent with PreToolUse + PostToolUse frontmatter hooks

### Documentation
- `issues/004-plugin-agent-hook-mitigation.md` — full issue specification
- `docs/extensibility/audit.md` — extensibility audit §3 (M1) and §4.1

### Issues / PRs
- Issue 004: Plugin Agent Hook Mitigation (this feature)
- Blocks: marketplace publication
