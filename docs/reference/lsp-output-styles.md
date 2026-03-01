# LSP Servers & Output Styles

## LSP Servers

**Docs**: [code.claude.com/docs/en/plugins-reference](https://code.claude.com/docs/en/plugins-reference)

### Configuration Format

`.lsp.json` at plugin root or inline in `plugin.json` under `lspServers`:

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": {
      ".go": "go"
    }
  }
}
```

### All Fields

| Field | Required | Description |
|-------|----------|-------------|
| `command` | Yes | LSP binary to execute (must be in PATH) |
| `extensionToLanguage` | Yes | Maps file extensions to language identifiers |
| `args` | No | Command-line arguments |
| `transport` | No | `stdio` (default) or `socket` |
| `env` | No | Environment variables |
| `initializationOptions` | No | Options passed during initialization |
| `settings` | No | Settings via `workspace/didChangeConfiguration` |
| `workspaceFolder` | No | Workspace folder path |
| `startupTimeout` | No | Max startup wait (ms) |
| `shutdownTimeout` | No | Max graceful shutdown wait (ms) |
| `restartOnCrash` | No | Auto-restart on crash (boolean) |
| `maxRestarts` | No | Max restart attempts |

### Available Official LSP Plugins

| Plugin | Server | Install |
|--------|--------|---------|
| `pyright-lsp` | Pyright (Python) | `pip install pyright` or `npm install -g pyright` |
| `typescript-lsp` | TypeScript Language Server | `npm install -g typescript-language-server typescript` |
| `rust-lsp` | rust-analyzer | See rust-analyzer docs |

### Capabilities

- Instant diagnostics (errors/warnings after each edit)
- Code navigation (go to definition, find references, hover info)
- Language awareness (type information, documentation)

---

## Output Styles

**Docs**: [code.claude.com/docs/en/output-styles](https://code.claude.com/docs/en/output-styles)

### Built-in Styles

| Style | Description |
|-------|-------------|
| Default | Standard software engineering system prompt |
| Explanatory | Educational "Insights" between tasks |
| Learning | Collaborative mode with `TODO(human)` markers |

### Custom Styles

Markdown files with frontmatter stored in:
- User: `~/.claude/output-styles/`
- Project: `.claude/output-styles/`
- Plugin: via `outputStyles` in plugin.json

```markdown
---
name: My Custom Style
description: Brief description for UI
keep-coding-instructions: false
---

# Custom Style Instructions
You are an interactive CLI tool that...
```

| Frontmatter | Default | Description |
|-------------|---------|-------------|
| `name` | File name | Display name |
| `description` | -- | Description for UI |
| `keep-coding-instructions` | `false` | Keep coding parts of system prompt |

### Changing Styles

- `/output-style` interactive menu
- `/output-style [name]` direct switch
- Saved to `.claude/settings.local.json`
- `outputStyle` field in settings

### vs Related Features

- **vs CLAUDE.md**: Styles modify system prompt; CLAUDE.md adds user message after it
- **vs Agents**: Styles affect main agent only; agents have separate configs
- **vs Skills**: Styles always active; skills are task-specific
