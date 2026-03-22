#!/bin/bash

# Test suite for cr-role-creator.md — CR role file path references
# Verifies all role output path references use .claude/skills/ convention.

CR_FILE="skills/role-init/reference/cr-role-creator.md"

# Helper: extract a section by heading name (## level)
get_section() {
  local heading="$1"
  sed -n "/^## ${heading}$/,/^## /p" "$CR_FILE" | sed '$d'
}

# ---------- Test 1: CR Constraints section references .claude/skills/ path ----------

function test_constraints_references_claude_skills_path() {
  local constraints
  constraints=$(get_section "Constraints")

  assert_contains ".claude/skills/" "$constraints"
}

# ---------- Test 2: CR Constraints section does NOT reference context/roles/ ----------

function test_constraints_does_not_reference_context_roles() {
  local constraints
  constraints=$(get_section "Constraints")

  assert_not_contains "context/roles/" "$constraints"
}

# ---------- Test 3: CR Startup section references .claude/skills/ for existing role check ----------

function test_startup_references_claude_skills_path() {
  local startup
  startup=$(get_section "Startup")

  assert_contains ".claude/skills/" "$startup"
}

# ---------- Test 4: CR Workflow Approve step references .claude/skills/ ----------

function test_workflow_approve_references_claude_skills_path() {
  local workflow
  workflow=$(get_section "Workflow")

  assert_contains ".claude/skills/" "$workflow"
}

# ---------- Test 5: CR file has no remaining references to context/roles/ ----------

function test_no_remaining_context_roles_references() {
  assert_file_not_contains "$CR_FILE" "context/roles/"
}
