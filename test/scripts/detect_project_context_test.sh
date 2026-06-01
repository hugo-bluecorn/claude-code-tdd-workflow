#!/bin/bash

# Tests for detect-project-context.sh.
#
# C6 (R1 Wave 1): test_runner + test_count are now PACK-DRIVEN.
#   - test_runner derives from the active pack's commands.test.run (via the C0
#     active-pack.sh resolve chain), with a command -v built-in fallback when no
#     pack is bound (env unset).
#   - test_count data-drives its glob from the active pack's testFilePattern /
#     extensions PLUS the .sh built-in, falling back to the built-in
#     *_test.{dart,cpp,sh,c} glob when no pack is bound.
#
# The script is invoked cwd'd into the project (the SKILL.md `!` backtick
# contract), so resolution is against $PWD. Synthetic fixtures only.

SCRIPT="$(pwd)/scripts/detect-project-context.sh"
FIXTURES="$(pwd)/test/fixtures"
DART_FIXTURE="${FIXTURES}/dart-fixture"
CPP_FIXTURE="${FIXTURES}/cpp-fixture"

# Helper: create a temp directory for isolated testing
create_tmp_dir() {
  local dir
  dir=$(mktemp -d)
  TMP_PROJECTS+=("$dir")
  echo "$dir"
}

# Helper: run detect-project-context.sh in a given directory (suppress stderr)
run_detect_in_dir() {
  local dir="$1"
  (cd "$dir" && bash "$SCRIPT" 2>/dev/null)
}

# Write a dev-pack binding into <project-dir>/.claude/tdd-conventions.json for
# the given pack source path(s). Each path is bound as a local dev pack.
write_dev_binding() {
  local proj="$1"
  shift
  local packs="" src
  mkdir -p "$proj/.claude"
  for src in "$@"; do
    [ -n "$packs" ] && packs="${packs},"
    packs="${packs}{\"source\":\"${src}\",\"dev\":true}"
  done
  printf '{"packs":[%s]}\n' "$packs" >"$proj/.claude/tdd-conventions.json"
}

function set_up() {
  TMP_PROJECTS=()
  unset TDD_ACTIVE_PACK
}

function tear_down() {
  local dir
  for dir in "${TMP_PROJECTS[@]:-}"; do
    [ -n "$dir" ] && rm -rf "$dir"
  done
  unset TDD_ACTIVE_PACK
}

# ---------- Test 1: test_runner derived from the active pack (net-new) ----------

function test_test_runner_derived_from_active_pack() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)
  : >"$tmp_dir/pubspec.yaml"
  write_dev_binding "$tmp_dir" "$DART_FIXTURE"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  # The dart fixture's commands.test.run is "flutter test {file}" -> the runner
  # reflects the pack, not a hardcoded command -v result.
  assert_contains "test_runner=flutter test" "$output"
}

# ---------- Test 1b: test_runner reflects a pack the command -v ladder never emits ----------

function test_test_runner_reflects_pack_not_command_ladder() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)
  # cpp pack via the env fast-path; commands.test.run is "ctest ..." -- a runner
  # the hardcoded flutter/dart command -v ladder could NEVER produce. This proves
  # the runner is pack-derived, not a coincidental command -v hit.
  export TDD_ACTIVE_PACK="$CPP_FIXTURE"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "test_runner=ctest" "$output"
  assert_not_contains "test_runner=flutter test" "$output"
}

# ---------- Test 2: test_count data-driven from pack extensions (mixed) ----------

function test_test_count_data_driven_from_pack_extensions() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)
  : >"$tmp_dir/pubspec.yaml"
  write_dev_binding "$tmp_dir" "$DART_FIXTURE"

  mkdir -p "$tmp_dir/test"
  touch "$tmp_dir/test/widget_test.dart"
  touch "$tmp_dir/test/model_test.dart"
  touch "$tmp_dir/test/hook_test.sh"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  # Pack pattern (*_test.dart) + the .sh built-in -> 2 dart + 1 sh = 3.
  assert_contains "test_count=3" "$output"
}

# ---------- Test 2b: pack pattern excludes non-pack extensions ----------

function test_test_count_pack_pattern_excludes_unrelated_extensions() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)
  : >"$tmp_dir/pubspec.yaml"
  write_dev_binding "$tmp_dir" "$DART_FIXTURE"

  mkdir -p "$tmp_dir/test"
  touch "$tmp_dir/test/widget_test.dart"
  touch "$tmp_dir/test/algo_test.cpp"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  # dart pack pattern + .sh built-in only; the .cpp file is NOT counted.
  assert_contains "test_count=1" "$output"
}

# ---------- Test 3: test_count with no test files reports zero (KEEP) ----------

function test_counts_zero_when_no_test_files() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Create a non-test file to make sure it's not counted
  touch "$tmp_dir/main.c"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "test_count=0" "$output"
}

# ---------- Test 4 (edge): no pack bound falls back to a sane built-in ----------

function test_no_pack_falls_back_to_builtin() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  mkdir -p "$tmp_dir/test"
  touch "$tmp_dir/test/hook_test.sh"
  touch "$tmp_dir/test/util_test.sh"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  # No binding, env unset: built-in glob still counts the .sh files...
  assert_contains "test_count=2" "$output"
  # ...and a test_runner line is still emitted (never crashes pack-less).
  assert_contains "test_runner=" "$output"
}

# ---------- Test 4b (edge): built-in glob still counts mixed types pack-less ----------

function test_no_pack_builtin_glob_counts_mixed_types() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  mkdir -p "$tmp_dir/test"
  touch "$tmp_dir/test/widget_test.dart"
  touch "$tmp_dir/test/algo_test.cpp"
  touch "$tmp_dir/test/hook_test.sh"
  touch "$tmp_dir/test/unit_test.c"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  # Built-in fallback glob *_test.{dart,cpp,sh,c} counts all four.
  assert_contains "test_count=4" "$output"
}

# ---------- Test 5: Script passes shellcheck (KEEP) ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}

# ---------- Test 6: references no role file (PRIME-safe) ----------

function test_references_no_role_file() {
  assert_not_contains "role-" "$(cat "$SCRIPT")"
  assert_not_contains "role_" "$(cat "$SCRIPT")"
}
