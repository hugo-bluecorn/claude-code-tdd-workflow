#!/bin/bash

# Test suite for bashunit-patterns.md reference document content

DOC="skills/bash-testing-conventions/reference/bashunit-patterns.md"

# ---------- Test 1: Contains test structure documentation ----------

function test_doc_contains_test_prefix_naming_convention() {
  assert_file_contains "$DOC" "test_"
}

function test_doc_contains_assert_equals_documentation() {
  assert_file_contains "$DOC" "assert_equals"
}

function test_doc_contains_assert_contains_documentation() {
  assert_file_contains "$DOC" "assert_contains"
}

function test_doc_contains_assert_exit_code_documentation() {
  assert_file_contains "$DOC" "assert_exit_code"
}

function test_doc_contains_assert_status_code_documentation() {
  # assert_successful_code / assert_unsuccessful_code are the status-related assertions
  assert_file_contains "$DOC" "assert_successful_code"
}

function test_doc_contains_test_file_naming_convention() {
  # Must document that test files end with _test.sh
  assert_file_contains "$DOC" "_test.sh"
}

function test_doc_contains_file_organization_section() {
  assert_file_contains "$DOC" "## File Organization"
}

function test_doc_contains_directory_structure_example() {
  # Should show a directory tree with test/ directory
  assert_file_contains "$DOC" "test/"
}

# ---------- Test 2: Contains setup/teardown patterns ----------

function test_doc_contains_set_up_function() {
  assert_file_contains "$DOC" "set_up"
}

function test_doc_contains_tear_down_function() {
  assert_file_contains "$DOC" "tear_down"
}

function test_doc_contains_set_up_before_script_function() {
  assert_file_contains "$DOC" "set_up_before_script"
}

function test_doc_contains_tear_down_after_script_function() {
  assert_file_contains "$DOC" "tear_down_after_script"
}

function test_doc_contains_code_examples_for_setup_teardown() {
  # Must have fenced code blocks showing examples
  local content
  content=$(cat "$DOC")
  local code_block_count
  code_block_count=$(echo "$content" | grep -c '```')
  # At least 4 code blocks (opening + closing pairs for multiple examples)
  assert_greater_or_equal_than 4 "$code_block_count"
}

# ---------- Test 3: Contains running tests section ----------

function test_doc_contains_run_single_test_file_command() {
  assert_file_contains "$DOC" "bashunit test/path_test.sh"
}

function test_doc_contains_run_all_tests_command() {
  assert_file_contains "$DOC" "bashunit test/"
}

function test_doc_contains_run_specific_test_by_name() {
  # Should document the --filter flag for running specific tests
  # Note: assert_file_contains passes the search string to grep which
  # interprets leading dashes as options; read content and use assert_contains.
  local content
  content=$(cat "$DOC")
  assert_contains "--filter" "$content"
}

function test_doc_contains_bash_naming_reference_section() {
  assert_file_contains "$DOC" "## Bash Naming Reference"
}

function test_doc_contains_snake_case_convention() {
  assert_file_contains "$DOC" "snake_case"
}

function test_doc_contains_snake_case_for_functions() {
  # Should reference snake_case for functions
  local content
  content=$(cat "$DOC")
  assert_contains "function" "$content"
  assert_contains "snake_case" "$content"
}

function test_doc_contains_snake_case_for_variables() {
  # Should reference snake_case for variables
  local content
  content=$(cat "$DOC")
  assert_contains "variable" "$content"
}

# ---------- Edge Cases: Structural parity ----------

function test_doc_has_similar_section_depth_as_googletest() {
  local googletest_doc="skills/cpp-testing-conventions/reference/googletest-patterns.md"
  local bash_section_count
  local googletest_section_count

  bash_section_count=$(grep -c "^## " "$DOC")
  googletest_section_count=$(grep -c "^## " "$googletest_doc")

  # bashunit-patterns.md should have at least as many sections as googletest-patterns.md
  assert_greater_or_equal_than "$googletest_section_count" "$bash_section_count"
}

function test_doc_does_not_contain_dart_content() {
  assert_file_not_contains "$DOC" "dart"
  assert_file_not_contains "$DOC" "Dart"
  assert_file_not_contains "$DOC" "Flutter"
}

function test_doc_does_not_contain_cpp_content() {
  assert_file_not_contains "$DOC" "cpp"
  assert_file_not_contains "$DOC" "C++"
  assert_file_not_contains "$DOC" "gtest"
  assert_file_not_contains "$DOC" "EXPECT_"
}
