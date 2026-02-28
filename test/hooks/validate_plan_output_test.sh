#!/bin/bash

# Test suite for validate-plan-output.sh hook
# Tests: stop hook guard, plan file existence, required sections, and refactoring leak detection.

HOOK_ABS="$(pwd)/hooks/validate-plan-output.sh"

# Helper: build Stop hook JSON with stop_hook_active flag
build_json() {
  local stop_active="$1"
  printf '{"stop_hook_active": %s}\n' "$stop_active"
}

# Helper: create an isolated temp directory with the hook script copied in
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)

  cp "$HOOK_ABS" "$tmp_dir/"
  mkdir -p "$tmp_dir/planning"

  echo "$tmp_dir"
}

# Helper: run hook inside a given directory, piping JSON via stdin
run_hook_in_dir() {
  local dir="$1"
  local json="$2"
  (cd "$dir" && echo "$json" | bash "$dir/validate-plan-output.sh" 2>/dev/null)
}

# Helper: run hook inside a given directory, capturing stderr
run_hook_in_dir_stderr() {
  local dir="$1"
  local json="$2"
  # shellcheck disable=SC2069
  (cd "$dir" && echo "$json" | bash "$dir/validate-plan-output.sh" 2>&1 >/dev/null)
}

# Helper: write a plan file with all required sections
write_valid_plan() {
  local dir="$1"
  local extra_content="${2:-}"
  cat > "$dir/planning/feature-plan.md" <<PLAN
## Feature Analysis

This is the feature analysis section.

## Slice 1: Core implementation

This is the first slice.
${extra_content}
PLAN
}

# ---------- Test 1: Exits 0 when stop_hook_active is true ----------

function test_exits_zero_when_stop_hook_active_is_true() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "true")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Bug 1: Deadlock fix — no plan file + no .tdd-progress.md = allow stop ----------

function test_exits_zero_when_no_plan_file_and_no_progress_file() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  # Neither planning/*.md nor .tdd-progress.md exist — discard scenario

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_exits_two_when_no_plan_file_but_progress_file_exists() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  # .tdd-progress.md exists but no planning/*.md — inconsistent state
  echo "# TDD Progress" > "$tmp_dir/.tdd-progress.md"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  rm -rf "$tmp_dir"
}

function test_stderr_message_when_progress_exists_but_no_plan_file() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  echo "# TDD Progress" > "$tmp_dir/.tdd-progress.md"

  local json
  json=$(build_json "false")

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$json")

  assert_contains ".tdd-progress.md exists" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Exits 0 when valid plan file exists with recent modification ----------

function test_exits_zero_when_recent_plan_file_exists() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create a recently modified .md file in planning/ with required sections
  write_valid_plan "$tmp_dir"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Edge Case 1: JSON with no stop_hook_active field ----------

function test_missing_stop_hook_active_proceeds_to_validation() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # No stop_hook_active field, no plan file, no .tdd-progress.md -> should exit 0 (discard)
  local json='{"some_other_field": "value"}'

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Edge Case 2: Plan file older than 30 minutes ----------

function test_stale_plan_file_no_progress_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Stale plan file (>30 min) and no .tdd-progress.md -> exit 0 (no active session)
  echo "# Old Plan" > "$tmp_dir/planning/old-plan.md"
  touch -t "$(date -d '60 minutes ago' '+%Y%m%d%H%M.%S')" "$tmp_dir/planning/old-plan.md"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_stale_plan_file_with_progress_exits_two() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Stale plan file BUT .tdd-progress.md exists -> exit 2 (need fresh archive)
  echo "# Old Plan" > "$tmp_dir/planning/old-plan.md"
  touch -t "$(date -d '60 minutes ago' '+%Y%m%d%H%M.%S')" "$tmp_dir/planning/old-plan.md"
  echo "# TDD Progress" > "$tmp_dir/.tdd-progress.md"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Test 1: Exits 2 when feature analysis section missing ----------

function test_exits_two_when_feature_analysis_section_missing() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Plan file has Slice heading but NO feature analysis heading
  cat > "$tmp_dir/planning/feature-plan.md" <<PLAN
## Slice 1: Something

Details about the first slice.
PLAN

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$json")
  assert_contains "missing required sections" "$stderr_output"
  assert_contains "Feature-Analysis" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Test 2: Exits 2 when test specification/slice sections missing ----------

function test_exits_two_when_slice_sections_missing() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Plan file has Feature Analysis but NO slice headings
  cat > "$tmp_dir/planning/feature-plan.md" <<PLAN
## Feature Analysis

Details about the feature but no slice sections.
PLAN

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$json")
  assert_contains "missing required sections" "$stderr_output"
  assert_contains "Test-Specification" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Test 3: Exits 0 when all required sections present ----------

function test_exits_zero_when_all_required_sections_present() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Bug 4: Section mismatch — accept feature-notes-template.md headings ----------

function test_exits_zero_when_overview_section_used_instead_of_feature_analysis() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # feature-notes-template.md uses "## Overview" not "## Feature Analysis"
  cat > "$tmp_dir/planning/feature-plan.md" <<PLAN
## Overview

This is the overview section.

## Slice 1: Core implementation

This is the first slice.
PLAN

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_exits_zero_when_requirements_analysis_used() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # feature-notes-template.md has "## Requirements Analysis"
  cat > "$tmp_dir/planning/feature-plan.md" <<PLAN
## Requirements Analysis

This is the requirements analysis.

## Slice 1: Core implementation

This is the first slice.
PLAN

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Test 4: Exits 2 when refactoring leak (refactor: commit type) ----------

function test_exits_two_when_refactoring_leak_refactor_commit_type() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir" "refactor: clean up authentication"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$json")
  assert_contains "REFACTORING LEAK" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Test 5: Exits 2 when refactoring leak in prose (not header/boilerplate) ----------

function test_exits_two_when_refactoring_leak_in_prose() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir" "In the REFACTOR phase we should reorganize the modules"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$json")
  assert_contains "REFACTORING LEAK" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Bug 3: Markdown headers should NOT trigger refactoring leak ----------

function test_refactor_phase_in_markdown_header_does_not_trigger_leak() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir" "### Iteration 3 (REFACTOR Phase)"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_refactoring_phase_in_markdown_header_does_not_trigger_leak() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Phase tracking header with "REFACTOR:" as a bold label (template boilerplate)
  write_valid_plan "$tmp_dir" "- **REFACTOR:** pending"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Edge 1: Standalone word "refactoring" does NOT trigger leak ----------

function test_standalone_word_refactoring_does_not_trigger_leak() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir" "Consider refactoring later if needed."

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Edge 2: Case-insensitive section matching ----------

function test_case_insensitive_section_matching() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/planning/feature-plan.md" <<PLAN
## FEATURE ANALYSIS

This is the feature analysis section in uppercase.

### slice 1: core implementation

This is a slice heading in lowercase.
PLAN

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# =====================================================================
# Slice 3 — Lock lifecycle: creation and cleanup
# =====================================================================

# ---------- S3-Test2: Lock file removed before stop_hook_active check ----------

function test_lock_file_removed_when_stop_hook_active_true() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create the lock file
  touch "$tmp_dir/.tdd-plan-locked"

  local json
  json=$(build_json "true")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  # Lock file must be removed even though stop_hook_active=true
  assert_file_not_exists "$tmp_dir/.tdd-plan-locked"

  rm -rf "$tmp_dir"
}

# ---------- S3-Test3: Normal approved flow — lock already removed by agent ----------

function test_lock_file_removed_on_normal_stop_with_valid_plan() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # No lock file — agent removed it after AskUserQuestion approval
  # Create a valid plan
  write_valid_plan "$tmp_dir"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- S3-Test4: Discard flow — lock already removed by agent ----------

function test_lock_file_removed_on_discard_no_plan_no_progress() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # No lock file — agent removed it after AskUserQuestion discard
  # No plan and no progress — discard scenario

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# =====================================================================
# Approval Enforcement Gate — Lock-based approval detection
# =====================================================================

# ---------- AEG-Test1: Lock present exits 2 with AskUserQuestion feedback ----------

function test_lock_present_exits_two_with_ask_user_question_feedback() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Lock exists = agent never called AskUserQuestion
  touch "$tmp_dir/.tdd-plan-locked"

  local json
  json=$(build_json "false")

  # Capture exit code and stderr in a single invocation to avoid double-incrementing counter
  local stderr_output
  stderr_output=$(cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/validate-plan-output.sh" 2>&1 >/dev/null)
  local rc=$?

  assert_equals 2 "$rc"

  # Stderr should contain AskUserQuestion guidance
  assert_contains "AskUserQuestion" "$stderr_output"

  # Retry counter should be created with "1"
  assert_file_exists "$tmp_dir/.tdd-plan-approval-retries"
  local counter
  counter=$(cat "$tmp_dir/.tdd-plan-approval-retries")
  assert_equals "1" "$counter"

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test2: Lock present with max retries exits 0 and cleans up ----------

function test_lock_present_with_max_retries_exits_zero_and_cleans_up() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  touch "$tmp_dir/.tdd-plan-locked"
  echo "2" > "$tmp_dir/.tdd-plan-approval-retries"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  # Both files should be cleaned up
  assert_file_not_exists "$tmp_dir/.tdd-plan-locked"
  assert_file_not_exists "$tmp_dir/.tdd-plan-approval-retries"

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test3: Lock absent proceeds to normal validation ----------

function test_lock_absent_proceeds_to_normal_validation() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # No lock file, valid plan -> exits 0 (normal flow)
  write_valid_plan "$tmp_dir"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test4: stop_hook_active cleans up both lock and retry counter ----------

function test_stop_hook_active_cleans_up_lock_and_retry_counter() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  touch "$tmp_dir/.tdd-plan-locked"
  echo "1" > "$tmp_dir/.tdd-plan-approval-retries"

  local json
  json=$(build_json "true")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  # Both files should be cleaned up
  assert_file_not_exists "$tmp_dir/.tdd-plan-locked"
  assert_file_not_exists "$tmp_dir/.tdd-plan-approval-retries"

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test5: Lock present with missing retry counter = first retry ----------

function test_lock_present_missing_retry_counter_is_first_retry() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  touch "$tmp_dir/.tdd-plan-locked"
  # No .tdd-plan-approval-retries file

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  # Counter created with "1"
  assert_file_exists "$tmp_dir/.tdd-plan-approval-retries"
  local counter
  counter=$(cat "$tmp_dir/.tdd-plan-approval-retries")
  assert_equals "1" "$counter"

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test6: Retry counter cleaned up on normal stop when lock absent ----------

function test_stale_retry_counter_cleaned_up_when_lock_absent() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # No lock file, but stale retry counter exists from previous session
  echo "1" > "$tmp_dir/.tdd-plan-approval-retries"
  write_valid_plan "$tmp_dir"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  # Stale retry counter should be cleaned up
  assert_file_not_exists "$tmp_dir/.tdd-plan-approval-retries"

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test7: Lock present stderr feedback is actionable ----------

function test_lock_present_stderr_is_actionable() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  touch "$tmp_dir/.tdd-plan-locked"

  local json
  json=$(build_json "false")

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$json")

  assert_contains "MUST call" "$stderr_output"
  assert_contains "AskUserQuestion" "$stderr_output"
  assert_contains "Approve" "$stderr_output"
  assert_contains "Discard" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test8: Existing stop_hook_active lock cleanup still works ----------

function test_existing_stop_hook_active_lock_cleanup_still_works() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  touch "$tmp_dir/.tdd-plan-locked"

  local json
  json=$(build_json "true")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  assert_file_not_exists "$tmp_dir/.tdd-plan-locked"

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test9: Lock present with valid plan still blocks ----------

function test_lock_present_with_valid_plan_still_blocks() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  touch "$tmp_dir/.tdd-plan-locked"
  write_valid_plan "$tmp_dir"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  rm -rf "$tmp_dir"
}

# ---------- AEG-Test10: Lock present with no plan no progress blocks ----------

function test_lock_present_no_plan_no_progress_blocks() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  touch "$tmp_dir/.tdd-plan-locked"
  # No plan file, no .tdd-progress.md

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  local rc=$?

  assert_equals 2 "$rc"

  rm -rf "$tmp_dir"
}

# =====================================================================
# Slice 5 — Integration: hooks.json SubagentStop entry for tdd-planner
# =====================================================================

HOOKS_JSON="hooks/hooks.json"

# ---------- Test S5-3: hooks.json SubagentStop entry for tdd-planner ----------

function test_hooks_json_has_subagent_stop_tdd_planner_matcher() {
  local result
  result=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-planner") | .matcher' "$HOOKS_JSON")
  assert_equals "tdd-planner" "$result"
}

function test_hooks_json_tdd_planner_entry_uses_validate_plan_output() {
  local result
  result=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-planner") | .hooks[0].command' "$HOOKS_JSON")
  assert_contains "validate-plan-output.sh" "$result"
}

function test_hooks_json_tdd_planner_entry_has_timeout_10() {
  local result
  result=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-planner") | .hooks[0].timeout' "$HOOKS_JSON")
  assert_equals "10" "$result"
}

function test_hooks_json_tdd_planner_entry_type_is_command() {
  local result
  result=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-planner") | .hooks[0].type' "$HOOKS_JSON")
  assert_equals "command" "$result"
}

# ---------- Test S5-4: hooks.json is valid JSON and existing entries preserved ----------

function test_hooks_json_is_valid_json() {
  jq empty "$HOOKS_JSON"
  assert_exit_code 0
}

function test_hooks_json_existing_tdd_implementer_subagent_stop_preserved() {
  local result
  result=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-implementer") | .matcher' "$HOOKS_JSON")
  assert_equals "tdd-implementer" "$result"
}

function test_hooks_json_existing_stop_hook_preserved() {
  local result
  result=$(jq -r '.hooks.Stop[0].hooks[0].command' "$HOOKS_JSON")
  assert_contains "check-tdd-progress.sh" "$result"
}

# ---------- S3-Test1: hooks.json SubagentStart for tdd-planner includes lock creation ----------

function test_hooks_json_subagent_start_tdd_planner_creates_lock() {
  local result
  result=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .hooks[0].command' "$HOOKS_JSON")
  assert_contains "touch .tdd-plan-locked" "$result"
}
