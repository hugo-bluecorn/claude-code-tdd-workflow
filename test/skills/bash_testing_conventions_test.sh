#!/bin/bash

# Test suite for bash-testing-conventions skill structure

SKILL_DIR="skills/bash-testing-conventions"
SKILL_FILE="${SKILL_DIR}/SKILL.md"
REF_DIR="${SKILL_DIR}/reference"

# ---------- Test 1: SKILL.md exists with correct frontmatter ----------

function test_skill_file_exists() {
  assert_file_exists "$SKILL_FILE"
}

function test_frontmatter_delimited_by_markers() {
  local first_line
  first_line=$(head -n 1 "$SKILL_FILE")
  assert_equals "---" "$first_line"

  # Find the closing --- (second occurrence, skipping line 1)
  local closing_line
  closing_line=$(tail -n +2 "$SKILL_FILE" | grep -n "^---$" | head -1 | cut -d: -f1)
  assert_not_empty "$closing_line"
}

function test_frontmatter_name_field() {
  assert_file_contains "$SKILL_FILE" "name: bash-testing-conventions"
}

function test_frontmatter_description_references_bash_bashunit_shellcheck() {
  # Extract the description block (between the --- markers)
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE")

  assert_contains "bash" "$frontmatter"
  assert_contains "bashunit" "$frontmatter"
  assert_contains "shellcheck" "$frontmatter"
}

function test_frontmatter_user_invocable_false() {
  assert_file_contains "$SKILL_FILE" "user-invocable: false"
}

# ---------- Test 2: SKILL.md content references all reference docs ----------

function test_content_references_bashunit_patterns() {
  assert_file_contains "$SKILL_FILE" "reference/bashunit-patterns.md"
}

function test_content_references_shellcheck_guide() {
  assert_file_contains "$SKILL_FILE" "reference/shellcheck-guide.md"
}

function test_content_includes_running_tests_section() {
  assert_file_contains "$SKILL_FILE" "## Running Tests"
}

function test_running_tests_section_has_bashunit_commands() {
  # The Running Tests section should contain actual bashunit invocation examples
  assert_file_contains "$SKILL_FILE" "bashunit"
}

# ---------- Test 3: Reference directory structure exists ----------

function test_bashunit_patterns_reference_exists() {
  assert_file_exists "${REF_DIR}/bashunit-patterns.md"
}

function test_shellcheck_guide_reference_exists() {
  assert_file_exists "${REF_DIR}/shellcheck-guide.md"
}

# ---------- Edge Cases: Content completeness ----------

function test_no_unfilled_template_placeholders() {
  # File must exist first
  assert_file_exists "$SKILL_FILE"
  # Ensure no {placeholder} patterns remain (common in templates)
  assert_file_not_contains "$SKILL_FILE" "{"
}

function test_valid_markdown_no_broken_reference_links() {
  # File must exist first
  assert_file_exists "$SKILL_FILE"
  # Extract all reference/ paths mentioned in the file and verify they exist
  local ref_paths
  ref_paths=$(grep -oP 'reference/[a-z0-9_-]+\.md' "$SKILL_FILE" | sort -u)

  assert_not_empty "$ref_paths"
  for ref_path in $ref_paths; do
    local full_path="${SKILL_DIR}/${ref_path}"
    assert_file_exists "$full_path"
  done
}
