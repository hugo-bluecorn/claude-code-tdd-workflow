#!/bin/bash

# Test suite for planner-bash-guard.sh hook — command allowlist and redirection blocking
# Tests that the hook correctly allows read-only commands, blocks others,
# and prevents output redirection except to /dev/null and planning/.

HOOK="hooks/planner-bash-guard.sh"
HOOK_ABS="$(pwd)/$HOOK"

# Helper: build PreToolUse JSON for a given bash command
build_json() {
  local cmd="$1"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}\n' "$cmd"
}

# Helper: build PreToolUse JSON with no command field
build_json_no_command() {
  printf '{"tool_name":"Bash","tool_input":{"description":"do something"}}\n'
}

# Helper: run the hook with a given command, suppressing stderr
run_hook() {
  local cmd="$1"
  local json
  json=$(build_json "$cmd")
  echo "$json" | bash "$HOOK_ABS" 2>/dev/null
}

# Helper: run the hook and capture stderr (stdout suppressed)
run_hook_stderr() {
  local cmd="$1"
  local json
  json=$(build_json "$cmd")
  # shellcheck disable=SC2069
  echo "$json" | bash "$HOOK_ABS" 2>&1 >/dev/null
}

# ---------- Test 1: Allows allowlisted read-only commands ----------

function test_guard_allowlisted_command_exits_zero() {
  run_hook "cat README.md"
  assert_exit_code 0
}

# ---------- Test 2: Blocks non-allowlisted commands ----------

function test_guard_blocked_command_exits_two() {
  run_hook "rm -rf /tmp/data"
  assert_exit_code 2
}

function test_guard_blocked_command_stderr_contains_blocked() {
  local stderr_output
  stderr_output=$(run_hook_stderr "rm -rf /tmp/data")

  assert_contains "BLOCKED" "$stderr_output"
}

function test_guard_blocked_command_stderr_contains_allowlist_message() {
  local stderr_output
  stderr_output=$(run_hook_stderr "python3 -c 'import os'")

  assert_contains "not in the planner's allowlist" "$stderr_output"
}

# ---------- Test 3: Allows commands with leading env var assignments ----------

function test_guard_env_var_prefix_allowlisted_command_exits_zero() {
  run_hook "FOO=bar grep pattern file.txt"
  assert_exit_code 0
}

# ---------- Test 4: Blocks non-allowlisted commands with leading env vars ----------

function test_guard_env_var_prefix_blocked_command_exits_two() {
  run_hook "FOO=bar python3 -c 'import os'"
  assert_exit_code 2
}

function test_guard_env_var_prefix_blocked_command_stderr_contains_blocked() {
  local stderr_output
  stderr_output=$(run_hook_stderr "FOO=bar python3 -c 'import os'")

  assert_contains "BLOCKED" "$stderr_output"
}

# ---------- Test 5: Each allowlisted command is individually accepted ----------

function test_guard_all_allowlisted_commands_exit_zero() {
  local -a allowed_commands=(
    find grep rg cat head tail wc ls tree file stat du df
    git flutter dart fvm test command which type pwd echo
  )

  for cmd in "${allowed_commands[@]}"; do
    run_hook "$cmd --help"
    local rc=$?
    if [ "$rc" -ne 0 ]; then
      bashunit::fail "Expected exit 0 for allowlisted command '$cmd', got $rc"
      return
    fi
  done
}

# ---------- Edge Case 1: Empty command ----------

function test_guard_empty_command_exits_two() {
  run_hook ""
  assert_exit_code 2
}

# ---------- Edge Case 2: Missing tool_input.command field ----------

function test_guard_missing_command_field_exits_two() {
  local json
  json=$(build_json_no_command)
  echo "$json" | bash "$HOOK_ABS" 2>/dev/null
  assert_exit_code 2
}

# ---------- Edge Case 3: Partial match is rejected ----------

function test_guard_partial_match_rejected_exits_two() {
  run_hook "grep-extended foo"
  assert_exit_code 2
}

# ---------- Redirection Blocking Tests ----------

# ---------- Test R1: Blocks output redirection to arbitrary paths ----------

function test_guard_redirect_to_arbitrary_path_exits_two() {
  run_hook "echo hello > /tmp/output.txt"
  assert_exit_code 2
}

function test_guard_redirect_to_arbitrary_path_stderr_contains_blocked() {
  local stderr_output
  stderr_output=$(run_hook_stderr "echo hello > /tmp/output.txt")

  assert_contains "BLOCKED" "$stderr_output"
}

function test_guard_redirect_to_arbitrary_path_stderr_contains_redirection() {
  local stderr_output
  stderr_output=$(run_hook_stderr "echo hello > /tmp/output.txt")

  assert_contains "redirection" "$stderr_output"
}

# ---------- Test R2: Allows redirection to /dev/null ----------

function test_guard_redirect_to_dev_null_exits_zero() {
  run_hook "git status > /dev/null"
  assert_exit_code 0
}

# ---------- Test R3: Allows redirection to planning/ directory ----------

function test_guard_redirect_to_planning_dir_exits_zero() {
  run_hook "echo content > planning/notes.md"
  assert_exit_code 0
}

# ---------- Test R4: Allows redirection to ./planning/ with dot prefix ----------

function test_guard_redirect_to_dot_planning_dir_exits_zero() {
  run_hook "echo content > ./planning/notes.md"
  assert_exit_code 0
}

# ---------- Edge Case R1: Append redirection blocked ----------

function test_guard_append_redirect_to_arbitrary_path_exits_two() {
  run_hook "ls -la >> /tmp/log.txt"
  assert_exit_code 2
}

# ---------- Edge Case R2: Stderr redirection to /dev/null allowed ----------

function test_guard_stderr_redirect_to_dev_null_exits_zero() {
  run_hook "ls 2>/dev/null"
  assert_exit_code 0
}

# ---------- Pipe Bypass Detection Tests ----------

# ---------- Test P1: Blocks pipe-to-file via tee to arbitrary path ----------

function test_guard_pipe_tee_to_arbitrary_path_exits_two() {
  run_hook "cat README.md | tee .tdd-progress.md"
  assert_exit_code 2
}

function test_guard_pipe_tee_to_arbitrary_path_stderr_contains_blocked() {
  local stderr_output
  stderr_output=$(run_hook_stderr "cat README.md | tee .tdd-progress.md")

  assert_contains "BLOCKED" "$stderr_output"
}

# ---------- Test P2: Allows pipe-to-file via tee to planning/ directory ----------

function test_guard_pipe_tee_to_planning_dir_exits_zero() {
  run_hook "cat notes.md | tee planning/notes.md"
  assert_exit_code 0
}

# ---------- Test P3: Allows pipe-to-file via tee to /dev/null ----------

function test_guard_pipe_tee_to_dev_null_exits_zero() {
  run_hook "cat README.md | tee /dev/null"
  assert_exit_code 0
}

# ---------- Test P4 (Edge Case): Blocks pipe-to-file via sponge to arbitrary path ----------

function test_guard_pipe_sponge_to_arbitrary_path_exits_two() {
  run_hook "cat README.md | sponge .tdd-progress.md"
  assert_exit_code 2
}

function test_guard_pipe_sponge_to_arbitrary_path_stderr_contains_blocked() {
  local stderr_output
  stderr_output=$(run_hook_stderr "cat README.md | sponge .tdd-progress.md")

  assert_contains "BLOCKED" "$stderr_output"
}

# =====================================================================
# Slice 2 — Lock-file gate and rm exception
# =====================================================================

# Helper: create an isolated temp directory with the hook script copied in
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  cp "$HOOK_ABS" "$tmp_dir/"
  echo "$tmp_dir"
}

# Helper: run hook inside a given directory, suppressing stderr
run_hook_in_dir() {
  local dir="$1"
  local cmd="$2"
  local json
  json=$(build_json "$cmd")
  (cd "$dir" && echo "$json" | bash "$dir/planner-bash-guard.sh" 2>/dev/null)
}

# Helper: run hook inside a given directory, capturing stderr (stdout suppressed)
run_hook_in_dir_stderr() {
  local dir="$1"
  local cmd="$2"
  local json
  json=$(build_json "$cmd")
  # shellcheck disable=SC2069
  (cd "$dir" && echo "$json" | bash "$dir/planner-bash-guard.sh" 2>&1 >/dev/null)
}

# ---------- Test L1: Blocks .tdd-progress.md reference while locked ----------

function test_guard_lock_gate_blocks_progress_ref_when_locked_exits_two() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  touch "$tmp_dir/.tdd-plan-locked"

  run_hook_in_dir "$tmp_dir" "cat .tdd-progress.md"
  assert_exit_code 2

  rm -rf "$tmp_dir"
}

function test_guard_lock_gate_blocks_progress_ref_when_locked_stderr_contains_blocked() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  touch "$tmp_dir/.tdd-plan-locked"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "cat .tdd-progress.md")

  assert_contains "BLOCKED" "$stderr_output"

  rm -rf "$tmp_dir"
}

function test_guard_lock_gate_blocks_progress_ref_when_locked_stderr_contains_not_yet_approved() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  touch "$tmp_dir/.tdd-plan-locked"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "cat .tdd-progress.md")

  assert_contains "not yet approved" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test L2: Allows .tdd-progress.md reference when unlocked ----------

function test_guard_lock_gate_allows_progress_ref_when_unlocked_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  # No .tdd-plan-locked file created

  run_hook_in_dir "$tmp_dir" "cat .tdd-progress.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test L3: Allows rm .tdd-plan-locked ----------

function test_guard_rm_exception_allows_rm_lockfile_exits_zero() {
  run_hook "rm .tdd-plan-locked"
  assert_exit_code 0
}

# ---------- Test L4: Allows rm -f .tdd-plan-locked ----------

function test_guard_rm_exception_allows_rm_f_lockfile_exits_zero() {
  run_hook "rm -f .tdd-plan-locked"
  assert_exit_code 0
}

# ---------- Test L5 (Edge Case): Blocks rm of arbitrary files ----------

function test_guard_rm_exception_blocks_rm_arbitrary_file_exits_two() {
  run_hook "rm somefile.txt"
  assert_exit_code 2
}

function test_guard_rm_exception_blocks_rm_arbitrary_file_stderr_contains_blocked() {
  local stderr_output
  stderr_output=$(run_hook_stderr "rm somefile.txt")

  assert_contains "BLOCKED" "$stderr_output"
}

# ---------- Test L6 (Edge Case): Blocks rm -rf ----------

function test_guard_rm_exception_blocks_rm_rf_exits_two() {
  run_hook "rm -rf /"
  assert_exit_code 2
}

function test_guard_rm_exception_blocks_rm_rf_stderr_contains_blocked() {
  local stderr_output
  stderr_output=$(run_hook_stderr "rm -rf /")

  assert_contains "BLOCKED" "$stderr_output"
}

# =====================================================================
# Slice 5 — Integration: Planner frontmatter hooks wiring
# =====================================================================

PLANNER_MD="agents/tdd-planner.md"

# ---------- Test S5-1: Frontmatter contains PreToolUse Bash hook ----------

function test_frontmatter_contains_pretooluse_hook() {
  assert_file_contains "$PLANNER_MD" "PreToolUse:"
}

function test_frontmatter_contains_bash_matcher() {
  assert_file_contains "$PLANNER_MD" 'matcher: "Bash"'
}

function test_frontmatter_contains_planner_bash_guard_hook() {
  assert_file_contains "$PLANNER_MD" "planner-bash-guard.sh"
}

# ---------- Test S5-2: Frontmatter contains Stop hook ----------

function test_frontmatter_contains_stop_hook() {
  assert_file_contains "$PLANNER_MD" "Stop:"
}

function test_frontmatter_stop_hook_references_validate_plan_output() {
  assert_file_contains "$PLANNER_MD" "validate-plan-output.sh"
}

# ---------- Edge Case: Existing frontmatter fields preserved ----------

function test_frontmatter_preserves_name_field() {
  assert_file_contains "$PLANNER_MD" "name: tdd-planner"
}

function test_frontmatter_preserves_tools_field() {
  assert_file_contains "$PLANNER_MD" "tools: Read, Glob, Grep, Bash, AskUserQuestion"
}

function test_frontmatter_preserves_disallowed_tools_field() {
  assert_file_contains "$PLANNER_MD" "disallowedTools: Write, Edit, MultiEdit, NotebookEdit, Task"
}

function test_frontmatter_preserves_model_field() {
  assert_file_contains "$PLANNER_MD" "model: opus"
}

function test_frontmatter_preserves_permission_mode_field() {
  assert_file_contains "$PLANNER_MD" "permissionMode: plan"
}

# function test_frontmatter_preserves_max_turns_field() {
#   assert_file_contains "$PLANNER_MD" "maxTurns: 30"
# }

function test_frontmatter_preserves_skills_list() {
  assert_file_contains "$PLANNER_MD" "dart-flutter-conventions"
  assert_file_contains "$PLANNER_MD" "cpp-testing-conventions"
  assert_file_contains "$PLANNER_MD" "bash-testing-conventions"
}

# =====================================================================
# Prompt file content assertions — approval flow
# =====================================================================

SKILL_PLAN="skills/tdd-plan/SKILL.md"
SKILL_IMPLEMENT="skills/tdd-implement/SKILL.md"

# ---------- Test PF1: SKILL.md contains compaction guard instruction ----------

function test_skill_plan_contains_compaction_guard() {
  assert_file_contains "$SKILL_PLAN" "CRITICAL"
  assert_file_contains "$SKILL_PLAN" ".tdd-plan-locked"
  assert_file_contains "$SKILL_PLAN" "re-ask"
}

# ---------- Test PF2: SKILL.md contains lock removal step ----------

function test_skill_plan_contains_lock_removal_step() {
  assert_file_contains "$SKILL_PLAN" "rm .tdd-plan-locked"
}

# ---------- Test PF3: SKILL.md contains Approved header instruction ----------

function test_skill_plan_contains_approved_header_instruction() {
  assert_file_contains "$SKILL_PLAN" "Approved:"
}

# ---------- Test PF4: tdd-planner.md contains compaction guard and lock removal ----------

function test_planner_md_contains_compaction_guard_and_lock_removal() {
  assert_file_contains "$PLANNER_MD" ".tdd-plan-locked"
  assert_file_contains "$PLANNER_MD" "rm .tdd-plan-locked"
}

# ---------- Test PF5: tdd-implement SKILL.md contains approval verification gate ----------

function test_implement_skill_contains_approval_verification_gate() {
  assert_file_contains "$SKILL_IMPLEMENT" "Approved:"
  assert_file_contains "$SKILL_IMPLEMENT" "/tdd-plan"
}

# ---------- Test PF6 (Edge Case): tdd-planner.md preserves existing mandatory approval sequence ----------

function test_planner_md_preserves_mandatory_approval_sequence() {
  assert_file_contains "$PLANNER_MD" "AskUserQuestion"
  assert_file_contains "$PLANNER_MD" "Approve"
  assert_file_contains "$PLANNER_MD" "Modify"
  assert_file_contains "$PLANNER_MD" "Discard"
}

# ---------- Test S5-5: Existing hook scripts unmodified ----------

function test_existing_hooks_unmodified() {
  local expected_checksums
  expected_checksums="a5f793ccf8604d6fe26dfc3c32a03476  hooks/planner-bash-guard.sh
fc7c54fc106268577da49bd4a3e40eb4  hooks/validate-plan-output.sh
9d6249abc46f477c707d50fa759d412e  hooks/validate-tdd-order.sh
fa36eb282579bed351c1b32bd08376f4  hooks/auto-run-tests.sh
68528fca7cd1b4a652d3365174246341  hooks/check-tdd-progress.sh"

  local actual_checksums
  actual_checksums=$(md5sum \
    hooks/planner-bash-guard.sh \
    hooks/validate-plan-output.sh \
    hooks/validate-tdd-order.sh \
    hooks/auto-run-tests.sh \
    hooks/check-tdd-progress.sh)

  assert_equals "$expected_checksums" "$actual_checksums"
}
