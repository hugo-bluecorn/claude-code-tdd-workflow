# Claude Code Plugin API Reference — Index

> Exhaustive reference for developing Claude Code plugins, split by topic for
> targeted loading. Compiled from official Anthropic documentation at
> [code.claude.com/docs](https://code.claude.com/docs/en/). Last updated: 2026-03-01.

Read only the file(s) relevant to your current task.

## Core Plugin Components

| File | Lines | What's Inside |
|------|-------|---------------|
| [plugin-system.md](plugin-system.md) | ~160 | plugin.json schema (all fields), directory structure, installation scopes, caching, `${CLAUDE_PLUGIN_ROOT}`, CLI commands |
| [skills.md](skills.md) | ~155 | SKILL.md frontmatter (all 10 fields), invocation control matrix, context modes (inline vs fork), string substitutions, dynamic context injection, "ultrathink", context budget |
| [agents.md](agents.md) | ~175 | Agent frontmatter (all 14 fields), tool allowlist/denylist rules, permission modes, persistent memory, skills preloading, foreground vs background, CLI-defined agents |
| [hooks.md](hooks.md) | ~300 | All 18 hook events, 4 handler types, complete input/output schemas per event, matcher regex patterns, exit code behaviors, PreToolUse decision control, async/once modifiers |

## Configuration & Infrastructure

| File | Lines | What's Inside |
|------|-------|---------------|
| [settings.md](settings.md) | ~175 | Settings hierarchy (5 scopes), all settings keys, permission rule syntax (`Tool(specifier)`), sandbox config, UI/UX settings |
| [mcp-servers.md](mcp-servers.md) | ~80 | Transport types, .mcp.json format, plugin MCP, OAuth, tool search, managed MCP, CLI commands |
| [claude-md-memory.md](claude-md-memory.md) | ~100 | CLAUDE.md loading order, `@import` syntax, `.claude/rules/` with path scoping, auto memory system |

## Advanced / Peripheral

| File | Lines | What's Inside |
|------|-------|---------------|
| [agent-teams.md](agent-teams.md) | ~55 | Experimental multi-instance coordination, display modes, task coordination, quality hooks |
| [lsp-output-styles.md](lsp-output-styles.md) | ~105 | .lsp.json format (all fields), official LSP plugins, custom output styles (frontmatter, storage) |
| [environment-variables.md](environment-variables.md) | ~100 | 60+ env vars: auth, model config, feature flags, bash, context/caching, MCP, telemetry, providers |
| [api-providers.md](api-providers.md) | ~55 | Bedrock, Vertex AI, Foundry setup, LLM gateway config, model aliases |

## Quick Decision Guide

**Working on...** → **Read...**

- Hook scripts → `hooks.md`
- Agent definitions → `agents.md`
- Skill definitions → `skills.md`
- Plugin manifest / structure → `plugin-system.md`
- Permission rules → `settings.md`
- MCP server integration → `mcp-servers.md`
- CLAUDE.md / rules / memory → `claude-md-memory.md`
- Environment variables → `environment-variables.md`

## Sources

All content sourced from official Anthropic documentation:
- [Plugins](https://code.claude.com/docs/en/plugins) | [Reference](https://code.claude.com/docs/en/plugins-reference)
- [Skills](https://code.claude.com/docs/en/skills)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Hooks](https://code.claude.com/docs/en/hooks) | [Guide](https://code.claude.com/docs/en/hooks-guide)
- [Settings](https://code.claude.com/docs/en/settings)
- [MCP](https://code.claude.com/docs/en/mcp)
- [Memory](https://code.claude.com/docs/en/memory)
- [Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Output Styles](https://code.claude.com/docs/en/output-styles)
- [Settings JSON Schema](https://json.schemastore.org/claude-code-settings.json)
