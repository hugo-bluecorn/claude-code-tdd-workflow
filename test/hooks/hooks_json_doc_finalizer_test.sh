#!/bin/bash

# Test suite for hooks.json integration — validates that the tdd-doc-finalizer
# SubagentStop entry exists, is well-formed, and does not break existing entries.

HOOKS_JSON="$(pwd)/hooks/hooks.json"

# ---------- Test 1: SubagentStop entry with matcher tdd-doc-finalizer exists ----------

function test_hooks_json_has_subagent_stop_entry_for_tdd_doc_finalizer() {
  local result
  result=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-doc-finalizer") | .matcher' "$HOOKS_JSON")

  assert_equals "tdd-doc-finalizer" "$result"
}

# ---------- Test 2: SubagentStop entry command references check-release-complete.sh ----------

function test_subagent_stop_tdd_doc_finalizer_command_references_check_release_complete() {
  local command
  command=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-doc-finalizer") | .hooks[0].command' "$HOOKS_JSON")

  assert_contains 'hooks/check-release-complete.sh' "$command"
  assert_contains '${CLAUDE_PLUGIN_ROOT}' "$command"
}

# ---------- Test 3: SubagentStop entry type is command ----------

function test_subagent_stop_tdd_doc_finalizer_type_is_command() {
  local hook_type
  hook_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-doc-finalizer") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "command" "$hook_type"
}

# ---------- Test 4: SubagentStop timeout for tdd-doc-finalizer is 15 ----------

function test_subagent_stop_tdd_doc_finalizer_timeout_is_15() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-doc-finalizer") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "15" "$timeout"
}

# ---------- Test 5: hooks.json is valid JSON ----------

function test_hooks_json_is_valid_json() {
  jq . "$HOOKS_JSON" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 6: Existing SubagentStop entries preserved ----------

function test_existing_subagent_stop_entries_preserved() {
  # Verify tdd-implementer entry still exists with prompt type
  local implementer_type
  implementer_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-implementer") | .hooks[0].type' "$HOOKS_JSON")
  assert_equals "prompt" "$implementer_type"

  # Verify tdd-releaser entry still exists with command type and timeout 15
  local releaser_type
  releaser_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].type' "$HOOKS_JSON")
  assert_equals "command" "$releaser_type"

  local releaser_timeout
  releaser_timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].timeout' "$HOOKS_JSON")
  assert_equals "15" "$releaser_timeout"

  # Verify total SubagentStop entries count is 3 (implementer + releaser + doc-finalizer)
  local count
  count=$(jq '.hooks.SubagentStop | length' "$HOOKS_JSON")
  assert_equals "3" "$count"
}

# ---------- Test 7: Existing SubagentStart entries preserved ----------

function test_existing_subagent_start_entries_preserved() {
  # Verify context-updater entry exists
  local updater
  updater=$(jq -r '.hooks.SubagentStart[] | select(.matcher == "context-updater") | .matcher' "$HOOKS_JSON")
  assert_equals "context-updater" "$updater"

  # Verify total SubagentStart entries count is 1
  local count
  count=$(jq '.hooks.SubagentStart | length' "$HOOKS_JSON")
  assert_equals "1" "$count"
}

# ---------- Test 8: Stop hook entries preserved ----------

function test_stop_hook_entries_preserved() {
  local command
  command=$(jq -r '.hooks.Stop[0].hooks[0].command' "$HOOKS_JSON")

  assert_contains 'check-tdd-progress.sh' "$command"
}
