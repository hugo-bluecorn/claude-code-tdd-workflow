# Plugin System

**Docs**: [code.claude.com/docs/en/plugins](https://code.claude.com/docs/en/plugins) |
[code.claude.com/docs/en/plugins-reference](https://code.claude.com/docs/en/plugins-reference)

## What Plugins Are

A plugin is a self-contained directory that extends Claude Code with custom
skills, agents, hooks, MCP servers, LSP servers, and output styles. Plugins
are namespaced: a skill `hello/` inside plugin `my-plugin` becomes
`/my-plugin:hello`.

## When to Use Plugins vs Standalone

| Approach | Skill Names | Best For |
|----------|-------------|----------|
| **Standalone** (`.claude/`) | `/hello` | Personal workflows, project-specific, quick experiments |
| **Plugins** | `/plugin-name:hello` | Sharing with teammates, community distribution, versioned releases |

## Directory Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json           # Manifest (ONLY file in this dir)
├── agents/                   # Subagent markdown files
│   └── reviewer.md
├── skills/                   # Agent Skills (preferred over commands/)
│   └── my-skill/
│       ├── SKILL.md          # Skill definition (required)
│       ├── reference/        # Supporting reference files
│       └── scripts/          # Scripts the skill can run
├── commands/                 # Legacy skill markdown files
│   └── status.md
├── hooks/
│   └── hooks.json            # Hook configuration
├── scripts/                  # Hook and utility scripts
│   └── validate.sh
├── settings.json             # Default settings (only "agent" key supported)
├── .mcp.json                 # MCP server definitions
├── .lsp.json                 # LSP server configurations
├── LICENSE
└── CHANGELOG.md
```

**Critical**: Only `plugin.json` goes inside `.claude-plugin/`. All other
directories (`agents/`, `skills/`, `hooks/`, etc.) must be at the plugin root.

## plugin.json Manifest Schema

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

**Required fields**: Only `name` is required. The manifest itself is optional;
if omitted, Claude Code auto-discovers components in default directories and
derives the name from the directory.

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | **Required.** Kebab-case, no spaces. Used as namespace prefix |
| `version` | string | Semantic version (MAJOR.MINOR.PATCH) |
| `description` | string | Shown in plugin manager |
| `author` | object | `{ name, email, url }` |
| `homepage` | string | Documentation URL |
| `repository` | string | Source code URL |
| `license` | string | License identifier (MIT, Apache-2.0, etc.) |
| `keywords` | string[] | Discovery tags |
| `commands` | string \| string[] | Additional command files/directories |
| `agents` | string \| string[] | Additional agent files/directories |
| `skills` | string \| string[] | Additional skill directories |
| `hooks` | string \| string[] \| object | Hook config paths or inline config |
| `mcpServers` | string \| string[] \| object | MCP config paths or inline config |
| `outputStyles` | string \| string[] | Output style files/directories |
| `lspServers` | string \| string[] \| object | LSP config paths or inline config |

**Path rules**:
- Custom paths **supplement** defaults (they do NOT replace them)
- All paths must be relative and start with `./`
- Multiple paths can be specified as arrays

## Plugin settings.json

Plugins can ship `settings.json` at the plugin root. Currently only the
`agent` key is supported, which activates one of the plugin's custom agents
as the main thread:

```json
{
  "agent": "security-reviewer"
}
```

## Installation and Lifecycle

**Local testing**:
```bash
claude --plugin-dir ./my-plugin
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two   # Multiple
```

**CLI commands**:

| Command | Description |
|---------|-------------|
| `claude plugin install <plugin>` | Install a plugin |
| `claude plugin uninstall <plugin>` | Uninstall (aliases: `remove`, `rm`) |
| `claude plugin enable <plugin>` | Enable a disabled plugin |
| `claude plugin disable <plugin>` | Disable a plugin |
| `claude plugin update <plugin>` | Update a plugin |

All accept `-s, --scope <scope>` option: `user` (default), `project`, `local`, `managed` (update only).

**Installation scopes**:

| Scope | Settings File | Use Case |
|-------|---------------|----------|
| `user` | `~/.claude/settings.json` | Personal, all projects (default) |
| `project` | `.claude/settings.json` | Team, shared via version control |
| `local` | `.claude/settings.local.json` | Project-specific, gitignored |
| `managed` | Managed settings | Admin-controlled, read-only |

## Caching and File Resolution

- Marketplace plugins are copied to `~/.claude/plugins/cache`
- Installed plugins **cannot** reference files outside their directory
- Path traversal (e.g., `../shared-utils`) does not work after install
- **Workaround**: Create symbolic links within the plugin directory; symlinks
  are honored during copy
- If code changes without version bump, existing users won't see changes

## Environment Variable

`${CLAUDE_PLUGIN_ROOT}` resolves to the plugin's absolute path at runtime.
Use it in hooks, MCP servers, and scripts.

## Debugging

```bash
claude --debug     # Full plugin loading details
```

Shows: loaded plugins, manifest errors, component registration, MCP server
initialization.
