#!/bin/bash

# Test suite for C language documentation updates: tdd-verifier.md, CLAUDE.md, README.md
# Verifies that C support is documented alongside Dart/Flutter, C++, and Bash/Shell

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

# ---------- Test 4: CLAUDE.md auto-load table includes c-conventions ----------

function test_claude_md_plugin_skills_table_has_c_conventions() {
  # The Plugin Convention Skills table must include c-conventions
  assert_file_contains "$CLAUDE_MD" "c-conventions"
}

# ---------- Test 5: CLAUDE.md c-conventions row references all three reference docs ----------

function test_claude_md_c_conventions_references_testing_patterns() {
  local table_line
  table_line=$(grep "c-conventions" "$CLAUDE_MD" | head -1)
  assert_contains "c-testing-patterns" "$table_line"
}

function test_claude_md_c_conventions_references_coding_standards() {
  local table_line
  table_line=$(grep "c-conventions" "$CLAUDE_MD" | head -1)
  assert_contains "c-coding-standards" "$table_line"
}

function test_claude_md_c_conventions_references_static_analysis() {
  local table_line
  table_line=$(grep "c-conventions" "$CLAUDE_MD" | head -1)
  assert_contains "c-static-analysis" "$table_line"
}

function test_claude_md_c_conventions_triggers_on_c_files() {
  local table_line
  table_line=$(grep "c-conventions" "$CLAUDE_MD" | head -1)
  assert_contains ".c" "$table_line"
}

# ---------- Test 6: CLAUDE.md has C Testing subsection ----------

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

# ---------- Test 7: CLAUDE.md pre-commit checklist includes C analysis tools ----------

function test_claude_md_precommit_includes_c_analysis() {
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---/p' "$CLAUDE_MD")
  assert_matches "cppcheck|clang-tidy" "$checklist"
}

# ---------- Test 8: README.md skills table includes c-conventions ----------

function test_readme_skills_table_has_c_conventions() {
  local skills_section
  skills_section=$(sed -n '/### Skills/,/^###/p' "$README_MD")
  assert_contains "c-conventions" "$skills_section"
}

# ---------- Test 9: README.md file structure shows c-conventions directory ----------

function test_readme_file_structure_has_c_conventions_dir() {
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  assert_contains "c-conventions/" "$file_structure"
}

function test_readme_file_structure_has_c_conventions_skill_md() {
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  assert_contains "SKILL.md" "$file_structure"
}

function test_readme_file_structure_has_c_conventions_reference() {
  # The c-conventions section in file structure should show a reference/ subdirectory
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  # Check that c-conventions is followed by reference content
  local c_conv_section
  c_conv_section=$(echo "$file_structure" | sed -n '/c-conventions/,/^[^ │├└]/p')
  assert_contains "reference" "$c_conv_section"
}

# ---------- Test 10: README.md overview mentions C ----------

function test_readme_overview_mentions_c_language() {
  # First few lines (overview/description) should mention C
  local overview
  overview=$(sed -n '1,10p' "$README_MD")
  # Must mention C as a standalone language (not just C++ which is already there)
  # Look for ", C," or ", C " or "C, " pattern that distinguishes from C++
  assert_matches ", C,|, C " "$overview"
}

# ---------- Test 11: CLAUDE.md preserves existing skill rows ----------

function test_claude_md_still_has_dart_flutter_conventions() {
  assert_file_contains "$CLAUDE_MD" "dart-flutter-conventions"
}

function test_claude_md_still_has_cpp_testing_conventions() {
  assert_file_contains "$CLAUDE_MD" "cpp-testing-conventions"
}

function test_claude_md_still_has_bash_testing_conventions() {
  assert_file_contains "$CLAUDE_MD" "bash-testing-conventions"
}

# ---------- Test 12: README.md preserves existing skill entries ----------

function test_readme_still_has_dart_flutter_conventions() {
  assert_file_contains "$README_MD" "dart-flutter-conventions"
}

function test_readme_still_has_cpp_testing_conventions() {
  assert_file_contains "$README_MD" "cpp-testing-conventions"
}

function test_readme_still_has_bash_testing_conventions() {
  assert_file_contains "$README_MD" "bash-testing-conventions"
}
