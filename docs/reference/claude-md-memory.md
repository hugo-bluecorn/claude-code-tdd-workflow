# CLAUDE.md / Memory

**Docs**: [code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory)

## Two Memory Systems

| | CLAUDE.md Files | Auto Memory |
|--|-----------------|-------------|
| **Who writes** | You | Claude |
| **Contains** | Instructions and rules | Learnings and patterns |
| **Scope** | Project, user, or org | Per working tree |
| **Loaded** | Every session | First 200 lines of MEMORY.md |
| **Use for** | Standards, workflows, architecture | Build commands, debugging, preferences |

## File Locations and Scopes

| Scope | Location | Shared With |
|-------|----------|-------------|
| Managed policy | System paths (see below) | All users in org |
| Project | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team via VCS |
| User | `~/.claude/CLAUDE.md` | Just you |
| Local | `./CLAUDE.local.md` | Just you (gitignored) |

**Managed paths**:
- macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`
- Linux/WSL: `/etc/claude-code/CLAUDE.md`
- Windows: `C:\Program Files\ClaudeCode\CLAUDE.md`

## Loading Order

- Files **above** working directory: loaded in full at launch
- Files in **subdirectories**: loaded on demand when Claude reads files there
- Claude walks **up** directory tree, loading `CLAUDE.md` and `CLAUDE.local.md` at each level
- More specific locations take precedence
- Managed policy CLAUDE.md cannot be excluded
- CLAUDE.md **fully survives compaction** (re-read from disk)

## Import Syntax

```markdown
See @README for overview and @package.json for scripts.
@docs/git-instructions.md
@~/.claude/my-project-instructions.md
```

- Relative paths resolve relative to containing file
- Recursive imports (max depth: 5 hops)
- First external import shows approval dialog

## .claude/rules/ Directory

Modular instruction files with optional path scoping:

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules
- All endpoints must include input validation
```

- All `.md` files discovered recursively
- Rules without `paths` loaded at launch
- Rules with `paths` loaded on demand when matching files opened
- Supports symlinks (circular detected)
- User-level: `~/.claude/rules/`
- Glob patterns: `**/*.ts`, `src/**/*`, `*.{ts,tsx}`

## Excluding Files

```json
{
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md",
    "/home/user/other-team/.claude/rules/**"
  ]
}
```

Patterns matched against absolute paths. Arrays merge across layers.

## Auto Memory

- Storage: `~/.claude/projects/<project>/memory/`
- First 200 lines of `MEMORY.md` loaded at startup
- Topic files loaded on demand
- Toggle: `/memory` command or `autoMemoryEnabled` setting
- Disable: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`
- Machine-local, not shared
- All worktrees within same git repo share one directory

## Best Practices

- Target under 200 lines per CLAUDE.md
- Use markdown headers and bullets
- Write concrete, verifiable instructions
- Use `@path` imports and `.claude/rules/` for overflow
- `/init` generates a starting CLAUDE.md
