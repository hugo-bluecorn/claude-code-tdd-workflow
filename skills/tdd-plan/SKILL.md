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
- Flutter available: !`flutter --version 2>/dev/null`
- FVM available: !`fvm --version 2>/dev/null`
- Existing test count: !`find . -name "*_test.dart" -o -name "*_test.cpp" 2>/dev/null | wc -l`
- Has pubspec.yaml: !`ls pubspec.yaml 2>/dev/null`
- Has CMakeLists.txt: !`ls CMakeLists.txt 2>/dev/null`

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

   Use the format defined in `reference/tdd-task-template.md` for structuring
   each slice's test specification. In particular:
   - Use Given-When-Then format for test descriptions
   - Include acceptance criteria as verification checkpoints
   - Track phase results (RED confirmed / GREEN confirmed / REFACTOR complete)

5. **Present the plan** as text output so the user can read it in full.

6. **Get explicit approval** using AskUserQuestion with options: Approve / Modify / Discard.
   - If Modify: revise based on feedback and repeat from step 5
   - If Discard: stop without writing any files

7. **Only after "Approve"**: write the plan as structured markdown to
   `.tdd-progress.md` at the project root. Also write a read-only archive
   to `planning/YYYYMMDD_HHMM_feature_name.md` using the structure defined
   in `reference/feature-notes-template.md`. The archive should capture:
   - Feature purpose and requirements analysis
   - Architectural approach and design decisions
   - Dependencies (external packages, internal modules)
   - Known limitations and trade-offs
   - The slice decomposition (referencing .tdd-progress.md for live status)

## Constraints
- Do NOT write any implementation code or test code in the plan
- Do NOT assume implementation details — specify BEHAVIOR only
- Do NOT plan refactoring steps — refactoring is an implementation-time concern
- Implement ONLY the features explicitly described in the user's request
- Keep slices to 2-5 minutes of implementation work each
- Order slices so each builds on the last
