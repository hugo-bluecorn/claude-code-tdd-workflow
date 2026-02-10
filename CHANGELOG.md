# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- User guide with step-by-step walkthrough (docs/user-guide.md)

### Changed
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
