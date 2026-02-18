---
name: tdd-plan
description: >
  Create a TDD implementation plan for a feature. Researches the codebase,
  decomposes work into testable slices, and produces a structured plan
  with test specifications, implementation scope, and verification criteria.
  Triggers on: "implement with TDD", "TDD plan", "test-driven".
context: fork
agent: tdd-planner
argument-hint: "[feature description]"
disable-model-invocation: true
---

# TDD Implementation Planning

<!-- ultrathink -->

Plan TDD implementation for: $ARGUMENTS

## Process

0. **Load and follow convention references** (mandatory, do this first):
   - Dart/Flutter projects (`pubspec.yaml` exists): read every file in `skills/dart-flutter-conventions/reference/`
   - C++ projects (`CMakeLists.txt` exists): read every file in `skills/cpp-testing-conventions/reference/`
   - Bash projects (`_test.sh` files exist or `.bashunit.yml` exists): read every file in `skills/bash-testing-conventions/reference/`
   - Also read `reference/tdd-task-template.md` for the output format
   The plan MUST conform to the architecture, directory structure, state management,
   and naming conventions defined in these files. Do not proceed to step 1 until all
   reference files for the detected project type are loaded.

1. **Detect project context** by running: `${CLAUDE_PLUGIN_ROOT}/hooks/detect-project-context.sh`
   This outputs key=value lines for test_runner, test_count, branch, dirty_files, and fvm.
   Use this information to guide your research — skip detection steps you already have answers for.

2. **Research the codebase** using Glob, Grep, and Read to understand:
   - Existing test patterns and frameworks in use
   - Project structure and architecture
   - Related code that the feature will interact with
   - Existing test configuration (pubspec.yaml, CMakeLists.txt, test/ directories)
   - **FVM detection:** if `.fvmrc` exists in the project root AND `command -v fvm` succeeds,
     use `fvm flutter` / `fvm dart` as the command prefix throughout the plan.
     Otherwise use `flutter` / `dart` directly.
   - If clarification is needed about scope or architectural decisions, ASK the user

3. **Identify the testing frameworks** already in use:
   - Dart/Flutter: flutter_test, mockito, bloc_test, integration_test
   - C++: GoogleTest, Catch2, or project-specific framework
   - Bash: bashunit, shellcheck

4. **Decompose into feature slices.** Each slice must be:
   - Small enough to complete in one test-implement-refactor cycle
   - Independently testable
   - Ordered by dependency (foundations first)

5. **Re-read format requirements before writing the plan:**
   - Re-read `reference/tdd-task-template.md` for the output structure
   - Re-read step 0's convention requirements (architecture, state management)
   - The plan you are about to write MUST use the exact format from the template —
     Given/When/Then blocks, acceptance criteria, and phase tracking per slice.
     Summary tables and bullet descriptions are NOT acceptable.
   This step exists because research (19+ tool uses, ~30k tokens) pushes the
   original instructions far back in context. Re-reading them right before output
   ensures they are in active attention.

6. **For each slice, produce this exact structure:**

   ```
   ## Slice N: {Slice Name}

   **Status:** pending

   **Source:** `{source file path}`
   **Tests:** `{test file path}`

   ### Test 1: {Test Name}
   Given: {precondition}
   When: {action}
   Then: {expected outcome}

   ### Edge Cases

   ### Test 2: {Edge Case Test Name}
   Given: {edge case condition}
   When: {action}
   Then: {expected behavior}

   ### Acceptance Criteria
   - [ ] All tests pass
   - [ ] {slice-specific criteria}

   ### Phase Tracking

   - **RED:** pending
   - **GREEN:** pending
   - **REFACTOR:** pending

   **Depends on:** {slice numbers} | **Blocks:** {slice numbers}
   ```

   Do NOT summarize tests as bullet points or table rows. Each test MUST have
   explicit Given/When/Then on compact single lines (no bold, no bullet points).
   This is the format that gets written to `.tdd-progress.md`.

7. **Self-check before presenting** — verify EVERY slice has all of these.
   If any are missing, fix the plan before showing it:
   - [ ] Given/When/Then as compact single lines (e.g., `Given: {precondition}`)
   - [ ] Acceptance Criteria section with checkboxes
   - [ ] Phase Tracking section (RED: pending, GREEN: pending, REFACTOR: pending)
   - [ ] Source and Test file paths
   - [ ] Depends on / Blocks references
   - [ ] Edge Cases section
   If a slice is missing any of these, add them before proceeding.
   Do NOT present an incomplete plan.

8. **Present the plan** as text output so the user can read it in full.

9. **Get explicit approval** using AskUserQuestion with options: Approve / Modify / Discard.
   - If Modify: revise based on feedback and repeat from step 7
   - If Discard: stop without writing any files

10. **Only after "Approve"**: write the plan as structured markdown to
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
- The plan's architecture, directory layout, state management approach, and naming
  MUST match what the convention references prescribe — do not invent alternatives
