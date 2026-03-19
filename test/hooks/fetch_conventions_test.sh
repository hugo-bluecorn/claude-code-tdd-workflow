#!/bin/bash

# Test suite for fetch-conventions.sh — SessionStart hook that fetches/refreshes
# convention repos into local cache.

HOOK="hooks/fetch-conventions.sh"
PROJECT_ROOT="$(pwd)"
HOOK_ABS="$PROJECT_ROOT/$HOOK"
HOOKS_JSON="$PROJECT_ROOT/hooks/hooks.json"

# Helper: create a tmp dir with config and plugin data dir
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/.claude"
  mkdir -p "$tmp_dir/plugin-data"
  echo "$tmp_dir"
}

# Helper: assert a directory exists (bashunit assert_file_exists uses -f, not -d)
assert_directory_exists() {
  local dir="$1"
  if [ -d "$dir" ]; then
    assert_equals "exists" "exists"
  else
    assert_equals "directory $dir exists" "directory $dir does not exist"
  fi
}

# Helper: run the hook in a given directory
run_hook_in_dir() {
  local dir="$1"
  (cd "$dir" && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 2>/dev/null)
}

# Helper: run the hook and capture stderr
run_hook_in_dir_stderr() {
  local dir="$1"
  { cd "$dir" && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 1>/dev/null; } 2>&1
}

# ---------- Test 1: Script exists and is executable ----------

function test_fetch_conventions_script_exists() {
  assert_file_exists "$HOOK_ABS"
}

function test_fetch_conventions_script_is_executable() {
  local perms
  perms=$(stat -c "%a" "$HOOK_ABS")
  # Must have at least user execute bit
  assert_matches "^7" "$perms"
}

# ---------- Test 2: Fresh fetch clones real conventions repo ----------

function test_fresh_fetch_clones_conventions_repo() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Write config pointing to the real conventions repo
  cat > "$tmp_dir/.claude/tdd-conventions.json" << 'EOF'
{"conventions": ["https://github.com/hugo-bluecorn/tdd-workflow-conventions"]}
EOF

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"
  assert_directory_exists "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions/.git"

  # Check that convention skill directories exist
  assert_directory_exists "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions/dart-flutter-conventions"
  assert_directory_exists "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions/cpp-testing-conventions"
  assert_directory_exists "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions/bash-testing-conventions"
  assert_directory_exists "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions/c-conventions"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Stale cache refreshes via git pull ----------

function test_stale_cache_refreshes_via_pull() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.claude/tdd-conventions.json" << 'EOF'
{"conventions": ["https://github.com/hugo-bluecorn/tdd-workflow-conventions"]}
EOF

  # Pre-clone the repo so cache exists
  mkdir -p "$tmp_dir/plugin-data/conventions"
  git clone --quiet https://github.com/hugo-bluecorn/tdd-workflow-conventions "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions" 2>/dev/null

  # Record the .git directory inode to confirm it was NOT replaced
  local git_inode_before
  git_inode_before=$(stat -c "%i" "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions/.git")

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"

  # The .git directory should still exist (pull, not fresh clone)
  assert_directory_exists "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions/.git"

  # The inode should be the same — directory was NOT replaced
  local git_inode_after
  git_inode_after=$(stat -c "%i" "$tmp_dir/plugin-data/conventions/tdd-workflow-conventions/.git")
  assert_equals "$git_inode_before" "$git_inode_after"

  rm -rf "$tmp_dir"
}

# ---------- Test 4: Local path conventions are not fetched ----------

function test_local_path_not_fetched() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create a local conventions path
  mkdir -p "$tmp_dir/my-local-conventions/dart-flutter-conventions"

  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"conventions": ["$tmp_dir/my-local-conventions"]}
EOF

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"

  # No .git directory should be in the local path (not cloned into)
  local git_dir="$tmp_dir/my-local-conventions/.git"
  if [ -d "$git_dir" ]; then
    assert_equals "no .git directory" "found .git directory in local path"
  else
    assert_equals "no .git" "no .git"
  fi

  # The conventions cache should be empty or not contain the local path
  local cached_count
  cached_count=$(find "$tmp_dir/plugin-data/conventions" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
  assert_equals "0" "$cached_count"

  rm -rf "$tmp_dir"
}

# ---------- Test 5: No config file creates empty cache dir ----------

function test_no_config_creates_empty_cache() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Remove the config file
  rm -f "$tmp_dir/.claude/tdd-conventions.json"

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"
  assert_directory_exists "$tmp_dir/plugin-data/conventions"

  # Should be empty
  local count
  count=$(find "$tmp_dir/plugin-data/conventions" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
  assert_equals "0" "$count"

  rm -rf "$tmp_dir"
}

# ---------- Test 6: Network failure does not crash the hook ----------

function test_network_failure_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.claude/tdd-conventions.json" << 'EOF'
{"conventions": ["https://github.com/nonexistent/repo-that-does-not-exist-12345"]}
EOF

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"

  rm -rf "$tmp_dir"
}

function test_network_failure_logs_error_to_stderr() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.claude/tdd-conventions.json" << 'EOF'
{"conventions": ["https://github.com/nonexistent/repo-that-does-not-exist-12345"]}
EOF

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir")

  # Should contain an error message about cloning failure (not a bash "not found" error)
  assert_contains "clone" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 7: Hook is registered in hooks.json ----------

function test_hooks_json_has_session_start_section() {
  local result
  result=$(jq -r '.hooks.SessionStart | type' "$HOOKS_JSON")
  assert_equals "array" "$result"
}

function test_hooks_json_session_start_references_fetch_conventions() {
  local command
  command=$(jq -r '.hooks.SessionStart[].command // .hooks.SessionStart[].hooks[]?.command // empty' "$HOOKS_JSON" 2>/dev/null)

  # Try the direct format first
  if [ -z "$command" ]; then
    command=$(jq -r '.hooks.SessionStart[] | .command // empty' "$HOOKS_JSON" 2>/dev/null)
  fi

  assert_contains "fetch-conventions.sh" "$command"
}

function test_hooks_json_session_start_type_is_command() {
  local hook_type
  hook_type=$(jq -r '.hooks.SessionStart[] | .type // empty' "$HOOKS_JSON" 2>/dev/null)
  assert_equals "command" "$hook_type"
}
