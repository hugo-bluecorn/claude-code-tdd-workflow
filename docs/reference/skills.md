# Skills

**Docs**: [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)

## What Skills Are

Skills are task-specific, reusable modules defined as `SKILL.md` files
following the [Agent Skills](https://agentskills.io) open standard. Claude
loads them automatically when relevant, or users invoke them with `/skill-name`.

Legacy `commands/` directories (plain markdown files) still work but `skills/`
is preferred. Both create slash commands; skills take precedence on name conflict.

## Skill Directory Structure

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Optional template for Claude to fill in
├── examples/
│   └── sample.md      # Optional example output
├── reference/         # Reference documentation files
│   └── patterns.md
└── scripts/
    └── validate.sh    # Optional scripts Claude can execute
```

## Where Skills Live (Priority Order)

| Location | Path | Priority |
|----------|------|----------|
| Enterprise | Managed settings | Highest |
| Personal | `~/.claude/skills/<name>/SKILL.md` | |
| Project | `.claude/skills/<name>/SKILL.md` | |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Lowest (namespaced) |

Higher-priority locations win for same-named skills. Plugin skills use
`plugin-name:skill-name` namespace so they never conflict with standalone skills.

Skills are also discovered from nested `.claude/skills/` in subdirectories
(monorepo support) and from `--add-dir` directories (live change detection).

## SKILL.md Format (Complete Frontmatter)

```yaml
---
name: my-skill
description: What this skill does and when to use it
argument-hint: [issue-number]
disable-model-invocation: true
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
context: fork
agent: Explore
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
---

Your skill instructions here in Markdown...
```

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `name` | No | Directory name | Lowercase, hyphens, max 64 chars |
| `description` | Recommended | First paragraph of body | Used by Claude to decide auto-invocation |
| `argument-hint` | No | -- | Hint shown in autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation` | No | `false` | If `true`, only user can invoke (description NOT in context) |
| `user-invocable` | No | `true` | If `false`, hidden from `/` menu (Claude-only) |
| `allowed-tools` | No | -- | Tools allowed without permission prompts when active |
| `model` | No | -- | Model override when skill is active |
| `context` | No | inline | `fork` to run in isolated subagent context |
| `agent` | No | `general-purpose` | Subagent type for `context: fork` |
| `hooks` | No | -- | Lifecycle hooks scoped to this skill |

## Invocation Control Matrix

| Frontmatter | User can invoke | Claude can invoke | Context loading |
|---|---|---|---|
| (default) | Yes | Yes | Description always in context; full loads on invoke |
| `disable-model-invocation: true` | Yes | No | Description NOT in context; full loads when user invokes |
| `user-invocable: false` | No | Yes | Description always in context; full loads when Claude invokes |

## String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` or `$N` | Specific argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID |

If `$ARGUMENTS` is not present in skill content, arguments are appended as
`ARGUMENTS: <value>`.

## Dynamic Context Injection

`` !`command` `` syntax runs shell commands before skill content is sent to
Claude. Output replaces the placeholder. This is preprocessing.

```markdown
## PR Context
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`
```

## Context Modes

- **Default (inline)**: Skill runs in main conversation context
- **`context: fork`**: Skill runs in isolated subagent. Content becomes the
  prompt driving the subagent. No access to conversation history.

`context: fork` only makes sense for skills with explicit tasks, not passive
guidelines.

**Skills + Subagents interaction**:

| Approach | System Prompt | Task Prompt | Also Loads |
|---|---|---|---|
| Skill with `context: fork` | From agent type | SKILL.md content | CLAUDE.md |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation | Preloaded skills + CLAUDE.md |

## Extended Thinking

Include the word **"ultrathink"** anywhere in skill content to enable extended
thinking mode.

## Skill Context Budget

Descriptions consume ~2% of context window (fallback: 16,000 characters).
Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var. Run `/context` to
check for excluded skills.

## Supporting Files (reference/)

Keep `SKILL.md` under 500 lines. Move detailed reference material to separate
files in subdirectories. Reference from SKILL.md so Claude knows what they
contain and when to load them.

## Bundled Skills

| Skill | Description |
|-------|-------------|
| `/simplify` | Reviews recently changed files for reuse, quality, efficiency (3 parallel agents) |
| `/batch <instruction>` | Large-scale parallel changes using git worktrees (5-30 independent units) |
| `/debug [description]` | Troubleshoots current session by reading debug log |

## Restricting Claude's Skill Access

1. Deny `Skill` tool entirely in `/permissions`
2. Allow/deny specific skills: `Skill(commit)`, `Skill(review-pr *)`
3. Set `disable-model-invocation: true` in individual skill frontmatter

Note: `user-invocable` only controls menu visibility, NOT Skill tool access.
