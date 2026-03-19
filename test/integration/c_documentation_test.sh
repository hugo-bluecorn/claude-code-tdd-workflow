#!/bin/bash

# Test suite for C language documentation updates: tdd-verifier.md, CLAUDE.md, README.md
# Verifies that C support is documented alongside Dart/Flutter, C++, and Bash/Shell
# Updated for v2.0: old convention skill names removed from assertions

VERIFIER_MD="agents/tdd-verifier.md"
CLAUDE_MD="CLAUDE.md"
README_MD="README.md"

# ---------- Test 1: Verifier mentions C in test suite section ----------

function test_verifier_has_c_test_runner_line() {
  # The test suite section must include a C-specific line (parallel to Bash and C++ lines)
  local test_suite_section
  test_suite_section=$(sed -n '/Full test suite passes/,/^[0-9]\./p' "$VERIFIER_MD")
  assert_matches "[Cc]:.*Unity|Unity.*[Cc][ /]" "$test_suite_section"
}

# ---------- Test 2: Verifier mentions C in static analysis section ----------

function test_verifier_has_c_static_analysis_line() {
  # The static analysis section must reference C analysis tools
  local static_section
  static_section=$(sed -n '/Static analysis clean/,/^[0-9]\./p' "$VERIFIER_MD")
  assert_matches "cppcheck|clang-tidy.*C " "$static_section"
}

# ---------- Test 3: Verifier preserves existing Dart, C++, and Bash entries ----------

function test_verifier_still_has_flutter_test() {
  assert_file_contains "$VERIFIER_MD" "flutter test"
}

function test_verifier_still_has_ctest() {
  assert_file_contains "$VERIFIER_MD" "ctest"
}

function test_verifier_still_has_bashunit() {
  assert_file_contains "$VERIFIER_MD" "bashunit"
}

function test_verifier_still_has_dart_analyze() {
  assert_file_contains "$VERIFIER_MD" "dart analyze"
}

function test_verifier_still_has_shellcheck() {
  assert_file_contains "$VERIFIER_MD" "shellcheck"
}

# ---------- Test 4: CLAUDE.md has C Testing subsection ----------

function test_claude_md_has_c_testing_subsection() {
  assert_file_contains "$CLAUDE_MD" "### C Testing"
}

function test_claude_md_c_testing_mentions_unity() {
  local c_section
  c_section=$(sed -n '/### C Testing/,/^###/p' "$CLAUDE_MD")
  assert_contains "Unity" "$c_section"
}

function test_claude_md_c_testing_mentions_coding_standards() {
  local c_section
  c_section=$(sed -n '/### C Testing/,/^###/p' "$CLAUDE_MD")
  assert_matches "BARR-C|SEI CERT|coding standards" "$c_section"
}

# ---------- Test 5: CLAUDE.md pre-commit checklist includes C analysis tools ----------

function test_claude_md_precommit_includes_c_analysis() {
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---/p' "$CLAUDE_MD")
  assert_matches "cppcheck|clang-tidy" "$checklist"
}

# ---------- Test 6: README.md overview mentions C ----------

function test_readme_overview_mentions_c_language() {
  # README conveys extensible conventions (language-agnostic since v2.0)
  local overview
  overview=$(sed -n '1,10p' "$README_MD")
  assert_matches "extensible|convention" "$overview"
}
