#!/bin/bash

# Test suite for skills/c-conventions/SKILL.md structure

SKILL_DIR="skills/c-conventions"
SKILL_FILE="${SKILL_DIR}/SKILL.md"
REF_DIR="${SKILL_DIR}/reference"

# ---------- Test 1: SKILL.md exists with correct frontmatter ----------

function test_skill_file_exists() {
  assert_file_exists "$SKILL_FILE"
}

function test_frontmatter_has_correct_name() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
  assert_contains "name: c-conventions" "$frontmatter"
}

function test_frontmatter_has_user_invocable_false() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
  assert_contains "user-invocable: false" "$frontmatter"
}

# ---------- Test 2: Frontmatter description references C testing and coding standards ----------

function test_frontmatter_description_references_c_language() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
  # Description should reference C language
  assert_matches "C " "$frontmatter"
}

function test_frontmatter_description_references_testing() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
  assert_contains "testing" "$frontmatter"
}

function test_frontmatter_description_references_standards_or_analysis() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
  # Should reference coding standards or static analysis
  assert_matches "(coding standards|static analysis)" "$frontmatter"
}

# ---------- Test 3: SKILL.md content references c-testing-patterns.md ----------

function test_content_references_c_testing_patterns() {
  assert_file_contains "$SKILL_FILE" "reference/c-testing-patterns.md"
}

# ---------- Test 4: SKILL.md content references c-coding-standards.md ----------

function test_content_references_c_coding_standards() {
  assert_file_contains "$SKILL_FILE" "reference/c-coding-standards.md"
}

# ---------- Test 5: SKILL.md content references c-static-analysis.md ----------

function test_content_references_c_static_analysis() {
  assert_file_contains "$SKILL_FILE" "reference/c-static-analysis.md"
}

# ---------- Test 6: SKILL.md includes a Running Tests section ----------

function test_content_has_running_tests_section() {
  assert_file_contains "$SKILL_FILE" "## Running Tests"
}

function test_running_tests_section_is_build_system_agnostic() {
  # Should not mandate a specific build system; should be general guidance
  local body
  body=$(sed -n '/^---$/,/^---$/d; p' "$SKILL_FILE" | sed '/./,$!d')
  # Should mention building/running tests generically
  assert_contains "build" "$body"
}

# ---------- Test 7: Reference directory structure exists ----------

function test_reference_c_testing_patterns_exists() {
  assert_file_exists "${REF_DIR}/c-testing-patterns.md"
}

function test_reference_c_coding_standards_exists() {
  assert_file_exists "${REF_DIR}/c-coding-standards.md"
}

function test_reference_c_static_analysis_exists() {
  assert_file_exists "${REF_DIR}/c-static-analysis.md"
}

# ---------- Test 8: No unfilled template placeholders in SKILL.md ----------

function test_no_unfilled_template_placeholders() {
  # Search for { characters, excluding lines with C function syntax () {
  local placeholder_lines
  placeholder_lines=$(grep '{' "$SKILL_FILE" | grep -v '() {' || true)
  assert_empty "$placeholder_lines"
}

# ---------- Test 9: All reference/ paths in SKILL.md point to existing files ----------

function test_all_reference_paths_resolve_to_existing_files() {
  local ref_paths
  ref_paths=$(grep -oP 'reference/[a-z0-9_-]+\.md' "$SKILL_FILE" | sort -u)
  assert_not_empty "$ref_paths"

  local all_exist="true"
  local missing=""
  while IFS= read -r ref_path; do
    if [[ ! -f "${SKILL_DIR}/${ref_path}" ]]; then
      all_exist="false"
      missing="${missing} ${ref_path}"
    fi
  done <<< "$ref_paths"

  assert_equals "true" "$all_exist"
}
