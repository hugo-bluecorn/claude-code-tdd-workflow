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

# Helper: extract the description frontmatter field value
get_description() {
  get_frontmatter | sed -n '/^description:/,/^[a-z]/p' | head -n -1 | sed 's/^description: *>*//'
}

# ===== Preserved existing tests (unchanged behavior) =====

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

# ---------- Test: Body mentions constraints (CHANGELOG do not modify) ----------

function test_body_mentions_constraints() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)
  assert_matches "Do NOT modify CHANGELOG|do not modify CHANGELOG|CHANGELOG.*read.only|not.*modify.*CHANGELOG" "$body"
}

# ===== New Slice 5 tests =====

# ---------- Slice 5 Test 13: Skill description has no plugin-specific language ----------

function test_description_has_no_plugin_specific_language() {
  assert_file_exists "$SKILL_FILE"
  local description
  description=$(get_description)

  assert_not_contains "plugin.json" "$description"
  assert_not_contains "tdd-workflow plugin" "$description"

  # Must describe generic documentation finalization
  assert_matches "documentation" "$description"
}

# ---------- Slice 5 Test 14: Skill body does NOT reference plugin.json ----------

function test_body_does_not_reference_plugin_json() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)
  assert_not_contains "plugin.json" "$body"
}

# ---------- Slice 5 Test 15: Skill body references documentation discovery ----------

function test_body_references_documentation_discovery() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)
  assert_matches "discover|detect-doc-context" "$body"
}

# ---------- Slice 5 Test 16: Skill body does NOT reference version bumping as a step ----------

function test_body_does_not_reference_version_bumping() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)
  assert_not_matches "Bump version" "$body"
  assert_not_matches "version bump" "$body"
}

# ---------- Slice 5 Test 17: Skill body still mentions CHANGELOG as read-only reference ----------

function test_body_mentions_changelog_as_read_only_reference() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)
  assert_contains "CHANGELOG" "$body"
  assert_matches "Read.*CHANGELOG|CHANGELOG.*understand|CHANGELOG.*what changed|CHANGELOG.*source" "$body"
}

# ---------- Slice 5 Test 18: Skill body mentions running project tests for verification ----------

function test_body_mentions_running_tests_generically() {
  assert_file_exists "$SKILL_FILE"
  local body
  body=$(get_body)

  # Must reference running tests
  assert_matches "test|Test" "$body"

  # Must NOT contain hardcoded bashunit paths
  assert_not_contains "release_version_test.sh" "$body"
}

# ---------- Slice 5 Test 20: Skill frontmatter fields unchanged ----------

function test_skill_frontmatter_fields_unchanged() {
  assert_file_exists "$SKILL_FILE"
  local frontmatter
  frontmatter=$(get_frontmatter)

  local name agent context disable_model
  name=$(echo "$frontmatter" | grep '^name:' | sed 's/^name: *//')
  agent=$(echo "$frontmatter" | grep '^agent:' | sed 's/^agent: *//')
  context=$(echo "$frontmatter" | grep '^context:' | sed 's/^context: *//')
  disable_model=$(echo "$frontmatter" | grep '^disable-model-invocation:' | sed 's/^disable-model-invocation: *//')

  assert_equals "tdd-finalize-docs" "$name"
  assert_equals "tdd-doc-finalizer" "$agent"
  assert_equals "fork" "$context"
  assert_equals "true" "$disable_model"
}
