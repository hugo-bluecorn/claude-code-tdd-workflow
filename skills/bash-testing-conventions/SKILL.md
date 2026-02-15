---
name: bash-testing-conventions
description: >
  Bash testing conventions using bashunit and shellcheck for script
  validation. Loaded by TDD agents when working on shell scripts.
user-invocable: false
---

# Bash Testing Conventions

## Test Structure
See `reference/bashunit-patterns.md` for:
- Test function naming with test_ prefix
- Setup and teardown functions
- Assertion macros (assert_equals, assert_contains, assert_file_exists)
- Parameterized and data-driven tests

## Static Analysis
See `reference/shellcheck-guide.md` for:
- Common shellcheck rules and fixes
- Severity levels and directive comments
- Integration with CI pipelines

## Running Tests
- Single file: `./lib/bashunit test/path/to_test.sh`
- All tests: `./lib/bashunit test/`
- Specific test: `./lib/bashunit --filter "test_name" test/`
- Verbose: `./lib/bashunit --verbose test/`
