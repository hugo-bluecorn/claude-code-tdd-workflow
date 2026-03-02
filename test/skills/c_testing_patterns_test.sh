#!/bin/bash

# Test suite for c-testing-patterns.md reference document content

DOC="skills/c-conventions/reference/c-testing-patterns.md"

# ---------- Test 1: Document covers Unity test framework ----------

function test_doc_contains_unity_framework() {
  assert_file_contains "$DOC" "Unity"
}

function test_doc_contains_test_assert_macro() {
  assert_file_contains "$DOC" "TEST_ASSERT"
}

function test_doc_contains_setUp() {
  assert_file_contains "$DOC" "setUp"
}

function test_doc_contains_tearDown() {
  assert_file_contains "$DOC" "tearDown"
}

# ---------- Test 2: Document covers CMock for C function mocking ----------

function test_doc_contains_cmock() {
  assert_file_contains "$DOC" "CMock"
}

function test_doc_references_mocking_c_functions() {
  local content
  content=$(cat "$DOC")
  assert_contains "mock" "$content"
}

# ---------- Test 3: Document covers assert.h patterns ----------

function test_doc_contains_assert_h() {
  assert_file_contains "$DOC" "assert.h"
}

# ---------- Test 4: Document acknowledges GoogleTest interop ----------

function test_doc_contains_googletest() {
  assert_file_contains "$DOC" "GoogleTest"
}

function test_doc_contains_extern_c_pattern() {
  local content
  content=$(cat "$DOC")
  assert_contains 'extern "C"' "$content"
}

# ---------- Test 5: Document covers test file naming conventions ----------

function test_doc_contains_test_c_naming_pattern() {
  assert_file_contains "$DOC" "_test.c"
}

# ---------- Test 6: Document covers build-then-test sequence ----------

function test_doc_covers_cmake_configure_step() {
  assert_file_contains "$DOC" "cmake"
}

function test_doc_covers_build_step() {
  local content
  content=$(cat "$DOC")
  assert_contains "build" "$content"
}

function test_doc_covers_ctest_or_test_step() {
  assert_file_contains "$DOC" "ctest"
}

# ---------- Test 7: Document covers bootstrapping Unity with FetchContent ----------

function test_doc_contains_fetchcontent() {
  assert_file_contains "$DOC" "FetchContent"
}

# ---------- Test 8: Document does not contain Dart-specific content ----------

function test_doc_does_not_contain_dart_lowercase() {
  assert_file_not_contains "$DOC" "dart"
}

function test_doc_does_not_contain_dart_capitalized() {
  assert_file_not_contains "$DOC" "Dart"
}

function test_doc_does_not_contain_flutter_capitalized() {
  assert_file_not_contains "$DOC" "Flutter"
}

function test_doc_does_not_contain_flutter_lowercase() {
  assert_file_not_contains "$DOC" "flutter"
}

# ---------- Test 9: Document does not contain unfilled template placeholders ----------

function test_doc_does_not_contain_unfilled_template_placeholders() {
  # Check for template placeholders like {your_value} while allowing
  # C syntax: () {, = {, brace-enclosed blocks, and code fences
  # Strategy: strip fenced code blocks, then check remaining lines for {
  local content
  content=$(cat "$DOC")

  # Remove fenced code blocks (everything between ``` markers)
  local stripped
  stripped=$(echo "$content" | sed '/^```/,/^```/d')

  # Count { outside of C function syntax patterns
  # Allow: () {, = {, struct/enum/union {, and standalone { on its own line
  local count
  count=$(echo "$stripped" | grep -v '() {' | grep -v '= {' | grep -c '{' || true)
  assert_equals "0" "$count"
}

# ---------- Test 10: Document has code examples ----------

function test_doc_has_at_least_four_code_block_markers() {
  local content
  content=$(cat "$DOC")
  local code_block_count
  code_block_count=$(echo "$content" | grep -c '```')
  # At least 4 code block markers (2+ complete examples)
  assert_greater_or_equal_than 4 "$code_block_count"
}
