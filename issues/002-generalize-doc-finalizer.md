# Generalize tdd-doc-finalizer for Any Project

**Created:** 2026-03-01
**Status:** Proposed
**Discovered during:** Real-world testing of v1.11.0 on zenoh-dart project

## The Problem

The `tdd-doc-finalizer` agent and `/tdd-finalize-docs` skill are hardcoded for
the tdd-workflow plugin's own documentation structure. When invoked on an
external project (e.g., zenoh-dart), the agent correctly identifies that the
plugin-specific files don't exist and refuses to run.

This means `/tdd-finalize-docs` is a plugin-internal maintenance tool, not a
general workflow step — but it's exposed as a user-facing skill alongside
`/tdd-plan`, `/tdd-implement`, and `/tdd-release`, which all work on any project.

### What's Hardcoded

The agent body references these plugin-specific files:

| File | Purpose | Plugin-Specific? |
|------|---------|-----------------|
| `.claude-plugin/plugin.json` | Version bump | Yes — only plugins have this |
| `docs/user-guide.md` | User guide updates | Yes — path is plugin-specific |
| `docs/version-control-integration.md` | VCS docs | Yes — plugin-specific |
| `docs/tdd-workflow-extensibility-audit.md` | Audit docs | Yes — plugin-specific |
| `test/integration/release_version_test.sh` | Version assertions | Yes — plugin-specific |
| `test/integration/release_documentation_test.sh` | Doc assertions | Yes — plugin-specific |

### Observed Symptom

```
❯ /tdd-workflow:tdd-finalize-docs

● This skill is designed for the tdd-workflow plugin's own internal
  documentation (plugin.json, README.md for the plugin itself, etc.)
  — not for the zenoh-dart project.
```

The agent is being honest — it can't do its job because the target files
don't exist. The problem is the agent's scope, not its behavior.

## Proposed Fix: Generalize via Project Discovery

Rewrite the agent to discover the project's documentation structure instead
of assuming the plugin's layout. The agent should:

1. **Discover what exists** — scan for README.md, CLAUDE.md, CHANGELOG.md,
   docs/ directory, any version-bearing files (package.json, pubspec.yaml,
   Cargo.toml, pyproject.toml, plugin.json, CMakeLists.txt)
2. **Determine the release version** — from CHANGELOG.md (already done) or
   the version file appropriate to the project type
3. **Bump version where found** — pubspec.yaml for Dart, package.json for
   Node, Cargo.toml for Rust, etc.
4. **Update documentation that exists** — README.md, CLAUDE.md, any docs/
   files. Skip what doesn't exist. Don't create files that aren't there.
5. **Run project-appropriate verification** — if tests exist, run them.
   Don't assume bashunit or specific test file paths.

### What Changes

| Component | Change |
|-----------|--------|
| `agents/tdd-doc-finalizer.md` | Replace hardcoded file list with discovery logic. Keep the same structure (determine version → bump → assess impact → update → verify → commit/push) but make each step project-aware |
| `skills/tdd-finalize-docs/SKILL.md` | Minimal change — the skill body is already a reasonable process description. May need to remove plugin-specific file references |

### What Stays

- The agent's role (post-release documentation finalization)
- The workflow position (runs after `/tdd-release`)
- The tool permissions (Edit-only for targeted changes)
- The SubagentStop hook (check-release-complete.sh)
- The commit/push/report flow

## Design Considerations

### Version File Detection

The agent should detect version files by project type, similar to how
`detect-project-context.sh` detects test runners:

| Project Type | Version File | Version Pattern |
|-------------|-------------|----------------|
| Dart/Flutter | `pubspec.yaml` | `version: X.Y.Z` |
| Node.js | `package.json` | `"version": "X.Y.Z"` |
| Rust | `Cargo.toml` | `version = "X.Y.Z"` |
| Python | `pyproject.toml` | `version = "X.Y.Z"` |
| Claude Code Plugin | `.claude-plugin/plugin.json` | `"version": "X.Y.Z"` |
| C/C++ | `CMakeLists.txt` | `project(... VERSION X.Y.Z)` |

### Documentation Discovery

Rather than hardcoding paths, scan for common documentation files:
- `README.md` (any project)
- `CLAUDE.md` (Claude Code projects)
- `docs/` directory (any project with documentation)
- `CHANGELOG.md` (already handled by `/tdd-release`)

### Plugin-Internal Mode

For the tdd-workflow plugin itself, the agent could detect it's running in its
own repo (e.g., `.claude-plugin/plugin.json` with `name: "tdd-workflow"`) and
apply the plugin-specific logic (release integration tests, user-guide, etc.)
as a special case. This preserves backward compatibility.

## Test Impact

- Existing release integration tests are plugin-specific and would remain
  for testing the plugin itself
- New tests needed for the generic discovery logic
- Convention skill detection could be reused from `detect-project-context.sh`

## Implementation Notes

- Should be implemented via `/tdd-plan` (dogfooding)
- Medium-sized refactor — primarily the agent body and possibly the skill body
- Reference: `scripts/detect-project-context.sh` for the detection pattern
- The tdd-releaser may also benefit from similar generalization (it has some
  plugin-specific assumptions) but that's a separate issue
