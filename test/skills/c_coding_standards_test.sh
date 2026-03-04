#!/bin/bash

# Test suite for c-coding-standards.md reference document content

DOC="skills/c-conventions/reference/c-coding-standards.md"

# ---------- Test 1: Document covers BARR-C:2018 key rules ----------

function test_doc_contains_barr_c() {
  assert_file_contains "$DOC" "BARR-C"
}

function test_doc_covers_snake_case_naming() {
  assert_file_contains "$DOC" "snake_case"
}

function test_doc_covers_formatting_rules() {
  local content
  content=$(cat "$DOC")
  assert_contains "brace" "$content"
}

function test_doc_covers_function_rules() {
  local content
  content=$(cat "$DOC")
  assert_contains "function" "$content"
}

# ---------- Test 2: Document covers SEI CERT C priority rules ----------

function test_doc_contains_sei_cert_c() {
  assert_file_contains "$DOC" "SEI CERT C"
}

function test_doc_covers_mem_category() {
  assert_file_contains "$DOC" "MEM"
}

function test_doc_covers_int_category() {
  assert_file_contains "$DOC" "INT"
}

function test_doc_covers_str_category() {
  assert_file_contains "$DOC" "STR"
}

function test_doc_covers_arr_category() {
  assert_file_contains "$DOC" "ARR"
}

# ---------- Test 3: Document maps rules to clang-tidy checks ----------

function test_doc_contains_clang_tidy() {
  assert_file_contains "$DOC" "clang-tidy"
}

function test_doc_contains_cert_check_prefix() {
  assert_file_contains "$DOC" "cert-"
}

function test_doc_contains_specific_cert_check() {
  # At least one specific cert check should be referenced
  assert_file_contains "$DOC" "cert-err33-c"
}

# ---------- Test 4: Document covers fixed-width integers via stdint.h ----------

function test_doc_contains_stdint_h() {
  assert_file_contains "$DOC" "stdint.h"
}

function test_doc_contains_fixed_width_integer_type() {
  # At least one fixed-width type like uint8_t, int32_t, uint64_t
  local content
  content=$(cat "$DOC")
  assert_matches "(uint8_t|int32_t|uint64_t)" "$content"
}

# ---------- Test 5: Document covers BARR-C naming conventions ----------

function test_doc_contains_global_prefix() {
  assert_file_contains "$DOC" "g_"
}

function test_doc_contains_pointer_prefix() {
  assert_file_contains "$DOC" "p_"
}

function test_doc_covers_snake_case_for_functions_and_variables() {
  local content
  content=$(cat "$DOC")
  assert_contains "snake_case" "$content"
  assert_contains "variable" "$content"
}

# ---------- Test 6: Document does not contain C++-specific content ----------

function test_doc_does_not_contain_expect_macro() {
  assert_file_not_contains "$DOC" "EXPECT_"
}

function test_doc_does_not_contain_gtest() {
  assert_file_not_contains "$DOC" "gtest"
}

function test_doc_does_not_contain_mock_method() {
  assert_file_not_contains "$DOC" "MOCK_METHOD"
}

function test_doc_does_not_contain_namespace() {
  assert_file_not_contains "$DOC" "namespace"
}

# ---------- Test 7: Document does not contain unfilled template placeholders ----------

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
  local count
  count=$(echo "$stripped" | grep -v '() {' | grep -v '= {' | grep -c '{' || true)
  assert_equals "0" "$count"
}

# ---------- Bonus: Document has code examples ----------

function test_doc_has_code_examples() {
  local content
  content=$(cat "$DOC")
  local code_block_count
  code_block_count=$(echo "$content" | grep -c '```')
  # At least 4 code block markers (2+ complete examples)
  assert_greater_or_equal_than 4 "$code_block_count"
}
