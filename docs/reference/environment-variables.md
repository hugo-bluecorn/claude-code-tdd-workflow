# Environment Variables

## Authentication & API

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | API key |
| `ANTHROPIC_AUTH_TOKEN` | Custom Authorization header value |
| `ANTHROPIC_CUSTOM_HEADERS` | Custom headers (newline-separated) |
| `ANTHROPIC_BASE_URL` | Override API base URL |

## Model Configuration

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_MODEL` | Override primary model |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Override Sonnet alias |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Override Opus alias |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Override Haiku alias |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Model for subagents |
| `CLAUDE_CODE_EFFORT_LEVEL` | `low`, `medium`, `high` (Opus 4.6 only) |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max output (default 32K, max 64K) |
| `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING` | Disable adaptive reasoning |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT` | Disable 1M context window |

## Feature Flags

| Variable | Purpose |
|----------|---------|
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | Disable auto memory |
| `CLAUDE_CODE_DISABLE_FAST_MODE` | Disable fast mode |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | Disable background tasks |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enable agent teams |
| `CLAUDE_CODE_SIMPLE` | Minimal mode (Bash + file read/edit only) |
| `CLAUDE_CODE_ENABLE_TASKS` | `false` to revert to TODO list |
| `ENABLE_CLAUDEAI_MCP_SERVERS` | `false` to disable claude.ai MCP servers |
| `CLAUDE_CODE_PLAN_MODE_REQUIRED` | `true` to require plan approval |

## Bash & Commands

| Variable | Purpose |
|----------|---------|
| `BASH_DEFAULT_TIMEOUT_MS` | Default bash timeout |
| `BASH_MAX_TIMEOUT_MS` | Maximum bash timeout |
| `BASH_MAX_OUTPUT_LENGTH` | Max chars before truncation |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | Return to project dir after Bash |
| `CLAUDE_CODE_SHELL` | Override shell detection |
| `CLAUDE_CODE_SHELL_PREFIX` | Command prefix for auditing |

## Context & Caching

| Variable | Purpose |
|----------|---------|
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Auto-compaction threshold (default ~95%) |
| `SLASH_COMMAND_TOOL_CHAR_BUDGET` | Skill description budget |
| `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` | File read token limit |
| `DISABLE_PROMPT_CACHING` | Disable for all models |
| `DISABLE_PROMPT_CACHING_HAIKU` | Disable for Haiku |
| `DISABLE_PROMPT_CACHING_SONNET` | Disable for Sonnet |
| `DISABLE_PROMPT_CACHING_OPUS` | Disable for Opus |

## MCP & Tools

| Variable | Purpose |
|----------|---------|
| `MAX_MCP_OUTPUT_TOKENS` | MCP output limit (default 25K) |
| `MCP_TIMEOUT` | MCP server startup timeout |
| `ENABLE_TOOL_SEARCH` | `auto`, `auto:<N>`, `true`, `false` |

## Telemetry & Monitoring

| Variable | Purpose |
|----------|---------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | Enable OpenTelemetry |
| `DISABLE_TELEMETRY` | Opt out of Statsig |
| `DISABLE_ERROR_REPORTING` | Opt out of Sentry |

## Build & Operations

| Variable | Purpose |
|----------|---------|
| `DISABLE_AUTOUPDATER` | Disable auto-updates |
| `CLAUDE_CODE_EXIT_AFTER_STOP_DELAY` | Auto-exit delay (ms) for automation |
| `CLAUDE_CONFIG_DIR` | Custom config directory |
| `CLAUDE_CODE_TMPDIR` | Override temp directory |
| `CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS` | Plugin git timeout (default 120s) |

## Alternate Providers

| Variable | Purpose |
|----------|---------|
| `CLAUDE_CODE_USE_BEDROCK` | Enable Amazon Bedrock |
| `CLAUDE_CODE_USE_VERTEX` | Enable Google Vertex AI |
| `CLAUDE_CODE_USE_FOUNDRY` | Enable Microsoft Foundry |
| `CLAUDE_CODE_SKIP_BEDROCK_AUTH` | Skip Bedrock auth |
| `CLAUDE_CODE_SKIP_VERTEX_AUTH` | Skip Vertex auth |
| `CLAUDE_CODE_SKIP_FOUNDRY_AUTH` | Skip Foundry auth |
| `ANTHROPIC_BEDROCK_BASE_URL` | Bedrock base URL |
| `ANTHROPIC_VERTEX_BASE_URL` | Vertex base URL |
| `ANTHROPIC_FOUNDRY_BASE_URL` | Foundry base URL |
