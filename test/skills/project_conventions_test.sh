#!/bin/bash

# Test suite for project-conventions skill structure

SKILL_DIR="skills/project-conventions"
SKILL_FILE="${SKILL_DIR}/SKILL.md"

# ---------- Test 1: SKILL.md file exists ----------

function test_skill_file_exists() {
  assert_file_exists "$SKILL_FILE"
}

# ---------- Test 2: Frontmatter has correct name ----------

function test_frontmatter_name_field() {
  assert_file_contains "$SKILL_FILE" "name: project-conventions"
}

# ---------- Test 3: Frontmatter has user-invocable false ----------

function test_frontmatter_user_invocable_false() {
  assert_file_contains "$SKILL_FILE" "user-invocable: false"
}

# ---------- Test 4: Body contains DCI invocation of load-conventions.sh ----------

function test_body_contains_dci_invocation() {
  local content
  content=$(cat "$SKILL_FILE")
  # DCI syntax: !`path/to/script`
  assert_contains "load-conventions.sh" "$content"
  # Verify it uses the !` DCI pattern (backtick after !)
  assert_contains '!`' "$content"
}

function test_dci_references_plugin_root_variable() {
  local content
  content=$(cat "$SKILL_FILE")
  assert_contains 'CLAUDE_PLUGIN_ROOT' "$content"
}

# ---------- Test 5: Description references dynamic convention loading ----------

function test_description_mentions_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE")
  assert_contains "conventions" "$frontmatter"
}

function test_description_mentions_project() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE")
  assert_contains "project" "$frontmatter"
}

# ---------- Test 6: No unfilled template placeholders ----------

function test_no_unfilled_template_placeholders() {
  assert_file_exists "$SKILL_FILE"
  local content
  content=$(cat "$SKILL_FILE")
  # Match {placeholder} but not ${VARIABLE} (shell variables are intentional)
  local stripped
  stripped=$(echo "$content" | sed 's/\${[^}]*}//g')
  assert_not_matches '\{[a-zA-Z_]+\}' "$stripped"
}
