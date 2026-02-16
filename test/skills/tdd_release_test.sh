#!/bin/bash

# Test suite for /tdd-release skill definition (skills/tdd-release/SKILL.md)

SKILL_FILE="skills/tdd-release/SKILL.md"

# Helper: extract YAML frontmatter (between the two --- lines)
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d'
}

# Helper: extract body (everything after the closing --- of frontmatter)
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$SKILL_FILE" | sed '/./,$!d'
}

# ---------- Test 1: Skill name = tdd-release ----------

function test_skill_name_is_tdd_release() {
  assert_file_exists "$SKILL_FILE"
  local name
  name=$(get_frontmatter | grep '^name:' | sed 's/^name: *//')
  assert_equals "tdd-release" "$name"
}

# ---------- Test 2: Skill agent = tdd-releaser ----------

function test_skill_agent_is_tdd_releaser() {
  assert_file_exists "$SKILL_FILE"
  local agent
  agent=$(get_frontmatter | grep '^agent:' | sed 's/^agent: *//')
  assert_equals "tdd-releaser" "$agent"
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

# ---------- Test 5: Body contains all release workflow steps ----------

function test_body_contains_release_workflow_steps() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)

  # Verify slices terminal in .tdd-progress.md
  assert_contains ".tdd-progress.md" "$body"
  assert_matches "terminal|slices.*terminal|all.*slices" "$body"

  # Refuse to release from main/master
  assert_matches "main|master" "$body"
  assert_matches "refuse|reject|abort|block|stop" "$body"

  # Run test suite
  assert_matches "test suite|flutter test|ctest|bashunit" "$body"

  # Run static analysis
  assert_matches "static analysis|analyze|shellcheck|clang-tidy" "$body"

  # Run formatter (project-type aware)
  assert_matches "format|formatter" "$body"

  # Update CHANGELOG.md
  assert_contains "CHANGELOG" "$body"

  # Create PR via gh
  assert_contains "gh pr create" "$body"

  # Optional cleanup of .tdd-progress.md
  assert_matches "cleanup|clean up|remove|archive" "$body"
}

# ---------- Test 6: Description contains trigger phrases ----------

function test_description_contains_trigger_phrases() {
  assert_file_exists "$SKILL_FILE"
  local frontmatter
  frontmatter=$(get_frontmatter)

  # Extract the description field (may be multi-line with > or |)
  local description
  description=$(echo "$frontmatter" | sed -n '/^description:/,/^[a-z]/p' | head -n -1)

  assert_matches "release" "$description"
  assert_matches "finalize" "$description"
  assert_matches "publish" "$description"
}
