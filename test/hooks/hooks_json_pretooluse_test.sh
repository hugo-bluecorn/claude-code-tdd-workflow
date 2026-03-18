#!/bin/bash

# Test suite for hooks.json PreToolUse and PostToolUse entries — validates
# dual-delivery hook entries for planner-bash-guard, validate-tdd-order,
# and auto-run-tests. Part of Issue 004: Plugin Agent Hook Mitigation.

HOOKS_JSON="$(pwd)/hooks/hooks.json"

# ---------- Test 1: PreToolUse array exists in hooks.json ----------

function test_pretooluse_array_exists() {
  local result
  result=$(jq -r '.hooks.PreToolUse | type' "$HOOKS_JSON")

  assert_equals "array" "$result"
}

# ---------- Test 2: PreToolUse has Bash matcher for planner-bash-guard ----------

function test_pretooluse_has_bash_matcher_for_planner_bash_guard() {
  local command
  command=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains "planner-bash-guard.sh" "$command"
  assert_contains '${CLAUDE_PLUGIN_ROOT}' "$command"
}

function test_pretooluse_bash_matcher_type_is_command() {
  local hook_type
  hook_type=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "command" "$hook_type"
}

function test_pretooluse_bash_matcher_timeout_is_5() {
  local timeout
  timeout=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "5" "$timeout"
}

# ---------- Test 3: PreToolUse has Write|Edit|MultiEdit matcher for validate-tdd-order ----------

function test_pretooluse_has_write_edit_matcher_for_validate_tdd_order() {
  local command
  command=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Write|Edit|MultiEdit") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains "validate-tdd-order.sh" "$command"
  assert_contains '${CLAUDE_PLUGIN_ROOT}' "$command"
}

function test_pretooluse_write_edit_matcher_type_is_command() {
  local hook_type
  hook_type=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Write|Edit|MultiEdit") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "command" "$hook_type"
}

function test_pretooluse_write_edit_matcher_timeout_is_10() {
  local timeout
  timeout=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Write|Edit|MultiEdit") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "10" "$timeout"
}

# ---------- Test 4: PostToolUse array exists in hooks.json ----------

function test_posttooluse_array_exists() {
  local result
  result=$(jq -r '.hooks.PostToolUse | type' "$HOOKS_JSON")

  assert_equals "array" "$result"
}

# ---------- Test 5: PostToolUse has Write|Edit|MultiEdit matcher for auto-run-tests ----------

function test_posttooluse_has_write_edit_matcher_for_auto_run_tests() {
  local command
  command=$(jq -r '.hooks.PostToolUse[] | select(.matcher == "Write|Edit|MultiEdit") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains "auto-run-tests.sh" "$command"
  assert_contains '${CLAUDE_PLUGIN_ROOT}' "$command"
}

function test_posttooluse_write_edit_matcher_type_is_command() {
  local hook_type
  hook_type=$(jq -r '.hooks.PostToolUse[] | select(.matcher == "Write|Edit|MultiEdit") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "command" "$hook_type"
}

function test_posttooluse_write_edit_matcher_timeout_is_30() {
  local timeout
  timeout=$(jq -r '.hooks.PostToolUse[] | select(.matcher == "Write|Edit|MultiEdit") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "30" "$timeout"
}

# ---------- Test 6: hooks.json remains valid JSON ----------

function test_hooks_json_is_valid_json() {
  jq . "$HOOKS_JSON" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 7: Existing SubagentStop entries preserved ----------

function test_existing_subagent_stop_entries_preserved() {
  local implementer_type
  implementer_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-implementer") | .hooks[0].type' "$HOOKS_JSON")
  assert_equals "prompt" "$implementer_type"

  local releaser_type
  releaser_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].type' "$HOOKS_JSON")
  assert_equals "command" "$releaser_type"

  local doc_finalizer_type
  doc_finalizer_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-doc-finalizer") | .hooks[0].type' "$HOOKS_JSON")
  assert_equals "command" "$doc_finalizer_type"
}

# ---------- Test 8: Existing SubagentStart entries preserved ----------

function test_existing_subagent_start_entries_preserved() {
  local matcher
  matcher=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "context-updater") | .matcher' "$HOOKS_JSON")
  assert_equals "context-updater" "$matcher"
}

# ---------- Test 9: Existing Stop entries preserved ----------

function test_existing_stop_entries_preserved() {
  local command
  command=$(jq -r '.hooks.Stop[0].hooks[0].command' "$HOOKS_JSON")
  assert_contains "check-tdd-progress.sh" "$command"
}

# ---------- Test 10: PreToolUse entry count is exactly 2 ----------

function test_pretooluse_entry_count_is_2() {
  local count
  count=$(jq '.hooks.PreToolUse | length' "$HOOKS_JSON")

  assert_equals "2" "$count"
}

# ---------- Test 11: PostToolUse entry count is exactly 1 ----------

function test_posttooluse_entry_count_is_1() {
  local count
  count=$(jq '.hooks.PostToolUse | length' "$HOOKS_JSON")

  assert_equals "1" "$count"
}
