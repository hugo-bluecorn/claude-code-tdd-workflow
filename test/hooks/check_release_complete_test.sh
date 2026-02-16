#!/bin/bash

# Test suite for check-release-complete.sh hook — stop hook that validates
# the branch is pushed to remote before allowing the tdd-releaser to stop.

HOOK_ABS="$(pwd)/hooks/check-release-complete.sh"

# Helper: build Stop hook JSON with stop_hook_active flag
build_json() {
  local stop_active="$1"
  printf '{"stop_hook_active": %s}\n' "$stop_active"
}

# Helper: create an isolated temp directory (NOT a git repo)
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  echo "$tmp_dir"
}

# Helper: run hook inside a given directory, piping JSON via stdin
# Captures stdout, stderr, and exit code separately
run_hook_in_dir() {
  local dir="$1"
  local json="$2"
  (cd "$dir" && echo "$json" | bash "$HOOK_ABS")
}

# Helper: create a git repo with one commit but NO remote tracking
# Returns the repo directory path
create_git_env_no_upstream() {
  local tmp_dir
  tmp_dir=$(mktemp -d)

  git init "$tmp_dir" >/dev/null 2>&1
  (
    cd "$tmp_dir" || exit 1
    git config user.email "test@test.com"
    git config user.name "Test"
    git checkout -b feature-branch >/dev/null 2>&1
    echo "content" > file.txt
    git add file.txt
    git commit -m "initial commit" >/dev/null 2>&1
  )

  echo "$tmp_dir"
}

# Helper: create a git repo with a bare remote so we can push/track
# Sets up: repo_dir (working), bare_dir (remote), branch "main" with upstream
# Returns: base_dir/repo (line 1), base_dir (line 2)
create_git_env_with_remote() {
  local base_dir
  base_dir=$(mktemp -d)

  local bare_dir="$base_dir/remote.git"
  local repo_dir="$base_dir/repo"

  # Create bare remote
  git init --bare "$bare_dir" >/dev/null 2>&1

  # Create working repo
  git init "$repo_dir" >/dev/null 2>&1
  (
    cd "$repo_dir" || exit 1
    git config user.email "test@test.com"
    git config user.name "Test"
    git checkout -b main >/dev/null 2>&1
    echo "initial" > file.txt
    git add file.txt
    git commit -m "initial commit" >/dev/null 2>&1
    git remote add origin "$bare_dir"
    git push -u origin main >/dev/null 2>&1
  )

  echo "$repo_dir"
  echo "$base_dir"
}

# ---------- Test 1: stop_hook_active=true exits 0 with empty stdout ----------

function test_stop_hook_active_true_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "true")

  run_hook_in_dir "$tmp_dir" "$json" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_stop_hook_active_true_produces_empty_stdout() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "true")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json" 2>/dev/null)

  assert_empty "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: Not in a git repo exits 0 ----------

function test_not_in_git_repo_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_not_in_git_repo_produces_empty_stdout() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "false")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json" 2>/dev/null)

  assert_empty "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Branch pushed to remote exits 0 ----------

function test_branch_pushed_exits_zero() {
  local paths
  paths=$(create_git_env_with_remote)
  local repo_dir
  repo_dir=$(echo "$paths" | sed -n '1p')
  local base_dir
  base_dir=$(echo "$paths" | sed -n '2p')

  local json
  json=$(build_json "false")

  # HEAD matches upstream — branch is pushed
  run_hook_in_dir "$repo_dir" "$json" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$base_dir"
}

function test_branch_pushed_produces_empty_stdout() {
  local paths
  paths=$(create_git_env_with_remote)
  local repo_dir
  repo_dir=$(echo "$paths" | sed -n '1p')
  local base_dir
  base_dir=$(echo "$paths" | sed -n '2p')

  local json
  json=$(build_json "false")

  local output
  output=$(run_hook_in_dir "$repo_dir" "$json" 2>/dev/null)

  assert_empty "$output"

  rm -rf "$base_dir"
}

# ---------- Test 4: Branch not pushed exits 2 ----------

function test_branch_not_pushed_exits_two() {
  local paths
  paths=$(create_git_env_with_remote)
  local repo_dir
  repo_dir=$(echo "$paths" | sed -n '1p')
  local base_dir
  base_dir=$(echo "$paths" | sed -n '2p')

  # Make a new commit that is NOT pushed
  (
    cd "$repo_dir" || exit 1
    echo "unpushed change" >> file.txt
    git add file.txt
    git commit -m "unpushed commit" >/dev/null 2>&1
  )

  local json
  json=$(build_json "false")

  run_hook_in_dir "$repo_dir" "$json" >/dev/null 2>&1
  assert_exit_code 2

  rm -rf "$base_dir"
}

function test_branch_not_pushed_has_stderr_message() {
  local paths
  paths=$(create_git_env_with_remote)
  local repo_dir
  repo_dir=$(echo "$paths" | sed -n '1p')
  local base_dir
  base_dir=$(echo "$paths" | sed -n '2p')

  # Make a new commit that is NOT pushed
  (
    cd "$repo_dir" || exit 1
    echo "unpushed change" >> file.txt
    git add file.txt
    git commit -m "unpushed commit" >/dev/null 2>&1
  )

  local json
  json=$(build_json "false")

  local stderr_output
  stderr_output=$(run_hook_in_dir "$repo_dir" "$json" 2>&1 >/dev/null)

  assert_contains "push" "$stderr_output"

  rm -rf "$base_dir"
}

# ---------- Test 5: No upstream tracking branch exits 2 ----------

function test_no_upstream_exits_two() {
  local tmp_dir
  tmp_dir=$(create_git_env_no_upstream)

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json" >/dev/null 2>&1
  assert_exit_code 2

  rm -rf "$tmp_dir"
}

function test_no_upstream_has_stderr_message() {
  local tmp_dir
  tmp_dir=$(create_git_env_no_upstream)

  local json
  json=$(build_json "false")

  local stderr_output
  stderr_output=$(run_hook_in_dir "$tmp_dir" "$json" 2>&1 >/dev/null)

  assert_contains "upstream" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 6: Missing stop_hook_active field (empty JSON) ----------

function test_missing_stop_hook_active_proceeds_to_git_validation() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Empty JSON, not in a git repo -> should proceed to git check, exit 0
  local json='{}'

  run_hook_in_dir "$tmp_dir" "$json" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_missing_stop_hook_active_in_git_repo_no_upstream_exits_two() {
  local tmp_dir
  tmp_dir=$(create_git_env_no_upstream)

  # Empty JSON — missing stop_hook_active — should proceed to git validation
  local json='{}'

  run_hook_in_dir "$tmp_dir" "$json" >/dev/null 2>&1
  assert_exit_code 2

  rm -rf "$tmp_dir"
}

# ---------- Test 7: Detached HEAD exits 2 ----------

# Helper: create a git repo in detached HEAD state
create_git_env_detached_head() {
  local tmp_dir
  tmp_dir=$(mktemp -d)

  git init "$tmp_dir" >/dev/null 2>&1
  (
    cd "$tmp_dir" || exit 1
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "first" > file.txt
    git add file.txt
    git commit -m "first commit" >/dev/null 2>&1

    echo "second" > file.txt
    git add file.txt
    git commit -m "second commit" >/dev/null 2>&1

    # Detach HEAD at the first commit
    local first_hash
    first_hash=$(git rev-list --max-parents=0 HEAD)
    git checkout "$first_hash" >/dev/null 2>&1
  )

  echo "$tmp_dir"
}

function test_detached_head_exits_two() {
  local tmp_dir
  tmp_dir=$(create_git_env_detached_head)

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json" >/dev/null 2>&1
  assert_exit_code 2

  rm -rf "$tmp_dir"
}

function test_detached_head_has_stderr_message() {
  local tmp_dir
  tmp_dir=$(create_git_env_detached_head)

  local json
  json=$(build_json "false")

  local stderr_output
  stderr_output=$(run_hook_in_dir "$tmp_dir" "$json" 2>&1 >/dev/null)

  # Should mention detached HEAD or no upstream — not just a bash "file not found" error
  assert_matches "detached|upstream|HEAD" "$stderr_output"

  rm -rf "$tmp_dir"
}
