#!/bin/bash

# Test suite for tdd-releaser agent definition (agents/tdd-releaser.md)

AGENT_FILE="agents/tdd-releaser.md"

# Helper: extract YAML frontmatter (between the two --- lines)
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$AGENT_FILE" | sed '1d;$d'
}

# Helper: extract body (everything after the closing --- of frontmatter)
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$AGENT_FILE" | sed '/./,$!d'
}

# ---------- Test 1: Agent tools field ----------

function test_agent_tools_field_is_correct() {
  assert_file_exists "$AGENT_FILE"
  local tools
  tools=$(get_frontmatter | grep '^tools:' | sed 's/^tools: *//')
  assert_equals "Read, Bash, Glob, Grep, AskUserQuestion" "$tools"
}

# ---------- Test 2: Agent disallowedTools field ----------

function test_agent_disallowed_tools_field_is_correct() {
  assert_file_exists "$AGENT_FILE"
  local disallowed
  disallowed=$(get_frontmatter | grep '^disallowedTools:' | sed 's/^disallowedTools: *//')
  assert_equals "Write, Edit, MultiEdit, NotebookEdit" "$disallowed"
}

# ---------- Test 3: Agent model is sonnet ----------

function test_agent_model_is_sonnet() {
  assert_file_exists "$AGENT_FILE"
  local model
  model=$(get_frontmatter | grep '^model:' | sed 's/^model: *//')
  assert_equals "sonnet" "$model"
}

# ---------- Test 4: Agent has stop hook referencing check-release-complete.sh ----------

function test_agent_has_stop_hook_for_release_complete() {
  assert_file_exists "$AGENT_FILE"
  local frontmatter
  frontmatter=$(get_frontmatter)
  # Must contain a Stop hook section
  assert_contains "Stop:" "$frontmatter"
  # Must reference the check-release-complete.sh script
  assert_contains 'check-release-complete.sh' "$frontmatter"
  # Must use CLAUDE_PLUGIN_ROOT variable
  assert_contains '${CLAUDE_PLUGIN_ROOT}/hooks/check-release-complete.sh' "$frontmatter"
}

# ---------- Test 5: Agent does NOT have memory field ----------

function test_agent_does_not_have_memory_field() {
  assert_file_exists "$AGENT_FILE"
  local memory_line
  memory_line=$(get_frontmatter | grep '^memory:' || true)
  assert_empty "$memory_line"
}

# ---------- Test 6: Body contains CHANGELOG workflow + Bash modification ----------

function test_body_contains_changelog_workflow() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  # Must mention CHANGELOG.md
  assert_contains "CHANGELOG" "$body"
  # Must mention using Bash for modifications (sed or echo)
  assert_matches "sed|echo" "$body"
}

# ---------- Test 7: Body contains PR creation with gh pr create + fallback ----------

function test_body_contains_pr_creation_workflow() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  # Must reference gh pr create
  assert_contains "gh pr create" "$body"
  # Must mention fallback/unavailable for when gh is not installed
  assert_matches "unavailable|not installed|not available|fallback|copy-paste|manually" "$body"
}

# ---------- Test 8: Body contains project-type aware formatter ----------

function test_body_contains_project_type_aware_formatter() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  # Must mention dart format for Dart projects
  assert_contains "dart format" "$body"
  # Must mention handling for non-Dart projects (skip or appropriate tool)
  assert_matches "skip|non-Dart|Bash|C[+][+]|shellcheck|clang-format" "$body"
}

# ---------- Test 9: Task tool NOT in agent tools list ----------

function test_task_tool_not_in_tools_list() {
  assert_file_exists "$AGENT_FILE"
  local tools
  tools=$(get_frontmatter | grep '^tools:' | sed 's/^tools: *//')
  # Task must NOT appear in the tools list
  if echo "$tools" | grep -q '\bTask\b'; then
    fail "Task tool should NOT be in the agent tools list, but found: $tools"
  fi
}
