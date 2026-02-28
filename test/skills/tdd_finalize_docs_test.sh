#!/bin/bash

# Test suite for /tdd-finalize-docs skill definition (skills/tdd-finalize-docs/SKILL.md)

SKILL_FILE="skills/tdd-finalize-docs/SKILL.md"

# Helper: extract YAML frontmatter (between the two --- lines)
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d'
}

# Helper: extract body (everything after the closing --- of frontmatter)
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$SKILL_FILE" | sed '/./,$!d'
}

# ---------- Test 1: Skill name = tdd-finalize-docs ----------

function test_skill_name_is_tdd_finalize_docs() {
  assert_file_exists "$SKILL_FILE"
  local name
  name=$(get_frontmatter | grep '^name:' | sed 's/^name: *//')
  assert_equals "tdd-finalize-docs" "$name"
}

# ---------- Test 2: Skill agent = tdd-doc-finalizer ----------

function test_skill_agent_is_tdd_doc_finalizer() {
  assert_file_exists "$SKILL_FILE"
  local agent
  agent=$(get_frontmatter | grep '^agent:' | sed 's/^agent: *//')
  assert_equals "tdd-doc-finalizer" "$agent"
}

# ---------- Test 3: Skill context = fork ----------

function test_skill_context_is_fork() {
  assert_file_exists "$SKILL_FILE"
  local context
  context=$(get_frontmatter | grep '^context:' | sed 's/^context: *//')
  assert_equals "fork" "$context"
}

# ---------- Test 4: Skill disable-model-invocation = true ----------

function test_skill_disable_model_invocation_is_true() {
  assert_file_exists "$SKILL_FILE"
  local value
  value=$(get_frontmatter | grep '^disable-model-invocation:' | sed 's/^disable-model-invocation: *//')
  assert_equals "true" "$value"
}

# ---------- Test 5: Body contains all major process steps ----------

function test_body_contains_all_major_process_steps() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)

  # Version detection/bump
  assert_matches "version" "$body"

  # plugin.json reference
  assert_contains "plugin.json" "$body"

  # Documentation updates
  assert_matches "documentation" "$body"

  # Integration test updates
  assert_matches "integration test" "$body"

  # Git push
  assert_contains "git push" "$body"

  # CHANGELOG as read-only reference
  assert_contains "CHANGELOG" "$body"
}

# ---------- Test 6: Description contains trigger phrases ----------

function test_description_contains_trigger_phrases() {
  assert_file_exists "$SKILL_FILE"
  local frontmatter
  frontmatter=$(get_frontmatter)

  # Extract the description field (may be multi-line with > or |)
  local description
  description=$(echo "$frontmatter" | sed -n '/^description:/,/^[a-z]/p' | head -n -1)

  assert_matches "docs" "$description"
  assert_matches "finalize" "$description"
  assert_matches "documentation" "$description"
}

# ---------- Test 7: Body mentions all documentation files to check ----------

function test_body_mentions_all_documentation_files() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)

  assert_contains "README.md" "$body"
  assert_contains "CLAUDE.md" "$body"
  assert_contains "user-guide.md" "$body"
}

# ---------- Test 8: Body mentions constraints ----------

function test_body_mentions_constraints() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)

  # Should mention not modifying CHANGELOG
  assert_matches "Do NOT modify CHANGELOG|do not modify CHANGELOG|CHANGELOG.*read.only|not.*modify.*CHANGELOG" "$body"
}

# ---------- Test 9: Body mentions running tests for verification ----------

function test_body_mentions_running_tests() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)

  # Should mention test verification via bashunit or specific test files
  assert_matches "bashunit|release_version_test|release_documentation_test" "$body"
}
