# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.10.0] - 2026-03-01

### Added
- Plugin API reference documentation in `docs/reference/` (12 files covering
  agents, hooks, skills, settings, MCP, plugins, and more)
- `docs/plugin-developer-prompt.md` — developer role and architecture overview
- CLAUDE.md pointer to plugin development reference docs
- `color` frontmatter field to all 6 agents for UI differentiation:
  tdd-planner (blue), tdd-implementer (green), tdd-verifier (yellow),
  tdd-releaser (cyan), tdd-doc-finalizer (magenta), context-updater (red)
- `color` field documented in `docs/reference/agents.md` as undocumented
  but functional (values: blue, cyan, green, yellow, magenta, red, pink)
- `scripts/` directory for utility scripts (non-hook)

### Fixed
- README agents table: corrected context-updater model from `sonnet` to
  `opus` to match actual agent definition
- `test/skills/shellcheck_guide_test.sh`: template placeholder test now
  filters out bash function definitions (`() {`) before checking for
  stray braces, fixing false positive on shellcheck guide examples

### Changed
- Moved `hooks/detect-project-context.sh` to `scripts/detect-project-context.sh`
  — it is a utility script invoked by the tdd-plan skill, not an event-driven
  hook. Updated references in SKILL.md, README, and extensibility audit.

## [1.9.0] - 2026-02-28

### Added
- `tdd-doc-finalizer` agent at `agents/tdd-doc-finalizer.md`: post-release
  documentation finalization agent handling version bumps in `plugin.json`,
  documentation updates (README, CLAUDE.md, user-guide.md), release integration
  test maintenance, and pushing changes to the existing PR branch
- `/tdd-finalize-docs` skill at `skills/tdd-finalize-docs/SKILL.md`:
  orchestrating skill that invokes `tdd-doc-finalizer` with `context: fork`
  and `disable-model-invocation: true`
- SubagentStop hook entry for `tdd-doc-finalizer` in `hooks/hooks.json`
  reusing the existing `check-release-complete.sh` (timeout 15s)
- 3 new test files: `test/agents/tdd_doc_finalizer_test.sh` (13 tests),
  `test/skills/tdd_finalize_docs_test.sh` (9 tests),
  `test/hooks/hooks_json_doc_finalizer_test.sh` (9 tests)

## [1.8.2] - 2026-02-28

### Fixed
- validate-plan-output.sh: replaced unconditional `.tdd-plan-locked`
  removal with approval enforcement gate — stop hook now detects when
  the planner agent stops without calling AskUserQuestion and blocks
  with actionable feedback (retry counter, max 2 retries)
- tdd-planner agent: Discard path now removes `.tdd-plan-locked` so
  the stop hook can distinguish "user chose Discard" from "agent
  forgot to call AskUserQuestion after auto-compaction"

### Added
- Approval enforcement gate in `validate-plan-output.sh` with retry
  counter (`.tdd-plan-approval-retries`) preventing infinite blocking
- Post-compaction AskUserQuestion reminder at end of tdd-planner
  agent prompt (concise, minimal token overhead)
- SubagentStart hook cleans up stale retry counter from previous
  sessions
- `.gitignore` with `.tdd-plan-locked` and `.tdd-plan-approval-retries`
- 20 new tests in `validate_plan_output_test.sh` (50 total)

## [1.8.1] - 2026-02-24

### Changed
- tdd-planner agent: fixed misleading frontmatter description from "Codebase
  research agent... Read-only" to "Autonomous TDD planning agent" with accurate
  capability listing (approval flow, file writing, AskUserQuestion)
- tdd-planner agent: added `## Identity & Invocation` section to system prompt
  with invocation detection and graceful degradation to research-only mode when
  manually launched outside `/tdd-plan`
- CLAUDE.md: updated Plugin Architecture table — tdd-planner row now says
  "Read-write (gated by approval lock)" instead of "Read-only"
- CLAUDE.md: added invocation warning after Available Commands section advising
  against manual Task tool invocation of tdd-planner

### Added
- `test/agents/tdd_planner_identity_test.sh` — 26 tests verifying agent
  description accuracy, identity guard content, and CLAUDE.md documentation

## [1.8.0] - 2026-02-23

### Added
- C++ conventions: `clang-tooling.md` reference covering clang-format,
  clang-tidy testing checks, and sanitizer (ASan/UBSan/TSan) CMake integration

### Changed
- C++ conventions: GoogleTest updated from v1.14.0 to v1.17.0 (requires C++17);
  CMake minimum raised from 3.14 to 3.16 with `CMAKE_CXX_STANDARD 17` enforced
- C++ conventions: added `DistanceFrom()` matcher (GoogleTest 1.17+) and CMake
  4.x compatibility note
- Dart/Flutter conventions: split `project-conventions.md` (536 lines) into
  `project-conventions.md` (~200 lines) and `riverpod-guide.md` (~190 lines)
- Dart/Flutter conventions: split `test-patterns.md` (411 lines) into
  `test-patterns.md` (~220 lines) and `test-recipes.md` (~160 lines)
- Dart/Flutter conventions: fixed deprecated `tester.binding.window` API
  replaced with `tester.view` in golden test examples
- Bash conventions: added ShellCheck 0.11.0 warning codes SC2329/SC2330
  (unused function detection) to shellcheck-guide.md
- README: added context-updater agent, `/tdd-update-context` skill, new
  reference files, and SubagentStart hook to component tables and file tree
- User guide: added "Updating Convention References" section documenting
  `/tdd-update-context` workflow; updated reference list with new files
- CLAUDE.md: updated convention skills table with new reference file names

## [1.7.0] - 2026-02-23

### Added
- `/tdd-update-context` skill for updating convention reference files to latest
  framework versions, best practices, and gap analysis with breaking-change
  detection
- `context-updater` agent with web search, approval gate, and targeted edits
  to reference content files only
- SubagentStart hook for context-updater injecting git branch, last commit,
  and dirty file count with edit warning

## [1.6.6] - 2026-02-20

### Fixed
- Pipe bypass in planner bash guard: `cat | tee .tdd-progress.md` now blocked
  alongside `>` redirects; covers `tee` and `sponge` patterns
- Auto-compaction unapproved plan cascade: `.tdd-plan-locked` filesystem lock
  prevents `.tdd-progress.md` writes until explicit approval via AskUserQuestion
- Stop hook imperative language: "Continue implementing." replaced with
  declarative "TDD session has N of M slices remaining."
- Unapproved plans no longer trap user in session: missing `Approved:` marker
  allows session exit instead of blocking

### Added
- Lock-file gate in planner bash guard with targeted `rm .tdd-plan-locked`
  exception
- Lock lifecycle: SubagentStart creates `.tdd-plan-locked`, SubagentStop
  unconditionally removes it (before stop_hook_active check)
- `Approved:` marker in `.tdd-progress.md` header for downstream validation
- Compaction guard in SKILL.md and tdd-planner.md referencing lock file as
  ground truth
- Step -1 approval verification gate in tdd-implement skill


## [1.6.5] - 2026-02-20

### Changed
- Project conventions: migrated from Riverpod 2.x to Riverpod 3.x (v3.2.1)
  with no-codegen stance, updated provider types, sealed Ref class, and
  `ref.mounted` async safety checks

## [1.6.4] - 2026-02-18

### Fixed
- Deadlock in `validate-plan-output.sh` when user discards plan or planner
  stops without writing files — hook now allows stop when no `.tdd-progress.md`
  exists
- Section validation mismatch: hook now accepts `Overview` and `Requirements
  Analysis` headings from `feature-notes-template.md`, not just `Feature Analysis`
- Refactoring leak false positive: markdown headers (`### Iteration 3 (REFACTOR
  Phase)`) and phase tracking boilerplate (`- **REFACTOR:** pending`) are excluded
  from the leak check
- Error message clarity: distinguishes between "no active session" (exit 0) and
  "progress file exists but archive missing" (exit 2 with specific guidance)

## [1.6.3] - 2026-02-18

### Added
- Plugin update instructions in user guide covering marketplace, direct install,
  and local development workflows

## [1.6.2] - 2026-02-18

### Changed
- Disabled `maxTurns` limit on tdd-planner agent to prevent premature
  termination during complex planning sessions

## [1.6.1] - 2026-02-18

### Changed
- Test specification format: compact single-line Given/When/Then replacing
  multi-line bold blocks with bullet points
- User guide: added "Changing the test specification format" configuration section
- README: added Test Specification Format to Configuration section

## [1.6.0] - 2026-02-16

### Added
- `/tdd-release` skill for orchestrating version releases with CHANGELOG updates
  and PR creation
- `tdd-releaser` agent with read-write access for executing the release workflow
- `check-release-complete.sh` SubagentStop hook validating that all release
  checklist items are complete before the releaser agent finishes

## [1.5.0] - 2026-02-15

### Added
- Git auto-commit workflow in tdd-implementer: commits after each R-G-R phase
  with conventional commit messages (`test:`, `feat:`, `refactor:`)
- Feature branch creation in `/tdd-implement`: auto-creates `feature/<name>`
  branch before first slice if on main/master

### Fixed
- README: model references corrected from `sonnet` to `opus` (5 places)
- README: hooks table and file structure updated with 3 missing hooks and
  tdd-plan/reference/ directory
- User guide: stale hook count, reversed model config section, missing bash
  prerequisites, missing bash-testing-conventions reference
- User guide: "Committing Your Work" updated to describe auto-commits and
  branch creation
- version-control-integration.md: Layers 1 and 2 marked as implemented

## [1.4.0] - 2026-02-15

### Added
- `memory: project` on tdd-planner with memory instructions for cross-session
  knowledge accumulation (S1)
- SubagentStart hook injecting git branch, last commit, and dirty file count
  into planner as additional context (S3)
- `detect-project-context.sh` helper script for project context detection (S4)

### Changed
- Planner SKILL.md: added step 1 to run `detect-project-context.sh` via Bash
  tool for test runner, test count, branch, dirty files, and FVM detection

### Fixed
- `!` backtick preprocessing blocked by Claude Code permission system — even
  via helper script. Replaced with planner step 1 running detect script directly

## [1.3.1] - 2026-02-15

### Added
- Retroactive test coverage for `check-tdd-progress.sh` (16 new tests)
- Extended test coverage for `auto-run-tests.sh` (16 new tests: FVM, JSON
  safety, dart/C++ paths, .hpp handling)
- Extended test coverage for `validate-tdd-order.sh` (10 new tests: .cc, .hpp,
  test_ prefix, malformed JSON, git failure)

### Fixed
- JSON output safety in `auto-run-tests.sh`: replaced raw `echo` with `jq -n
  --arg` to prevent malformed JSON from test output containing special characters
- Executable permission on `planner-bash-guard.sh` (was `-rw-rw-r--`, now
  `-rwxrwxr-x` matching all other hook scripts)

## [1.3.0] - 2026-02-15

### Added
- `planner-bash-guard.sh`: PreToolUse allowlist hook restricting planner to
  read-only commands (M1)
- `validate-plan-output.sh`: Stop hook validating plan file has required
  sections and no refactoring leak (M2)
- SubagentStop hook for tdd-planner reusing validate-plan-output.sh (S2)

## [1.2.0] - 2026-02-14

### Added
- `bash-testing-conventions` skill with bashunit-patterns and shellcheck-guide
  reference docs
- validate-tdd-order.sh bash support: recognizes `_test.sh` files and bash
  test patterns
- auto-run-tests.sh bashunit integration: detects and runs bashunit for `.sh`
  file changes
- Verifier bash/shellcheck support: runs shellcheck static analysis and
  bashunit test suite
- Permission requirements: users must allow `Bash(shellcheck *)` and
  `Bash(bashunit *)` in `.claude/settings.local.json`

## [1.1.0] - 2026-02-14

### Added
- `/tdd-implement` skill for starting and resuming the TDD implementation loop
- User guide with step-by-step walkthrough (docs/user-guide.md)
- TDD task template (`skills/tdd-plan/reference/tdd-task-template.md`) with
  Given-When-Then test specification format and acceptance criteria structure
- Feature notes template (`skills/tdd-plan/reference/feature-notes-template.md`)
  for planning archive documents with architectural context and trade-offs
- Enhanced `CLAUDE.md` with development workflow, project guidelines,
  pre-commit checklist, and project-specific customization section
- `model: opus` on tdd-planner and tdd-implementer (P1)
- `argument-hint: "[feature description]"` on `/tdd-plan` (N1)
- `user-invocable: false` on convention skills (N2)
- `$schema` on hooks.json (N5)

### Changed
- Planner skill (`tdd-plan/SKILL.md`) restructured with 10-step process (0-9):
  - Step 0: mandatory convention reference loading before any research
  - Step 1: codebase research with FVM detection
  - Step 4: re-read format requirements after research (~30k tokens of research
    was pushing original instructions out of LLM attention)
  - Step 5: inline template example showing exact output structure
  - Step 6: self-check checklist verifying every slice has Given-When-Then
    blocks, Phase Tracking, Acceptance Criteria, Edge Cases, and file paths
- Planner agent (`tdd-planner.md`): removed duplicated file lists and FVM
  detection (now handled by SKILL.md), tightened Output section to require
  template structure
- `project-conventions.md`: clarified ephemeral vs app state management —
  ChangeNotifier/ValueNotifier only for widget-local state (animations, form
  focus), Riverpod required for all app/business state

### Fixed
- FVM detection: moved from agent system prompt (ignored after research) to
  SKILL.md step 1 (task prompt, reliably executed)
- Plan format consistency: planner was ignoring template format in 50%+ of
  runs. Fixed with three-layer defense (load → re-read → self-check)
- Architecture consistency: planner was choosing ChangeNotifier instead of
  Riverpod. Fixed at source (conventions doc) rather than patching the plugin
- FVM auto-detection: all agents use `command -v fvm` + `.fvmrc` check
- Planner now requires explicit approval via AskUserQuestion before writing
  `.tdd-progress.md`
- Stop hook: replaced prompt hook with deterministic command hook
  (check-tdd-progress.sh)

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
