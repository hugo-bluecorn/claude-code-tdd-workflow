#!/bin/bash

# Test suite for validate-plan-output.sh hook
# Tests: plan file argument, fallback find, required sections, and refactoring leak detection.

HOOK_ABS="$(pwd)/hooks/validate-plan-output.sh"

# Helper: create an isolated temp directory with the hook script copied in
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)

  mkdir -p "$tmp_dir/planning"

  echo "$tmp_dir"
}

# Helper: run hook inside a given directory with optional file path argument
run_hook_in_dir() {
  local dir="$1"
  local plan_file="${2:-}"
  (cd "$dir" && bash "$HOOK_ABS" "$plan_file" 2>/dev/null)
}

# Helper: run hook inside a given directory, capturing stderr
run_hook_in_dir_stderr() {
  local dir="$1"
  local plan_file="${2:-}"
  # shellcheck disable=SC2069
  (cd "$dir" && bash "$HOOK_ABS" "$plan_file" 2>&1 >/dev/null)
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

# ---------- Test: Accepts file path argument and validates ----------

function test_accepts_file_path_argument_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  write_valid_plan "$tmp_dir"

  bash "$HOOK_ABS" "$tmp_dir/planning/feature-plan.md" 2>/dev/null
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test: Exits 2 when no plan file found ----------

function test_exits_two_when_no_plan_file_found() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  (cd "$tmp_dir" && bash "$HOOK_ABS" 2>/dev/null)
  assert_exit_code 2

  rm -rf "$tmp_dir"
}

# ---------- Test: Exits 2 with error message when no plan file found ----------

function test_stderr_message_when_no_plan_file_found() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local stderr_output
  # shellcheck disable=SC2069
  stderr_output=$(cd "$tmp_dir" && bash "$HOOK_ABS" 2>&1 >/dev/null)

  assert_contains "No plan file found" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test: No stdin parsing — exits 0 with file arg ----------

function test_no_stdin_parsing_exits_zero_with_file_arg() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  write_valid_plan "$tmp_dir"

  # No stdin piped -- just file path argument
  bash "$HOOK_ABS" "$tmp_dir/planning/feature-plan.md" 2>/dev/null
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test: Fallback to find when no argument ----------

function test_exits_zero_when_recent_plan_file_exists() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create a recently modified .md file in planning/ with required sections
  write_valid_plan "$tmp_dir"

  # No file argument -- should find via fallback
  run_hook_in_dir "$tmp_dir"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Edge Case: Stale plan file (>30 min) with no argument = exit 2 ----------

function test_stale_plan_file_no_argument_exits_two() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Stale plan file (>30 min) and no argument -> find returns nothing -> exit 2
  echo "# Old Plan" > "$tmp_dir/planning/old-plan.md"
  touch -t "$(date -d '60 minutes ago' '+%Y%m%d%H%M.%S')" "$tmp_dir/planning/old-plan.md"

  run_hook_in_dir "$tmp_dir"
  assert_exit_code 2

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

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  local rc=$?

  assert_equals 2 "$rc"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$tmp_dir/planning/feature-plan.md")
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

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  local rc=$?

  assert_equals 2 "$rc"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$tmp_dir/planning/feature-plan.md")
  assert_contains "missing required sections" "$stderr_output"
  assert_contains "Test-Specification" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Test 3: Exits 0 when all required sections present ----------

function test_exits_zero_when_all_required_sections_present() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir"

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Bug 4: Section mismatch -- accept feature-notes-template.md headings ----------

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

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
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

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Test 4: Exits 2 when refactoring leak (refactor: commit type) ----------

function test_exits_two_when_refactoring_leak_refactor_commit_type() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir" "refactor: clean up authentication"

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  local rc=$?

  assert_equals 2 "$rc"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$tmp_dir/planning/feature-plan.md")
  assert_contains "REFACTORING LEAK" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Test 5: Exits 2 when refactoring leak in prose (not header/boilerplate) ----------

function test_exits_two_when_refactoring_leak_in_prose() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir" "In the REFACTOR phase we should reorganize the modules"

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  local rc=$?

  assert_equals 2 "$rc"

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir" "$tmp_dir/planning/feature-plan.md")
  assert_contains "REFACTORING LEAK" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Bug 3: Markdown headers should NOT trigger refactoring leak ----------

function test_refactor_phase_in_markdown_header_does_not_trigger_leak() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir" "### Iteration 3 (REFACTOR Phase)"

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_refactoring_phase_in_markdown_header_does_not_trigger_leak() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Phase tracking header with "REFACTOR:" as a bold label (template boilerplate)
  write_valid_plan "$tmp_dir" "- **REFACTOR:** pending"

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Slice 4, Edge 1: Standalone word "refactoring" does NOT trigger leak ----------

function test_standalone_word_refactoring_does_not_trigger_leak() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  write_valid_plan "$tmp_dir" "Consider refactoring later if needed."

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
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

  run_hook_in_dir "$tmp_dir" "$tmp_dir/planning/feature-plan.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# =====================================================================
# Slice 3 — Planner hooks removed from hooks.json
# =====================================================================

HOOKS_JSON="hooks/hooks.json"

# ---------- Test S3-1: No SubagentStart entry for tdd-planner ----------

function test_hooks_json_no_subagent_start_tdd_planner() {
  local result
  result=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .matcher' "$HOOKS_JSON")
  assert_empty "$result"
}

# ---------- Test S3-2: No SubagentStop entry for tdd-planner ----------

function test_hooks_json_no_subagent_stop_tdd_planner() {
  local result
  result=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-planner") | .matcher' "$HOOKS_JSON")
  assert_empty "$result"
}

# ---------- Test S3-3: All non-planner hooks preserved ----------

function test_hooks_json_non_planner_hooks_preserved() {
  local impl
  impl=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-implementer") | .matcher' "$HOOKS_JSON")
  assert_equals "tdd-implementer" "$impl"

  local rel
  rel=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .matcher' "$HOOKS_JSON")
  assert_equals "tdd-releaser" "$rel"

  local doc
  doc=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-doc-finalizer") | .matcher' "$HOOKS_JSON")
  assert_equals "tdd-doc-finalizer" "$doc"

  local ctx
  ctx=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "context-updater") | .matcher' "$HOOKS_JSON")
  assert_equals "context-updater" "$ctx"

  local stop
  stop=$(jq -r '.hooks.Stop[0].hooks[0].command' "$HOOKS_JSON")
  assert_contains "check-tdd-progress.sh" "$stop"
}

# ---------- Test S3-4: SubagentStop count is 3 ----------

function test_hooks_json_subagent_stop_count_is_three() {
  local count
  count=$(jq '.hooks.SubagentStop | length' "$HOOKS_JSON")
  assert_equals "3" "$count"
}

# ---------- Test S3-5: SubagentStart count is 1 ----------

function test_hooks_json_subagent_start_count_is_one() {
  local count
  count=$(jq '.hooks.SubagentStart | length' "$HOOKS_JSON")
  assert_equals "1" "$count"
}

# ---------- Test S3-6: hooks.json is valid JSON ----------

function test_hooks_json_valid_after_planner_removal() {
  jq empty "$HOOKS_JSON"
  assert_exit_code 0
}

# =====================================================================
# Slice 2 — Prompt Updates: Discard lock removal + AskUserQuestion reminder
# =====================================================================

SKILL_PLAN="skills/tdd-plan/SKILL.md"
PLANNER_MD="agents/tdd-planner.md"

# ---------- S2-1: SKILL.md Discard path contains lock removal ----------

function test_skill_plan_discard_path_contains_lock_removal() {
  # Extract the Discard bullet from step 9 area and check for rm .tdd-plan-locked
  local discard_context
  discard_context=$(grep -A1 -i "discard" "$SKILL_PLAN" | head -4)
  assert_contains "rm .tdd-plan-locked" "$discard_context"
}

# ---------- S2-6: Existing SKILL.md constraints preserved ----------

function test_skill_plan_constraints_preserved_after_discard_fix() {
  assert_file_contains "$SKILL_PLAN" "Do NOT write any implementation code"
}

