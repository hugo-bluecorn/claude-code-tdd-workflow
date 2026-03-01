# tdd-workflow

A Claude Code plugin for Test-Driven Development with context-isolated agents. Enforces red-green-refactor discipline for Dart/Flutter, C++, and Bash/Shell projects.

## Overview

This plugin decomposes TDD into six context-isolated agents that prevent the common failure modes of single-context TDD: training distribution bias toward implementation-first code, context rot under token accumulation, and absence of epistemic boundaries between test and implementation reasoning.

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
/tdd-plan (Inline Orchestrating Skill)
    |  Spawns tdd-planner (opus, read-only) via Agent tool
    |  Planner researches codebase, returns structured plan text
    |  Skill handles AskUserQuestion approval
    |  Writes: .tdd-progress.md + planning/ archive after approval
    v
Human Review (approve / revise / reject)
    |
    v  For each slice:
tdd-implementer (opus)
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
    |
    v  (all slices done)
/tdd-release (Orchestrating Skill)
    |  context: fork
    |  agent: tdd-releaser (sonnet)
    |  Updates CHANGELOG, pushes branch, creates PR
    v
/tdd-finalize-docs (Orchestrating Skill)
    |  context: fork
    |  agent: tdd-doc-finalizer (sonnet)
    |  Bumps versions, updates docs, updates release tests, pushes
    v
Done
```

## Components

### Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| tdd-planner | opus | Read-only codebase research; returns structured plan text to `/tdd-plan` skill |
| tdd-implementer | opus | Red-green-refactor per slice (full tools) |
| tdd-verifier | haiku | Blackbox validation (read-only) |
| tdd-releaser | sonnet | Release workflow (CHANGELOG, PR) |
| tdd-doc-finalizer | sonnet | Post-release documentation updates, version bumps, release test maintenance |
| context-updater | opus | Updates convention reference files to latest versions |

### Skills

| Skill | Type |
|-------|------|
| `/tdd-plan` | Inline orchestrating skill (spawns planner subagent, handles approval, writes files) |
| `/tdd-implement` | Implementation loop (reads progress, runs slices) |
| `/tdd-release` | Release entry point (forks context) |
| `/tdd-finalize-docs` | Post-release documentation finalization (forks context) |
| `/tdd-update-context` | Updates convention reference files to latest versions |
| dart-flutter-conventions | Convention reference (auto-loaded by agents) |
| cpp-testing-conventions | Convention reference (auto-loaded by agents) |
| bash-testing-conventions | Convention reference (auto-loaded by agents) |

### Hooks

| Hook | Type | Purpose |
|------|------|---------|
| validate-tdd-order.sh | PreToolUse (command) | Blocks implementation writes before test exists |
| auto-run-tests.sh | PostToolUse (command) | Runs tests after every file change |
| planner-bash-guard.sh | PreToolUse (command) | Allowlists read-only commands for planner |
| validate-plan-output.sh | standalone utility | Validates plan file structure (required sections, no refactoring leak); called by `/tdd-plan` skill after approval |
| check-tdd-progress.sh | Stop (command) | Prevents session end with pending slices |
| SubagentStart (context-updater) | command | Injects git context with edit warning |
| check-release-complete.sh | SubagentStop (command) | Validates branch is pushed to remote (releaser + doc-finalizer) |
| SubagentStop (implementer) | prompt | Verifies R-G-R cycle completion |

## Configuration

### Planner Model

Default: `model: opus`. For faster but less thorough planning, change to `model: sonnet` in `agents/tdd-planner.md`. The `/tdd-plan` skill includes `ultrathink` which works with both models.

### Web Tools on Planner

Default: not included. To let the planner check pub.dev or API docs, add `WebFetch, WebSearch` to the planner's tools list.

### Test Specification Format

Default: compact single-line Given/When/Then. Customizable via the template and planner instructions. See [Changing the test specification format](docs/user-guide.md#changing-the-test-specification-format).

### permissionMode on Planner

Default: `permissionMode: plan`. The planner is read-only and does not write files, so plan mode is a safe default. If Bash read commands are unexpectedly blocked, remove `permissionMode: plan` from `agents/tdd-planner.md`.

## File Structure

```
tdd-workflow/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── tdd-planner.md
│   ├── tdd-implementer.md
│   ├── tdd-verifier.md
│   ├── tdd-releaser.md
│   ├── tdd-doc-finalizer.md
│   └── context-updater.md
├── skills/
│   ├── tdd-plan/
│   │   ├── SKILL.md
│   │   └── reference/
│   │       ├── tdd-task-template.md
│   │       └── feature-notes-template.md
│   ├── tdd-implement/
│   │   └── SKILL.md
│   ├── tdd-release/
│   │   └── SKILL.md
│   ├── tdd-finalize-docs/
│   │   └── SKILL.md
│   ├── tdd-update-context/
│   │   └── SKILL.md
│   ├── dart-flutter-conventions/
│   │   ├── SKILL.md
│   │   └── reference/
│   │       ├── test-patterns.md
│   │       ├── test-recipes.md
│   │       ├── mocking-guide.md
│   │       ├── widget-testing.md
│   │       ├── project-conventions.md
│   │       └── riverpod-guide.md
│   ├── cpp-testing-conventions/
│   │   ├── SKILL.md
│   │   └── reference/
│   │       ├── googletest-patterns.md
│   │       ├── cmake-integration.md
│   │       ├── googlemock-guide.md
│   │       └── clang-tooling.md
│   └── bash-testing-conventions/
│       ├── SKILL.md
│       └── reference/
│           ├── bashunit-patterns.md
│           └── shellcheck-guide.md
├── hooks/
│   ├── hooks.json
│   ├── validate-tdd-order.sh
│   ├── auto-run-tests.sh
│   ├── check-tdd-progress.sh
│   ├── planner-bash-guard.sh
│   ├── validate-plan-output.sh
│   └── check-release-complete.sh
├── scripts/
│   └── detect-project-context.sh
├── docs/
│   ├── version-control.md
│   ├── version-control-integration.md
│   ├── user-guide.md
│   ├── tdd-workflow-extensibility-audit.md
│   ├── extensibility-audit-prompt.md
│   └── new-feature_documentation_skill.md
├── CLAUDE.md
├── README.md
├── CHANGELOG.md
├── MEMORY.md
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
