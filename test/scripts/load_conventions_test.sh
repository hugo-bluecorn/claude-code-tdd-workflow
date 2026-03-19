#!/bin/bash

# Tests for scripts/load-conventions.sh: project type detection and convention loading
# Validates against real convention content from hugo-bluecorn/tdd-workflow-conventions

SCRIPT="$(pwd)/scripts/load-conventions.sh"

# Shared clone of the conventions repo (cloned once in setup, cleaned in teardown)
CONVENTIONS_CLONE=""

# ---------- Helpers ----------

create_tmp_dir() {
  mktemp -d
}

# Clone the conventions repo once for the test suite
setup_conventions_cache() {
  local cache_dir
  cache_dir=$(create_tmp_dir)
  git clone --depth 1 --quiet \
    https://github.com/hugo-bluecorn/tdd-workflow-conventions.git \
    "$cache_dir/conventions/tdd-workflow-conventions" 2>/dev/null
  echo "$cache_dir"
}

# Run load-conventions.sh in a given directory with a conventions cache
run_load_in_dir() {
  local dir="$1"
  local plugin_data="$2"
  (cd "$dir" && CLAUDE_PLUGIN_DATA="$plugin_data" bash "$SCRIPT" 2>/dev/null)
}

# ---------- Suite setup / teardown ----------

function set_up() {
  if [ -z "$CONVENTIONS_CLONE" ]; then
    CONVENTIONS_CLONE=$(setup_conventions_cache)
  fi
}

# ---------- Test 1: Script exists and is executable ----------

function test_script_exists_and_is_executable() {
  assert_file_exists "$SCRIPT"

  test -x "$SCRIPT"
  assert_exit_code 0
}

# ---------- Test 2: Detects Dart/Flutter project ----------

function test_detects_dart_flutter_project() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/pubspec.yaml"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$CONVENTIONS_CLONE")

  # Should contain Dart SKILL.md content
  assert_contains "dart-flutter-conventions" "$output"
  # Should contain reference content (Riverpod is in riverpod-guide.md)
  assert_contains "Riverpod" "$output"
  # Should contain widget testing content
  assert_contains "pumpWidget" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Detects C++ project ----------

function test_detects_cpp_project() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/CMakeLists.txt"
  mkdir -p "$tmp_dir/src"
  touch "$tmp_dir/src/main.cpp"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$CONVENTIONS_CLONE")

  # Should contain C++ SKILL.md content
  assert_contains "cpp-testing-conventions" "$output"
  # Should contain GoogleTest reference content
  assert_contains "GoogleTest" "$output"
  # Should contain GoogleMock content
  assert_contains "MOCK_METHOD" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 4: Detects Bash project ----------

function test_detects_bash_project() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/my_test.sh"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$CONVENTIONS_CLONE")

  # Should contain Bash SKILL.md content
  assert_contains "bash-testing-conventions" "$output"
  # Should contain bashunit assertion patterns
  assert_contains "assert_equals" "$output"
  # Should contain shellcheck guidance
  assert_contains "shellcheck" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 4b: Detects Bash project via .bashunit.yml ----------

function test_detects_bash_project_via_bashunit_yml() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/.bashunit.yml"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$CONVENTIONS_CLONE")

  assert_contains "bash-testing-conventions" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 5: Detects C project ----------

function test_detects_c_project() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/main.c"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$CONVENTIONS_CLONE")

  # Should contain C SKILL.md content
  assert_contains "c-conventions" "$output"
  # Should contain Unity test macro content
  assert_contains "Unity" "$output"
  # Should contain BARR-C coding standards
  assert_contains "BARR-C" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 5b: C not detected when .cpp files also exist ----------

function test_c_not_detected_alone_when_cpp_present() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/main.c"
  touch "$tmp_dir/main.cpp"
  touch "$tmp_dir/CMakeLists.txt"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$CONVENTIONS_CLONE")

  # Both C and C++ should be loaded when both are present
  assert_contains "c-conventions" "$output"
  assert_contains "cpp-testing-conventions" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 6: Multi-language project loads all relevant conventions ----------

function test_multi_language_project_loads_all() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/pubspec.yaml"
  touch "$tmp_dir/util.c"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$CONVENTIONS_CLONE")

  # Should contain both Dart and C content
  assert_contains "dart-flutter-conventions" "$output"
  assert_contains "c-conventions" "$output"
  assert_contains "Riverpod" "$output"
  assert_contains "Unity" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 7: No matching project type outputs nothing ----------

function test_no_matching_type_outputs_nothing() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/main.rs"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$CONVENTIONS_CLONE")
  local rc=$?

  assert_empty "$output"
  assert_equals 0 "$rc"

  rm -rf "$tmp_dir"
}

# ---------- Test 8: Empty cache directory outputs nothing ----------

function test_empty_cache_outputs_nothing() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)
  touch "$tmp_dir/pubspec.yaml"

  local empty_cache
  empty_cache=$(create_tmp_dir)
  mkdir -p "$empty_cache/conventions"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$empty_cache")
  local rc=$?

  assert_empty "$output"
  assert_equals 0 "$rc"

  rm -rf "$tmp_dir" "$empty_cache"
}

# ---------- Test 9: Missing CLAUDE_PLUGIN_DATA env var handled gracefully ----------

function test_missing_plugin_data_env_var() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)
  touch "$tmp_dir/pubspec.yaml"

  local output
  output=$(cd "$tmp_dir" && unset CLAUDE_PLUGIN_DATA && bash "$SCRIPT" 2>/dev/null)
  local rc=$?

  assert_empty "$output"
  assert_equals 0 "$rc"

  rm -rf "$tmp_dir"
}

# ---------- Test 10: Script passes shellcheck ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}

# ---------- Cleanup ----------

function tear_down() {
  # Convention clone cleaned up at end if set
  :
}

function tear_down_after_script() {
  if [ -n "$CONVENTIONS_CLONE" ] && [ -d "$CONVENTIONS_CLONE" ]; then
    rm -rf "$CONVENTIONS_CLONE"
  fi
}
