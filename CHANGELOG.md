# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `/tdd-implement` skill for starting and resuming the TDD implementation loop
- User guide with step-by-step walkthrough (docs/user-guide.md)
- TDD task template (`skills/tdd-plan/reference/tdd-task-template.md`) with
  Given-When-Then test specification format and acceptance criteria structure
- Feature notes template (`skills/tdd-plan/reference/feature-notes-template.md`)
  for planning archive documents with architectural context and trade-offs
- Enhanced `CLAUDE.md` with development workflow, project guidelines,
  pre-commit checklist, and project-specific customization section

### Changed
- Planner skill (`tdd-plan/SKILL.md`) now references templates for
  structured output formatting
- Planner agent reads reference templates during codebase research phase

### Fixed
- FVM auto-detection: all agents check for `.fvmrc` and use `fvm flutter` when present; planner runs detection during exploration phase
- Moved project context detection (Flutter, FVM, test count, frameworks) from skill `!` backtick snippets to planner agent exploration — avoids Bash permission issues
- Planner agent now explicitly reads convention reference docs (test-patterns, mocking-guide, widget-testing, project-conventions for Dart/Flutter; googletest-patterns, cmake-integration, googlemock-guide for C++) based on detected project type — previously the skill SKILL.md was injected but reference files were not read
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
