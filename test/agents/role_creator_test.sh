#!/bin/bash

# Test suite for role-creator agent definition
# Verifies frontmatter, body content, and CLAUDE.md documentation.

AGENT_FILE="agents/role-creator.md"

# Helper: extract YAML frontmatter (between --- delimiters)
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$AGENT_FILE" | sed '1d;$d'
}

# Helper: extract body (after frontmatter)
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$AGENT_FILE" | sed '/./,$!d'
}

# ========== Slice 1: Agent Frontmatter ==========

# ---------- Test 1: Agent file exists at correct path ----------

function test_agent_file_exists() {
  assert_file_exists "$AGENT_FILE"
}

# ---------- Test 2: Frontmatter name field is "role-creator" ----------

function test_frontmatter_name_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "name: role-creator" "$frontmatter"
}

# ---------- Test 3: Frontmatter description mentions role creation ----------

function test_frontmatter_description_mentions_role() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "description:" "$frontmatter"
  assert_contains "role" "$frontmatter"
}

# ---------- Test 4: Tools field includes Read, Bash, Glob, Grep, WebSearch, WebFetch ----------

function test_tools_includes_required_tools() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "Read" "$frontmatter"
  assert_contains "Bash" "$frontmatter"
  assert_contains "Glob" "$frontmatter"
  assert_contains "Grep" "$frontmatter"
  assert_contains "WebSearch" "$frontmatter"
  assert_contains "WebFetch" "$frontmatter"
}

# ---------- Test 5: Tools field does NOT include Write or Edit ----------

function test_tools_excludes_write_edit() {
  local tools_line
  tools_line=$(get_frontmatter | grep '^tools:')
  assert_not_contains "Write" "$tools_line"
  assert_not_contains "Edit" "$tools_line"
}

# ---------- Test 6: No disallowedTools field ----------

function test_no_disallowed_tools_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "disallowedTools" "$frontmatter"
}

# ---------- Test 7: Model field is set ----------

function test_model_field_present() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "model:" "$frontmatter"
}

# ---------- Test 8: No memory field ----------

function test_no_memory_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "memory:" "$frontmatter"
}

# ---------- Test 9: No hooks in frontmatter ----------

function test_no_hooks_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "hooks:" "$frontmatter"
}

# ---------- Test 10: No skills in frontmatter ----------

function test_no_skills_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "skills:" "$frontmatter"
}

# ---------- Test 11: No context or agent field in frontmatter ----------

function test_no_context_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "context:" "$frontmatter"
}

function test_no_agent_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "agent:" "$frontmatter"
}
