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

# Helper: extract the description frontmatter field value
get_description() {
  # Handles multi-line description with > or | folding
  get_frontmatter | sed -n '/^description:/,/^[a-z]/p' | head -n -1 | sed 's/^description: *>*//'
}

# ===== Preserved existing tests (unchanged behavior) =====

# ---------- Test: Agent tools field includes Read, Bash, Glob, Grep, Edit ----------

function test_agent_tools_field_is_correct() {
  assert_file_exists "$AGENT_FILE"
  local tools
  tools=$(get_frontmatter | grep '^tools:' | sed 's/^tools: *//')
  assert_equals "Read, Bash, Glob, Grep, Edit" "$tools"
}

# ---------- Test: Agent disallowedTools blocks Write, MultiEdit, NotebookEdit ----------

function test_agent_disallowed_tools_field_is_correct() {
  assert_file_exists "$AGENT_FILE"
  local disallowed
  disallowed=$(get_frontmatter | grep '^disallowedTools:' | sed 's/^disallowedTools: *//')
  assert_equals "Write, MultiEdit, NotebookEdit" "$disallowed"
}

# ---------- Test: Agent model is sonnet ----------

function test_agent_model_is_sonnet() {
  assert_file_exists "$AGENT_FILE"
  local model
  model=$(get_frontmatter | grep '^model:' | sed 's/^model: *//')
  assert_equals "sonnet" "$model"
}

# ---------- Test: Agent maxTurns is 30 ----------

function test_agent_max_turns_is_30() {
  assert_file_exists "$AGENT_FILE"
  local max_turns
  max_turns=$(get_frontmatter | grep '^maxTurns:' | sed 's/^maxTurns: *//')
  assert_equals "30" "$max_turns"
}

# ---------- Test: Agent has Stop hook referencing check-release-complete.sh ----------

function test_agent_has_stop_hook_for_release_complete() {
  assert_file_exists "$AGENT_FILE"
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "Stop:" "$frontmatter"
  assert_contains "check-release-complete.sh" "$frontmatter"
  assert_contains '${CLAUDE_PLUGIN_ROOT}/hooks/check-release-complete.sh' "$frontmatter"
}

# ---------- Test: Body contains git commit and push workflow ----------

function test_body_contains_git_commit_and_push_workflow() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_contains "git push" "$body"
  assert_contains "git commit" "$body"
}

# ---------- Test: Body contains CHANGELOG constraint ----------

function test_body_contains_changelog_constraint() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_matches "Do NOT modify CHANGELOG" "$body"
}

# ---------- Test: Body contains source code constraint ----------

function test_body_contains_source_code_constraint() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_matches "Do NOT modify source code|agent definitions|skill definitions" "$body"
}

# ---------- Test: Task tool NOT in agent tools list ----------

function test_task_tool_not_in_tools_list() {
  assert_file_exists "$AGENT_FILE"
  local tools
  tools=$(get_frontmatter | grep '^tools:' | sed 's/^tools: *//')
  assert_not_contains "Task" "$tools"
}

# ---------- Test: Agent does NOT have memory field ----------

function test_agent_does_not_have_memory_field() {
  assert_file_exists "$AGENT_FILE"
  local memory_line
  memory_line=$(get_frontmatter | grep '^memory:' || true)
  assert_empty "$memory_line"
}

# ===== New Slice 5 tests =====

# ---------- Slice 5 Test 1: Agent description frontmatter has no plugin-specific language ----------

function test_description_has_no_plugin_specific_language() {
  assert_file_exists "$AGENT_FILE"
  local description
  description=$(get_description)

  # Must NOT contain plugin-specific references
  assert_not_contains "plugin.json" "$description"
  assert_not_contains "plugin" "$description"
  assert_not_contains "tdd-workflow plugin" "$description"

  # Must describe generic post-release documentation finalization
  assert_matches "documentation" "$description"
}

# ---------- Slice 5 Test 2: Agent body does NOT mention plugin.json ----------

function test_body_does_not_mention_plugin_json() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_not_contains "plugin.json" "$body"
}

# ---------- Slice 5 Test 3: Agent body does NOT contain version-bumping steps ----------

function test_body_does_not_contain_version_bumping_steps() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_not_matches "Bump version" "$body"
  assert_not_contains "version-bearing files" "$body"
}

# ---------- Slice 5 Test 4: Agent body references detect-doc-context.sh for discovery ----------

function test_body_references_detect_doc_context_script() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_contains "detect-doc-context.sh" "$body"
}

# ---------- Slice 5 Test 5: Agent body references CHANGELOG as source of truth ----------

function test_body_references_changelog_as_source_of_truth() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_contains "CHANGELOG.md" "$body"
  assert_matches "Read.*CHANGELOG|CHANGELOG.*understand.*changed|CHANGELOG.*source of truth|CHANGELOG.*what changed" "$body"
}

# ---------- Slice 5 Test 6: Agent body contains documentation update workflow ----------

function test_body_contains_documentation_update_workflow() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_contains "README.md" "$body"
  assert_contains "CLAUDE.md" "$body"
  assert_contains "docs/" "$body"
}

# ---------- Slice 5 Test 8: Agent body does NOT hardcode plugin-specific doc paths ----------

function test_body_does_not_hardcode_plugin_doc_paths() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_not_contains "docs/user-guide.md" "$body"
  assert_not_contains "docs/archive/version-control-integration.md" "$body"
  assert_not_contains "docs/extensibility/audit.md" "$body"
}

# ---------- Slice 5 Test 9: Agent body does NOT reference release integration test files ----------

function test_body_does_not_reference_release_test_files() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_not_contains "release_version_test.sh" "$body"
  assert_not_contains "release_documentation_test.sh" "$body"
}

# ---------- Slice 5 Test 19: Agent body does NOT mention specific test file paths ----------

function test_body_does_not_mention_specific_test_paths() {
  assert_file_exists "$AGENT_FILE"
  local body
  body=$(get_body)
  assert_not_contains "bashunit test/integration/" "$body"
}
