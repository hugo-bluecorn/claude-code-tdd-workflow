#!/bin/bash

# Test suite for role-format.md — Role File Format specification
# Verifies output convention, skill frontmatter documentation, and filename convention.

FORMAT_FILE="skills/role-init/reference/role-format.md"

# Helper: extract the Output convention paragraph (lines around "Output convention:")
get_output_convention() {
  sed -n '/\*\*Output convention:\*\*/,/^$/p' "$FORMAT_FILE"
}

# Helper: extract section 1 (YAML Frontmatter section)
get_section_1() {
  sed -n '/^## 1\. YAML Frontmatter/,/^## [0-9]/p' "$FORMAT_FILE" | sed '$d'
}

# Helper: extract body outside code blocks (for placeholder scanning)
get_body_no_code() {
  awk '/^```/{skip=!skip; next} !skip{print}' "$FORMAT_FILE"
}

# ---------- Test 1: Format spec contains .claude/skills/ output convention ----------

function test_output_convention_references_claude_skills_path() {
  local output_convention
  output_convention=$(get_output_convention)

  assert_contains ".claude/skills/role-" "$output_convention"
  assert_contains "SKILL.md" "$output_convention"
}

# ---------- Test 2: Format spec does NOT reference context/roles/ as output convention ----------

function test_output_convention_does_not_reference_context_roles() {
  local output_convention
  output_convention=$(get_output_convention)

  assert_not_contains "context/roles/" "$output_convention"
}

# ---------- Test 3: Format spec documents skill frontmatter fields ----------

function test_section_1_documents_skill_frontmatter_fields() {
  local section_1
  section_1=$(get_section_1)

  assert_contains "description" "$section_1"
  assert_contains "disable-model-invocation" "$section_1"
}

# ---------- Test 4: Format spec filename convention reflects SKILL.md ----------

function test_output_convention_mentions_skill_md_filename() {
  local output_convention
  output_convention=$(get_output_convention)

  assert_contains "SKILL.md" "$output_convention"
}

# ---------- Test 5: No unresolved placeholders outside code blocks ----------

function test_no_unresolved_placeholders_outside_code_blocks() {
  local body_no_code
  body_no_code=$(get_body_no_code)

  # Check for {word} patterns that are NOT inside backtick spans
  # Strip inline code spans first
  local stripped
  stripped=$(echo "$body_no_code" | sed 's/`[^`]*`//g')

  # Should not contain {word} placeholders
  local placeholders
  placeholders=$(echo "$stripped" | grep -oE '\{[a-zA-Z_][a-zA-Z0-9_]*\}' || true)

  assert_empty "$placeholders"
}
