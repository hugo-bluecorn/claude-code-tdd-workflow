---
name: c-conventions
description: >
  C language testing conventions using Unity/CMock, coding standards
  based on BARR-C:2018 and SEI CERT C, and static analysis tooling.
  Loaded by TDD agents when working on C source files.
user-invocable: false
---

# C Language Conventions

## Test Framework

See `reference/c-testing-patterns.md` for:
- Unity test macros (TEST_ASSERT_*, setUp, tearDown)
- CMock for mocking C functions
- Test file organization and naming conventions
- GoogleTest interop via extern "C"
- Minimal assert.h patterns

## Coding Standards

See `reference/c-coding-standards.md` for:
- BARR-C:2018 naming, formatting, and function rules
- SEI CERT C priority rules (MEM, INT, STR, ARR, ERR)
- Rule-to-clang-tidy check mapping

## Static Analysis

See `reference/c-static-analysis.md` for:
- Compiler warning flags (-Wall -Wextra -Werror -pedantic)
- cppcheck for bug detection
- clang-tidy with cert-* and bugprone-* checks
- gcc -fanalyzer for deep path analysis
- Integration with TDD verification phase

## Running Tests

C projects require a build step before test execution. The typical sequence is:

1. **Configure** the build system (generate build files)
2. **Build** the test executables
3. **Run** the tests

This sequence applies regardless of whether the project uses CMake, Make, Meson,
or another build system. The convention docs describe what good C tests look like,
not which build tool to use.
