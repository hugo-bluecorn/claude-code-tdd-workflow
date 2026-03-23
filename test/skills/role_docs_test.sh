#!/bin/bash

# Test suite for documentation references to /role-create
# Verifies CLAUDE.md, README.md, and user-guide.md use /role-create (not /role-cr).

CLAUDE_MD="CLAUDE.md"
README_MD="README.md"
USER_GUIDE="docs/user-guide.md"

# Helper: extract /role-create lines from a file
get_role_create_lines() {
  local file="$1"
  grep '/role-create' "$file"
}

# ---------- Test 1: CLAUDE.md prime directive references /role-create ----------

function test_claude_md_prime_directive_role_create() {
  local prime_line
  prime_line=$(grep "PRIME DIRECTIVE" "$CLAUDE_MD")
  assert_contains "/role-create" "$prime_line"
}

# ---------- Test 2: CLAUDE.md command table lists /role-create ----------

function test_claude_md_commands_has_role_create() {
  assert_file_contains "$CLAUDE_MD" '`/role-create`'
}

# ---------- Test 3: CLAUDE.md agent table mentions /role-create ----------

function test_claude_md_agent_table_role_create() {
  local row
  row=$(grep "role-creator" "$CLAUDE_MD" | head -1)
  assert_contains "/role-create" "$row"
}

# ---------- Test 4: README.md skill table lists /role-create ----------

function test_readme_skill_table_role_create() {
  assert_file_contains "$README_MD" '`/role-create`'
}

# ---------- Test 5: README.md directory tree shows role-create ----------

function test_readme_directory_tree_role_create() {
  assert_file_contains "$README_MD" "role-create/"
}

# ---------- Test 6: user-guide.md references /role-create ----------

function test_user_guide_role_create() {
  assert_file_contains "$USER_GUIDE" "/role-create"
}

# ---------- Test 7: CLAUDE.md /role-create description references .claude/skills/ ----------

function test_claude_md_role_create_references_claude_skills() {
  local lines
  lines=$(get_role_create_lines "$CLAUDE_MD")
  assert_contains ".claude/skills/" "$lines"
}

# ---------- Test 8: README.md /role-create description references .claude/skills/ ----------

function test_readme_role_create_references_claude_skills() {
  local lines
  lines=$(get_role_create_lines "$README_MD")
  assert_contains ".claude/skills/" "$lines"
}

# ---------- Test 9: No /role-cr references remain in CLAUDE.md ----------

function test_no_role_cr_in_claude_md() {
  local content stripped
  content=$(cat "$CLAUDE_MD")
  stripped=$(echo "$content" | sed 's|/role-create||g')
  assert_not_contains "/role-cr" "$stripped"
}

# ---------- Test 10: No /role-cr references remain in README.md ----------

function test_no_role_cr_in_readme() {
  local content stripped
  content=$(cat "$README_MD")
  stripped=$(echo "$content" | sed 's|/role-create||g')
  assert_not_contains "/role-cr" "$stripped"
}

# ---------- Test 11: No /role-cr references remain in user-guide.md ----------

function test_no_role_cr_in_user_guide() {
  local content stripped
  content=$(cat "$USER_GUIDE")
  stripped=$(echo "$content" | sed 's|/role-create||g')
  assert_not_contains "/role-cr" "$stripped"
}
