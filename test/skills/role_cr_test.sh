#!/bin/bash

# Test suite for role-cr SKILL.md — inline skill definition
# Verifies the skill file structure, frontmatter, DCI loading,
# approval gate, and validation script invocation.

SKILL_FILE="skills/role-cr/SKILL.md"

# Helper: extract YAML frontmatter (between --- delimiters)
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d'
}

# Helper: extract body (after frontmatter)
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$SKILL_FILE" | sed '/./,$!d'
}

# ---------- Test 1: Skill file exists at correct path ----------

function test_skill_file_exists() {
  assert_file_exists "$SKILL_FILE"
}

# ---------- Test 2: Frontmatter name field is "role-cr" ----------

function test_frontmatter_name_field() {
  assert_file_contains "$SKILL_FILE" "name: role-cr"
}

# ---------- Test 3: Frontmatter has disable-model-invocation: true ----------

function test_frontmatter_disable_model_invocation() {
  assert_file_contains "$SKILL_FILE" "disable-model-invocation: true"
}

# ---------- Test 4: Frontmatter does NOT have context: fork or agent: field ----------

function test_no_fork_context() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "context:" "$frontmatter"
}

function test_no_agent_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "agent:" "$frontmatter"
}

# ---------- Test 5: Body loads CR role content via DCI ----------

function test_body_loads_cr_role_via_dci() {
  local content
  content=$(cat "$SKILL_FILE")
  assert_contains '!`' "$content"
  assert_contains "cr-role-creator.md" "$content"
}

# ---------- Test 6: Body loads format spec via DCI ----------

function test_body_loads_format_spec_via_dci() {
  local content
  content=$(cat "$SKILL_FILE")
  assert_contains '!`' "$content"
  assert_contains "role-format.md" "$content"
}

# ---------- Test 7: Body contains Approve/Modify/Reject gate ----------

function test_body_contains_approve() {
  local body
  body=$(get_body)
  assert_contains "Approve" "$body"
}

function test_body_contains_modify() {
  local body
  body=$(get_body)
  assert_contains "Modify" "$body"
}

function test_body_contains_reject() {
  local body
  body=$(get_body)
  assert_contains "Reject" "$body"
}

# ---------- Test 8: Body contains generator field assignment ----------

function test_body_contains_generator_field() {
  local body
  body=$(get_body)
  assert_contains "generator" "$body"
  assert_contains "/role-cr" "$body"
}

# ---------- Test 9: Body contains validate-role-output.sh invocation ----------

function test_body_contains_validation_script() {
  local body
  body=$(get_body)
  assert_contains "validate-role-output.sh" "$body"
}

# ---------- Test 10: Body contains context/roles/ directory creation ----------

function test_body_contains_roles_directory() {
  local body
  body=$(get_body)
  assert_contains "context/roles/" "$body"
}

# ---------- Test 11: Body contains write-after-approve ordering ----------

function test_write_instruction_after_approval() {
  local approve_line write_line
  approve_line=$(grep -n "Approve" "$SKILL_FILE" | head -1 | cut -d: -f1)
  write_line=$(grep -n "context/roles/" "$SKILL_FILE" | head -1 | cut -d: -f1)
  assert_not_empty "$approve_line"
  assert_not_empty "$write_line"
  # The approval gate must appear before the write-to-disk instruction
  # assert_greater_or_equal_than expected actual => checks actual >= expected
  assert_greater_or_equal_than "$approve_line" "$write_line"
}

# ---------- Test 12: No template placeholders in skill file ----------

function test_no_template_placeholders() {
  local content stripped
  content=$(cat "$SKILL_FILE")
  # Strip ${VARIABLE} patterns (shell variables are intentional in DCI)
  stripped=${content//\$\{*\}/}
  assert_not_matches '\{[a-zA-Z_]+\}' "$stripped"
}

# ---------- Test 13: No references to /role-init ----------

function test_no_role_init_references() {
  local body
  body=$(get_body)
  # Strip file paths (skills/role-init/reference/ is a valid directory path)
  # Check for /role-init as a standalone command reference
  local stripped
  stripped=$(echo "$body" | sed 's|skills/role-init/reference/[^ ]*||g')
  assert_not_contains "/role-init" "$stripped"
}
