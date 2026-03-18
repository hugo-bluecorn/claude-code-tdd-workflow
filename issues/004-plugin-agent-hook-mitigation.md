# Issue 004: Plugin Agent Hook Mitigation

## Problem

Claude Code silently ignores `hooks`, `mcpServers`, and `permissionMode`
frontmatter fields on agents loaded from plugins. This is a deliberate
Anthropic security restriction documented at
https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope:

> "For security reasons, plugin subagents do not support the hooks,
> mcpServers, or permissionMode frontmatter fields. These fields are
> ignored when loading agents from a plugin."

All 6 tdd-workflow agents define hooks in frontmatter. Two also rely on
`permissionMode: plan`. When installed from any marketplace (including
local directory-based ones), the core enforcement mechanisms silently
stop working.

### Empirical Verification (2026-03-18)

Tested from `/tmp/tdd-plugin-test` with the plugin installed as
`tdd-workflow@local-plugins` at user scope:

- `python3 --version` executed successfully inside `tdd-planner` — **not blocked**
- `python3` is NOT on the Bash guard allowlist
- Expected behavior: `BLOCKED: Command 'python3' is not in the planner's allowlist`
- Conclusion: planner-bash-guard.sh PreToolUse hook is not firing

### Impact Per Agent

| Agent | Lost `hooks` | Lost `permissionMode` | Severity |
|-------|-------------|----------------------|----------|
| tdd-planner | PreToolUse Bash guard — can run any command | `plan` — but `tools` already restricts to Read/Glob/Grep/Bash | **Critical** |
| tdd-implementer | PreToolUse validate-tdd-order — no test-first enforcement; PostToolUse auto-run-tests — no feedback loop | N/A | **Critical** |
| tdd-verifier | Stop prompt — no completion check | `plan` — but `tools`+`disallowedTools` already restrict writes | Moderate |
| tdd-releaser | Stop command — but SubagentStop in hooks.json covers this | N/A | Low |
| tdd-doc-finalizer | Stop command — but SubagentStop in hooks.json covers this | N/A | Low |
| context-updater | Stop prompt — no completion check | N/A | Low |

### What Already Works (hooks.json session-level)

These hooks are defined in `hooks/hooks.json`, NOT agent frontmatter,
so they work regardless of installation method:

- SubagentStop on `tdd-implementer` (R-G-R cycle validation) ✅
- SubagentStop on `tdd-releaser` (branch pushed check) ✅
- SubagentStop on `tdd-doc-finalizer` (branch pushed check) ✅
- SubagentStart on `context-updater` (git context injection) ✅
- Stop on main thread (check-tdd-progress) ✅

## Solution

### Key Discovery

PreToolUse hook input JSON includes `agent_type` when firing inside a
subagent. Empirically verified:

```json
{
  "agent_type": "tdd-workflow:tdd-planner",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "ls -la" }
}
```

This means hooks.json PreToolUse/PostToolUse hooks CAN be agent-scoped
by checking `agent_type` in the script. The agent type includes the
plugin namespace prefix (`tdd-workflow:`).

### Approach: Dual Delivery

Move all agent-scoped hooks to hooks.json WITH agent_type guards in the
scripts. Keep existing hooks in agent frontmatter as well.

**Why dual delivery works:**
- **Marketplace install:** Agent frontmatter hooks stripped → hooks.json fires ✅
- **`--plugin-dir` dev mode:** Both fire → Claude Code deduplicates by command string ✅
- **Copied to `.claude/agents/`:** Both fire → deduplicated ✅

Anthropic docs confirm: "Identical handlers deduplicated automatically.
Command hooks: deduplicated by command string."

### Changes Required

#### 1. Modify existing hook scripts (3 files)

Each script gets an agent_type guard at the top. When `agent_type` doesn't
match the target agent, exit 0 (allow). This prevents the hook from
interfering with other agents when triggered from hooks.json.

The guard must handle the namespaced format (`tdd-workflow:tdd-planner`)
for marketplace installs AND the plain format (`tdd-planner`) for
`--plugin-dir` / `.claude/agents/` installs.

**`hooks/planner-bash-guard.sh`** — add after `INPUT=$(cat)`:
```bash
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -n "$AGENT_TYPE" ] && \
   [ "$AGENT_TYPE" != "tdd-planner" ] && \
   [ "$AGENT_TYPE" != "tdd-workflow:tdd-planner" ]; then
  exit 0
fi
```

**`hooks/validate-tdd-order.sh`** — add after `INPUT=$(cat)`:
```bash
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -n "$AGENT_TYPE" ] && \
   [ "$AGENT_TYPE" != "tdd-implementer" ] && \
   [ "$AGENT_TYPE" != "tdd-workflow:tdd-implementer" ]; then
  exit 0
fi
```

**`hooks/auto-run-tests.sh`** — add after `INPUT=$(cat)`:
```bash
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -n "$AGENT_TYPE" ] && \
   [ "$AGENT_TYPE" != "tdd-implementer" ] && \
   [ "$AGENT_TYPE" != "tdd-workflow:tdd-implementer" ]; then
  exit 0
fi
```

Note: When `agent_type` is empty (main thread context, or frontmatter hook
already scoped to the correct agent), the guard passes through — existing
behavior is preserved.

#### 2. Add PreToolUse and PostToolUse to hooks.json

```json
"PreToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/planner-bash-guard.sh",
        "timeout": 5
      }
    ]
  },
  {
    "matcher": "Write|Edit|MultiEdit",
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-tdd-order.sh",
        "timeout": 10
      }
    ]
  }
],
"PostToolUse": [
  {
    "matcher": "Write|Edit|MultiEdit",
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/auto-run-tests.sh",
        "timeout": 30
      }
    ]
  }
]
```

#### 3. Add missing SubagentStop entries to hooks.json

Add SubagentStop for verifier and context-updater (currently only in
agent frontmatter, not hooks.json):

```json
{
  "matcher": "tdd-verifier",
  "hooks": [
    {
      "type": "prompt",
      "prompt": "The tdd-verifier has finished. Evaluate: $ARGUMENTS\n\nCheck:\n1. Did the verifier run the COMPLETE test suite (not just new tests)?\n2. Did it run static analysis?\n3. Did it report a clear PASS or FAIL verdict?\n\nIf any check fails, respond with {\"decision\": \"block\", \"reason\": \"<what's missing>\"}.\nIf all checks pass, respond with {\"decision\": \"allow\"}.",
      "timeout": 30
    }
  ]
},
{
  "matcher": "context-updater",
  "hooks": [
    {
      "type": "prompt",
      "prompt": "The context-updater has finished. Evaluate: $ARGUMENTS\n\nCheck:\n1. Did it research latest framework versions via web search?\n2. Did it produce a change proposal with breaking-change detection?\n3. Did it get user approval before applying changes?\n\nIf any check fails, respond with {\"decision\": \"block\", \"reason\": \"<what's missing>\"}.\nIf all checks pass, respond with {\"decision\": \"allow\"}.",
      "timeout": 30
    }
  ]
}
```

#### 4. Add SubagentStart context injection for planner

The planner currently lacks SubagentStart context (only context-updater
has it). Add to hooks.json SubagentStart:

```json
{
  "matcher": "tdd-planner",
  "hooks": [
    {
      "type": "command",
      "command": "echo \"{ \\\"additionalContext\\\": \\\"Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown'). Last commit: $(git log --oneline -1 2>/dev/null || echo 'none'). Dirty files: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ').\\\"}\""  ,
      "timeout": 5
    }
  ]
}
```

#### 5. permissionMode: plan (NO ACTION NEEDED)

For both planner and verifier, `permissionMode: plan` is redundant:
- Planner: `tools: Read, Glob, Grep, Bash` — no Write/Edit access. Bash
  writes are blocked by the Bash guard (now via hooks.json).
- Verifier: `tools: Read, Bash, Glob, Grep` + `disallowedTools: Write, Edit, MultiEdit`
  — Write/Edit explicitly denied. `tools` and `disallowedTools` are NOT
  affected by the plugin restriction.

No mitigation needed for `permissionMode`.

## What NOT To Do

- **Don't remove hooks from agent frontmatter** — they serve as documentation
  of intent and work correctly in `--plugin-dir` / `.claude/agents/` modes.
  Dual delivery with deduplication is the correct pattern.
- **Don't add a post-install script** — the hooks.json solution is transparent
  and requires no user action.
- **Don't try to replicate `permissionMode: plan`** — the `tools` allowlist
  already provides equivalent protection.

## Acceptance Criteria

- [ ] `planner-bash-guard.sh` has agent_type guard, passes through for non-planner agents
- [ ] `validate-tdd-order.sh` has agent_type guard, passes through for non-implementer agents
- [ ] `auto-run-tests.sh` has agent_type guard, passes through for non-implementer agents
- [ ] hooks.json has PreToolUse entries for Bash (planner guard) and Write|Edit|MultiEdit (tdd-order)
- [ ] hooks.json has PostToolUse entry for Write|Edit|MultiEdit (auto-run-tests)
- [ ] hooks.json has SubagentStop entries for tdd-verifier and context-updater
- [ ] hooks.json has SubagentStart entry for tdd-planner (git context injection)
- [ ] All existing tests pass (617+)
- [ ] New tests verify agent_type guard behavior (pass-through and block cases)
- [ ] New tests verify hooks.json entries exist with correct matchers and commands
- [ ] Empirical verification: planner Bash guard blocks `python3` from marketplace install
- [ ] shellcheck clean on all modified scripts
- [ ] Agent frontmatter hooks preserved (not removed)

## Testing Notes

### Agent-type guard tests

Each modified script needs tests for:
1. Target agent_type (namespaced) → original behavior (block/allow as before)
2. Target agent_type (plain) → original behavior
3. Different agent_type → exit 0 (pass through)
4. Empty agent_type → original behavior (preserves main-thread/frontmatter case)

### hooks.json integration tests

Verify new entries exist with correct structure (matcher, hook type, command path, timeout).

### Empirical verification

Repeat the test from this issue: install from local marketplace, invoke
`/tdd-plan` in a separate project, have the planner run `python3 --version`,
verify it is blocked with the allowlist message.

## References

- Anthropic docs: https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope
- Hook deduplication: https://code.claude.com/docs/en/hooks (deduplication section)
- Hook input schema: https://code.claude.com/docs/en/hooks#pretooluse-input
- Audit finding: `docs/extensibility/audit.md` §3 item M1, §4.1
- Audit inventory: `docs/extensibility/audit-prompt.md` items A27, D27
