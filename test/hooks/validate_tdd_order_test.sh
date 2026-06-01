#!/bin/bash

# Test suite for validate-tdd-order.sh hook — .sh file recognition
# Tests that the hook correctly handles bash test and source files.

HOOK="hooks/validate-tdd-order.sh"
HOOK_ABS="$(pwd)/hooks/validate-tdd-order.sh"
PROJECT_ROOT="$(pwd)"
DART_FIXTURE="$PROJECT_ROOT/test/fixtures/dart-fixture"

# Helper: build PreToolUse JSON for a given file path
build_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"#!/bin/bash"},"agent_type":"tdd-workflow:tdd-implementer"}\n' "$file_path"
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

# RECONCILED (C4): with NO pack bound, .dart is an unknown extension to the
# pack-optional hook (the copied-tmp repo has no ../scripts and no binding), so
# it must DEGRADE to pass-through (exit 0) -- never block a language for which
# there is no pack or built-in. Blocking for .dart now requires an active pack
# (see test_dart_source_blocked_when_no_test_pack_path).
function test_dart_source_no_pack_passes_through() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo "$tmp_repo" "lib/widget.dart"
  local rc=$?

  assert_equals 0 "$rc"

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

# Helper: create a temporary directory that is NOT a git repo, copy the hook
create_tmp_no_repo() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  cp "$HOOK_ABS" "$tmp_dir/"
  echo "$tmp_dir"
}

# Helper: run hook inside a given directory (not necessarily a repo), capturing stderr
run_hook_in_dir_stderr() {
  local dir="$1"
  local file_path="$2"
  local json
  json=$(build_json "$file_path")
  (cd "$dir" && { echo "$json" | bash "$dir/validate-tdd-order.sh" >/dev/null; } 2>&1)
}

# Helper: run hook with raw stdin (for malformed JSON tests)
run_hook_raw_stdin() {
  local raw_input="$1"
  echo "$raw_input" | bash "$HOOK" 2>/dev/null
}

# ========== Edge Case Tests (Slice 4) ==========

# ---------- Test 10: test_ prefix file allowed ----------

function test_test_prefix_file_allowed() {
  run_hook "test_helper.sh"
  assert_exit_code 0
}

# ---------- Test 11: .hpp in test/ directory allowed ----------

function test_hpp_in_test_directory_allowed() {
  run_hook "test/unit/test_fixture.hpp"
  assert_exit_code 0
}

# ---------- Test 12: .hpp source, no pack -> pass-through (RECONCILED C4) ------
# Without an active pack, .hpp is an unknown extension -> degrade, never block.

function test_hpp_source_no_pack_passes_through() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo "$tmp_repo" "src/utils.hpp"
  local rc=$?

  assert_equals 0 "$rc"

  rm -rf "$tmp_repo"
}

# ---------- Test 13: Empty file_path passes through ----------

function test_empty_file_path_passes() {
  run_hook ""
  assert_exit_code 0
}

# ---------- Test 14: Git diff failure (non-git directory) blocks with BLOCKED ----------

function test_git_diff_failure_blocks_with_message() {
  local tmp_dir
  tmp_dir=$(create_tmp_no_repo)

  (cd "$tmp_dir" && build_json "hooks/my_script.sh" | bash "$tmp_dir/validate-tdd-order.sh" 2>/dev/null)
  local rc=$?

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "hooks/my_script.sh")

  assert_equals 2 "$rc"
  assert_contains "BLOCKED" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 15: .cc source, no pack -> pass-through (RECONCILED C4) -------
# Without an active pack, .cc is an unknown extension -> degrade, never block.

function test_cc_source_no_pack_passes_through() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo "$tmp_repo" "src/parser.cc"
  local rc=$?

  assert_equals 0 "$rc"

  rm -rf "$tmp_repo"
}

# ---------- Test 16: _test.cc file, no pack -> pass-through (RECONCILED C4) ----
# .cc is not the .sh built-in and not under test/, and there is no pack -> the
# unknown extension degrades to pass-through (exit 0).

function test_test_cc_file_no_pack_passes_through() {
  run_hook "src/parser_test.cc"
  assert_exit_code 0
}

# ---------- Test 17: _test.hpp, no pack -> pass-through (RECONCILED C4) --------
# Previously a LATENT BUG: the hardcoded regex omitted .hpp from the _test
# pattern, so a *_test.hpp write FALSE-BLOCKED (exit 2). Under the pack-driven,
# pack-optional design that bug is gone: with no pack bound, .hpp is an unknown
# extension and the hook DEGRADES to pass-through (exit 0) rather than blocking a
# write for a language it has no pack/built-in for.

function test_test_hpp_no_pack_passes_through() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo "$tmp_repo" "src/parser_test.hpp"
  local rc=$?

  assert_equals 0 "$rc"

  rm -rf "$tmp_repo"
}

# ---------- Test 18: test/ subdirectory without _test suffix allowed ----------

function test_test_subdir_without_test_suffix_allowed() {
  run_hook "test/helpers/setup.sh"
  assert_exit_code 0
}

# ---------- Test 19: Malformed JSON input passes through ----------

function test_malformed_json_passes_through() {
  run_hook_raw_stdin "not json at all"
  assert_exit_code 0
}

# ========== agent_type Guard Tests (Slice 2, Issue 004) ==========

# Helper: build PreToolUse JSON with agent_type field
build_json_with_agent_type() {
  local file_path="$1"
  local agent_type="$2"
  printf '{"tool_name":"Write","agent_type":"%s","tool_input":{"file_path":"%s","content":"#!/bin/bash"}}\n' "$agent_type" "$file_path"
}

# Helper: run hook in repo with agent_type, capturing both exit code and stderr
run_hook_in_repo_with_agent_type() {
  local repo_dir="$1"
  local file_path="$2"
  local agent_type="$3"
  local json
  json=$(build_json_with_agent_type "$file_path" "$agent_type")
  (cd "$repo_dir" && echo "$json" | bash "$repo_dir/validate-tdd-order.sh" 2>/dev/null)
}

run_hook_in_repo_with_agent_type_stderr() {
  local repo_dir="$1"
  local file_path="$2"
  local agent_type="$3"
  local json
  json=$(build_json_with_agent_type "$file_path" "$agent_type")
  (cd "$repo_dir" && { echo "$json" | bash "$repo_dir/validate-tdd-order.sh" >/dev/null; } 2>&1)
}

# ---------- Test 20: Namespaced implementer agent_type preserves blocking ----------

function test_namespaced_implementer_agent_type_preserves_blocking() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo_with_agent_type "$tmp_repo" "hooks/my_script.sh" "tdd-workflow:tdd-implementer"
  local rc=$?

  local stderr_output
  stderr_output=$(run_hook_in_repo_with_agent_type_stderr "$tmp_repo" "hooks/my_script.sh" "tdd-workflow:tdd-implementer")

  assert_equals 2 "$rc"
  assert_contains "BLOCKED" "$stderr_output"

  rm -rf "$tmp_repo"
}

# ---------- Test 21: Plain implementer agent_type preserves blocking ----------

function test_plain_implementer_agent_type_preserves_blocking() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo_with_agent_type "$tmp_repo" "hooks/my_script.sh" "tdd-implementer"
  local rc=$?

  local stderr_output
  stderr_output=$(run_hook_in_repo_with_agent_type_stderr "$tmp_repo" "hooks/my_script.sh" "tdd-implementer")

  assert_equals 2 "$rc"
  assert_contains "BLOCKED" "$stderr_output"

  rm -rf "$tmp_repo"
}

# ---------- Test 22: Non-implementer agent_type passes through ----------

function test_non_implementer_agent_type_passes_through() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo_with_agent_type "$tmp_repo" "hooks/my_script.sh" "tdd-workflow:tdd-planner"
  local rc=$?

  assert_equals 0 "$rc"

  rm -rf "$tmp_repo"
}

# ---------- Test 23: Empty agent_type passes through (main thread) ----------

function test_empty_agent_type_passes_through() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  # Send JSON without agent_type to simulate main thread
  local json
  json=$(printf '{"tool_name":"Write","tool_input":{"file_path":"hooks/my_script.sh","content":"#!/bin/bash"}}\n')
  (cd "$tmp_repo" && echo "$json" | bash "$tmp_repo/validate-tdd-order.sh" 2>/dev/null)
  local rc=$?

  assert_equals 0 "$rc"

  rm -rf "$tmp_repo"
}

# ---------- Test 24: Namespaced implementer allows when tests exist ----------

function test_namespaced_implementer_allows_when_tests_exist() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  # Stage a test file
  echo '#!/bin/bash' > "$tmp_repo/my_test.sh"
  git -C "$tmp_repo" add my_test.sh

  run_hook_in_repo_with_agent_type "$tmp_repo" "hooks/my_script.sh" "tdd-workflow:tdd-implementer"
  assert_exit_code 0

  rm -rf "$tmp_repo"
}

# ==========================================================================
# C4: test-file recognition driven by the active pack's testFilePattern.
# These run the REAL committed hook ($HOOK_ABS) from inside a temp git PROJECT
# so its sibling ../scripts/active-pack.sh resolves. The dart fixture is bound
# as a DEV pack via .claude/tdd-conventions.json (committed-binding path), with
# TDD_ACTIVE_PACK UNSET -- proving the env-unset fallback works (decision #1).
# ==========================================================================

# Helper: scaffold a temp git project with the dart fixture bound as a dev pack.
# pubspec.yaml marker makes the data-driven detector match the dart fixture.
make_dart_pack_repo() {
  local proj
  proj=$(mktemp -d)
  git init --quiet "$proj"
  git -C "$proj" config user.email "test@test.com"
  git -C "$proj" config user.name "Test"
  echo 'name: tmp_app' > "$proj/pubspec.yaml"
  mkdir -p "$proj/.claude"
  cat > "$proj/.claude/tdd-conventions.json" << JSON
{ "packs": [ { "source": "$DART_FIXTURE", "dev": true } ] }
JSON
  git -C "$proj" add -A
  git -C "$proj" commit --quiet -m "init"
  printf '%s\n' "$proj"
}

# Run the REAL hook from inside a project dir with env unset, capturing exit code.
run_real_hook_env_unset() {
  local proj="$1" file_path="$2"
  local json
  json=$(build_json "$file_path")
  (cd "$proj" && unset TDD_ACTIVE_PACK && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)
}

# Run the REAL hook from inside a project dir with env unset, capturing stderr.
run_real_hook_env_unset_stderr() {
  local proj="$1" file_path="$2"
  local json
  json=$(build_json "$file_path")
  (cd "$proj" && unset TDD_ACTIVE_PACK && { echo "$json" | bash "$HOOK_ABS" >/dev/null; } 2>&1)
}

# ---------- C4 Test 1: testFilePattern recognition (env unset) ----------
# A write matching the pack's testFilePattern (*_test.dart) is recognized as a
# test -> exit 0 (allowed), even with no test files staged yet.

function test_pack_testfilepattern_recognized_as_test_env_unset() {
  local proj
  proj=$(make_dart_pack_repo)

  run_real_hook_env_unset "$proj" "test/models/user_test.dart"
  assert_exit_code 0

  rm -rf "$proj"
}

# ---------- C4 Test 2: pack source write blocked when no test written yet ------
# A .dart SOURCE write (does NOT match testFilePattern) with no staged/changed
# test files -> exit 2 with BLOCKED on stderr (RED-first enforced, pack path).

function test_dart_source_blocked_when_no_test_pack_path() {
  local proj
  proj=$(make_dart_pack_repo)

  run_real_hook_env_unset "$proj" "lib/models/user.dart"
  local rc=$?

  local stderr_output
  stderr_output=$(run_real_hook_env_unset_stderr "$proj" "lib/models/user.dart")

  assert_equals 2 "$rc"
  assert_contains "BLOCKED" "$stderr_output"

  rm -rf "$proj"
}

# ---------- C4 Test 3: .sh recognition is built-in, no pack required ----------
# A write to a *_test.sh path with NO pack bound is recognized via the built-in
# bashunit default -> exit 0.

function test_sh_test_recognized_builtin_no_pack() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo "$tmp_repo" "hooks/my_test.sh"
  assert_exit_code 0

  rm -rf "$tmp_repo"
}

# ---------- C4 Test 4 (edge): unknown ext + no pack -> pass-through ----------
# A .py SOURCE write with no pack bound is a language the plugin has no pack or
# built-in for -> degrade to pass-through (exit 0), never block.

function test_unknown_extension_no_pack_passes_through() {
  local tmp_repo
  tmp_repo=$(create_tmp_repo)

  run_hook_in_repo "$tmp_repo" "src/script.py"
  local rc=$?

  assert_equals 0 "$rc"

  rm -rf "$tmp_repo"
}
