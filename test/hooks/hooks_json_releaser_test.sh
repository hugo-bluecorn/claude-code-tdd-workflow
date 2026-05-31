#!/bin/bash

# Test suite for hooks.json integration — validates that the tdd-releaser
# SubagentStop entry exists, is well-formed, and does not break existing entries.

HOOKS_JSON="$(pwd)/hooks/hooks.json"
RELEASER_AGENT="$(pwd)/agents/tdd-releaser.md"
DOC_FINALIZER_AGENT="$(pwd)/agents/tdd-doc-finalizer.md"

# Helper: extract YAML frontmatter (between first two --- markers, excluding them)
get_frontmatter() {
  local file="$1"
  sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Helper: extract body (everything after the closing --- of frontmatter)
get_body() {
  local file="$1"
  sed -n '/^---$/,/^---$/d; p' "$file" | sed '/./,$!d'
}

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

  # Verify total SubagentStop entries count is 5 (implementer + releaser + doc-finalizer + verifier + context-updater)
  local count
  count=$(jq '.hooks.SubagentStop | length' "$HOOKS_JSON")
  assert_equals "5" "$count"
}

# ---------- Test A (NEW): canonical releaser gate survives in hooks.json ----------
# Confirms the canonical SubagentStop gate still references check-release-complete.sh
# after the inert frontmatter copies are removed from the agent files.

function test_canonical_releaser_gate_present_in_hooks_json() {
  local matcher command
  matcher=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .matcher' "$HOOKS_JSON")
  assert_equals "tdd-releaser" "$matcher"

  command=$(jq -r '.hooks.SubagentStop[] | select(.matcher == "tdd-releaser") | .hooks[0].command' "$HOOKS_JSON")
  assert_contains 'check-release-complete.sh' "$command"
}

# ---------- Test B (NEW): tdd-releaser frontmatter has no top-level hooks key ----------

function test_releaser_frontmatter_has_no_hooks_key() {
  local frontmatter
  frontmatter=$(get_frontmatter "$RELEASER_AGENT")
  assert_not_contains "hooks:" "$(echo "$frontmatter" | grep -E '^hooks:')"
}

# ---------- Test C (NEW): tdd-doc-finalizer frontmatter has no top-level hooks key ----------

function test_doc_finalizer_frontmatter_has_no_hooks_key() {
  local frontmatter
  frontmatter=$(get_frontmatter "$DOC_FINALIZER_AGENT")
  assert_not_contains "hooks:" "$(echo "$frontmatter" | grep -E '^hooks:')"
}

# ---------- Test D (NEW): doc-finalizer body README-guidance "hooks" lines preserved ----------

function test_doc_finalizer_body_hooks_guidance_preserved() {
  local body
  body=$(get_body "$DOC_FINALIZER_AGENT")
  assert_contains "New hook added" "$body"
  assert_contains "Hook behavior changed" "$body"
}
