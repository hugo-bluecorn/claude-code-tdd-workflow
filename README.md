# tdd-workflow

A Claude Code plugin for Test-Driven Development with context-isolated agents. Enforces red-green-refactor discipline for Dart/Flutter, C++, and Bash/Shell projects.

## Overview

This plugin decomposes TDD into three context-isolated agents that prevent the common failure modes of single-context TDD: training distribution bias toward implementation-first code, context rot under token accumulation, and absence of epistemic boundaries between test and implementation reasoning.

## Requirements

- Claude Code with plugin support

## Installation

```bash
claude plugin install <path-to-tdd-workflow>
```

## Quick Start

```
/tdd-plan Implement a LocationService that wraps geolocator
```

This forks a fresh context, researches your codebase, and produces a structured plan with testable slices. After reviewing and approving the plan:

```
/tdd-implement
```

This reads `.tdd-progress.md`, finds pending slices, and runs each through red-green-refactor with automated verification. Supports resuming interrupted sessions.

## How It Works

```
User Request
    |
    v
/tdd-plan (Orchestrating Skill)
    |  context: fork
    |  agent: tdd-planner (sonnet, read-only)
    |  Researches codebase, produces slice-oriented plan
    |  Writes: .tdd-progress.md + planning/ archive
    v
Human Review (approve / revise / reject)
    |
    v  For each slice:
tdd-implementer (sonnet)
    |  1. Write failing test (RED)
    |  2. Minimal implementation (GREEN)
    |  3. Refactor (still GREEN)
    |  Hooks: validate-tdd-order, auto-run-tests
    v
tdd-verifier (haiku, read-only)
    |  Blackbox validation:
    |  - Full test suite
    |  - Static analysis
    |  - Coverage check
    |  - Plan criteria verification
    v
PASS -> next slice | FAIL -> retry
```

## Components

### Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| tdd-planner | sonnet | Codebase research, plan creation (read-only) |
| tdd-implementer | sonnet | Red-green-refactor per slice (full tools) |
| tdd-verifier | haiku | Blackbox validation (read-only) |

### Skills

| Skill | Type |
|-------|------|
| `/tdd-plan` | Orchestrating entry point (forks context) |
| `/tdd-implement` | Implementation loop (reads progress, runs slices) |
| dart-flutter-conventions | Convention reference (auto-loaded by agents) |
| cpp-testing-conventions | Convention reference (auto-loaded by agents) |
| bash-testing-conventions | Convention reference (auto-loaded by agents) |

### Hooks

| Hook | Type | Purpose |
|------|------|---------|
| validate-tdd-order.sh | PreToolUse (command) | Blocks implementation writes before test exists |
| auto-run-tests.sh | PostToolUse (command) | Runs tests after every file change |
| SubagentStop (implementer) | prompt | Verifies R-G-R cycle completion |
| SubagentStop (verifier) | prompt | Verifies full suite + analysis ran |
| check-tdd-progress.sh | Stop (command) | Prevents session end with pending slices |

## Configuration

### Planner Model (sonnet vs opus)

Default: `model: sonnet` with ultrathink. For complex features where a bad plan cascades, change to `model: opus` in `agents/tdd-planner.md`.

### Web Tools on Planner

Default: not included. To let the planner check pub.dev or API docs, add `WebFetch, WebSearch` to the planner's tools list.

### permissionMode on Planner

Default: `permissionMode: plan`. If plan mode blocks Bash writes to `.tdd-progress.md`, remove `permissionMode: plan` and rely on `disallowedTools` instead.

## File Structure

```
tdd-workflow/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── tdd-planner.md
│   ├── tdd-implementer.md
│   └── tdd-verifier.md
├── skills/
│   ├── tdd-plan/
│   │   └── SKILL.md
│   ├── tdd-implement/
│   │   └── SKILL.md
│   ├── dart-flutter-conventions/
│   │   ├── SKILL.md
│   │   └── reference/
│   │       ├── test-patterns.md
│   │       ├── mocking-guide.md
│   │       ├── widget-testing.md
│   │       └── project-conventions.md
│   ├── cpp-testing-conventions/
│   │   ├── SKILL.md
│   │   └── reference/
│   │       ├── googletest-patterns.md
│   │       ├── cmake-integration.md
│   │       └── googlemock-guide.md
│   └── bash-testing-conventions/
│       ├── SKILL.md
│       └── reference/
│           ├── bashunit-patterns.md
│           └── shellcheck-guide.md
├── hooks/
│   ├── hooks.json
│   ├── validate-tdd-order.sh
│   ├── auto-run-tests.sh
│   └── check-tdd-progress.sh
├── docs/
│   └── version-control.md
├── CLAUDE.md
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Bash/Shell Prerequisites

To use bash testing support, install bashunit and shellcheck:

### bashunit

```bash
curl -s https://bashunit.typeddevs.com/install.sh | bash
```

### shellcheck

```bash
# Debian/Ubuntu
apt install shellcheck

# macOS
brew install shellcheck
```

### Permissions

Add the following to your `.claude/settings.local.json` to allow Claude Code to run these tools:

```json
{
  "permissions": {
    "allow": [
      "Bash(shellcheck *)",
      "Bash(bashunit *)"
    ]
  }
}
```

## Documentation

- **[User Guide](docs/user-guide.md)** — Step-by-step walkthrough of the full TDD workflow
- **[Version Control](docs/version-control.md)** — Git workflow and commit conventions

## License

Apache-2.0
