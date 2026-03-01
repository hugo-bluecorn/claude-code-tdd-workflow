# Hooks

**Docs**: [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks) |
[code.claude.com/docs/en/hooks-guide](https://code.claude.com/docs/en/hooks-guide)

## All Hook Events

| Event | When It Fires | Can Block? | Supported Types |
|-------|---------------|------------|-----------------|
| `SessionStart` | Session begins/resumes | No | command only |
| `UserPromptSubmit` | User submits prompt | Yes (erases prompt) | all 4 |
| `PreToolUse` | Before tool executes | Yes (blocks tool) | all 4 |
| `PermissionRequest` | Permission dialog shown | Yes (denies) | all 4 |
| `PostToolUse` | After tool succeeds | No (feedback only) | all 4 |
| `PostToolUseFailure` | After tool fails | No (feedback only) | all 4 |
| `Notification` | Notification sent | No | command only |
| `SubagentStart` | Subagent spawned | No (context injection) | command only |
| `SubagentStop` | Subagent finishes | Yes | all 4 |
| `Stop` | Claude finishes responding | Yes | all 4 |
| `TeammateIdle` | Teammate about to go idle | Yes (exit 2 only) | command only |
| `TaskCompleted` | Task marked completed | Yes (exit 2 only) | all 4 |
| `ConfigChange` | Config file changes | Yes (except policy) | command only |
| `WorktreeCreate` | Worktree being created | Yes (non-zero fails) | command only |
| `WorktreeRemove` | Worktree being removed | No | command only |
| `PreCompact` | Before compaction | No | command only |
| `SessionEnd` | Session terminates | No | command only |

## Handler Types

| Type | Description | Key Fields |
|------|-------------|------------|
| `command` | Run shell command. JSON on stdin, exit codes + stdout for output | `command`, `async`, `timeout` |
| `http` | POST to URL. Response body uses same JSON format | `url`, `headers`, `allowedEnvVars`, `timeout` |
| `prompt` | Single-turn LLM evaluation. Returns `{ok: true/false, reason}` | `prompt`, `model`, `timeout` (default 30s) |
| `agent` | Multi-turn subagent with tools (Read, Grep, Glob). Same response format | `prompt`, `model`, `timeout` (default 60s) |

## Configuration Format

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/validate.sh",
            "timeout": 600,
            "statusMessage": "Validating...",
            "async": true,
            "once": true
          }
        ]
      }
    ]
  }
}
```

Three levels of nesting:
1. Hook event (e.g., `PreToolUse`)
2. Matcher group (regex filter)
3. Hook handlers (one or more per matcher group)

## Hook Locations

| Location | Scope | Shareable |
|----------|-------|-----------|
| `~/.claude/settings.json` | All projects | No |
| `.claude/settings.json` | Single project | Yes (committed) |
| `.claude/settings.local.json` | Single project | No (gitignored) |
| Managed policy settings | Organization-wide | Yes (admin) |
| Plugin `hooks/hooks.json` | When plugin enabled | Yes (bundled) |
| Skill/agent frontmatter | While component active | Yes (in component) |

## Matcher Patterns

The `matcher` field is a regex string. Omit, use `""`, or `"*"` to match all.

| Event | What Matcher Filters | Example Values |
|-------|---------------------|----------------|
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest` | Tool name | `Bash`, `Edit\|Write`, `mcp__.*` |
| `SessionStart` | How session started | `startup`, `resume`, `clear`, `compact` |
| `SessionEnd` | Why session ended | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |
| `Notification` | Notification type | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` |
| `SubagentStart`, `SubagentStop` | Agent type | `Bash`, `Explore`, `Plan`, custom agent names |
| `PreCompact` | What triggered | `manual`, `auto` |
| `ConfigChange` | Config source | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` |

**MCP tool matching**: Tools follow `mcp__<server>__<tool>` pattern.
Example regex: `mcp__memory__.*`, `mcp__.*__write.*`

Events with no matcher support (always fire): `UserPromptSubmit`, `Stop`,
`TeammateIdle`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`.

## Common Input Fields (All Events)

| Field | Description |
|-------|-------------|
| `session_id` | Current session identifier |
| `transcript_path` | Path to conversation JSON |
| `cwd` | Current working directory |
| `permission_mode` | `default`, `plan`, `acceptEdits`, `dontAsk`, `bypassPermissions` |
| `hook_event_name` | Name of the event that fired |

## Exit Code Behaviors

| Code | Meaning | Effect |
|------|---------|--------|
| **0** | Success | Parse stdout for JSON output |
| **2** | Blocking error | Stderr fed to Claude as error; blocks action (if blockable) |
| **Other** | Non-blocking error | Stderr shown in verbose mode only |

## JSON Output Fields (Universal)

| Field | Default | Description |
|-------|---------|-------------|
| `continue` | `true` | `false` stops Claude entirely (takes precedence over all) |
| `stopReason` | -- | Message shown to user when `continue` is `false` |
| `suppressOutput` | `false` | Hide stdout from verbose mode |
| `systemMessage` | -- | Warning message shown to user |

## Event-Specific Input/Output Details

### SessionStart

- **Matcher values**: `startup`, `resume`, `clear`, `compact`
- **Extra input**: `source`, `model`, optionally `agent_type`
- **Output**: `additionalContext` in hookSpecificOutput. Plain text stdout also added as context
- **Special**: `$CLAUDE_ENV_FILE` available for persisting env vars (`export` statements)

### UserPromptSubmit

- **Extra input**: `prompt`
- **Output**: `decision: "block"` prevents processing and erases prompt. Plain text stdout added as context

### PreToolUse

- **Extra input**: `tool_name`, `tool_input`, `tool_use_id`
- **Tool input schemas**:
  - **Bash**: `command`, `description`, `timeout`, `run_in_background`
  - **Write**: `file_path`, `content`
  - **Edit**: `file_path`, `old_string`, `new_string`, `replace_all`
  - **Read**: `file_path`, `offset`, `limit`
  - **Glob**: `pattern`, `path`
  - **Grep**: `pattern`, `path`, `glob`, `output_mode`, `-i`, `multiline`
  - **WebFetch**: `url`, `prompt`
  - **WebSearch**: `query`, `allowed_domains`, `blocked_domains`
  - **Agent**: `prompt`, `description`, `subagent_type`, `model`
- **Output** (`hookSpecificOutput` with `hookEventName: "PreToolUse"`):
  - `permissionDecision`: `"allow"` | `"deny"` | `"ask"`
  - `permissionDecisionReason`: Explanation
  - `updatedInput`: Modifies tool input before execution
  - `additionalContext`: String added to Claude's context

### PermissionRequest

- **Extra input**: `tool_name`, `tool_input`, `permission_suggestions`
- **Output** (`hookSpecificOutput`):
  - `decision.behavior`: `"allow"` | `"deny"`
  - `decision.updatedInput`: Modify tool input (allow only)
  - `decision.updatedPermissions`: Apply permission rule updates (allow only)
  - `decision.message`: Tell Claude why (deny only)
  - `decision.interrupt`: Stop Claude if `true` (deny only)
- **Note**: Does NOT fire in non-interactive mode (`-p`). Use PreToolUse instead

### PostToolUse

- **Extra input**: `tool_name`, `tool_input`, `tool_response`, `tool_use_id`
- **Output**: `decision: "block"` with `reason` (prompts Claude), `additionalContext`, `updatedMCPToolOutput` (MCP tools only)

### PostToolUseFailure

- **Extra input**: `tool_name`, `tool_input`, `tool_use_id`, `error`, `is_interrupt`
- **Output**: `additionalContext` only

### Notification

- **Matcher values**: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`
- **Extra input**: `message`, `title`, `notification_type`
- **Output**: `additionalContext` only. Cannot block

### SubagentStart

- **Matcher values**: Agent type names (`Bash`, `Explore`, `Plan`, custom)
- **Extra input**: `agent_id`, `agent_type`
- **Output**: `additionalContext` injected into subagent. Cannot block

### SubagentStop

- **Matcher values**: Same as SubagentStart
- **Extra input**: `stop_hook_active`, `agent_id`, `agent_type`, `agent_transcript_path`, `last_assistant_message`
- **Output**: `decision: "block"` with `reason` prevents subagent from stopping

### Stop

- **Extra input**: `stop_hook_active` (boolean), `last_assistant_message` (string)
- **Output**: `decision: "block"` with `reason` prevents Claude from stopping
- **Note**: Does NOT fire on user interrupts

### TeammateIdle

- **Extra input**: `teammate_name`, `team_name`
- **Decision**: Exit code 2 only (no JSON decision). Stderr is feedback

### TaskCompleted

- **Extra input**: `task_id`, `task_subject`, `task_description`, `teammate_name`, `team_name`
- **Decision**: Exit code 2 only. Fires when TaskUpdate marks complete or teammate finishes with in-progress tasks

### ConfigChange

- **Matcher values**: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`
- **Extra input**: `source`, `file_path`
- **Output**: `decision: "block"` with `reason`. `policy_settings` CANNOT be blocked

### WorktreeCreate

- **Extra input**: `name` (slug, e.g., `bold-oak-a3f2`)
- **Output**: Print absolute path to created worktree on stdout. Non-zero exit fails

### WorktreeRemove

- **Extra input**: `worktree_path` (absolute path)
- **Output**: None. Cannot block. Failures logged in debug mode only

### PreCompact

- **Matcher values**: `manual`, `auto`
- **Extra input**: `trigger`, `custom_instructions`
- **Output**: None

### SessionEnd

- **Matcher values**: `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`
- **Extra input**: `reason`
- **Output**: None

## Environment Variables in Hooks

| Variable | Available In | Description |
|----------|--------------|-------------|
| `$CLAUDE_PROJECT_DIR` | All hooks | Project root |
| `${CLAUDE_PLUGIN_ROOT}` | Plugin hooks | Plugin root directory |
| `$CLAUDE_ENV_FILE` | SessionStart only | File path for persisting env vars |
| `$CLAUDE_CODE_REMOTE` | All hooks | `"true"` in remote web environments |

## Plugin Hook Format

```json
{
  "description": "Automatic code formatting",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Async Hooks

Set `"async": true` on command hooks only. Hook runs in background; Claude
continues. Output delivered on next conversation turn. Cannot block or
return decisions. No deduplication between async executions.

## Once Field

`"once": true` runs only once per session then is removed. Skills only, not
agents.

## Execution Model

- All matching hooks for an event run **in parallel**
- Identical command strings are automatically **deduplicated**
- HTTP hooks deduplicated by URL

## Disabling Hooks

- `"disableAllHooks": true` in settings or toggle in `/hooks` menu
- `"allowManagedHooksOnly": true` in managed settings blocks user/project/plugin hooks
- Hooks are snapshotted at startup; external edits require `/hooks` menu review

## Troubleshooting

- **Not firing**: Check `/hooks`, verify matcher case-sensitivity, correct event type
- **Error**: Test manually; use absolute paths or `$CLAUDE_PROJECT_DIR`; `chmod +x`
- **Stop hook loops**: Check `stop_hook_active` field, exit early if `true`
- **JSON parse failure**: Shell profile `echo` statements interfere; wrap in `if [[ $- == *i* ]]`
- **Debug**: `Ctrl+O` for verbose mode, `claude --debug`
