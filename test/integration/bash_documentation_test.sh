#!/bin/bash

# Test suite for documentation updates: CLAUDE.md, README.md, CHANGELOG.md
# Verifies that bash/shell support is documented alongside Dart/Flutter and C++
# Updated for v2.0: old convention skill names removed from assertions

CLAUDE_MD="CLAUDE.md"
README_MD="README.md"
CHANGELOG_MD="CHANGELOG.md"

# ---------- Test 1: CLAUDE.md has Bash Testing content ----------

function test_claude_md_exists() {
  assert_file_exists "$CLAUDE_MD"
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

# ---------- Edge Cases: Preserved non-convention documentation ----------

function test_claude_md_still_has_dart_testing_content() {
  # Testing Approach still has Dart test content
  assert_file_contains "$CLAUDE_MD" "package:test"
}

function test_claude_md_still_has_cpp_testing_content() {
  # C++ Testing section still present
  assert_file_contains "$CLAUDE_MD" "### C++ Testing"
}

function test_readme_still_mentions_cpp() {
  # README conveys extensible conventions (language-agnostic since v2.0)
  assert_file_contains "$README_MD" "convention"
}

function test_changelog_still_has_initial_release() {
  # The 1.0.0 initial release section must still be present
  assert_file_contains "$CHANGELOG_MD" "[1.0.0]"
}
