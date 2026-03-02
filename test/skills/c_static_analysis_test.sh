#!/bin/bash

# Test suite for c-static-analysis.md reference document content

DOC="skills/c-conventions/reference/c-static-analysis.md"

# ---------- Test 1: Document covers compiler warning flags ----------
# Note: assert_file_contains uses grep -F which treats leading hyphens
# as options. Use assert_contains with file content for hyphen-prefixed strings.

function test_doc_contains_wall() {
  local content
  content=$(cat "$DOC")
  assert_contains "-Wall" "$content"
}

function test_doc_contains_wextra() {
  local content
  content=$(cat "$DOC")
  assert_contains "-Wextra" "$content"
}

function test_doc_contains_werror() {
  local content
  content=$(cat "$DOC")
  assert_contains "-Werror" "$content"
}

function test_doc_contains_pedantic() {
  local content
  content=$(cat "$DOC")
  assert_contains "-pedantic" "$content"
}

# ---------- Test 2: Document covers cppcheck ----------

function test_doc_contains_cppcheck() {
  assert_file_contains "$DOC" "cppcheck"
}

function test_doc_contains_cppcheck_usage_guidance() {
  local content
  content=$(cat "$DOC")
  # Should have guidance on running cppcheck, not just mention it
  assert_contains "cppcheck" "$content"
  assert_contains "--enable" "$content"
}

# ---------- Test 3: Document covers clang-tidy with cert and bugprone checks ----------

function test_doc_contains_clang_tidy() {
  assert_file_contains "$DOC" "clang-tidy"
}

function test_doc_contains_cert_checks() {
  assert_file_contains "$DOC" "cert-"
}

function test_doc_contains_bugprone_checks() {
  assert_file_contains "$DOC" "bugprone-"
}

# ---------- Test 4: Document covers compile_commands.json generation ----------

function test_doc_contains_compile_commands_json() {
  assert_file_contains "$DOC" "compile_commands.json"
}

function test_doc_contains_cmake_export_compile_commands() {
  assert_file_contains "$DOC" "CMAKE_EXPORT_COMPILE_COMMANDS"
}

# ---------- Test 5: Document covers gcc -fanalyzer ----------

function test_doc_contains_fanalyzer() {
  local content
  content=$(cat "$DOC")
  assert_contains "-fanalyzer" "$content"
}

function test_doc_references_gcc_12() {
  local content
  content=$(cat "$DOC")
  assert_contains "GCC 12" "$content"
}

# ---------- Test 6: Document covers integration with TDD verification phase ----------

function test_doc_references_verification_or_static_analysis_role() {
  local content
  content=$(cat "$DOC")
  # Should reference static analysis as equivalent to dart analyze or shellcheck
  # in the TDD workflow verification phase
  assert_matches "(dart analyze|shellcheck|[Vv]erif)" "$content"
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

# ---------- Test 8: Document has code examples ----------

function test_doc_has_at_least_four_code_block_markers() {
  local content
  content=$(cat "$DOC")
  local code_block_count
  code_block_count=$(echo "$content" | grep -c '```')
  # At least 4 code block markers (2+ complete examples)
  assert_greater_or_equal_than 4 "$code_block_count"
}
