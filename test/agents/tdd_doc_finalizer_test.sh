#!/bin/bash

# Test suite for tdd-doc-finalizer agent definition (agents/tdd-doc-finalizer.md)

AGENT_FILE="agents/tdd-doc-finalizer.md"

# Helper: extract YAML frontmatter (between the two --- lines)
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$AGENT_FILE" | sed '1d;$d'
}

# Helper: extract body (everything after the closing --- of frontmatter)
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$AGENT_FILE" | sed '/./,$!d'
}

# ---------- Test 1: Agent tools field includes Read, Bash, Glob, Grep, Edit ----------

function test_agent_tools_field_is_correct() {
  assert_file_exists "$AGENT_FILE"
  local tools
  tools=$(get_frontmatter | grep '^tools:' | sed 's/^tools: *//')
  assert_equals "Read, Bash, Glob, Grep, Edit" "$tools"
}

# ---------- Test 2: Agent disallowedTools blocks Write, MultiEdit, NotebookEdit ----------

function test_agent_disallowed_tools_field_is_correct() {
  assert_file_exists "$AGENT_FILE"
  local disallowed
  disallowed=$(get_frontmatter | grep '^disallowedTools:' | sed 's/^disallowedTools: *//')
  assert_equals "Write, MultiEdit, NotebookEdit" "$disallowed"
}

# ---------- Test 3: Agent model is sonnet ----------

function test_agent_model_is_sonnet() {
  assert_file_exists "$AGENT_FILE"
  local model
  model=$(get_frontmatter | grep '^model:' | sed 's/^model: *//')
  assert_equals "sonnet" "$model"
}

# ---------- Test 4: Agent maxTurns is 30 ----------

function test_agent_max_turns_is_30() {
  assert_file_exists "$AGENT_FILE"
  local max_turns
  max_turns=$(get_frontmatter | grep '^maxTurns:' | sed 's/^maxTurns: *//')
  assert_equals "30" "$max_turns"
}

# ---------- Test 5: Agent has Stop hook referencing check-release-complete.sh ----------

function test_agent_has_stop_hook_for_release_complete() {
  assert_file_exists "$AGENT_FILE"
  local frontmatter
  frontmatter=$(get_frontmatter)
  # Must contain a Stop hook section
  assert_contains "Stop:" "$frontmatter"
  # Must reference the check-release-complete.sh script
  assert_contains "check-release-complete.sh" "$frontmatter"
  # Must use CLAUDE_PLUGIN_ROOT variable
  assert_contains '${CLAUDE_PLUGIN_ROOT}/hooks/check-release-complete.sh' "$frontmatter"
}

# ---------- Test 6: Body contains version bump workflow ----------

function test_body_contains_version_bump_workflow() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_contains "plugin.json" "$body"
  assert_contains "version" "$body"
  assert_contains "CHANGELOG.md" "$body"
}

# ---------- Test 7: Body contains documentation update workflow ----------

function test_body_contains_documentation_update_workflow() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_contains "README.md" "$body"
  assert_contains "CLAUDE.md" "$body"
  assert_contains "user-guide.md" "$body"
}

# ---------- Test 8: Body contains release integration test update workflow ----------

function test_body_contains_release_integration_test_workflow() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_contains "release_version_test.sh" "$body"
  assert_contains "release_documentation_test.sh" "$body"
}

# ---------- Test 9: Body contains git commit and push workflow ----------

function test_body_contains_git_commit_and_push_workflow() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_contains "git push" "$body"
  assert_contains "git commit" "$body"
}

# ---------- Test 10: Body contains CHANGELOG constraint ----------

function test_body_contains_changelog_constraint() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_matches "Do NOT modify CHANGELOG" "$body"
}

# ---------- Test 11: Body contains source code constraint ----------

function test_body_contains_source_code_constraint() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_matches "Do NOT modify source code|agent definitions|skill definitions" "$body"
}

# ---------- Test 12: Task tool NOT in agent tools list ----------

function test_task_tool_not_in_tools_list() {
  assert_file_exists "$AGENT_FILE"
  local tools
  tools=$(get_frontmatter | grep '^tools:' | sed 's/^tools: *//')
  # Task must NOT appear in the tools list
  if echo "$tools" | grep -q '\bTask\b'; then
    fail "Task tool should NOT be in the agent tools list, but found: $tools"
  fi
}

# ---------- Test 13: Agent does NOT have memory field ----------

function test_agent_does_not_have_memory_field() {
  assert_file_exists "$AGENT_FILE"
  local memory_line
  memory_line=$(get_frontmatter | grep '^memory:' || true)
  assert_empty "$memory_line"
}
