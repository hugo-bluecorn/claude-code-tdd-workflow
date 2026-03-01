# Agent Teams

**Docs**: [code.claude.com/docs/en/agent-teams](https://code.claude.com/docs/en/agent-teams)

## Overview

Experimental. Enable: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

Teams coordinate multiple Claude Code instances working in parallel:
- **Team lead**: Main session that creates team, spawns teammates, coordinates
- **Teammates**: Separate Claude instances working on tasks
- **Task list**: Shared work items with claiming via file locking
- **Mailbox**: Direct messaging between agents

## Teams vs Subagents

| Aspect | Subagents | Agent Teams |
|--------|-----------|-------------|
| Context | Own window; results return | Own window; fully independent |
| Communication | Report to main only | Message each other directly |
| Coordination | Main manages all | Shared task list, self-coordination |
| Best for | Focused tasks | Complex collaborative work |
| Token cost | Lower | Higher (each is full instance) |

## Display Modes

| Mode | Description |
|------|-------------|
| `in-process` | All in one terminal. `Shift+Down` cycles. Works anywhere |
| `tmux` | Each teammate gets own pane. Requires tmux or iTerm2 |
| `auto` (default) | Split panes if inside tmux, otherwise in-process |

## Task Coordination

- States: pending, in progress, completed
- Dependencies supported (blocked tasks can't be claimed)
- File-locking prevents race conditions
- Recommend 5-6 tasks per teammate

## Quality Hooks

- `TeammateIdle`: Exit 2 sends feedback, keeps teammate working
- `TaskCompleted`: Exit 2 prevents completion, sends feedback

## Plan Approval

Teammates can be required to plan in read-only mode before implementing.
Lead approves or rejects with feedback.

## Limitations

- No session resumption with in-process teammates
- One team per session; no nested teams
- Lead is fixed for lifetime
- Split panes not supported in VS Code terminal, Windows Terminal, Ghostty
