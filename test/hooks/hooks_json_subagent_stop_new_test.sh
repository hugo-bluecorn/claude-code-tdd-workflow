#!/bin/bash

# Test suite for hooks.json SubagentStop entries for tdd-verifier and
# context-updater — validates dual-delivery hook entries that replicate
# frontmatter Stop hooks lost during marketplace install.
# Part of Issue 004: Plugin Agent Hook Mitigation.

HOOKS_JSON="$(pwd)/hooks/hooks.json"

# ---------- Test 1: SubagentStop entry for tdd-verifier exists ----------

function test_subagent_stop_verifier_exists() {
  local matcher
  matcher=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-verifier") | .matcher' "$HOOKS_JSON")

  assert_equals "tdd-verifier" "$matcher"
}

function test_subagent_stop_verifier_type_is_prompt() {
  local hook_type
  hook_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-verifier") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "prompt" "$hook_type"
}

function test_subagent_stop_verifier_prompt_contains_complete_test_suite() {
  local prompt
  prompt=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-verifier") | .hooks[0].prompt' "$HOOKS_JSON")

  assert_contains "COMPLETE test suite" "$prompt"
}

function test_subagent_stop_verifier_prompt_contains_static_analysis() {
  local prompt
  prompt=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-verifier") | .hooks[0].prompt' "$HOOKS_JSON")

  assert_contains "static analysis" "$prompt"
}

function test_subagent_stop_verifier_timeout_is_30() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-verifier") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "30" "$timeout"
}

# ---------- Test 2: SubagentStop entry for context-updater exists ----------

function test_subagent_stop_context_updater_exists() {
  local matcher
  matcher=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "context-updater") | .matcher' "$HOOKS_JSON")

  assert_equals "context-updater" "$matcher"
}

function test_subagent_stop_context_updater_type_is_prompt() {
  local hook_type
  hook_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "context-updater") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "prompt" "$hook_type"
}

function test_subagent_stop_context_updater_prompt_contains_framework_versions() {
  local prompt
  prompt=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "context-updater") | .hooks[0].prompt' "$HOOKS_JSON")

  assert_contains "framework versions" "$prompt"
}

function test_subagent_stop_context_updater_prompt_contains_change_proposal() {
  local prompt
  prompt=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "context-updater") | .hooks[0].prompt' "$HOOKS_JSON")

  assert_contains "change proposal" "$prompt"
}

function test_subagent_stop_context_updater_prompt_contains_user_approval() {
  local prompt
  prompt=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "context-updater") | .hooks[0].prompt' "$HOOKS_JSON")

  assert_contains "user approval" "$prompt"
}

function test_subagent_stop_context_updater_timeout_is_30() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "context-updater") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "30" "$timeout"
}

# ---------- Test 3: SubagentStop total count is 5 ----------

function test_subagent_stop_total_count_is_5() {
  local count
  count=$(jq '.hooks.SubagentStop | length' "$HOOKS_JSON")

  assert_equals "5" "$count"
}

# ---------- Test 4: Existing SubagentStop entries preserved ----------

function test_existing_subagent_stop_implementer_preserved() {
  local hook_type
  hook_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-implementer") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "prompt" "$hook_type"
}

function test_existing_subagent_stop_implementer_timeout_preserved() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-implementer") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "30" "$timeout"
}

function test_existing_subagent_stop_releaser_preserved() {
  local hook_type
  hook_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "command" "$hook_type"
}

function test_existing_subagent_stop_releaser_timeout_preserved() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "15" "$timeout"
}

function test_existing_subagent_stop_doc_finalizer_preserved() {
  local hook_type
  hook_type=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-doc-finalizer") | .hooks[0].type' "$HOOKS_JSON")

  assert_equals "command" "$hook_type"
}

function test_existing_subagent_stop_doc_finalizer_timeout_preserved() {
  local timeout
  timeout=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-doc-finalizer") | .hooks[0].timeout' "$HOOKS_JSON")

  assert_equals "15" "$timeout"
}

# ---------- Test 5: hooks.json remains valid JSON ----------

function test_hooks_json_is_valid_json() {
  jq . "$HOOKS_JSON" >/dev/null 2>&1
  assert_exit_code 0
}
