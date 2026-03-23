#!/bin/bash

# Test suite for documentation path references (Slice 5)
# Verifies CLAUDE.md and README.md use .claude/skills/ for /role-cr output path.

CLAUDE_MD="CLAUDE.md"
README_MD="README.md"

# Helper: extract /role-cr lines from a file (all occurrences)
get_role_cr_lines() {
  local file="$1"
  grep '/role-cr' "$file"
}

# ---------- Test 1: CLAUDE.md /role-cr command description references .claude/skills/ ----------

function test_claude_md_role_cr_references_claude_skills() {
  local lines
  lines=$(get_role_cr_lines "$CLAUDE_MD")

  assert_contains ".claude/skills/" "$lines"
}

# ---------- Test 2: CLAUDE.md does not reference context/roles/ for /role-cr ----------

function test_claude_md_role_cr_does_not_reference_context_roles() {
  local lines
  lines=$(get_role_cr_lines "$CLAUDE_MD")

  assert_not_contains "context/roles/" "$lines"
}

# ---------- Test 3: README.md /role-cr description references .claude/skills/ ----------

function test_readme_role_cr_references_claude_skills() {
  local lines
  lines=$(get_role_cr_lines "$README_MD")

  assert_contains ".claude/skills/" "$lines"
}

# ---------- Test 4: README.md /role-cr does not reference context/roles/ ----------

function test_readme_role_cr_does_not_reference_context_roles() {
  local lines
  lines=$(get_role_cr_lines "$README_MD")

  assert_not_contains "context/roles/" "$lines"
}
