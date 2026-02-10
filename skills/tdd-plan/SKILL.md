---
name: tdd-plan
description: >
  Create a TDD implementation plan for a feature. Researches the codebase,
  decomposes work into testable slices, and produces a structured plan
  with test specifications, implementation scope, and verification criteria.
  Triggers on: "implement with TDD", "TDD plan", "test-driven".
context: fork
agent: tdd-planner
disable-model-invocation: true
---

# TDD Implementation Planning

<!-- ultrathink -->

Plan TDD implementation for: $ARGUMENTS

## Project Context (auto-detected)
- Test runner: !`which flutter >/dev/null 2>&1 && echo "flutter test" || echo "ctest"`
- Existing test count: !`find . -name "*_test.dart" -o -name "*_test.cpp" 2>/dev/null | wc -l`
- Test frameworks: !`grep -l "flutter_test\|package:test" pubspec.yaml 2>/dev/null | head -1 && echo "dart" || grep -l "gtest\|catch2" CMakeLists.txt 2>/dev/null | head -1 && echo "cpp"`

## Process

1. **Research the codebase** using Glob, Grep, and Read to understand:
   - Existing test patterns and frameworks in use
   - Project structure and architecture
   - Related code that the feature will interact with
   - Existing test configuration (pubspec.yaml, CMakeLists.txt, test/ directories)
   - If clarification is needed about scope or architectural decisions, ASK the user

2. **Identify the testing frameworks** already in use:
   - Dart/Flutter: flutter_test, mockito, bloc_test, integration_test
   - C++: GoogleTest, Catch2, or project-specific framework

3. **Decompose into feature slices.** Each slice must be:
   - Small enough to complete in one test-implement-refactor cycle
   - Independently testable
   - Ordered by dependency (foundations first)

4. **For each slice, specify:**

   ### Test Specification
   - What behavior to assert (not how to implement)
   - Test file path following project conventions
   - Test descriptions using "when X, then Y" format
   - Which test doubles are needed (mocks, fakes, stubs)
   - Edge cases to cover

   ### Implementation Scope
   - Files to create or modify
   - Public API surface (function signatures, class interfaces)
   - Dependencies on other slices

   ### Verification Criteria
   - Expected test command and output
   - Coverage expectations
   - Static analysis requirements (dart analyze, clang-tidy)

5. **Write the plan** as structured markdown to `.tdd-progress.md` at the project root (using the format specified in this workflow). Also write a read-only archive to `planning/YYYYMMDD_HHMM_feature_name.md`.

## Constraints
- Do NOT write any implementation code or test code in the plan
- Do NOT assume implementation details — specify BEHAVIOR only
- Do NOT plan refactoring steps — refactoring is an implementation-time concern
- Implement ONLY the features explicitly described in the user's request
- Keep slices to 2-5 minutes of implementation work each
- Order slices so each builds on the last
