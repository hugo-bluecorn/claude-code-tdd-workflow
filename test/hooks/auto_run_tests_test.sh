#!/bin/bash

# Test suite for auto-run-tests.sh hook — .sh file support
# Tests that the hook correctly triggers bashunit for shell files.

HOOK="hooks/auto-run-tests.sh"
PROJECT_ROOT="$(pwd)"
HOOK_ABS="$PROJECT_ROOT/$HOOK"

# Helper: build PostToolUse JSON for a given file path
build_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"echo hello"}}\n' "$file_path"
}

# Helper: run the hook with a given file path from the project root
run_hook() {
  local file_path="$1"
  local json
  json=$(build_json "$file_path")
  echo "$json" | bash "$HOOK_ABS" 2>/dev/null
}

# Helper: create a tmp dir with the hook copied in, return the path
# Usage: tmp_dir=$(create_tmp_env [--with-bashunit])
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/hooks"
  cp "$HOOK_ABS" "$tmp_dir/$HOOK"
  if [[ "${1:-}" == "--with-bashunit" ]]; then
    mkdir -p "$tmp_dir/lib"
    cp "$PROJECT_ROOT/lib/bashunit" "$tmp_dir/lib/bashunit"
    chmod +x "$tmp_dir/lib/bashunit"
  fi
  echo "$tmp_dir"
}

# Helper: run the hook inside a tmp dir
run_hook_in_tmp() {
  local tmp_dir="$1"
  local file_path="$2"
  local json
  json=$(build_json "$file_path")
  (cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
}

# ---------- Test 1: Detects .sh file changes and triggers bashunit ----------

function test_sh_file_triggers_bashunit() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source and matching test file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/my_script.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "hooks/my_script.sh")

  assert_contains "bashunit" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: Detects _test.sh directly and runs bashunit on it ----------

function test_test_sh_file_runs_bashunit_directly() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create only the test file (simulating editing a test directly)
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "test/hooks/my_script_test.sh")

  assert_contains "bashunit" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Reports when no matching test file found ----------

function test_sh_no_matching_test_file() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source file but no matching test file
  echo '#!/bin/bash' > "$tmp_dir/hooks/orphan.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "hooks/orphan.sh")

  assert_contains "systemMessage" "$output"
  assert_contains "No matching test file" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 4: Existing dart/cpp behavior unchanged ----------

function test_dart_file_still_triggers_flutter() {
  local output
  output=$(run_hook "lib/widget.dart")

  # Should reference flutter test, not bashunit
  assert_contains "systemMessage" "$output"
  assert_not_contains "bashunit" "$output"
}

function test_cpp_file_still_triggers_cmake() {
  local output
  output=$(run_hook "src/parser.cpp")

  # Should reference cmake/build, not bashunit
  assert_contains "systemMessage" "$output"
  assert_not_contains "bashunit" "$output"
}

# ---------- Edge Case: bashunit not installed ----------

function test_sh_file_when_bashunit_not_installed() {
  local tmp_dir
  # Create env WITHOUT bashunit (no --with-bashunit flag)
  tmp_dir=$(create_tmp_env)

  # Create source and matching test file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/my_script.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local json
  json=$(build_json "hooks/my_script.sh")
  local output
  local exit_code
  # Restrict PATH so bashunit is not found on PATH either
  output=$(cd "$tmp_dir" && PATH="/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
  exit_code=$?

  assert_contains "systemMessage" "$output"
  assert_contains "not installed" "$output"
  assert_equals 0 "$exit_code"

  rm -rf "$tmp_dir"
}
