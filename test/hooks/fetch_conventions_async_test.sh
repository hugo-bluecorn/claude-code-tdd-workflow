#!/bin/bash

# Test suite for hooks.json — validates that the SessionStart fetch-conventions
# hook is marked async (R7), without disturbing any other hook entry.

HOOKS_JSON="$(pwd)/hooks/hooks.json"

# ---------- Test 1: fetch-conventions SessionStart inner hook is async ----------

function test_fetch_conventions_session_start_hook_is_async() {
  local result
  result=$(jq -r '.hooks.SessionStart[] | select(.hooks[]?.command | contains("fetch-conventions.sh")) | .hooks[0].async' "$HOOKS_JSON")

  assert_equals "true" "$result"
}

# ---------- Test 2: command and type unchanged ----------

function test_fetch_conventions_command_and_type_unchanged() {
  local command hook_type
  command=$(jq -r '.hooks.SessionStart[] | select(.hooks[]?.command | contains("fetch-conventions.sh")) | .hooks[0].command' "$HOOKS_JSON")
  hook_type=$(jq -r '.hooks.SessionStart[] | select(.hooks[]?.command | contains("fetch-conventions.sh")) | .hooks[0].type' "$HOOKS_JSON")

  # shellcheck disable=SC2016 # literal placeholder, not a shell expansion
  assert_contains '${CLAUDE_PLUGIN_ROOT}/hooks/fetch-conventions.sh' "$command"
  assert_equals "command" "$hook_type"
}

# ---------- Test 3: hooks.json is valid JSON ----------

function test_hooks_json_is_valid_json() {
  jq . "$HOOKS_JSON" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 4: exactly one hook object across all events is async ----------

function test_exactly_one_hook_object_is_async() {
  local count
  count=$(jq '[.. | objects | select(.async == true)] | length' "$HOOKS_JSON")

  assert_equals "1" "$count"
}
