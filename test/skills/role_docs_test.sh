#!/bin/bash

# Test suite for documentation path references (Slice 5)
# Verifies CLAUDE.md and README.md use .claude/skills/ for /role-cr output path.

CLAUDE_MD="CLAUDE.md"
README_MD="README.md"

# Helper: extract the /role-cr line from a file
get_role_cr_line() {
  local file="$1"
  grep '/role-cr' "$file" | head -1
}

# ---------- Test 1: CLAUDE.md /role-cr description references .claude/skills/ ----------

function test_claude_md_role_cr_references_claude_skills() {
  local line
  line=$(get_role_cr_line "$CLAUDE_MD")

  assert_contains ".claude/skills/" "$line"
}

# ---------- Test 2: CLAUDE.md does not reference context/roles/ for /role-cr ----------

function test_claude_md_role_cr_does_not_reference_context_roles() {
  local line
  line=$(get_role_cr_line "$CLAUDE_MD")

  assert_not_contains "context/roles/" "$line"
}

# ---------- Test 3: README.md /role-cr description references .claude/skills/ ----------

function test_readme_role_cr_references_claude_skills() {
  local line
  line=$(get_role_cr_line "$README_MD")

  assert_contains ".claude/skills/" "$line"
}

# ---------- Test 4: README.md /role-cr does not reference context/roles/ ----------

function test_readme_role_cr_does_not_reference_context_roles() {
  local line
  line=$(get_role_cr_line "$README_MD")

  assert_not_contains "context/roles/" "$line"
}
