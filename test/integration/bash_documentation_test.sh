#!/bin/bash

# Test suite for documentation updates: CLAUDE.md, README.md, CHANGELOG.md
# Verifies that bash/shell support is documented alongside Dart/Flutter and C++

CLAUDE_MD="CLAUDE.md"
README_MD="README.md"
CHANGELOG_MD="CHANGELOG.md"

# ---------- Test 1: CLAUDE.md references bash-testing-conventions skill ----------

function test_claude_md_exists() {
  assert_file_exists "$CLAUDE_MD"
}

function test_claude_md_plugin_skills_table_has_bash_row() {
  # The Plugin Convention Skills table must include bash-testing-conventions
  assert_file_contains "$CLAUDE_MD" "bash-testing-conventions"
}

function test_claude_md_bash_skill_triggers_on_sh_files() {
  # The triggers column for bash skill mentions .sh files
  local table_line
  table_line=$(grep "bash-testing-conventions" "$CLAUDE_MD" | head -1)
  assert_contains ".sh" "$table_line"
}

function test_claude_md_bash_skill_references_bashunit_patterns() {
  # The reference docs column mentions bashunit-patterns
  local table_line
  table_line=$(grep "bash-testing-conventions" "$CLAUDE_MD" | head -1)
  assert_contains "bashunit-patterns" "$table_line"
}

function test_claude_md_bash_skill_references_shellcheck_guide() {
  # The reference docs column mentions shellcheck-guide
  local table_line
  table_line=$(grep "bash-testing-conventions" "$CLAUDE_MD" | head -1)
  assert_contains "shellcheck-guide" "$table_line"
}

function test_claude_md_has_bash_testing_subsection() {
  # Testing Approach section includes a Bash Testing subsection
  assert_file_contains "$CLAUDE_MD" "### Bash Testing"
}

function test_claude_md_bash_testing_mentions_bashunit() {
  # Bash Testing subsection references bashunit
  local bash_section
  bash_section=$(sed -n '/### Bash Testing/,/^###/p' "$CLAUDE_MD")
  assert_contains "bashunit" "$bash_section"
}

function test_claude_md_bash_testing_mentions_shellcheck() {
  # Bash Testing subsection references shellcheck
  local bash_section
  bash_section=$(sed -n '/### Bash Testing/,/^###/p' "$CLAUDE_MD")
  assert_contains "shellcheck" "$bash_section"
}

function test_claude_md_precommit_includes_bashunit() {
  # Pre-Commit Checklist includes bashunit
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---/p' "$CLAUDE_MD")
  assert_contains "bashunit" "$checklist"
}

function test_claude_md_precommit_includes_shellcheck() {
  # Pre-Commit Checklist includes shellcheck
  local checklist
  checklist=$(sed -n '/## Pre-Commit Checklist/,/^---/p' "$CLAUDE_MD")
  assert_contains "shellcheck" "$checklist"
}

# ---------- Test 2: README.md lists bash as a supported language ----------

function test_readme_exists() {
  assert_file_exists "$README_MD"
}

function test_readme_overview_mentions_bash() {
  # Overview/description mentions bash or shell alongside Dart/Flutter and C++
  # Check the first few lines for bash/shell reference
  local overview
  overview=$(sed -n '1,10p' "$README_MD")
  assert_matches "bash|Bash|shell|Shell" "$overview"
}

function test_readme_skills_table_has_bash() {
  # Skills table includes bash-testing-conventions
  assert_file_contains "$README_MD" "bash-testing-conventions"
}

function test_readme_file_structure_has_bash_conventions_dir() {
  # File Structure section shows bash-testing-conventions/ directory
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  assert_contains "bash-testing-conventions" "$file_structure"
}

function test_readme_hooks_mentions_sh_support() {
  # Hooks section mentions .sh file support
  local hooks_section
  hooks_section=$(sed -n '/### Hooks/,/^##/p' "$README_MD")
  assert_matches "\.sh" "$hooks_section"
}

function test_readme_has_bashunit_install_instructions() {
  # Installation instructions for bashunit
  assert_file_contains "$README_MD" "bashunit.typeddevs.com/install.sh"
}

function test_readme_has_shellcheck_install_apt() {
  # Installation instructions for shellcheck via apt
  assert_file_contains "$README_MD" "apt install shellcheck"
}

function test_readme_has_shellcheck_install_brew() {
  # Installation instructions for shellcheck via brew
  assert_file_contains "$README_MD" "brew install shellcheck"
}

function test_readme_has_permissions_note() {
  # Note about settings.local.json permissions for shellcheck and bashunit
  assert_file_contains "$README_MD" "settings.local.json"
}

function test_readme_permissions_mentions_shellcheck() {
  # Permissions note mentions shellcheck
  local perms_section
  perms_section=$(grep -A10 "settings.local.json" "$README_MD")
  assert_matches "shellcheck|Bash.shellcheck" "$perms_section"
}

function test_readme_permissions_mentions_bashunit() {
  # Permissions note mentions bashunit
  local perms_section
  perms_section=$(grep -A10 "settings.local.json" "$README_MD")
  assert_matches "bashunit|Bash.bashunit" "$perms_section"
}

# ---------- Test 3: CHANGELOG.md updated with bash support ----------

function test_changelog_exists() {
  assert_file_exists "$CHANGELOG_MD"
}

function test_changelog_has_bash_version_section() {
  # Bash support was released in v1.2.0 (originally [Unreleased], now versioned)
  assert_file_contains "$CHANGELOG_MD" "[1.2.0]"
}

function test_changelog_has_bash_testing_conventions_entry() {
  # Entry for bash-testing-conventions skill in v1.2.0
  local section
  section=$(sed -n '/## \[1.2.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "bash-testing-conventions" "$section"
}

function test_changelog_has_validate_tdd_order_bash_entry() {
  # Entry for validate-tdd-order.sh bash support in v1.2.0
  local section
  section=$(sed -n '/## \[1.2.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "validate-tdd-order" "$section"
}

function test_changelog_has_auto_run_tests_bashunit_entry() {
  # Entry for auto-run-tests.sh bashunit integration in v1.2.0
  local section
  section=$(sed -n '/## \[1.2.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "auto-run-tests" "$section"
}

function test_changelog_has_verifier_bash_entry() {
  # Entry for verifier bash/shellcheck support in v1.2.0
  local section
  section=$(sed -n '/## \[1.2.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_matches "[Vv]erifier.*bash|[Vv]erifier.*shellcheck|bash.*[Vv]erifier|shellcheck.*[Vv]erifier" "$section"
}

function test_changelog_has_permissions_entry() {
  # Entry for shellcheck/bashunit permission requirements in v1.2.0
  local section
  section=$(sed -n '/## \[1.2.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_matches "permission|Permission" "$section"
}

# ---------- Edge Cases: Additive-only documentation ----------

function test_claude_md_still_has_dart_flutter_skill() {
  # Existing dart-flutter-conventions skill must still be present
  assert_file_contains "$CLAUDE_MD" "dart-flutter-conventions"
}

function test_claude_md_still_has_cpp_skill() {
  # Existing cpp-testing-conventions skill must still be present
  assert_file_contains "$CLAUDE_MD" "cpp-testing-conventions"
}

function test_claude_md_still_has_dart_testing_content() {
  # Testing Approach still has Dart test content
  assert_file_contains "$CLAUDE_MD" "package:test"
}

function test_claude_md_still_has_cpp_testing_content() {
  # C++ Testing section still present
  assert_file_contains "$CLAUDE_MD" "### C++ Testing"
}

function test_readme_still_mentions_dart_flutter() {
  # README still references Dart/Flutter
  assert_file_contains "$README_MD" "Dart/Flutter"
}

function test_readme_still_mentions_cpp() {
  # README still references C++
  assert_file_contains "$README_MD" "C++"
}

function test_readme_still_has_dart_conventions_in_skills() {
  assert_file_contains "$README_MD" "dart-flutter-conventions"
}

function test_readme_still_has_cpp_conventions_in_skills() {
  assert_file_contains "$README_MD" "cpp-testing-conventions"
}

function test_changelog_still_has_initial_release() {
  # The 1.0.0 initial release section must still be present
  assert_file_contains "$CHANGELOG_MD" "[1.0.0]"
}
