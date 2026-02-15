# Feature Notes: Harden Hook Scripts — Retroactive Test Coverage + JSON Output Safety Fix

**Created:** 2026-02-15
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Three hook scripts in the TDD workflow plugin have insufficient test coverage,
and one has a JSON output safety bug. This feature hardens the hooks by:
1. Adding retroactive test coverage to `check-tdd-progress.sh` (zero tests)
2. Fixing a JSON injection vulnerability in `auto-run-tests.sh` line 64
3. Extending test coverage for `auto-run-tests.sh` (FVM, dart, C++ paths)
4. Extending edge case coverage for `validate-tdd-order.sh`

### Use Cases
- A developer stops a Claude Code session mid-TDD — `check-tdd-progress.sh` should reliably warn about incomplete slices
- Test output containing quotes/newlines/backslashes should not break JSON output from `auto-run-tests.sh`
- Projects using FVM for Flutter version management should have their test commands detected correctly
- Edge cases like `.hpp` files, `.cc` files, empty paths, and malformed JSON should be handled gracefully

### Context
The hook scripts were added in phases:
- `validate-tdd-order.sh` and `auto-run-tests.sh`: v1.0.0 with 9 and 6 tests respectively
- `check-tdd-progress.sh`: v1.2.0 with zero tests
- Bash testing support (bashunit + shellcheck): v1.2.0
- All scripts use a JSON-in/JSON-out protocol read from stdin

Existing test infrastructure uses bashunit with helper functions in
`test/hooks/` following established patterns: `create_tmp_env`, `build_json`,
isolated temp directories, cleanup via `tear_down`.

---

## Requirements Analysis

### Functional Requirements
1. `check-tdd-progress.sh` has complete test coverage for all 5 code paths
2. `auto-run-tests.sh` JSON output is always valid JSON regardless of `$RESULT` content
3. `auto-run-tests.sh` FVM detection path tested in 3 scenarios (fvmrc+fvm, fvmrc-nofvm, no-fvmrc)
4. `auto-run-tests.sh` dart file mapping and C++ build detection tested
5. `validate-tdd-order.sh` edge cases tested: `.cc`, `_test.cc`, `_test.hpp`, empty path, malformed JSON, git failure, `test_` prefix

### Non-Functional Requirements
- All scripts pass `shellcheck -S warning`
- All 67 existing tests continue to pass (no regressions)
- Test patterns match established conventions (helpers, naming, cleanup)

### Integration Points
- `check-tdd-progress.sh` reads `.tdd-progress.md` for slice status
- `auto-run-tests.sh` integrates with bashunit, flutter, fvm, cmake
- `validate-tdd-order.sh` integrates with git diff for test file detection
- `planner_bash_guard_test.sh` MD5 checksums must be updated when `auto-run-tests.sh` changes

---

## Implementation Details

### Architectural Approach
This is primarily retroactive testing — the implementation exists and must NOT
be modified (except the JSON fix on line 64 of `auto-run-tests.sh`). The RED
phase writes tests that PASS immediately since the implementation exists. This
is the expected inversion for retroactive coverage.

The JSON safety fix replaces raw string interpolation:
```bash
echo "{\"systemMessage\": \"Auto-test: $RESULT\"}"
```
with jq-based JSON construction:
```bash
jq -n --arg msg "Auto-test: $RESULT" '{"systemMessage": $msg}'
```

### Design Patterns
- **Isolated test environments**: Each test creates a temp directory, sets up fixtures, runs the hook, and cleans up
- **Stub commands**: FVM testing uses stub scripts on PATH to simulate `fvm` availability
- **Behavior documentation via tests**: Known bugs (e.g., `_test.hpp` not recognized as test file) are documented by tests that assert the current (buggy) behavior without fixing it

### File Structure
```
hooks/
  auto-run-tests.sh          # Source change: line 64 JSON fix
  check-tdd-progress.sh      # No changes
  validate-tdd-order.sh      # No changes
test/hooks/
  check_tdd_progress_test.sh # NEW: 9 tests
  auto_run_tests_test.sh     # EXTEND: +16 tests (6 JSON safety + 10 path coverage)
  validate_tdd_order_test.sh # EXTEND: +10 tests
```

### Naming Conventions
- Test files: `snake_case_test.sh` in `test/hooks/`
- Test functions: `test_descriptive_name` (bashunit convention)
- Hook scripts: `kebab-case.sh` in `hooks/`

---

## TDD Approach

### Slice Decomposition

The feature is broken into 4 independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** `./lib/bashunit test/hooks/`

### Slice Overview
| # | Slice | New Tests | Dependencies |
|---|-------|-----------|-------------|
| 1 | check-tdd-progress.sh — Retroactive coverage | 9 | None |
| 2 | auto-run-tests.sh — JSON output safety fix | 6 | None |
| 3 | auto-run-tests.sh — FVM + dart/C++ path coverage | 10 | Slice 2 |
| 4 | validate-tdd-order.sh — Edge case coverage | 10 | None |

**Total new tests:** 35 | **Existing tests:** 67 | **Expected total:** 102

---

## Dependencies

### External Packages
- `bashunit`: Test framework for shell scripts (already installed at `./lib/bashunit`)
- `shellcheck`: Static analysis for shell scripts (already available)
- `jq`: JSON processing (required for the line 64 fix — already a dependency)

### Internal Dependencies
- `hooks/check-tdd-progress.sh`: Reads `.tdd-progress.md`
- `hooks/auto-run-tests.sh`: Invokes bashunit, flutter, fvm, cmake
- `hooks/validate-tdd-order.sh`: Invokes git diff
- `test/hooks/planner_bash_guard_test.sh`: MD5 checksums for hook files

---

## Known Limitations / Trade-offs

### Limitations
- `_test.hpp` is NOT recognized as a test file by `validate-tdd-order.sh` line 9 — latent bug documented via test but not fixed in this scope
- `.hpp` files ARE handled as C++ by `auto-run-tests.sh` line 32 (contrary to initial assumption) — documented via test
- FVM tests use stub scripts rather than real FVM — they verify the detection logic, not the actual FVM integration

### Trade-offs Made
- **Retroactive testing inversion**: RED phase tests pass immediately because implementation exists. This sacrifices the normal TDD feedback loop but is the correct approach for adding coverage to existing code.
- **Behavior documentation over fixing**: Known bugs (`_test.hpp` gap) are documented by tests that assert current behavior without fixing it. Fixing is out of scope to minimize blast radius.

---

## Implementation Notes

### Key Decisions
- **jq for JSON output**: Chosen over printf/sed because jq handles all JSON escaping correctly and is already a project dependency
- **MD5 checksum update**: The `planner_bash_guard_test.sh` checksum for `auto-run-tests.sh` must be updated as part of the JSON fix — this is a known downstream effect
- **.hpp correction**: Initial analysis assumed `.hpp` was unhandled in `auto-run-tests.sh`, but code review confirmed line 32 includes it in the C++ elif branch

### Future Improvements
- Fix the `_test.hpp` recognition gap in `validate-tdd-order.sh` line 9 (add `hpp` to the test file regex)
- Add integration tests that run hooks against real Flutter/C++ projects
- Consider using `jq` for all JSON output in hook scripts (not just line 64)

### Potential Refactoring
- Extract common test helpers (temp dir creation, JSON building, hook execution) into a shared file if the pattern grows

---

## References

### Related Code
- `hooks/check-tdd-progress.sh` — stop hook with JSON decision protocol
- `hooks/auto-run-tests.sh` — post-tool-use hook for auto-testing
- `hooks/validate-tdd-order.sh` — pre-tool-use hook for TDD enforcement
- `test/hooks/auto_run_tests_test.sh` — existing 6 tests
- `test/hooks/validate_tdd_order_test.sh` — existing 9 tests
- `test/hooks/planner_bash_guard_test.sh` — MD5 checksums for hook integrity

### Documentation
- `CLAUDE.md` — project conventions and TDD workflow
- `skills/bash-testing-conventions/reference/` — bashunit patterns and shellcheck guide
