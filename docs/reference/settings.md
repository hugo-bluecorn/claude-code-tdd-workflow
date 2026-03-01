# Settings

**Docs**: [code.claude.com/docs/en/settings](https://code.claude.com/docs/en/settings)

## Scopes and Precedence (Highest to Lowest)

1. **Managed** (cannot be overridden)
   - Within managed: server-managed > MDM/OS > `managed-settings.json` > HKCU registry
2. **Command line arguments**
3. **Local** (`.claude/settings.local.json`)
4. **Project** (`.claude/settings.json`)
5. **User** (`~/.claude/settings.json`)

**Array settings merge** across scopes (concatenated and deduplicated).

## File Locations

| Feature | User | Project | Local |
|---------|------|---------|-------|
| Settings | `~/.claude/settings.json` | `.claude/settings.json` | `.claude/settings.local.json` |
| Subagents | `~/.claude/agents/` | `.claude/agents/` | -- |
| MCP servers | `~/.claude.json` | `.mcp.json` | `~/.claude.json` (per-project) |
| CLAUDE.md | `~/.claude/CLAUDE.md` | `CLAUDE.md` or `.claude/CLAUDE.md` | `CLAUDE.local.md` |

**Managed settings**:
- macOS: `/Library/Application Support/ClaudeCode/`
- Linux/WSL: `/etc/claude-code/`
- Windows: `C:\Program Files\ClaudeCode\` or registry `HKLM\SOFTWARE\Policies\ClaudeCode`

**JSON Schema**: `https://json.schemastore.org/claude-code-settings.json`

## Core Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `model` | string | -- | Override default model |
| `availableModels` | string[] | -- | Restrict selectable models (managed only) |
| `language` | string | -- | Response language |
| `autoUpdatesChannel` | string | `latest` | `stable` or `latest` |
| `apiKeyHelper` | string | -- | Script to generate auth value |
| `cleanupPeriodDays` | integer | 30 | Session cleanup threshold |
| `companyAnnouncements` | string[] | -- | Startup announcements |
| `env` | object | -- | Environment variables for every session |
| `outputStyle` | string | -- | Output style name |
| `showTurnDuration` | boolean | true | Show turn duration |
| `alwaysThinkingEnabled` | boolean | false | Extended thinking by default |
| `fastModePerSessionOptIn` | boolean | false | Fast mode doesn't persist across sessions |
| `plansDirectory` | string | `~/.claude/plans` | Plan file storage |

## Attribution Settings

```json
{
  "attribution": {
    "commit": "Generated with AI\n\nCo-Authored-By: AI <ai@example.com>",
    "pr": ""
  }
}
```

Empty string hides attribution.

## Permission Settings

```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep"],
    "ask": ["Bash(npm test *)"],
    "deny": ["Agent(Explore)"],
    "additionalDirectories": ["/path/to/extra"],
    "defaultMode": "acceptEdits"
  }
}
```

**Rule syntax**: `Tool` or `Tool(specifier)`

| Rule | Effect |
|------|--------|
| `Bash` | All Bash commands |
| `Bash(npm run *)` | Commands starting with `npm run` |
| `Read(./.env)` | Reading specific file |
| `Read(./**/*.env)` | All `.env` files recursively |
| `WebFetch(domain:example.com)` | Fetch to domain |
| `Edit(./src/**)` | Editing files in `src/` |
| `MCP(github)` | GitHub MCP server |
| `Agent(subagent-name)` | Specific subagent |

**Evaluation order**: Deny -> Ask -> Allow (first match wins).

## Hooks & Custom Commands Settings

| Key | Type | Description |
|-----|------|-------------|
| `hooks` | object | Hook configuration |
| `disableAllHooks` | boolean | Disable all hooks |
| `allowManagedHooksOnly` | boolean | Managed only |
| `allowedHttpHookUrls` | string[] | URL allowlist for HTTP hooks |
| `httpHookAllowedEnvVars` | string[] | Env var allowlist for HTTP hooks |
| `statusLine` | object | Custom status line (`type: "command"`, `command: path`) |

## MCP Settings

| Key | Type | Description |
|-----|------|-------------|
| `enableAllProjectMcpServers` | boolean | Auto-approve all project MCP servers |
| `enabledMcpjsonServers` | string[] | Specific servers to approve |
| `disabledMcpjsonServers` | string[] | Specific servers to reject |
| `allowedMcpServers` | object[] | Allowlist (managed only) |
| `deniedMcpServers` | object[] | Denylist (managed only) |
| `allowManagedMcpServersOnly` | boolean | Managed only |

## Plugin & Marketplace Settings

| Key | Type | Description |
|-----|------|-------------|
| `enabledPlugins` | object | `"plugin@marketplace": true/false` |
| `extraKnownMarketplaces` | object | Additional marketplaces |
| `strictKnownMarketplaces` | object[] | Allowlist (managed only) |
| `blockedMarketplaces` | object[] | Blocklist (managed only) |

## Sandbox Settings

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["docker"],
    "allowUnsandboxedCommands": true,
    "filesystem": {
      "allowWrite": ["//tmp/build"],
      "denyWrite": ["//etc"],
      "denyRead": ["~/.aws/credentials"]
    },
    "network": {
      "allowUnixSockets": ["/var/run/docker.sock"],
      "allowAllUnixSockets": false,
      "allowLocalBinding": true,
      "allowedDomains": ["github.com", "*.npmjs.org"],
      "allowManagedDomainsOnly": false,
      "httpProxyPort": 8080,
      "socksProxyPort": 8081
    },
    "enableWeakerNestedSandbox": false
  }
}
```

**Path prefixes**: `//` (absolute from root), `~/` (home), `/` (relative to settings file), `./` (runtime relative).

## UI/UX Settings

| Key | Type | Description |
|-----|------|-------------|
| `spinnerVerbs` | object | Custom action verbs. `mode`: `replace` or `append` |
| `spinnerTipsEnabled` | boolean | Show tips in spinner |
| `spinnerTipsOverride` | object | Override spinner tips |
| `terminalProgressBarEnabled` | boolean | Terminal progress bar |
| `prefersReducedMotion` | boolean | Reduce animations |
| `fileSuggestion` | object | Custom `@` file autocomplete script |
| `respectGitignore` | boolean | `@` picker respects `.gitignore` |

## Advanced Settings

| Key | Type | Description |
|-----|------|-------------|
| `teammateMode` | string | `auto`, `in-process`, `tmux` |
| `otelHeadersHelper` | string | Script for OpenTelemetry headers |
| `awsAuthRefresh` | string | Script to refresh AWS credentials |
| `awsCredentialExport` | string | Script outputting AWS credential JSON |
