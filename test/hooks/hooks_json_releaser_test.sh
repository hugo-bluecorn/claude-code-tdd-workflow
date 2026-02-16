#!/bin/bash

# Test suite for hooks.json integration — validates that the tdd-releaser
# SubagentStop entry exists, is well-formed, and does not break existing entries.

HOOKS_JSON="$(pwd)/hooks/hooks.json"

# ---------- Test 1: SubagentStop entry with matcher tdd-releaser exists ----------

function test_hooks_json_has_subagent_stop_entry_for_tdd_releaser() {
  local result
  result=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .matcher' "$HOOKS_JSON")

  assert_equals "tdd-releaser" "$result"
}

# ---------- Test 2: SubagentStop entry command references check-release-complete.sh ----------

function test_subagent_stop_tdd_releaser_command_references_check_release_complete() {
  local command
  command=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains 'hooks/check-release-complete.sh' "$command"
  assert_contains '${CLAUDE_PLUGIN_ROOT}' "$command"
}

# ---------- Test 3: SubagentStop entry type is command ----------

function test_subagent_stop_tdd_releaser_type_is_command() {
  local hook_type
  hook_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "command" "$hook_type"
}

# ---------- Test 4: hooks.json is valid JSON ----------

function test_hooks_json_is_valid_json() {
  jq . "$HOOKS_JSON" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 5: SubagentStop timeout for tdd-releaser is 15 ----------

function test_subagent_stop_tdd_releaser_timeout_is_15() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "15" "$timeout"
}

# ---------- Test 6: Existing SubagentStop entries preserved ----------

function test_existing_subagent_stop_entries_preserved() {
  # Verify tdd-implementer entry still exists with prompt type
  local implementer_type
  implementer_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-implementer") | .hooks[0].type' "$HOOKS_JSON")
  assert_equals "prompt" "$implementer_type"

  # Verify tdd-planner entry still exists with command type and timeout 10
  local planner_type
  planner_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-planner") | .hooks[0].type' "$HOOKS_JSON")
  assert_equals "command" "$planner_type"

  local planner_timeout
  planner_timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-planner") | .hooks[0].timeout' "$HOOKS_JSON")
  assert_equals "10" "$planner_timeout"

  # Verify total SubagentStop entries count is 3 (implementer + planner + releaser)
  local count
  count=$(jq '.hooks.SubagentStop | length' "$HOOKS_JSON")
  assert_equals "3" "$count"
}
