#!/bin/bash

# Test suite for shellcheck-guide.md reference document content

DOC="skills/bash-testing-conventions/reference/shellcheck-guide.md"

# ---------- Test 1: Covers basic usage ----------

function test_doc_contains_basic_shellcheck_invocation() {
  assert_file_contains "$DOC" "shellcheck script.sh"
}

function test_doc_contains_checking_multiple_files() {
  assert_file_contains "$DOC" "shellcheck *.sh"
}

function test_doc_contains_severity_level_error() {
  assert_file_contains "$DOC" "error"
}

function test_doc_contains_severity_level_warning() {
  assert_file_contains "$DOC" "warning"
}

function test_doc_contains_severity_level_info() {
  assert_file_contains "$DOC" "info"
}

function test_doc_contains_severity_level_style() {
  assert_file_contains "$DOC" "style"
}

function test_doc_contains_sc2086_unquoted_variables() {
  assert_file_contains "$DOC" "SC2086"
}

function test_doc_contains_sc2046_unquoted_command_substitution() {
  assert_file_contains "$DOC" "SC2046"
}

function test_doc_contains_sc2034_unused_variables() {
  assert_file_contains "$DOC" "SC2034"
}

# ---------- Test 2: Covers directive usage ----------

function test_doc_contains_disable_directive() {
  # Must document the shellcheck disable directive syntax
  local content
  content=$(cat "$DOC")
  assert_contains "# shellcheck disable=" "$content"
}

function test_doc_contains_source_directive() {
  local content
  content=$(cat "$DOC")
  assert_contains "# shellcheck source=" "$content"
}

function test_doc_contains_shell_directive() {
  local content
  content=$(cat "$DOC")
  assert_contains "# shellcheck shell=bash" "$content"
}

function test_doc_contains_guidance_on_suppression_appropriateness() {
  # Must discuss when it is appropriate vs inappropriate to suppress
  local content
  content=$(cat "$DOC")
  assert_contains "appropriate" "$content"
}

# ---------- Test 3: Covers integration with TDD workflow ----------

function test_doc_contains_static_analysis_command() {
  local content
  content=$(cat "$DOC")
  assert_contains "shellcheck -S warning" "$content"
}

function test_doc_explains_role_equivalence_with_other_analyzers() {
  # Must mention that shellcheck serves the same role as dart analyze or clang-tidy
  # (but not by naming those tools directly -- the comparison is abstract)
  local content
  content=$(cat "$DOC")
  assert_contains "dart analyze" "$content"
}

function test_doc_contains_references_section() {
  assert_file_contains "$DOC" "## References"
}

function test_doc_contains_shellcheck_wiki_link() {
  assert_file_contains "$DOC" "https://github.com/koalaman/shellcheck/wiki"
}

# ---------- Edge Cases: Content isolation ----------

function test_doc_does_not_reference_dart_tools() {
  # The doc should not name Dart/Flutter tools outside the comparison context
  # Check that "flutter" and "Flutter" do not appear
  assert_file_not_contains "$DOC" "Flutter"
  assert_file_not_contains "$DOC" "flutter"
}

function test_doc_does_not_reference_cpp_tools() {
  assert_file_not_contains "$DOC" "C++"
  assert_file_not_contains "$DOC" "gtest"
  assert_file_not_contains "$DOC" "EXPECT_"
}

function test_doc_does_not_contain_unfilled_template_placeholders() {
  assert_file_not_contains "$DOC" "{"
}
