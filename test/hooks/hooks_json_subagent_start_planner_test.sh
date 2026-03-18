#!/bin/bash

# Test suite for hooks.json SubagentStart entry for tdd-planner —
# validates dual-delivery hook entry that provides git context when
# the planner starts.
# Part of Issue 004: Plugin Agent Hook Mitigation.

HOOKS_JSON="$(pwd)/hooks/hooks.json"

# ---------- Test 1: SubagentStart entry for tdd-planner exists ----------

function test_subagent_start_planner_exists() {
  local matcher
  matcher=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .matcher' "$HOOKS_JSON")

  assert_equals "tdd-planner" "$matcher"
}

function test_subagent_start_planner_type_is_command() {
  local hook_type
  hook_type=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "command" "$hook_type"
}

function test_subagent_start_planner_timeout_is_5() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "5" "$timeout"
}

# ---------- Test 2: SubagentStart planner command outputs git context ----------

function test_subagent_start_planner_command_contains_git_branch() {
  local command
  command=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains "git branch --show-current" "$command"
}

function test_subagent_start_planner_command_contains_git_log() {
  local command
  command=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains "git log --oneline -1" "$command"
}

function test_subagent_start_planner_command_contains_git_status() {
  local command
  command=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains "git status --porcelain" "$command"
}

function test_subagent_start_planner_command_contains_additional_context() {
  local command
  command=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "tdd-planner") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains "additionalContext" "$command"
}

# ---------- Test 3: SubagentStart total count is 2 ----------

function test_subagent_start_total_count_is_2() {
  local count
  count=$(jq '.hooks.SubagentStart | length' "$HOOKS_JSON")

  assert_equals "2" "$count"
}

# ---------- Test 4: Existing context-updater SubagentStart preserved ----------

function test_existing_subagent_start_context_updater_preserved() {
  local matcher
  matcher=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "context-updater") | .matcher' "$HOOKS_JSON")

  assert_equals "context-updater" "$matcher"
}

function test_existing_subagent_start_context_updater_timeout_preserved() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "context-updater") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "5" "$timeout"
}

function test_existing_subagent_start_context_updater_command_preserved() {
  local command
  command=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "context-updater") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains "WARNING" "$command"
}

# ---------- Test 5: hooks.json remains valid JSON ----------

function test_hooks_json_is_valid_json() {
  jq . "$HOOKS_JSON" >/dev/null 2>&1
  assert_exit_code 0
}
