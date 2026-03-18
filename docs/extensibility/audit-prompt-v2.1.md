# Claude Code Extensibility Reference & Audit Prompt

> **Purpose:** Living reference of every Claude Code extensibility feature with
> direct documentation URLs. Use it to (1) audit a plugin or workflow against the
> full feature set, (2) verify the plugin follows Anthropic recommendations, and
> (3) identify new features to adopt when Anthropic updates their docs.
>
> **Last verified:** 2026-02-14
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
claude "Read the extensibility reference at ./docs/extensibility-audit-prompt.md, \
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
docs/extensibility-audit-prompt.md

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
| A3 | `tools` | Allowlist of tools the subagent can use; inherits all if omitted | No |
| A4 | `disallowedTools` | Denylist — hard-deny tools removed from any inherited set | No |
| A5 | `model` | `sonnet`, `opus`, `haiku`, or `inherit` (default: `inherit`) | No |
| A6 | `permissionMode` | `default`, `acceptEdits`, `delegate`, `dontAsk`, `bypassPermissions`, `plan` | No |
| A7 | `maxTurns` | Maximum agentic turns before forced stop; cost-control lever | No |
| A8 | `skills` | Skills preloaded into subagent context at startup (full content injected) | No |
| A9 | `memory` | Persistent memory scope: `user`, `project`, or `local` | No |
| A10 | `mcpServers` | MCP servers available to this subagent (name reference or inline definition) | No |
| A11 | `hooks` | Lifecycle hooks scoped to this subagent; `Stop` auto-converts to `SubagentStop` | No |

#### Behavioral Features

| # | Feature | Description |
|---|---------|-------------|
| A12 | Subagent resumption | Resume by agent ID to continue with full conversation history preserved |
| A13 | `Task(agent_type)` restriction | Restrict which subagent types can be spawned (only for `--agent` main thread) |
| A14 | Agent teams | Multiple instances with shared task lists; experimental. Env: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Token multiplier is workload-dependent (empirically ~7x observed) |
| A15 | Built-in agents | `Explore` (haiku, read-only), `Plan` (inherit, read-only), `general-purpose` (inherit, all tools), `Bash`, `statusline-setup`, `claude-code-guide` |
| A16 | No-nesting constraint | Subagents cannot spawn other subagents; only the main thread can spawn |
| A17 | Foreground/background execution | Background subagents run concurrently; pre-approve permissions; no MCP tools |
| A18 | Auto-compaction | Subagents auto-compact at ~95% capacity; configurable via `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` |
| A19 | CLI-defined subagents | `--agents` flag accepts JSON for session-only agents (not saved to disk) |
| A20 | Scope precedence | `--agents` flag > `.claude/agents/` > `~/.claude/agents/` > plugin `agents/` |
| A21 | Disable specific subagents | `permissions.deny: ["Task(Explore)", "Task(my-agent)"]` |

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
| B1 | `name` | Slash command name (`/name`); defaults to directory name if omitted | No |
| B2 | `description` | When Claude should use this skill; used for auto-invocation decisions | Recommended |
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
| B11 | `$ARGUMENTS` | All arguments passed when invoking the skill |
| B12 | `$ARGUMENTS[N]` / `$N` | Access specific argument by 0-based index |
| B13 | `${CLAUDE_SESSION_ID}` | Current session ID for logging or session-specific files |

#### Advanced Features

| # | Feature | Description |
|---|---------|-------------|
| B14 | Dynamic context injection (`!`cmd``) | Shell commands run before skill content sent to Claude; output replaces placeholder |
| B15 | `ultrathink` keyword | Include "ultrathink" anywhere in skill content to enable extended thinking |
| B16 | Supporting files | Additional files in skill directory (templates, examples, scripts); referenced from SKILL.md |
| B17 | Skills-in-subagents duality | `context: fork` + `agent` in skill vs `skills:` field in subagent; inverse patterns |
| B18 | `Skill()` permission syntax | `Skill(name)` exact match, `Skill(name *)` prefix match in permissions |
| B19 | Live change detection | Skills from `--add-dir` picked up during session without restart |
| B20 | Invocation matrix | See table below |
| B21 | Automatic subdirectory discovery | Skills from nested `.claude/skills/` in monorepo packages |
| B22 | Char budget | Skill descriptions budget: 2% of context window (fallback 16k chars); override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` |

#### Invocation Matrix (B20)

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

Hooks are user-defined shell commands, LLM prompts, or agents that execute
automatically at specific lifecycle points.

#### Hook Events

| # | Event | When It Fires | Can Block? | Matcher Field |
|---|-------|--------------|------------|---------------|
| C1 | `SessionStart` | Session begins or resumes | No | How started: `startup`, `resume`, `clear`, `compact` |
| C2 | `UserPromptSubmit` | User submits prompt, before processing | Yes | No matcher (always fires) |
| C3 | `PreToolUse` | Before tool call executes | Yes | Tool name: `Bash`, `Edit`, `Write`, `Read`, `mcp__*` |
| C4 | `PermissionRequest` | Permission dialog appears | Yes | Tool name |
| C5 | `PostToolUse` | After tool succeeds | No (feedback only) | Tool name |
| C6 | `PostToolUseFailure` | After tool fails | No (feedback only) | Tool name |
| C7 | `Notification` | Claude Code sends notification | No | Type: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` |
| C8 | `SubagentStart` | Subagent spawned | No (context injection) | Agent type name |
| C9 | `SubagentStop` | Subagent finishes | Yes | Agent type name |
| C10 | `Stop` | Main agent finishes responding | Yes | No matcher (always fires) |
| C11 | `TeammateIdle` | Agent team member about to idle | Yes (exit 2 only) | No matcher |
| C12 | `TaskCompleted` | Task marked completed | Yes (exit 2 only) | No matcher |
| C13 | `PreCompact` | Before context compaction | No | Trigger: `manual`, `auto` |
| C14 | `SessionEnd` | Session terminates | No | Reason: `clear`, `logout`, `prompt_input_exit`, etc. |

#### Hook Types

| # | Type | Description | Default Timeout |
|---|------|-------------|-----------------|
| C15 | `command` | Execute shell script; JSON stdin/stdout; exit codes 0/2 | 600s |
| C16 | `prompt` | Single-turn LLM evaluation; returns `{ok, reason}` | 30s |
| C17 | `agent` | Multi-turn subagent with tools (Read, Grep, Glob); up to 50 turns | 60s |

#### Hook Handler Fields

| # | Field | Required | Description |
|---|-------|----------|-------------|
| C18 | `type` | Yes | `"command"`, `"prompt"`, or `"agent"` |
| C19 | `command` | Yes (command) | Shell command to execute |
| C20 | `prompt` | Yes (prompt/agent) | Prompt text; `$ARGUMENTS` for hook input JSON |
| C21 | `model` | No | Model for prompt/agent hooks |
| C22 | `timeout` | No | Seconds before canceling |
| C23 | `statusMessage` | No | Custom spinner text while hook runs |
| C24 | `once` | No | If `true`, runs once per session then removed (skills only) |
| C25 | `async` | No | If `true`, runs in background without blocking (command only) |

#### Hook Variables & Protocol

| # | Feature | Description |
|---|---------|-------------|
| C26 | `$ARGUMENTS` | Placeholder in prompt hooks for JSON input data |
| C27 | `$CLAUDE_PROJECT_DIR` | Project root path for portable script references |
| C28 | `${CLAUDE_PLUGIN_ROOT}` | Plugin root directory for bundled scripts |
| C29 | `$CLAUDE_ENV_FILE` | SessionStart only: file path for persisting env vars |
| C30 | `$CLAUDE_CODE_REMOTE` | Set to `"true"` in remote web environments |
| C31 | `$TOOL_INPUT` | Appears in sub-agents docs as command-line variable for hook commands; hook commands also receive tool input as JSON on stdin |
| C32 | Exit code 0 | Allow; stdout parsed for JSON output |
| C33 | Exit code 2 | Block/deny; stderr fed back as error message |
| C34 | Other exit codes | Non-blocking error; stderr shown in verbose mode |
| C35 | `stop_hook_active` | Boolean in Stop/SubagentStop input preventing infinite loops |

#### JSON Output Fields (on exit 0)

| Field | Description |
|-------|-------------|
| `continue` | If `false`, Claude stops entirely |
| `stopReason` | Message shown to user when `continue: false` |
| `suppressOutput` | If `true`, hides stdout from verbose mode |
| `systemMessage` | Warning message shown to user |
| `decision` | `"block"` for Stop/SubagentStop/PostToolUse/UserPromptSubmit |
| `reason` | Explanation when `decision: "block"` |
| `additionalContext` | Context injected into Claude's conversation |
| `hookSpecificOutput` | Event-specific control (PreToolUse, PermissionRequest) |

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
| `decision.updatedPermissions` | For `"allow"` only: applies "always allow" rule updates |
| `decision.message` | For `"deny"` only: tells Claude why permission was denied |
| `decision.interrupt` | For `"deny"` only: if `true`, stops Claude |

#### PostToolUse hookSpecificOutput

| Field | Description |
|-------|-------------|
| `additionalContext` | Additional context for Claude to consider |
| `updatedMCPToolOutput` | For MCP tools only: replaces the tool's output with the provided value |

#### MCP Tool Matching

MCP tools follow pattern `mcp__<server>__<tool>`. Use regex: `mcp__memory__.*`
to match all tools from the memory server.

#### Hook Locations (precedence)

| Location | Scope | Shareable |
|----------|-------|-----------|
| `~/.claude/settings.json` | All projects | No |
| `.claude/settings.json` | Project | Yes (VCS) |
| `.claude/settings.local.json` | Project | No (gitignored) |
| Managed policy settings | Org-wide | Yes (admin) |
| Plugin `hooks/hooks.json` | Plugin | Yes (bundled) |
| Skill/agent frontmatter | Component lifetime | Yes (defined in file) |

---

### Category D — Plugins

**Docs:** https://code.claude.com/docs/en/plugins
**Reference:** https://code.claude.com/docs/en/plugins-reference
**Marketplaces:** https://code.claude.com/docs/en/plugin-marketplaces
**Discover/Install:** https://code.claude.com/docs/en/discover-plugins

#### Plugin Manifest (`.claude-plugin/plugin.json`)

| # | Field | Required | Description |
|---|-------|----------|-------------|
| D1 | `name` | Yes | Unique identifier (kebab-case); used for skill namespacing |
| D2 | `version` | No | Semantic version |
| D3 | `description` | No | Brief explanation of plugin purpose |
| D4 | `author` | No | `{name, email, url}` |
| D5 | `homepage` | No | Documentation URL |
| D6 | `repository` | No | Source code URL |
| D7 | `license` | No | License identifier |
| D8 | `keywords` | No | Discovery tags |
| D9 | `commands` | No | Additional command files/directories |
| D10 | `agents` | No | Additional agent files |
| D11 | `skills` | No | Additional skill directories |
| D12 | `hooks` | No | Hook config paths or inline config |
| D13 | `mcpServers` | No | MCP config paths or inline config |
| D14 | `lspServers` | No | LSP server config paths or inline config |
| D15 | `outputStyles` | No | Output style files/directories |

#### Plugin Directory Structure

```
plugin-root/
├── .claude-plugin/
│   └── plugin.json           # Manifest (optional — auto-discovery works)
├── commands/                 # Legacy command markdown files
├── agents/                   # Subagent definitions
├── skills/                   # Agent Skills (SKILL.md in subdirs)
├── hooks/
│   └── hooks.json            # Hook configuration
├── .mcp.json                 # MCP server definitions
├── .lsp.json                 # LSP server configurations
├── scripts/                  # Hook and utility scripts
├── LICENSE
└── CHANGELOG.md
```

#### Plugin Features

| # | Feature | Description |
|---|---------|-------------|
| D16 | `${CLAUDE_PLUGIN_ROOT}` | Absolute path to installed plugin directory |
| D17 | Scopes | `user` (~/.claude/), `project` (.claude/), `local` (.claude/*.local.*), `managed` |
| D18 | Namespacing | Skills prefixed: `/plugin-name:skill-name` |
| D19 | `--plugin-dir` | Dev flag: load plugin directly without installation |
| D20 | Plugin caching | Plugins copied to cache directory for security |
| D21 | CLI commands | `install`, `uninstall`, `enable`, `disable`, `update`, `validate` |
| D22 | Marketplace sources | github, git, url, npm, pip, file, directory, hostPattern |
| D23 | LSP servers | `.lsp.json` for code intelligence (go-to-definition, find references, diagnostics) |
| D24 | `strict: false` | In marketplace entry: merge manifest from marketplace + plugin.json |

---

### Category E — Memory / CLAUDE.md

**Docs:** https://code.claude.com/docs/en/memory

#### Memory Locations

| # | Type | Location | Scope | Shared |
|---|------|----------|-------|--------|
| E1 | Managed policy | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) or `/etc/claude-code/CLAUDE.md` (Linux) | Org-wide | All users |
| E2 | Project memory | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Project | Team (VCS) |
| E3 | Project rules | `./.claude/rules/*.md` | Project | Team (VCS) |
| E4 | User memory | `~/.claude/CLAUDE.md` | All projects | Just you |
| E5 | User rules | `~/.claude/rules/*.md` | All projects | Just you |
| E6 | Local memory | `./CLAUDE.local.md` | Project | Just you (gitignored) |
| E7 | Auto memory | `~/.claude/projects/<project>/memory/` | Per project | Just you |

#### Memory Features

| # | Feature | Description |
|---|---------|-------------|
| E8 | `@path/to/import` | Import other files from CLAUDE.md (relative paths, max depth 5) |
| E9 | Path-specific rules | `paths:` frontmatter in `.claude/rules/*.md` with glob patterns |
| E10 | Auto memory | Claude saves patterns, commands, preferences automatically; 200-line MEMORY.md limit |
| E11 | `/memory` command | Open memory files in system editor |
| E12 | `/init` command | Bootstrap CLAUDE.md for a codebase |
| E13 | `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | `=1` force off, `=0` force on |
| E14 | Child directory discovery | CLAUDE.md in subdirectories loaded on demand when Claude reads files there |
| E15 | `--add-dir` with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | Load memory from additional directories |

---

### Category F — Settings and Permissions

**Docs:** https://code.claude.com/docs/en/settings
**Permissions:** https://code.claude.com/docs/en/permissions

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
| F2 | `permissions.deny` | Block matching tools: `Task(Explore)`, `Read(./.env)` |
| F3 | `permissions.ask` | Always prompt: `Bash(git push *)` |
| F4 | `permissions.defaultMode` | Default permission mode for sessions |
| F5 | `permissions.additionalDirectories` | Extra working directories |

#### Key Settings

| # | Setting | Description |
|---|---------|-------------|
| F6 | `model` | Override default model |
| F7 | `hooks` | Hook configuration (same format as hooks.json) |
| F8 | `env` | Environment variables for every session |
| F9 | `disableAllHooks` | Disable all hooks |
| F10 | `allowManagedHooksOnly` | (Managed) block user/project/plugin hooks |
| F11 | `allowManagedPermissionRulesOnly` | (Managed) only managed permission rules apply |
| F12 | `language` | Claude's preferred response language |
| F13 | `outputStyle` | Adjust system prompt output style |
| F14 | `$schema` | JSON schema for IDE autocomplete: `https://json.schemastore.org/claude-code-settings.json` |

#### Sandbox Settings

| # | Setting | Description |
|---|---------|-------------|
| F15 | `sandbox.enabled` | Enable bash sandboxing |
| F16 | `sandbox.autoAllowBashIfSandboxed` | Auto-approve sandboxed commands |
| F17 | `sandbox.excludedCommands` | Commands run outside sandbox |
| F18 | `sandbox.network.allowedDomains` | Allowed outbound domains |

#### Environment Variables (Selected)

| # | Variable | Description |
|---|----------|-------------|
| F19 | `ANTHROPIC_MODEL` | Model name override |
| F20 | `CLAUDE_CODE_SUBAGENT_MODEL` | Subagent model override |
| F21 | `MAX_THINKING_TOKENS` | Extended thinking token budget |
| F22 | `CLAUDE_CODE_EFFORT_LEVEL` | `low`, `medium`, `high` (Opus 4.6 only) |
| F23 | `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Trigger compaction earlier (e.g., `50`) |
| F24 | `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | Disable background task functionality |
| F25 | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enable agent teams (`1`) |
| F26 | `SLASH_COMMAND_TOOL_CHAR_BUDGET` | Override skill description char budget |

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
| Sub-agents | https://code.claude.com/docs/en/sub-agents |
| Skills | https://code.claude.com/docs/en/skills |
| Hooks (guide) | https://code.claude.com/docs/en/hooks-guide |
| Hooks (reference) | https://code.claude.com/docs/en/hooks |
| Plugins (create) | https://code.claude.com/docs/en/plugins |
| Plugins (reference) | https://code.claude.com/docs/en/plugins-reference |
| Plugins (discover) | https://code.claude.com/docs/en/discover-plugins |
| Plugins (marketplaces) | https://code.claude.com/docs/en/plugin-marketplaces |
| Memory / CLAUDE.md | https://code.claude.com/docs/en/memory |
| Settings | https://code.claude.com/docs/en/settings |
| Permissions | https://code.claude.com/docs/en/permissions |
| Agent Teams | https://code.claude.com/docs/en/agent-teams |
| MCP Servers | https://code.claude.com/docs/en/mcp |
| Interactive Mode | https://code.claude.com/docs/en/interactive-mode |
| Model Configuration | https://code.claude.com/docs/en/model-config |
| CLI Reference | https://code.claude.com/docs/en/cli-reference |
| Common Workflows | https://code.claude.com/docs/en/common-workflows |
| Headless / SDK | https://code.claude.com/docs/en/headless |
| Troubleshooting | https://code.claude.com/docs/en/troubleshooting |
| Full docs (LLM-friendly) | https://code.claude.com/docs/llms.txt |

---

## Revision History

| Date | Changes |
|------|---------|
| 2026-02-14 | v2.1 — Round 1 CC×Web collaboration. Added: Pending Decisions tier to audit methodology (Phase 3). Added PermissionRequest hookSpecificOutput section (nested decision object with behavior/updatedInput/updatedPermissions/message/interrupt). Added PostToolUse hookSpecificOutput (`updatedMCPToolOutput` for MCP tools). Added PreToolUse deprecation note (top-level `decision`/`reason` deprecated). Added `$TOOL_INPUT` hook variable (C31, from sub-agents docs example). Fixed A14 agent teams token claim to note empirical basis. Renumbered C31→C35. |
| 2026-02-14 | v2.0 — Complete rewrite. Moved from docs.claude.com to code.claude.com URLs. Added: LSP servers (D23), agent teams (A14), auto memory (E7/E10), rules directory (E3/E5/E9), sandbox settings (F15-F18), background subagents (A17), CLI-defined subagents (A19), scope precedence (A20), plugin caching (D20), MCP tool matching in hooks, PermissionRequest hook (C4), SessionEnd hook (C14), async hooks (C25), `once` field (C24), `statusMessage` (C23), `$CLAUDE_ENV_FILE` (C29), PreToolUse `updatedInput`, skill char budget (B22), subdirectory discovery (B21), `@import` syntax (E8), path-specific rules (E9), environment variables (F19-F26). Restructured as living reference with URL index. |
| 2026-02-10 | v1.0 — Original audit prompt targeting docs.claude.com with 6 categories. |
