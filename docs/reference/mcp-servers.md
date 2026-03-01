# MCP Servers

**Docs**: [code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp)

## Transport Types

| Type | Description | Command |
|------|-------------|---------|
| **HTTP** (streamable-http) | Recommended for remote | `claude mcp add --transport http <name> <url>` |
| **SSE** | Deprecated, use HTTP | `claude mcp add --transport sse <name> <url>` |
| **stdio** | Local processes | `claude mcp add --transport stdio <name> -- <cmd> [args]` |

## Installation Scopes

| Scope | Storage | Description |
|-------|---------|-------------|
| **local** (default) | `~/.claude.json` under project path | Private, current project |
| **project** | `.mcp.json` at project root | Shared via version control |
| **user** | `~/.claude.json` | All projects |

## .mcp.json Format

```json
{
  "mcpServers": {
    "server-name": {
      "command": "/path/to/server",
      "args": [],
      "env": {},
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      }
    }
  }
}
```

Environment variable expansion: `${VAR}` and `${VAR:-default}` in `command`,
`args`, `env`, `url`, `headers`.

## Plugin MCP Servers

- Defined in `.mcp.json` at plugin root or inline in `plugin.json`
- Use `${CLAUDE_PLUGIN_ROOT}` for paths
- Start automatically when plugin is enabled

## Key Features

- **OAuth 2.0**: Use `/mcp` to authenticate; tokens auto-refreshed
- **Dynamic updates**: `list_changed` notifications for dynamic tool updates
- **Tool search**: Auto-enabled at 10% context threshold. `ENABLE_TOOL_SEARCH`: `auto`, `auto:<N>`, `true`, `false`
- **Resources**: `@server:protocol://resource/path` syntax
- **Prompts**: Available as `/mcp__servername__promptname`
- **Output limits**: Warning at 10K tokens, max 25K (override: `MAX_MCP_OUTPUT_TOKENS`)

## CLI Commands

| Command | Description |
|---------|-------------|
| `claude mcp add` | Add server |
| `claude mcp add-json <name> '<json>'` | Add from JSON |
| `claude mcp add-from-claude-desktop` | Import from Claude Desktop |
| `claude mcp list` | List servers |
| `claude mcp get <name>` | Get server details |
| `claude mcp remove <name>` | Remove server |
| `claude mcp reset-project-choices` | Reset project server approvals |
| `claude mcp serve` | Run Claude Code as MCP server |

## Managed MCP

**Option 1: `managed-mcp.json`** at system paths for exclusive control.

**Option 2: Allowlists/Denylists** in managed settings:
- `allowedMcpServers` / `deniedMcpServers`
- Restriction types: `serverName`, `serverCommand` (exact match), `serverUrl` (wildcard)
- Denylist takes absolute precedence
- `allowedMcpServers: []` = complete lockdown
