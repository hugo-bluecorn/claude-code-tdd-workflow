#!/bin/bash

# Test suite for validate-tdd-order.sh hook — .sh file recognition
# Tests that the hook correctly handles bash test and source files.

HOOK="hooks/validate-tdd-order.sh"
HOOK_ABS="$(pwd)/hooks/validate-tdd-order.sh"

# Helper: build PreToolUse JSON for a given file path
build_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"#!/bin/bash"}}\n' "$file_path"
}

# Helper: run the hook with a given file path (uses project root git repo)
run_hook() {
  local file_path="$1"
  local json
  json=$(build_json "$file_path")
  echo "$json" | bash "$HOOK" 2>/dev/null
}

# Helper: create a temporary git repo, copy the hook, return repo path
create_tmp_repo() {
  local tmp_repo
  tmp_repo=$(mktemp -d)

  git init --quiet "$tmp_repo"
  git -C "$tmp_repo" config user.email "test@test.com"
  git -C "$tmp_repo" config user.name "Test"

  cp "$HOOK_ABS" "$tmp_repo/"

  touch "$tmp_repo/init"
  git -C "$tmp_repo" add init
  git -C "$tmp_repo" commit --quiet -m "init"

  echo "$tmp_repo"
}

# Helper: run hook inside a given repo directory
run_hook_in_repo() {
  local repo_dir="$1"
  local file_path="$2"
  local json
  json=$(build_json "$file_path")
  # Must cd into repo so git diff runs in that repo
  (cd "$repo_dir" && echo "$json" | bash "$repo_dir/validate-tdd-order.sh" 2>/dev/null)
}

# Helper: run hook inside a given repo, capturing stderr
run_hook_in_repo_stderr() {
  local repo_dir="$1"
  local file_path="$2"
  local json
  json=$(build_json "$file_path")
  (cd "$repo_dir" && { echo "$json" | bash "$repo_dir/validate-tdd-order.sh" >/dev/null; } 2>&1)
}

# ---------- Test 1: Allows _test.sh files through ----------

function test_allows_test_sh_files() {
  run_hook "test/hooks/my_test.sh"
  assert_exit_code 0
}

# ---------- Test 2: Allows test directory .sh files through ----------

function test_allows_test_directory_sh_files() {
  run_hook "test/hooks/some_helper.sh"
  assert_exit_code 0
}

# ---------- Test 3: Blocks .sh source files when no tests written ----------

function test_blocks_sh_source_when_no_tests_written() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo "$tmp_repo" "hooks/my_script.sh"
  local rc=$?

  local stderr_output
  stderr_output=$(run_hook_in_repo_stderr "$tmp_repo" "hooks/my_script.sh")

  assert_equals 2 "$rc"
  assert_contains "BLOCKED" "$stderr_output"

  rm -rf "$tmp_repo"
}

# ---------- Test 4: Allows .sh source files after test files written ----------

function test_allows_sh_source_after_test_files_written() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  # Stage a _test.sh file so it appears in git diff HEAD
  echo '#!/bin/bash' > "$tmp_repo/my_test.sh"
  git -C "$tmp_repo" add my_test.sh

  run_hook_in_repo "$tmp_repo" "hooks/my_script.sh"
  assert_exit_code 0

  rm -rf "$tmp_repo"
}

# ---------- Test 5: Existing dart/cpp behavior unchanged ----------

function test_allows_dart_test_files() {
  run_hook "test/widget/my_widget_test.dart"
  assert_exit_code 0
}

function test_allows_cpp_test_files() {
  run_hook "test/unit/parser_test.cpp"
  assert_exit_code 0
}

function test_blocks_dart_source_when_no_tests_written() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo "$tmp_repo" "lib/widget.dart"
  local rc=$?

  assert_equals 2 "$rc"

  rm -rf "$tmp_repo"
}

# ---------- Edge Cases: Non-source files pass through ----------

function test_allows_readme_md() {
  run_hook "README.md"
  assert_exit_code 0
}

function test_allows_pubspec_yaml() {
  run_hook "pubspec.yaml"
  assert_exit_code 0
}
