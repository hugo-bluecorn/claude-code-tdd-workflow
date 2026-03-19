#!/bin/bash

# Test suite for Slice 9: Documentation updates for language-agnostic architecture
# Verifies CLAUDE.md, README.md, CHANGELOG.md, plugin.json, and docs/ reflect v2.0.0

CLAUDE_MD="CLAUDE.md"
README_MD="README.md"
CHANGELOG_MD="CHANGELOG.md"
PLUGIN_JSON=".claude-plugin/plugin.json"
USER_GUIDE="docs/user-guide.md"

# ---------- Test 1: CLAUDE.md Plugin Convention Skills table replaced ----------

function test_claude_md_no_dart_flutter_conventions_skill_row() {
  # The old convention skills table should not list dart-flutter-conventions as a skill row
  local skills_section
  skills_section=$(sed -n '/## Plugin Convention Skills/,/^---$/p' "$CLAUDE_MD")
  assert_not_contains "dart-flutter-conventions" "$skills_section"
}

function test_claude_md_no_cpp_testing_conventions_skill_row() {
  local skills_section
  skills_section=$(sed -n '/## Plugin Convention Skills/,/^---$/p' "$CLAUDE_MD")
  assert_not_contains "cpp-testing-conventions" "$skills_section"
}

function test_claude_md_no_bash_testing_conventions_skill_row() {
  local skills_section
  skills_section=$(sed -n '/## Plugin Convention Skills/,/^---$/p' "$CLAUDE_MD")
  assert_not_contains "bash-testing-conventions" "$skills_section"
}

function test_claude_md_no_c_conventions_skill_row() {
  local skills_section
  skills_section=$(sed -n '/## Plugin Convention Skills/,/^---$/p' "$CLAUDE_MD")
  assert_not_contains "c-conventions" "$skills_section"
}

function test_claude_md_has_project_conventions_skill_row() {
  # Must appear as a skill name in the table (backtick-quoted in first column)
  local skills_section
  skills_section=$(sed -n '/## Plugin Convention Skills/,/^---$/p' "$CLAUDE_MD")
  assert_contains '`project-conventions`' "$skills_section"
}

# ---------- Test 2: CLAUDE.md describes project-conventions behavior ----------

function test_claude_md_project_conventions_describes_dynamic_loading() {
  local skills_section
  skills_section=$(sed -n '/## Plugin Convention Skills/,/^---$/p' "$CLAUDE_MD")
  assert_matches "[Dd]ynamic" "$skills_section"
}

# ---------- Test 3: CLAUDE.md still has language-specific testing subsections ----------

function test_claude_md_has_bash_testing_subsection() {
  assert_file_contains "$CLAUDE_MD" "### Bash Testing"
}

function test_claude_md_has_cpp_testing_subsection() {
  assert_file_contains "$CLAUDE_MD" "### C++ Testing"
}

function test_claude_md_has_c_testing_subsection() {
  assert_file_contains "$CLAUDE_MD" "### C Testing"
}

# ---------- Test 4: README.md skills table lists project-conventions ----------

function test_readme_skills_table_has_project_conventions() {
  assert_file_contains "$README_MD" "project-conventions"
}

function test_readme_no_dart_flutter_conventions_skill() {
  local skills_section
  skills_section=$(sed -n '/### Skills/,/^###/p' "$README_MD")
  assert_not_contains "dart-flutter-conventions" "$skills_section"
}

function test_readme_no_cpp_testing_conventions_skill() {
  local skills_section
  skills_section=$(sed -n '/### Skills/,/^###/p' "$README_MD")
  assert_not_contains "cpp-testing-conventions" "$skills_section"
}

function test_readme_no_c_conventions_skill() {
  local skills_section
  skills_section=$(sed -n '/### Skills/,/^###/p' "$README_MD")
  assert_not_contains "c-conventions" "$skills_section"
}

function test_readme_no_bash_testing_conventions_skill() {
  local skills_section
  skills_section=$(sed -n '/### Skills/,/^###/p' "$README_MD")
  assert_not_contains "bash-testing-conventions" "$skills_section"
}

# ---------- Test 5: README.md file structure updated ----------

function test_readme_file_structure_has_project_conventions_dir() {
  local structure_section
  structure_section=$(sed -n '/## File Structure/,/^##[^#]/p' "$README_MD")
  assert_contains "project-conventions/" "$structure_section"
}

function test_readme_file_structure_no_dart_flutter_conventions_dir() {
  local structure_section
  structure_section=$(sed -n '/## File Structure/,/^##[^#]/p' "$README_MD")
  assert_not_contains "dart-flutter-conventions/" "$structure_section"
}

function test_readme_file_structure_no_cpp_testing_conventions_dir() {
  local structure_section
  structure_section=$(sed -n '/## File Structure/,/^##[^#]/p' "$README_MD")
  assert_not_contains "cpp-testing-conventions/" "$structure_section"
}

function test_readme_file_structure_no_bash_testing_conventions_dir() {
  local structure_section
  structure_section=$(sed -n '/## File Structure/,/^##[^#]/p' "$README_MD")
  assert_not_contains "bash-testing-conventions/" "$structure_section"
}

function test_readme_file_structure_no_c_conventions_dir() {
  local structure_section
  structure_section=$(sed -n '/## File Structure/,/^##[^#]/p' "$README_MD")
  assert_not_contains "c-conventions/" "$structure_section"
}

# ---------- Test 6: README.md overview reflects language-agnostic nature ----------

function test_readme_overview_no_fixed_language_list() {
  # First 10 lines should not claim a fixed set of languages
  local first_lines
  first_lines=$(head -10 "$README_MD")
  assert_not_contains "Dart/Flutter, C++, C, and Bash" "$first_lines"
}

# ---------- Test 7: CHANGELOG.md has v2.0.0 section ----------

function test_changelog_has_v2_section() {
  assert_file_contains "$CHANGELOG_MD" "## [2.0.0]"
}

function test_changelog_v2_mentions_convention_externalization() {
  local v2_section
  v2_section=$(sed -n '/## \[2.0.0\]/,/^## \[/p' "$CHANGELOG_MD")
  assert_matches "[Ee]xternali[sz]" "$v2_section"
}

# ---------- Test 8: Plugin version bumped to 2.0.0 ----------

function test_plugin_json_version_is_2_0_0() {
  local version
  version=$(grep '"version"' "$PLUGIN_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/')
  assert_equals "2.0.0" "$version"
}

# ---------- Test 9: CLAUDE.md still has pre-commit checklist entries ----------

function test_claude_md_prechecklist_has_bashunit() {
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---$/p' "$CLAUDE_MD")
  assert_contains "bashunit" "$checklist"
}

function test_claude_md_prechecklist_has_shellcheck() {
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---$/p' "$CLAUDE_MD")
  assert_contains "shellcheck" "$checklist"
}

function test_claude_md_prechecklist_has_flutter_test() {
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---$/p' "$CLAUDE_MD")
  assert_contains "flutter test" "$checklist"
}

function test_claude_md_prechecklist_has_ctest() {
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---$/p' "$CLAUDE_MD")
  assert_contains "ctest" "$checklist"
}

function test_claude_md_prechecklist_has_cppcheck() {
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---$/p' "$CLAUDE_MD")
  assert_contains "cppcheck" "$checklist"
}

function test_claude_md_prechecklist_has_clang_tidy() {
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---$/p' "$CLAUDE_MD")
  assert_contains "clang-tidy" "$checklist"
}

# ---------- Test 10: docs/user-guide.md updated ----------

function test_user_guide_no_dart_flutter_conventions_reference() {
  local content
  content=$(cat "$USER_GUIDE")
  assert_not_contains "dart-flutter-conventions" "$content"
}

function test_user_guide_no_cpp_testing_conventions_reference() {
  local content
  content=$(cat "$USER_GUIDE")
  assert_not_contains "cpp-testing-conventions" "$content"
}

function test_user_guide_no_bash_testing_conventions_reference() {
  local content
  content=$(cat "$USER_GUIDE")
  assert_not_contains "bash-testing-conventions" "$content"
}

function test_user_guide_no_c_conventions_reference() {
  local content
  content=$(cat "$USER_GUIDE")
  assert_not_contains "c-conventions" "$content"
}
