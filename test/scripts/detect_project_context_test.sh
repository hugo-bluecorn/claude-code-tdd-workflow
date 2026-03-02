#!/bin/bash

# Tests for detect-project-context.sh: C test file counting
# Verifies that *_test.c files are counted alongside existing test patterns.

SCRIPT="$(pwd)/scripts/detect-project-context.sh"

# Helper: create a temp directory for isolated testing
create_tmp_dir() {
  mktemp -d
}

# Helper: run detect-project-context.sh in a given directory (suppress stderr)
run_detect_in_dir() {
  local dir="$1"
  (cd "$dir" && bash "$SCRIPT" 2>/dev/null)
}

# ---------- Test 1: Script counts *_test.c files in test_count output ----------

function test_counts_c_test_files() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  mkdir -p "$tmp_dir/test"
  touch "$tmp_dir/test/unit_test.c"
  touch "$tmp_dir/test/integration_test.c"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "test_count=2" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: Script counts mixed C and other test file types together ----------

function test_counts_mixed_c_and_other_test_files() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  mkdir -p "$tmp_dir/test"
  touch "$tmp_dir/test/unit_test.c"
  touch "$tmp_dir/test/widget_test.dart"
  touch "$tmp_dir/test/hook_test.sh"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "test_count=3" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Script still counts existing patterns (dart, cpp, sh) ----------

function test_counts_existing_patterns_without_c_files() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  mkdir -p "$tmp_dir/test"
  touch "$tmp_dir/test/widget_test.dart"
  touch "$tmp_dir/test/algo_test.cpp"
  touch "$tmp_dir/test/hook_test.sh"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "test_count=3" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 4: Script counts zero when no test files exist ----------

function test_counts_zero_when_no_test_files() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Create a non-test file to make sure it's not counted
  touch "$tmp_dir/main.c"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "test_count=0" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 5: Script passes shellcheck ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}
