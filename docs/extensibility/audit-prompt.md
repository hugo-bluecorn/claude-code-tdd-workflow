# Claude Code Extensibility Reference & Audit Prompt

> **Purpose:** Living reference of every Claude Code extensibility feature with
> direct documentation URLs. Use it to (1) audit a plugin or workflow against the
> full feature set, (2) verify the plugin follows Anthropic recommendations, and
> (3) identify new features to adopt when Anthropic updates their docs.
>
> **Last verified:** 2026-03-18
> **Documentation home:** https://code.claude.com/docs/en/
> **Full docs index (LLM-friendly):** https://code.claude.com/docs/llms.txt

---

## How to Use This Document

### As a reference

Each category below lists every documented feature with its URL. When
Anthropic releases new Claude Code versions, re-fetch the URLs and compare
against this inventory to find newly added features.

### As an audit prompt

Provide this document plus a target plugin/workflow to Claude Code:

```bash
claude "Read the extensibility reference at ./docs/extensibility/audit-prompt.md, \
then audit this plugin following the audit methodology in Phase 1-5."
```

Or as a skill:

```yaml
# skills/extensibility-audit/SKILL.md
---
name: extensibility-audit
description: >
  Audit a workflow or plugin against all Claude Code extensibility features.
  Produces a gap analysis with prioritized revision recommendations.
disable-model-invocation: true
---

<!-- ultrathink -->

Read and follow the audit methodology in
docs/extensibility/audit-prompt.md

Audit target: $ARGUMENTS
```

Then invoke: `/extensibility-audit ../claude-code-tdd-workflow/`

---

## Feature Inventory

### Category A — Subagents

**Docs:** https://code.claude.com/docs/en/sub-agents

Subagents are specialized AI assistants that run in their own context window
with a custom system prompt, specific tool access, and independent permissions.

#### Frontmatter Fields

| # | Field | What It Does | Required |
|---|-------|-------------|----------|
| A1 | `name` | Unique identifier (lowercase + hyphens) | Yes |
| A2 | `description` | When Claude should delegate to this subagent | Yes |
| A3 | `tools` | Allowlist of tools the subagent can use; inherits all if omitted. Supports `Agent(type)` restriction syntax | No |
| A4 | `disallowedTools` | Denylist — hard-deny tools removed from any inherited set | No |
| A5 | `model` | `sonnet`, `opus`, `haiku`, a full model ID (e.g., `claude-opus-4-6`), or `inherit` (default: `inherit`) | No |
| A6 | `permissionMode` | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` | No |
| A7 | `maxTurns` | Maximum agentic turns before forced stop; cost-control lever | No |
| A8 | `skills` | Skills preloaded into subagent context at startup (full content injected) | No |
| A9 | `memory` | Persistent memory scope: `user`, `project`, or `local` | No |
| A10 | `mcpServers` | MCP servers available to this subagent — name reference to existing server, or inline definition with full MCP config | No |
| A11 | `hooks` | Lifecycle hooks scoped to this subagent; `Stop` auto-converts to `SubagentStop` | No |
| A12 | `background` | Set `true` to always run as a background task. Default: `false` | No |
| A13 | `isolation` | Set to `worktree` to run in a temporary git worktree (isolated copy of repo). Auto-cleaned if no changes | No |

#### Behavioral Features

| # | Feature | Description |
|---|---------|-------------|
| A14 | Subagent resumption | Resume by agent ID via `SendMessage` tool to continue with full conversation history preserved. Transcripts stored in `~/.claude/projects/{project}/{sessionId}/subagents/` |
| A15 | `Agent(agent_type)` restriction | Allowlist which subagent types can be spawned from `tools` field. Only applies to `--agent` main thread mode. Without parentheses = allow all |
| A16 | Agent teams | Multiple instances with shared task lists; experimental. Env: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. `teammateMode` setting controls display |
| A17 | Built-in agents | `Explore` (haiku, read-only), `Plan` (inherit, read-only), `general-purpose` (inherit, all tools), `Bash` (inherit), `statusline-setup` (sonnet), `Claude Code Guide` (haiku) |
| A18 | No-nesting constraint | Subagents cannot spawn other subagents; only the main thread can spawn |
| A19 | Foreground/background execution | Background subagents run concurrently; permissions pre-approved at launch; `AskUserQuestion` fails gracefully. Ctrl+B to background a running task |
| A20 | Auto-compaction | Subagents auto-compact at ~95% capacity; configurable via `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` |
| A21 | CLI-defined subagents | `--agents` flag accepts JSON with same frontmatter fields as file-based agents (use `prompt` for system prompt body) |
| A22 | Scope precedence | `--agents` flag > `.claude/agents/` > `~/.claude/agents/` > plugin `agents/` |
| A23 | Disable specific subagents | `permissions.deny: ["Agent(Explore)", "Agent(my-agent)"]` or `--disallowedTools` CLI flag |
| A24 | @-mention invocation | `@"agent-name (agent)"` guarantees delegation to that specific subagent; user message still goes to Claude which writes the task prompt |
| A25 | `--agent` flag / `agent` setting | Session-wide agent mode — main thread uses that subagent's system prompt, tool restrictions, and model. Setting persists across resumes |
| A26 | `/agents` command | Interactive interface to view, create, edit, and delete subagents. `claude agents` for non-interactive CLI listing |
| A27 | Plugin agent restrictions | Plugin agents **cannot** use `hooks`, `mcpServers`, or `permissionMode` — these fields are silently ignored. Copy to `.claude/agents/` to enable |
| A28 | Transcript persistence | Transcripts stored as `agent-{agentId}.jsonl`; survive main conversation compaction; cleaned up per `cleanupPeriodDays` setting (default: 30) |

#### Memory Details (A9)

**Docs:** https://code.claude.com/docs/en/sub-agents#enable-persistent-memory

| Scope | Location | Use When |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Learnings across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via VCS |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, gitignored |

When enabled: system prompt includes memory instructions, first 200 lines of
`MEMORY.md` auto-included, Read/Write/Edit auto-enabled for the memory directory.

---

### Category B — Skills

**Docs:** https://code.claude.com/docs/en/skills

Skills extend what Claude can do via `SKILL.md` files. Claude uses them when
relevant, or users invoke directly with `/skill-name`. Follows the
[Agent Skills](https://agentskills.io) open standard.

#### Frontmatter Fields

| # | Field | What It Does | Required |
|---|-------|-------------|----------|
| B1 | `name` | Slash command name (`/name`); defaults to directory name if omitted. Lowercase letters, numbers, hyphens (max 64 chars) | No |
| B2 | `description` | When Claude should use this skill; used for auto-invocation decisions. Falls back to first paragraph of content if omitted | Recommended |
| B3 | `argument-hint` | Autocomplete hint for expected arguments (e.g., `[feature-description]`) | No |
| B4 | `disable-model-invocation` | If `true`, only user can invoke via `/name`; Claude cannot auto-load | No |
| B5 | `user-invocable` | If `false`, hidden from `/` menu; only Claude can invoke | No |
| B6 | `allowed-tools` | Tools Claude can use without permission prompts when skill is active | No |
| B7 | `model` | Model override when skill is active | No |
| B8 | `context` | Set to `fork` to run in isolated subagent context | No |
| B9 | `agent` | Which subagent type when `context: fork` (default: `general-purpose`) | No |
| B10 | `hooks` | Lifecycle hooks scoped to skill execution; cleaned up when skill finishes | No |

#### String Substitutions

| # | Variable | Description |
|---|----------|-------------|
| B11 | `$ARGUMENTS` | All arguments passed when invoking the skill. If not present in content, appended as `ARGUMENTS: <value>` |
| B12 | `$ARGUMENTS[N]` / `$N` | Access specific argument by 0-based index (e.g., `$ARGUMENTS[0]` or `$0`) |
| B13 | `${CLAUDE_SESSION_ID}` | Current session ID for logging or session-specific files |
| B14 | `${CLAUDE_SKILL_DIR}` | Directory containing the skill's SKILL.md. For plugin skills, the skill's subdirectory within the plugin. Use for referencing bundled scripts/files |

#### Advanced Features

| # | Feature | Description |
|---|---------|-------------|
| B15 | Dynamic context injection (`` !`cmd` ``) | Shell commands run before skill content sent to Claude; output replaces placeholder |
| B16 | `ultrathink` keyword | Include "ultrathink" anywhere in skill content to enable extended thinking |
| B17 | Supporting files | Additional files in skill directory (templates, examples, scripts); referenced from SKILL.md. Keep SKILL.md under 500 lines |
| B18 | Skills-in-subagents duality | `context: fork` + `agent` in skill vs `skills:` field in subagent; inverse patterns |
| B19 | `Skill()` permission syntax | `Skill(name)` exact match, `Skill(name *)` prefix match in permissions |
| B20 | Live change detection | Skills from `--add-dir` picked up during session without restart |
| B21 | Invocation matrix | See table below |
| B22 | Automatic subdirectory discovery | Skills from nested `.claude/skills/` in monorepo packages |
| B23 | Char budget | Skill descriptions budget: 2% of context window (fallback 16k chars); override with `SLASH_COMMAND_TOOL_CHAR_BUDGET`. Run `/context` to check for excluded skills |
| B24 | Bundled skills | Built-in skills shipped with Claude Code: `/batch` (parallel codebase changes), `/claude-api` (API reference), `/debug` (session debugging), `/loop` (recurring prompts), `/simplify` (code review + fix) |

#### Invocation Matrix (B21)

| Frontmatter | User can invoke | Claude can invoke | When loaded |
|-------------|-----------------|-------------------|-------------|
| (default) | Yes | Yes | Description always; full content on invoke |
| `disable-model-invocation: true` | Yes | No | Not in context until user invokes |
| `user-invocable: false` | No | Yes | Description always; full content on invoke |

#### Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| Enterprise | Managed settings | All org users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

---

### Category C — Hooks

**Docs:** https://code.claude.com/docs/en/hooks
**Guide:** https://code.claude.com/docs/en/hooks-guide

Hooks are user-defined shell commands, HTTP calls, LLM prompts, or agents that
execute automatically at specific lifecycle points.

#### Hook Events

| # | Event | When It Fires | Can Block? | Matcher Field | Supported Types |
|---|-------|--------------|------------|---------------|-----------------|
| C1 | `SessionStart` | Session begins or resumes | No | Source: `startup`, `resume`, `clear`, `compact` | command |
| C2 | `InstructionsLoaded` | CLAUDE.md or rules file lazy-loaded | No | No matcher | command |
| C3 | `UserPromptSubmit` | User submits prompt, before processing | Yes | No matcher | all 4 |
| C4 | `PreToolUse` | Before tool call executes | Yes | Tool name | all 4 |
| C5 | `PermissionRequest` | Permission dialog appears | Yes | Tool name | all 4 |
| C6 | `PostToolUse` | After tool succeeds | No (feedback only) | Tool name | all 4 |
| C7 | `PostToolUseFailure` | After tool fails | No (feedback only) | Tool name | all 4 |
| C8 | `Notification` | Claude Code sends notification | No | Type: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` | command |
| C9 | `SubagentStart` | Subagent spawned | No (context injection) | Agent type name | command |
| C10 | `SubagentStop` | Subagent finishes | Yes | Agent type name | all 4 |
| C11 | `Stop` | Main agent finishes responding | Yes | No matcher | all 4 |
| C12 | `TeammateIdle` | Agent team member about to idle | Yes (exit 2 only) | No matcher | command |
| C13 | `TaskCompleted` | Task marked completed | Yes (exit 2 only) | No matcher | all 4 |
| C14 | `ConfigChange` | Settings change detected | Yes | Source: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` | command |
| C15 | `WorktreeCreate` | Isolated worktree requested | Yes (exit non-zero) | No matcher | command |
| C16 | `WorktreeRemove` | Isolated worktree cleanup | No | No matcher | command |
| C17 | `PreCompact` | Before context compaction | No | Trigger: `manual`, `auto` | command |
| C18 | `PostCompact` | After context compaction | No | Trigger: `manual`, `auto` | command |
| C19 | `Elicitation` | MCP server requests user input | Yes | MCP server name | command |
| C20 | `ElicitationResult` | User responds to MCP input | Yes | MCP server name | command |
| C21 | `SessionEnd` | Session terminates | No | Reason: `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` | command |

**"all 4"** = command, http, prompt, agent

#### Hook Types

| # | Type | Description | Default Timeout |
|---|------|-------------|-----------------|
| C22 | `command` | Execute shell script; JSON stdin/stdout; exit codes 0/2 | 600s |
| C23 | `http` | JSON POST to URL; env var interpolation in headers via `$VAR_NAME` syntax; requires `allowedEnvVars` whitelist for security. Non-2xx = non-blocking | 30s |
| C24 | `prompt` | Single-turn LLM evaluation; `$ARGUMENTS` placeholder for hook input JSON; returns structured decision | 30s |
| C25 | `agent` | Multi-turn subagent with tools (Read, Grep, Glob, etc.); up to 50 turns; returns structured decision | 60s |

#### Hook Handler Fields

| # | Field | Required | Description |
|---|-------|----------|-------------|
| C26 | `type` | Yes | `"command"`, `"http"`, `"prompt"`, or `"agent"` |
| C27 | `command` | Yes (command) | Shell command to execute |
| C28 | `url` | Yes (http) | Endpoint URL for HTTP POST |
| C29 | `headers` | No (http) | Key-value headers with env var interpolation (`$VAR_NAME` or `${VAR_NAME}`) |
| C30 | `allowedEnvVars` | No (http) | Whitelist of env var names allowed in header interpolation |
| C31 | `prompt` | Yes (prompt/agent) | Prompt text; `$ARGUMENTS` for hook input JSON |
| C32 | `model` | No | Model for prompt/agent hooks |
| C33 | `timeout` | No | Seconds before canceling |
| C34 | `statusMessage` | No | Custom spinner text while hook runs |
| C35 | `once` | No | If `true`, runs once per session then removed (skills only) |
| C36 | `async` | No | If `true`, runs in background without blocking (command only) |

#### Hook Variables & Protocol

| # | Feature | Description |
|---|---------|-------------|
| C37 | `$ARGUMENTS` | Placeholder in prompt/agent hooks for JSON input data |
| C38 | `$CLAUDE_PROJECT_DIR` | Project root path (quote for paths with spaces) |
| C39 | `${CLAUDE_PLUGIN_ROOT}` | Plugin root directory for bundled scripts. Changes on plugin update |
| C40 | `${CLAUDE_PLUGIN_DATA}` | Persistent plugin data directory; survives updates. Location: `~/.claude/plugins/data/{id}/` |
| C41 | `$CLAUDE_ENV_FILE` | SessionStart only: file path for persisting env vars to Bash commands |
| C42 | `$CLAUDE_CODE_REMOTE` | Set to `"true"` in remote web environments |
| C43 | Exit code 0 | Allow; stdout parsed for JSON output |
| C44 | Exit code 2 | Block/deny; stderr fed back as error message. See exit-code-2 table below |
| C45 | Other exit codes | Non-blocking error; stderr shown in verbose mode |
| C46 | `stop_hook_active` | Boolean in Stop/SubagentStop input preventing infinite loops |
| C47 | `last_assistant_message` | String in Stop/SubagentStop input; avoids transcript parsing |

#### Exit Code 2 Behavior Per Event

| Event | Effect |
|-------|--------|
| `PreToolUse` | Blocks tool call |
| `PermissionRequest` | Denies permission |
| `UserPromptSubmit` | Blocks prompt, erases it |
| `Stop` | Prevents Claude from stopping |
| `SubagentStop` | Prevents subagent from stopping |
| `TeammateIdle` | Prevents idle (teammate continues) |
| `TaskCompleted` | Prevents task completion |
| `ConfigChange` | Blocks config change (except `policy_settings`) |
| `Elicitation` | Denies elicitation |
| `ElicitationResult` | Blocks response (action becomes decline) |
| `WorktreeCreate` | Fails worktree creation |
| Other events | Non-blocking; stderr shown in verbose mode |

#### JSON Output Fields (on exit 0)

**Universal fields** (work on all events):

| Field | Description |
|-------|-------------|
| `continue` | If `false`, Claude stops entirely. Default: `true` |
| `stopReason` | Message shown to user when `continue: false` (not shown to Claude) |
| `suppressOutput` | If `true`, hides stdout from verbose mode. Default: `false` |
| `systemMessage` | Warning message shown to user |

**Decision fields** (event-specific):

| Pattern | Used By | Fields |
|---------|---------|--------|
| Top-level `decision`/`reason` | UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop, SubagentStop, ConfigChange | `"decision": "block"`, `"reason": "..."` |
| `hookSpecificOutput.additionalContext` | SessionStart, SubagentStart, Notification, PreToolUse, PostToolUse, PostToolUseFailure, UserPromptSubmit | Injects context into Claude's conversation |

#### PreToolUse Decision Control (hookSpecificOutput)

| Field | Description |
|-------|-------------|
| `permissionDecision` | `"allow"`, `"deny"`, or `"ask"` |
| `permissionDecisionReason` | Shown to user (allow/ask) or Claude (deny) |
| `updatedInput` | Modify tool parameters before execution |
| `additionalContext` | Context added before tool executes |

> **Deprecation note:** PreToolUse previously used top-level `decision` and
> `reason` fields — these are deprecated. Deprecated values `"approve"` and
> `"block"` map to `"allow"` and `"deny"` respectively.

#### PermissionRequest Decision Control (hookSpecificOutput)

The PermissionRequest `hookSpecificOutput` uses a nested `decision` **object**
(not a string like PreToolUse):

| Field | Description |
|-------|-------------|
| `decision.behavior` | `"allow"` grants permission, `"deny"` denies it |
| `decision.updatedInput` | For `"allow"` only: modifies tool input before execution |
| `decision.updatedPermissions` | For `"allow"` only: applies permission rule updates. Array of `{type, rules, behavior, destination}` |
| `decision.message` | For `"deny"` only: tells Claude why permission was denied |
| `decision.interrupt` | For `"deny"` only: if `true`, stops Claude |

Permission update types: `addRules`, `replaceRules`, `removeRules`, `setMode`,
`addDirectories`, `removeDirectories`. Destinations: `session`, `localSettings`,
`projectSettings`, `userSettings`.

#### PostToolUse hookSpecificOutput

| Field | Description |
|-------|-------------|
| `additionalContext` | Additional context for Claude to consider |
| `updatedMCPToolOutput` | For MCP tools only: replaces the tool's output with the provided value |

#### Elicitation hookSpecificOutput

| Field | Description |
|-------|-------------|
| `action` | `"accept"`, `"decline"`, or `"cancel"` |
| `content` | For `"accept"` only: form field values as object |

#### WorktreeCreate Special Case

- Hook **must print** absolute path to created worktree on stdout
- Exit code non-zero = creation failed
- No JSON output (path on stdout is the output)
- Pair with `WorktreeRemove` for non-git VCS

#### MCP Tool Matching

MCP tools follow pattern `mcp__<server>__<tool>`. Use regex in matchers:
`mcp__memory__.*` to match all tools from the memory server.

#### Hook Locations (precedence, highest to lowest)

| Location | Scope | Shareable |
|----------|-------|-----------|
| Managed policy settings | Org-wide | Yes (admin) |
| `.claude/settings.local.json` | Project | No (gitignored) |
| `.claude/settings.json` | Project | Yes (VCS) |
| Plugin `hooks/hooks.json` | Plugin | Yes (bundled) |
| Skill/agent frontmatter | Component lifetime | Yes (defined in file) |
| `~/.claude/settings.json` | All projects | No |

#### Hook Settings

| Setting | Description |
|---------|-------------|
| `disableAllHooks` | Disable all hooks and custom status line. Managed-level only disables managed hooks |
| `allowManagedHooksOnly` | (Managed only) Block user/project/plugin hooks. Only managed + SDK hooks load |
| `allowedHttpHookUrls` | URL pattern allowlist for HTTP hooks. Supports `*` wildcard. Undefined = no restriction, empty array = block all. Merges across scopes |
| `httpHookAllowedEnvVars` | Env var name allowlist for HTTP header interpolation. Intersection with per-hook `allowedEnvVars`. Merges across scopes |

---

### Category D — Plugins

**Docs:** https://code.claude.com/docs/en/plugins
**Reference:** https://code.claude.com/docs/en/plugins-reference
**Marketplaces:** https://code.claude.com/docs/en/plugin-marketplaces
**Discover/Install:** https://code.claude.com/docs/en/discover-plugins

#### Plugin Manifest (`.claude-plugin/plugin.json`)

| # | Field | Required | Description |
|---|-------|----------|-------------|
| D1 | `name` | Yes (if manifest exists) | Unique identifier (kebab-case); used for skill namespacing |
| D2 | `version` | No | Semantic version. `plugin.json` takes priority over marketplace entry |
| D3 | `description` | No | Brief explanation of plugin purpose |
| D4 | `author` | No | `{name, email, url}` |
| D5 | `homepage` | No | Documentation URL |
| D6 | `repository` | No | Source code URL |
| D7 | `license` | No | License identifier |
| D8 | `keywords` | No | Discovery tags |
| D9 | `commands` | No | Additional command files/directories (string or array) |
| D10 | `agents` | No | Additional agent files (string or array) |
| D11 | `skills` | No | Additional skill directories (string or array) |
| D12 | `hooks` | No | Hook config paths or inline config (string, array, or object) |
| D13 | `mcpServers` | No | MCP config paths or inline config (string, array, or object) |
| D14 | `lspServers` | No | LSP server config paths or inline config (string, array, or object) |
| D15 | `outputStyles` | No | Output style files/directories |

Custom paths supplement default directories — they don't replace them.

#### LSP Server Configuration Fields

**Required:** `command`, `extensionToLanguage`

**Optional:** `args`, `transport` (stdio/socket), `env`, `initializationOptions`,
`settings`, `workspaceFolder`, `startupTimeout`, `shutdownTimeout`,
`restartOnCrash`, `maxRestarts`

Official LSP plugins available: `pyright-lsp`, `typescript-lsp`, `rust-lsp`.

#### Plugin Features

| # | Feature | Description |
|---|---------|-------------|
| D16 | `${CLAUDE_PLUGIN_ROOT}` | Absolute path to installed plugin directory. Changes on update — do not write persistent data here |
| D17 | `${CLAUDE_PLUGIN_DATA}` | Persistent data directory (`~/.claude/plugins/data/{id}/`); survives updates. Auto-created on first reference. Deleted on uninstall from last scope (use `--keep-data` to preserve) |
| D18 | Scopes | `user` (~/.claude/), `project` (.claude/), `local` (.claude/*.local.*), `managed` |
| D19 | Namespacing | Skills prefixed: `/plugin-name:skill-name` |
| D20 | `--plugin-dir` | Dev flag: load plugin directly without installation |
| D21 | Plugin caching | Plugins copied to `~/.claude/plugins/cache` for security. Symlinks in plugin directory are honored during copy |
| D22 | CLI commands | `install`, `uninstall` (alias: `remove`/`rm`), `enable`, `disable`, `update`, `validate` |
| D23 | Marketplace sources | github, git, url, npm, pip, file, directory, hostPattern |
| D24 | LSP servers | `.lsp.json` for code intelligence (go-to-definition, find references, diagnostics) |
| D25 | `strict: false` | In marketplace entry: merge manifest from marketplace + plugin.json |
| D26 | Plugin `settings.json` | Default settings applied when plugin is enabled. Currently only `agent` setting is supported |
| D27 | Plugin agent restrictions | Plugin agents cannot use `hooks`, `mcpServers`, or `permissionMode` — silently ignored |
| D28 | Path traversal limitations | Installed plugins cannot reference files outside their directory (`../` won't work after caching) |

#### Plugin Directory Structure

```
plugin-root/
├── .claude-plugin/
│   └── plugin.json           # Manifest (optional — auto-discovery works)
├── agents/                   # Subagent definitions
├── skills/                   # Skills with <name>/SKILL.md structure
├── commands/                 # Legacy command markdown files
├── hooks/
│   └── hooks.json            # Hook configuration
├── .mcp.json                 # MCP server definitions
├── .lsp.json                 # LSP server configurations
├── settings.json             # Default settings (applied when enabled)
├── scripts/                  # Hook and utility scripts
├── LICENSE
└── CHANGELOG.md
```

---

### Category E — Memory / CLAUDE.md

**Docs:** https://code.claude.com/docs/en/memory

#### Memory Locations

| # | Type | Location | Scope | Shared |
|---|------|----------|-------|--------|
| E1 | Managed policy | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`; Linux: `/etc/claude-code/CLAUDE.md`; Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Org-wide | All users |
| E2 | Project memory | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Project | Team (VCS) |
| E3 | Project rules | `./.claude/rules/*.md` | Project | Team (VCS) |
| E4 | User memory | `~/.claude/CLAUDE.md` | All projects | Just you |
| E5 | User rules | `~/.claude/rules/*.md` | All projects | Just you |
| E6 | Local memory | `./CLAUDE.local.md` | Project | Just you (gitignored) |
| E7 | Auto memory | `~/.claude/projects/<project>/memory/` | Per project (per git repo) | Just you |

#### Memory Features

| # | Feature | Description |
|---|---------|-------------|
| E8 | `@path/to/import` | Import other files from CLAUDE.md (relative paths, max depth 5). First-time external imports show approval dialog |
| E9 | Path-specific rules | `paths:` frontmatter in `.claude/rules/*.md` with glob patterns. Only loaded when Claude reads matching files |
| E10 | Auto memory | Claude saves patterns, commands, preferences automatically; `MEMORY.md` first 200 lines loaded at session start; topic files loaded on demand |
| E11 | `/memory` command | Browse loaded CLAUDE.md and rules files, toggle auto memory, link to open auto memory folder |
| E12 | `/init` command | Bootstrap CLAUDE.md for a codebase. Set `CLAUDE_CODE_NEW_INIT=true` for interactive multi-phase flow (CLAUDE.md, skills, hooks) |
| E13 | `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | `=1` force off, `=0` force on |
| E14 | `autoMemoryEnabled` setting | Toggle auto memory per project |
| E15 | `autoMemoryDirectory` setting | Custom memory storage location. Accepted from policy, local, and user settings only (not project, for security) |
| E16 | Child directory discovery | CLAUDE.md in subdirectories loaded on demand when Claude reads files there |
| E17 | `--add-dir` with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | Load memory from additional directories |
| E18 | `claudeMdExcludes` setting | Skip specific CLAUDE.md files by path or glob pattern. For monorepos. Managed CLAUDE.md cannot be excluded. Configurable at any settings layer; arrays merge |
| E19 | `InstructionsLoaded` hook | Debug which CLAUDE.md/rules files are loaded, when, and why. Fields: `load_reason`, `parent_file_path`, `trigger_file_path` |
| E20 | Symlinks in `.claude/rules/` | Supported for sharing rules across projects. Circular symlinks detected gracefully |

---

### Category F — Settings and Permissions

**Docs:** https://code.claude.com/docs/en/settings
**Permissions:** https://code.claude.com/docs/en/permissions
**Sandbox:** https://code.claude.com/docs/en/sandboxing
**Env vars:** https://code.claude.com/docs/en/env-vars

#### Settings Precedence (highest to lowest)

1. Managed (cannot be overridden)
2. CLI arguments (temporary session)
3. Local (`.claude/settings.local.json`)
4. Project (`.claude/settings.json`)
5. User (`~/.claude/settings.json`)

#### Permission Settings

| # | Key | Description |
|---|-----|-------------|
| F1 | `permissions.allow` | Auto-approve matching tools: `Bash(npm run *)`, `Read(~/.zshrc)` |
| F2 | `permissions.deny` | Block matching tools: `Agent(Explore)`, `Read(./.env)` |
| F3 | `permissions.ask` | Always prompt: `Bash(git push *)` |
| F4 | `permissions.defaultMode` | Default permission mode for sessions |
| F5 | `permissions.additionalDirectories` | Extra working directories |
| F6 | `permissions.disableBypassPermissionsMode` | Set to `"disable"` to prevent `bypassPermissions` mode |

Permission rule syntax: `Tool` or `Tool(specifier)`. Evaluated in order:
deny first, then ask, then allow. First match wins.

#### Key Settings

| # | Setting | Description |
|---|---------|-------------|
| F7 | `model` | Override default model |
| F8 | `availableModels` | Restrict which models users can select via `/model`, `--model`, Config tool |
| F9 | `modelOverrides` | Map Anthropic model IDs to provider-specific IDs (e.g., Bedrock ARNs) |
| F10 | `effortLevel` | Persist effort level across sessions: `"low"`, `"medium"`, `"high"` |
| F11 | `hooks` | Hook configuration (same format as hooks.json) |
| F12 | `env` | Environment variables for every session |
| F13 | `agent` | Run main thread as a named subagent (system prompt, tools, model from that agent) |
| F14 | `outputStyle` | Adjust system prompt output style |
| F15 | `language` | Claude's preferred response language |
| F16 | `attribution` | Customize git commit and PR attribution. `{commit, pr}` — empty string hides attribution |
| F17 | `includeGitInstructions` | Include built-in commit/PR workflow instructions in system prompt (default: `true`). Env: `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS` |
| F18 | `statusLine` | Custom status line configuration: `{type: "command", command: "..."}` |
| F19 | `fileSuggestion` | Custom script for `@` file autocomplete. Receives JSON stdin with `query` field |
| F20 | `respectGitignore` | Control whether `@` file picker respects .gitignore (default: `true`) |
| F21 | `alwaysThinkingEnabled` | Enable extended thinking by default for all sessions |
| F22 | `plansDirectory` | Custom plan file storage location (default: `~/.claude/plans`) |
| F23 | `cleanupPeriodDays` | Session transcript cleanup period (default: 30). `0` = delete all + disable persistence |
| F24 | `autoUpdatesChannel` | `"stable"` (~1 week old, skips regressions) or `"latest"` (default) |
| F25 | `apiKeyHelper` | Custom script for auth value generation |
| F26 | `$schema` | JSON schema for IDE autocomplete: `https://json.schemastore.org/claude-code-settings.json` |
| F27 | `spinnerVerbs` | Customize spinner action verbs. `{mode: "replace"|"append", verbs: [...]}` |
| F28 | `spinnerTipsEnabled` | Show/hide spinner tips (default: `true`) |
| F29 | `spinnerTipsOverride` | Custom spinner tips. `{excludeDefault: bool, tips: [...]}` |
| F30 | `voiceEnabled` | Enable push-to-talk voice dictation (requires Claude.ai account) |
| F31 | `teammateMode` | Agent team display: `auto`, `in-process`, `tmux` |
| F32 | `fastModePerSessionOptIn` | Require per-session fast mode opt-in |
| F33 | `companyAnnouncements` | Startup messages for users (array, random rotation) |

#### Managed-Only Settings

| # | Setting | Description |
|---|---------|-------------|
| F34 | `allowManagedHooksOnly` | Block user/project/plugin hooks |
| F35 | `allowManagedPermissionRulesOnly` | Only managed permission rules apply |
| F36 | `allowManagedMcpServersOnly` | Only admin-defined MCP server allowlist applies |
| F37 | `strictKnownMarketplaces` | Allowlist of plugin marketplaces users can add |
| F38 | `blockedMarketplaces` | Blocklist of marketplace sources |
| F39 | `pluginTrustMessage` | Custom message appended to plugin trust warning |

#### Sandbox Settings

| # | Setting | Description |
|---|---------|-------------|
| F40 | `sandbox.enabled` | Enable bash sandboxing (macOS, Linux, WSL2) |
| F41 | `sandbox.autoAllowBashIfSandboxed` | Auto-approve sandboxed commands (default: `true`) |
| F42 | `sandbox.excludedCommands` | Commands that run outside sandbox |
| F43 | `sandbox.allowUnsandboxedCommands` | Allow `dangerouslyDisableSandbox` escape hatch (default: `true`). Set `false` for strict enforcement |
| F44 | `sandbox.filesystem.allowWrite` | Additional writable paths. Merged with `Edit(...)` allow rules |
| F45 | `sandbox.filesystem.denyWrite` | Blocked write paths. Merged with `Edit(...)` deny rules |
| F46 | `sandbox.filesystem.denyRead` | Blocked read paths. Merged with `Read(...)` deny rules |
| F47 | `sandbox.filesystem.allowRead` | Re-allowed read paths within denyRead regions |
| F48 | `sandbox.filesystem.allowManagedReadPathsOnly` | (Managed) Only managed allowRead paths apply |
| F49 | `sandbox.network.allowedDomains` | Allowed outbound domains. Supports wildcards |
| F50 | `sandbox.network.allowUnixSockets` | Unix socket paths accessible in sandbox |
| F51 | `sandbox.network.allowAllUnixSockets` | Allow all Unix socket connections |
| F52 | `sandbox.network.allowLocalBinding` | Allow binding to localhost ports (macOS only) |
| F53 | `sandbox.network.allowManagedDomainsOnly` | (Managed) Only managed domains apply |
| F54 | `sandbox.network.httpProxyPort` | Custom HTTP proxy port |
| F55 | `sandbox.network.socksProxyPort` | Custom SOCKS5 proxy port |
| F56 | `sandbox.enableWeakerNestedSandbox` | Weaker sandbox for unprivileged Docker (Linux/WSL2). Reduces security |
| F57 | `sandbox.enableWeakerNetworkIsolation` | (macOS) Allow TLS trust service. Reduces security |

Sandbox path prefixes: `//` = absolute, `~/` = home, `/` = relative to settings file, `./` = relative.

#### Environment Variables (Selected)

| # | Variable | Description |
|---|----------|-------------|
| F58 | `ANTHROPIC_MODEL` | Model name override |
| F59 | `CLAUDE_CODE_SUBAGENT_MODEL` | Subagent model override |
| F60 | `MAX_THINKING_TOKENS` | Extended thinking token budget |
| F61 | `CLAUDE_CODE_EFFORT_LEVEL` | `low`, `medium`, `high` |
| F62 | `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Trigger compaction earlier (e.g., `50`) |
| F63 | `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | Disable background task functionality |
| F64 | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enable agent teams (`1`) |
| F65 | `SLASH_COMMAND_TOOL_CHAR_BUDGET` | Override skill description char budget |
| F66 | `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | Disable auto memory (`1`) |
| F67 | `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS` | Disable built-in git workflow instructions |
| F68 | `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | Load CLAUDE.md from `--add-dir` directories (`1`) |
| F69 | `CLAUDE_CODE_NEW_INIT` | Enable interactive multi-phase `/init` (`true`) |

---

## Audit Methodology

When auditing a plugin or workflow against this inventory, follow these phases:

### Phase 1: Build the Feature Inventory

Use the categories above as your complete catalog. For each feature, determine
whether it is relevant to the target workflow (yes/no/maybe).

### Phase 2: Gap Analysis

Read the target document and for EVERY feature in the inventory, determine:

- **Used** — The document uses this feature correctly
- **Partial** — The document references this but incompletely or incorrectly
- **Not used, should be** — The document would benefit from this feature
- **Not used, correctly omitted** — State why it's correctly excluded

Present as tables organized by category. For every gap or partial, write a
concrete revision recommendation with enough detail to implement (YAML
frontmatter, hook JSON, script content, or directory layout).

### Phase 3: Prioritized Recommendations

Sort into four tiers:

**Pending Decisions (PD):** Changes already decided but not yet applied. These
are not gaps — they are known items awaiting implementation. List them first
to distinguish from new findings. Include the decision rationale and any
tradeoffs noted at decision time.

**Must-Have (Correctness / Safety):** Gaps that could cause incorrect behavior,
uncontrolled costs, or violated constraints. Examples: missing `maxTurns`,
missing `disallowedTools` on read-only agents, missing
`disable-model-invocation` on user-invoked-only skills.

**Should-Have (Quality / Robustness):** Improvements to reliability, DX, or
alignment with Anthropic best practices. Examples: adding `memory` fields,
`PostToolUse` auto-test hooks, `ultrathink` for planning agents.

**Nice-to-Have (Distribution / UX):** Packaging, sharing, or polish. Examples:
LSP integration, desktop notifications, dynamic context injection.

Number every recommendation with a one-line rationale.

### Phase 4: Revised Specifications

For every Must-Have and Should-Have, provide the **complete revised component
specification** — not a diff, but the full YAML frontmatter and any associated
script or config file. Copy-paste ready.

### Phase 5: Exclusion Table

End with a table of features evaluated and **correctly excluded**, with the
reason. This proves completeness.

### Output Format

Produce a single Markdown document:
1. Feature Inventory (tables by category)
2. Gap Analysis (status tables with revision notes)
3. Prioritized Recommendations (numbered, tiered)
4. Revised Component Specifications (copy-paste ready)
5. Correctly Excluded Features (table)

Title: `[Workflow Name] — Claude Code Extensibility Audit`

### Constraints

- Source from https://code.claude.com/docs/en/ only. Do not invent features.
- If a page cannot be accessed, note it and work from the inventory above.
- Every recommendation must cite the specific documentation URL.
- Note experimental features explicitly (e.g., agent teams require env flag).
- Prefer command-based hooks over prompt-based where deterministic logic is
  sufficient — this is an Anthropic best practice from the hooks docs.
- When recommending `maxTurns`, justify based on expected task complexity.

---

## Documentation URL Index

Quick-reference for all Claude Code documentation pages:

| Page | URL |
|------|-----|
| Overview | https://code.claude.com/docs/en/overview |
| Quickstart | https://code.claude.com/docs/en/quickstart |
| How Claude Code works | https://code.claude.com/docs/en/how-claude-code-works |
| Best practices | https://code.claude.com/docs/en/best-practices |
| Common workflows | https://code.claude.com/docs/en/common-workflows |
| Interactive mode | https://code.claude.com/docs/en/interactive-mode |
| Features overview | https://code.claude.com/docs/en/features-overview |
| **Sub-agents** | https://code.claude.com/docs/en/sub-agents |
| **Skills** | https://code.claude.com/docs/en/skills |
| **Hooks (guide)** | https://code.claude.com/docs/en/hooks-guide |
| **Hooks (reference)** | https://code.claude.com/docs/en/hooks |
| **Plugins (create)** | https://code.claude.com/docs/en/plugins |
| **Plugins (reference)** | https://code.claude.com/docs/en/plugins-reference |
| Plugins (discover) | https://code.claude.com/docs/en/discover-plugins |
| Plugins (marketplaces) | https://code.claude.com/docs/en/plugin-marketplaces |
| **Memory / CLAUDE.md** | https://code.claude.com/docs/en/memory |
| **Settings** | https://code.claude.com/docs/en/settings |
| **Permissions** | https://code.claude.com/docs/en/permissions |
| **Sandboxing** | https://code.claude.com/docs/en/sandboxing |
| **Environment variables** | https://code.claude.com/docs/en/env-vars |
| Agent teams | https://code.claude.com/docs/en/agent-teams |
| MCP servers | https://code.claude.com/docs/en/mcp |
| Model configuration | https://code.claude.com/docs/en/model-config |
| Output styles | https://code.claude.com/docs/en/output-styles |
| Status line | https://code.claude.com/docs/en/statusline |
| Voice dictation | https://code.claude.com/docs/en/voice-dictation |
| Fast mode | https://code.claude.com/docs/en/fast-mode |
| Checkpointing | https://code.claude.com/docs/en/checkpointing |
| Sessions | https://code.claude.com/docs/en/sessions |
| Scheduled tasks | https://code.claude.com/docs/en/scheduled-tasks |
| Built-in commands | https://code.claude.com/docs/en/commands |
| Tools reference | https://code.claude.com/docs/en/tools-reference |
| Keybindings | https://code.claude.com/docs/en/keybindings |
| CLI reference | https://code.claude.com/docs/en/cli-reference |
| Headless / SDK | https://code.claude.com/docs/en/headless |
| GitHub Actions | https://code.claude.com/docs/en/github-actions |
| GitLab CI/CD | https://code.claude.com/docs/en/gitlab-ci-cd |
| Code review | https://code.claude.com/docs/en/code-review |
| Chrome (beta) | https://code.claude.com/docs/en/chrome |
| Claude Code on the web | https://code.claude.com/docs/en/claude-code-on-the-web |
| Desktop app | https://code.claude.com/docs/en/desktop |
| Desktop quickstart | https://code.claude.com/docs/en/desktop-quickstart |
| VS Code | https://code.claude.com/docs/en/vs-code |
| JetBrains IDEs | https://code.claude.com/docs/en/jetbrains |
| Slack | https://code.claude.com/docs/en/slack |
| Remote control | https://code.claude.com/docs/en/remote-control |
| Dev containers | https://code.claude.com/docs/en/devcontainer |
| Terminal config | https://code.claude.com/docs/en/terminal-config |
| Advanced setup | https://code.claude.com/docs/en/setup |
| Authentication | https://code.claude.com/docs/en/authentication |
| Amazon Bedrock | https://code.claude.com/docs/en/amazon-bedrock |
| Google Vertex AI | https://code.claude.com/docs/en/google-vertex-ai |
| Microsoft Foundry | https://code.claude.com/docs/en/microsoft-foundry |
| LLM gateway | https://code.claude.com/docs/en/llm-gateway |
| Enterprise network config | https://code.claude.com/docs/en/network-config |
| Enterprise deployment | https://code.claude.com/docs/en/third-party-integrations |
| Server-managed settings | https://code.claude.com/docs/en/server-managed-settings |
| Analytics | https://code.claude.com/docs/en/analytics |
| Monitoring | https://code.claude.com/docs/en/monitoring-usage |
| Manage costs | https://code.claude.com/docs/en/costs |
| Data usage | https://code.claude.com/docs/en/data-usage |
| Security | https://code.claude.com/docs/en/security |
| Legal and compliance | https://code.claude.com/docs/en/legal-and-compliance |
| Zero data retention | https://code.claude.com/docs/en/zero-data-retention |
| Troubleshooting | https://code.claude.com/docs/en/troubleshooting |
| Changelog | https://code.claude.com/docs/en/changelog |
| Full docs (LLM-friendly) | https://code.claude.com/docs/llms.txt |

---

## Revision History

| Date | Changes |
|------|---------|
| 2026-03-18 | v3.0 — Full rewrite from current docs. **New in Category A:** `background` field (A12), `isolation` field (A13), @-mention invocation (A24), `--agent`/`agent` setting (A25), `/agents` command (A26), plugin agent restrictions (A27), transcript persistence (A28). Expanded: `model` now accepts full IDs (A5), `mcpServers` supports inline definitions (A10), `Agent(type)` restriction syntax (A15), background execution with Ctrl+B (A19). **New in Category B:** `${CLAUDE_SKILL_DIR}` substitution (B14), bundled skills (B24). **New in Category C:** `http` hook type (C23), 7 new events — `InstructionsLoaded` (C2), `ConfigChange` (C14), `WorktreeCreate`/`Remove` (C15-C16), `PostCompact` (C18), `Elicitation`/`ElicitationResult` (C19-C20). New fields: `url`, `headers`, `allowedEnvVars` for HTTP hooks (C28-C30), `${CLAUDE_PLUGIN_DATA}` (C40), `last_assistant_message` (C47). Hook settings: `allowedHttpHookUrls`, `httpHookAllowedEnvVars`. **New in Category D:** `${CLAUDE_PLUGIN_DATA}` persistent directory (D17), plugin `settings.json` (D26), plugin agent restrictions (D27), path traversal limitations (D28). LSP fields expanded. **New in Category E:** `autoMemoryEnabled` (E14), `autoMemoryDirectory` (E15), `claudeMdExcludes` (E18), `InstructionsLoaded` hook (E19), symlinks in rules (E20). **New in Category F:** 30+ new settings fields (F7-F69). Sandbox settings massively expanded (F40-F57). New managed-only settings (F34-F39). New env vars (F66-F69). URL index expanded from 18 to 60+ pages. |
| 2026-02-14 | v2.1 — Round 1 CC×Web collaboration. Added PermissionRequest hookSpecificOutput, PostToolUse hookSpecificOutput, PreToolUse deprecation note, `$TOOL_INPUT`, Pending Decisions audit tier. |
| 2026-02-14 | v2.0 — Complete rewrite from docs.claude.com to code.claude.com URLs. |
| 2026-02-10 | v1.0 — Original audit prompt with 6 categories. |
