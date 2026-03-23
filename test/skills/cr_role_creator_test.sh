#!/bin/bash

# Test suite for cr-role-creator.md — CR role file path references
# Verifies all role output path references use .claude/skills/ convention.

CR_FILE="skills/role-init/reference/cr-role-creator.md"

# Helper: extract a section by heading name (## level)
get_section() {
  local heading="$1"
  sed -n "/^## ${heading}$/,/^## /p" "$CR_FILE" | sed '$d'
}

# Helper: extract YAML frontmatter (between --- delimiters)
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$CR_FILE" | sed '1d;$d'
}

# ---------- Test 1: CR file has version 3 in frontmatter ----------

function test_frontmatter_version_3() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "version: 3" "$frontmatter"
}

# ---------- Test 2: CR file does not contain "optional" in Constraints ----------

function test_constraints_no_optional_framing() {
  local constraints
  constraints=$(get_section "Constraints")
  # v3 removed "Roles are optional context" wording
  assert_not_contains "optional" "$constraints"
}

# ---------- Test 3: CR file references .claude/skills/ path ----------

function test_file_references_claude_skills_path() {
  assert_file_contains "$CR_FILE" ".claude/skills/"
}

# ---------- Test 4: No context/roles/ references remain ----------

function test_no_remaining_context_roles_references() {
  assert_file_not_contains "$CR_FILE" "context/roles/"
}

# ---------- Test 5: Startup section references .claude/skills/ path ----------

function test_startup_references_claude_skills_path() {
  local startup
  startup=$(get_section "Startup")

  assert_contains ".claude/skills/" "$startup"
}

# ---------- Test 6: Identity section exists ----------

function test_identity_section_exists() {
  assert_file_contains "$CR_FILE" "## Identity"
}

# ---------- Test 7: No skill frontmatter fields in CR file ----------

function test_no_skill_frontmatter_fields() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "description:" "$frontmatter"
  assert_not_contains "disable-model-invocation:" "$frontmatter"
}

# ---------- Test 8: Generator field shows /role-create ----------

function test_generator_field_role_create() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "generator: /role-create" "$frontmatter"
}
