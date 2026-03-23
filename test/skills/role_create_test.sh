#!/bin/bash

# Test suite for role-create SKILL.md — inline skill definition
# Verifies the skill file structure, frontmatter, DCI loading,
# approval gate, and validation script invocation.

SKILL_FILE="skills/role-create/SKILL.md"

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

# ---------- Test 1b: Old skill directory does not exist ----------

function test_old_directory_does_not_exist() {
  assert_directory_not_exists "skills/role-cr"
}

# ---------- Test 1c: No /role-cr references remain in skill file ----------

function test_no_role_cr_references_in_skill_file() {
  local content
  content=$(cat "$SKILL_FILE")
  # Strip /role-create occurrences first, then check for /role-cr
  local stripped
  stripped=$(echo "$content" | sed 's|/role-create||g')
  assert_not_contains "/role-cr" "$stripped"
}

# ---------- Test 2: Frontmatter name field is "role-create" ----------

function test_frontmatter_name_field() {
  assert_file_contains "$SKILL_FILE" "name: role-create"
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

# ---------- Test 5: Body does NOT contain any DCI commands ----------

function test_body_no_dci_commands() {
  local content
  content=$(cat "$SKILL_FILE")
  assert_not_contains '!`' "$content"
}

# ---------- Test 6: Body does NOT reference load-role-references.sh ----------

function test_body_no_load_references_script() {
  local body
  body=$(get_body)
  assert_not_contains "load-role-references.sh" "$body"
}

# ---------- Test 6b: Skill description reflects orchestration pattern ----------

function test_description_reflects_orchestration() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  local description
  description=$(echo "$frontmatter" | sed -n '/^description:/,/^[a-z]/p' | sed '$d')
  assert_contains "role-creator" "$description"
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
  assert_contains "/role-create" "$body"
}

# ---------- Test 9: Body does NOT contain validate-role-output.sh ----------

function test_body_no_validation_script() {
  local body
  body=$(get_body)
  assert_not_contains "validate-role-output.sh" "$body"
}

# ---------- Test 10: Body contains .claude/skills/ output path ----------

function test_body_contains_claude_skills_output_path() {
  local body
  body=$(get_body)
  assert_contains ".claude/skills/" "$body"
}

# ---------- Test 11: Body does NOT contain context/roles/ output path ----------

function test_body_does_not_contain_context_roles() {
  local body
  body=$(get_body)
  assert_not_contains "context/roles/" "$body"
}

# ---------- Test 12: Body instructs mkdir -p .claude/skills/ ----------

function test_body_contains_mkdir_claude_skills() {
  local body
  body=$(get_body)
  assert_contains "mkdir -p" "$body"
  assert_contains ".claude/skills/" "$body"
}

# ---------- Test 13: Body instructs writing SKILL.md filename ----------

function test_body_contains_skill_md_filename() {
  local body
  body=$(get_body)
  assert_contains "SKILL.md" "$body"
}

# ---------- Test 14: Body instructs skill frontmatter injection ----------

function test_body_contains_skill_frontmatter_instructions() {
  local body
  body=$(get_body)
  assert_contains "name" "$body"
  assert_contains "description" "$body"
  assert_contains "disable-model-invocation" "$body"
}

# ---------- Test 15: Write instruction after approval (updated path) ----------

function test_write_instruction_after_approval() {
  local approve_line write_line
  approve_line=$(grep -n "Approve" "$SKILL_FILE" | head -1 | cut -d: -f1)
  write_line=$(grep -n ".claude/skills/" "$SKILL_FILE" | head -1 | cut -d: -f1)
  assert_not_empty "$approve_line"
  assert_not_empty "$write_line"
  # The approval gate must appear before the write-to-disk instruction
  assert_greater_or_equal_than "$approve_line" "$write_line"
}

# ---------- Test 16: No template placeholders in skill file ----------

function test_no_template_placeholders() {
  local content stripped
  content=$(cat "$SKILL_FILE")
  # Strip ${VARIABLE} patterns (shell variables are intentional)
  stripped=${content//\$\{*\}/}
  # Strip documented convention patterns like role-{code}
  stripped=$(echo "$stripped" | sed 's/role-{code}//g')
  assert_not_matches '\{[a-zA-Z_]+\}' "$stripped"
}

# ---------- Test 17: No references to /role-init ----------

function test_no_role_init_references() {
  local body
  body=$(get_body)
  # Strip file paths (skills/role-init/reference/ is a valid directory path)
  # Check for /role-init as a standalone command reference
  local stripped
  stripped=$(echo "$body" | sed 's|skills/role-init/reference/[^ ]*||g')
  assert_not_contains "/role-init" "$stripped"
}

# ========== Slice 4: Orchestration Body ==========

# ---------- Test 18: Body contains Agent tool spawning of role-creator ----------

function test_body_spawns_role_creator_agent() {
  local body
  body=$(get_body)
  assert_contains "Agent" "$body"
  assert_contains "role-creator" "$body"
}

# ---------- Test 19: Body contains input gathering step ----------

function test_body_contains_input_gathering() {
  local body
  body=$(get_body)
  assert_contains "tech stack" "$body"
}

# ---------- Test 20: Body does NOT duplicate agent procedure ----------

function test_body_no_rtfm_duplication() {
  local body
  body=$(get_body)
  assert_not_contains "RTFM" "$body"
}

# ---------- Test 21: Body does NOT contain validate-role-output.sh ----------

function test_body_no_validate_script_in_orchestration() {
  local body
  body=$(get_body)
  assert_not_contains "validate-role-output.sh" "$body"
}
