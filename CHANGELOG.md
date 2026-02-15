# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `bash-testing-conventions` skill with bashunit-patterns and shellcheck-guide reference docs
- validate-tdd-order.sh bash support: recognizes `_test.sh` files and bash test patterns
- auto-run-tests.sh bashunit integration: detects and runs bashunit for `.sh` file changes
- Verifier bash/shellcheck support: runs shellcheck static analysis and bashunit test suite
- Permission requirements: users must allow `Bash(shellcheck *)` and `Bash(bashunit *)` in `.claude/settings.local.json`
- `/tdd-implement` skill for starting and resuming the TDD implementation loop
- User guide with step-by-step walkthrough (docs/user-guide.md)
- TDD task template (`skills/tdd-plan/reference/tdd-task-template.md`) with
  Given-When-Then test specification format and acceptance criteria structure
- Feature notes template (`skills/tdd-plan/reference/feature-notes-template.md`)
  for planning archive documents with architectural context and trade-offs
- Enhanced `CLAUDE.md` with development workflow, project guidelines,
  pre-commit checklist, and project-specific customization section
- User guide: documented how to change state management or architecture
  by editing `project-conventions.md` (plugin is framework-agnostic)

### Changed
- Planner skill (`tdd-plan/SKILL.md`) restructured with 10-step process (0-9):
  - Step 0: mandatory convention reference loading before any research
  - Step 1: codebase research with FVM detection
  - Step 4: re-read format requirements after research (~30k tokens of research
    was pushing original instructions out of LLM attention)
  - Step 5: inline template example showing exact output structure
  - Step 6: self-check checklist verifying every slice has Given-When-Then blocks,
    Phase Tracking, Acceptance Criteria, Edge Cases, and file paths
- Planner agent (`tdd-planner.md`): removed duplicated file lists and FVM
  detection (now handled by SKILL.md), tightened Output section to require
  template structure
- `project-conventions.md`: clarified ephemeral vs app state management —
  ChangeNotifier/ValueNotifier only for widget-local state (animations, form
  focus), Riverpod required for all app/business state. Removed "built-in for
  simple cases" bullet that was causing the planner to choose ChangeNotifier.
  Split state management reference table into app state and ephemeral rows.

### Fixed
- FVM detection: moved from agent system prompt (ignored after research) to
  SKILL.md step 1 (task prompt, reliably executed)
- Plan format consistency: planner was ignoring template format in 50%+ of runs.
  Root cause: ~30k tokens of research displaced instructions from LLM attention.
  Fixed with three-layer defense (load → re-read → self-check) achieving 100%
  format compliance across parallel test runs
- Architecture consistency: planner was choosing ChangeNotifier/ValueNotifier
  instead of Riverpod across runs. Root cause: ambiguous "built-in for simple
  cases" language in conventions doc. Fixed at source (conventions doc) rather
  than patching the plugin
- FVM auto-detection: all agents use `command -v fvm` + `.fvmrc` check to decide whether to prefix commands with `fvm` — matches the hook pattern, never uses resolved absolute paths
- Moved project context detection (Flutter, FVM, test count, frameworks) from skill `!` backtick snippets to planner agent exploration — avoids Bash permission issues
- Planner now requires explicit approval via AskUserQuestion before writing `.tdd-progress.md` — prevents confusion with system permission dialogs
- Stop hook: replaced prompt hook with deterministic command hook (check-tdd-progress.sh) that reads .tdd-progress.md directly — fixes "JSON validation failed" error, prevents infinite loops via stop_hook_active check, zero latency

## [1.0.0] - 2026-02-10

### Added
- Initial release of tdd-workflow plugin
- Three context-isolated agents: tdd-planner, tdd-implementer, tdd-verifier
- Orchestrating skill: `/tdd-plan` for TDD planning with codebase research
- Convention skills: dart-flutter-conventions, cpp-testing-conventions
- Hook scripts: validate-tdd-order.sh (test-first enforcement), auto-run-tests.sh (immediate feedback)
- SubagentStop hooks for completion verification on implementer and verifier
- Stop hook preventing premature session completion when slices remain
- Dart/Flutter reference: test patterns, mocking guide, widget testing, project conventions
- C++ reference: GoogleTest patterns, CMake integration, GoogleMock guide
- Version control guidelines adapted for TDD workflow
- Progress tracking via `.tdd-progress.md` with slice-oriented status
- Planning archive via `planning/` directory
