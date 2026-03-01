# Agents / Subagents

**Docs**: [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)

## Built-in Subagents

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| **Explore** | Haiku | Read-only | File discovery, code search. Thoroughness: quick/medium/very thorough |
| **Plan** | Inherits | Read-only | Codebase research for plan mode |
| **general-purpose** | Inherits | All tools | Complex multi-step tasks |
| **Bash** | Inherits | Terminal | Commands in separate context |
| **statusline-setup** | Sonnet | -- | Configure status line |
| **Claude Code Guide** | Haiku | -- | Questions about Claude Code |

## Where Subagents Live (Priority Order)

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI flag (JSON) | Current session only | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All your projects | 3 |
| Plugin `agents/` | Where plugin is enabled | 4 (lowest) |

When multiple subagents share the same name, higher-priority location wins.

## Subagent File Format

Markdown files with YAML frontmatter + system prompt in body:

```markdown
---
name: code-reviewer
description: Reviews code for quality and security issues
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
model: sonnet
color: blue
permissionMode: default
maxTurns: 50
skills:
  - api-conventions
  - error-handling-patterns
mcpServers:
  - slack
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
memory: user
background: true
isolation: worktree
---

You are a senior code reviewer. Your task is to...
```

**Important**: Subagents receive only their system prompt (plus basic
environment details), NOT the full Claude Code system prompt.

## All Frontmatter Fields

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `name` | Yes | -- | Unique identifier. Lowercase letters and hyphens only |
| `description` | Yes | -- | When Claude should delegate to this subagent |
| `tools` | No | Inherit all | Tool allowlist (comma-separated or array) |
| `disallowedTools` | No | -- | Tool denylist. Ignored if `tools` is set |
| `model` | No | `inherit` | `sonnet`, `opus`, `haiku`, or `inherit` |
| `color` | No | -- | UI background color. Undocumented but functional. Values: `blue`, `cyan`, `green`, `yellow`, `magenta`, `red`, `pink` |
| `permissionMode` | No | `default` | See permission modes below |
| `maxTurns` | No | -- | Max agentic turns before stopping |
| `skills` | No | -- | Skills preloaded at startup (full content injected) |
| `mcpServers` | No | -- | MCP servers available (name ref or inline definition) |
| `hooks` | No | -- | Lifecycle hooks scoped to this subagent |
| `memory` | No | -- | Persistent memory scope: `user`, `project`, or `local` |
| `background` | No | `false` | Always run as background task |
| `isolation` | No | -- | `worktree` for temporary git worktree isolation |

## Tool Access Rules

- If `tools` (allowlist) is present, it is used exclusively; `disallowedTools` is ignored
- If `tools` is absent, subagent inherits all available tools minus `disallowedTools`
- `Agent(worker, researcher)` syntax in tools field restricts which subagent
  types can be spawned (only for main thread via `claude --agent`)
- **Subagents cannot spawn other subagents**

## Available Internal Tools

`Bash`, `Read`, `Write`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `LS`,
`NotebookEdit`, `NotebookRead`, `WebFetch`, `WebSearch`, `Agent` (formerly
`Task`), `TodoRead`, `TodoWrite`, `exit_plan_mode`

## Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission checking with prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny permission prompts (explicitly allowed tools still work) |
| `bypassPermissions` | Skip all permission checks |
| `plan` | Plan mode (read-only exploration) |

If parent uses `bypassPermissions`, that takes precedence and cannot be overridden.

## Persistent Memory

| Scope | Location | Use When |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Remember across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via VCS |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not committed |

When enabled:
- System prompt includes instructions for reading/writing to memory directory
- First 200 lines of `MEMORY.md` in memory directory are loaded at startup
- `Read`, `Write`, `Edit` tools automatically enabled

## Skills Preloading

Full content of each listed skill is injected into subagent's context at
startup. Subagents do NOT inherit skills from parent conversation.

## Hooks in Subagents

**In frontmatter** (scoped to subagent lifetime):

| Event | Matcher Input | When It Fires |
|-------|---------------|---------------|
| `PreToolUse` | Tool name | Before subagent uses a tool |
| `PostToolUse` | Tool name | After subagent uses a tool |
| `Stop` | (none) | When subagent finishes (auto-converted to SubagentStop) |

**In settings.json** (external):

| Event | Matcher Input | When It Fires |
|-------|---------------|---------------|
| `SubagentStart` | Agent type name | When subagent begins |
| `SubagentStop` | Agent type name | When subagent completes |

## Foreground vs Background

- **Foreground**: Blocking. Permission prompts and AskUserQuestion passed through
- **Background**: Concurrent. Permissions pre-approved at launch. Auto-deny
  anything not pre-approved. AskUserQuestion fails but subagent continues

Disable background: `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`

## CLI-Defined Subagents

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer.",
    "prompt": "You are a senior code reviewer.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

## Disable Specific Subagents

```json
{ "permissions": { "deny": ["Agent(Explore)", "Agent(my-custom-agent)"] } }
```

## Context and Transcripts

- Each invocation creates fresh context; resume via agent ID for continuation
- Transcripts stored at `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`
- Main conversation compaction does NOT affect subagent transcripts
- Auto-compaction at ~95% capacity (override: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`)
- Cleanup based on `cleanupPeriodDays` (default: 30 days)
