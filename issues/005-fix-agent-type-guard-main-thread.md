# Issue 005: Fix agent_type Guard — Main Thread Blocked by Plugin Hooks

**Status:** Open
**Priority:** High (blocks normal session usage)
**Discovered:** 2026-03-19
**Affects:** v1.14.0+

## Problem

The `agent_type` guard pattern introduced in Issue 004 (v1.14.0) treats absent
`agent_type` as "I am the target agent — apply restrictions." This is correct
for frontmatter delivery (where hooks are scoped to the agent), but wrong for
hooks.json delivery (session-level), where absent `agent_type` means "I am the
main thread."

Result: the main thread cannot run `mkdir`, `rm`, `mv`, `python3`, or any
command not on the planner's read-only allowlist. The `validate-tdd-order`
hook blocks source file edits unless test files are staged. The `auto-run-tests`
hook runs tests after every file edit.

## Root Cause

All three hook scripts use this guard pattern:

```bash
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -n "$AGENT_TYPE" ] \
  && [ "$AGENT_TYPE" != "tdd-planner" ] \
  && [ "$AGENT_TYPE" != "tdd-workflow:tdd-planner" ]; then
  exit 0
fi
```

When `agent_type` is absent (main thread), `jq` returns empty string, `-n`
fails, and the guard falls through to blocking logic.

Per Claude Code docs (v2.1.69+), `agent_type` is:
- **Absent** when the main thread makes a tool call
- **Present** when a subagent or `--agent` session makes a tool call

## Fix: Option B — Drop frontmatter hooks, hooks.json only

### Rationale

- Frontmatter `hooks:` are silently ignored in marketplace installs (A27/D27)
- hooks.json provides the same enforcement with `agent_type` guards
- Dual delivery adds complexity with no benefit
- One delivery path is easier to reason about and test

### Changes Required

**Fix guard logic (3 files):**
- `hooks/planner-bash-guard.sh`
- `hooks/validate-tdd-order.sh`
- `hooks/auto-run-tests.sh`

New guard pattern (pass through for main thread or non-target agents):

```bash
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -z "$AGENT_TYPE" ] \
  || { [ "$AGENT_TYPE" != "<target>" ] \
    && [ "$AGENT_TYPE" != "tdd-workflow:<target>" ]; }; then
  exit 0
fi
```

**Remove frontmatter hooks (4 files):**
- `agents/tdd-planner.md` — remove `hooks:` PreToolUse block
- `agents/tdd-implementer.md` — remove `hooks:` PreToolUse + PostToolUse blocks
- `agents/tdd-verifier.md` — remove `hooks:` Stop block
- `agents/context-updater.md` — remove `hooks:` Stop block

**Delete test file (1 file):**
- `test/hooks/agent_frontmatter_preservation_test.sh` — 5 tests no longer applicable

**Update test assertions (3 files):**
- `test/hooks/planner_bash_guard_test.sh` — Tests AT6, AT7: expect exit 0 (pass-through)
- `test/hooks/validate_tdd_order_test.sh` — Test 23: expect exit 0
- `test/hooks/auto_run_tests_test.sh` — Guard Test 4: expect empty output

### What stays unchanged

- hooks.json entries (PreToolUse x2, PostToolUse x1, SubagentStop x5, SubagentStart x2, Stop x1)
- Hook scripts' core logic (allowlist, tdd-order validation, auto-test running)
- Agent system prompts, tools, model assignments
- All other tests (680+ remain)

## Acceptance Criteria

- [ ] Main thread can run any Bash command without planner guard blocking
- [ ] Planner subagent is still restricted to read-only allowlist
- [ ] Implementer subagent still gets tdd-order validation and auto-test
- [ ] No agent frontmatter contains `hooks:` sections
- [ ] hooks.json unchanged
- [ ] All tests pass (minus 5 deleted, ~6 updated)
- [ ] shellcheck clean on all 3 modified scripts

## Test Plan

1. Run `./lib/bashunit test/` — all tests pass
2. Run `shellcheck` on modified hook scripts
3. Empirical verification:
   - Main thread: `echo '{"tool_name":"Bash","tool_input":{"command":"python3 --version"}}' | ./hooks/planner-bash-guard.sh` → exit 0
   - Planner: `echo '{"tool_name":"Bash","tool_input":{"command":"python3 --version"},"agent_type":"tdd-workflow:tdd-planner"}' | ./hooks/planner-bash-guard.sh` → exit 2, BLOCKED
