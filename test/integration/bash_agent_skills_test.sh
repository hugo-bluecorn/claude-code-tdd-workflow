#!/bin/bash

# Test suite for agent frontmatter and tdd-plan SKILL.md — project-conventions integration
# Originally tested bash-testing-conventions; updated for project-conventions migration.

PLANNER_FILE="agents/tdd-planner.md"
IMPLEMENTER_FILE="agents/tdd-implementer.md"
TDD_PLAN_SKILL="skills/tdd-plan/SKILL.md"

# ---------- Test 1: Planner agent uses project-conventions ----------

function test_planner_file_exists() {
  assert_file_exists "$PLANNER_FILE"
}

function test_planner_skills_include_project_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$PLANNER_FILE")
  assert_contains "project-conventions" "$frontmatter"
}

# ---------- Test 2: Implementer agent uses project-conventions ----------

function test_implementer_file_exists() {
  assert_file_exists "$IMPLEMENTER_FILE"
}

function test_implementer_skills_include_project_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$IMPLEMENTER_FILE")
  assert_contains "project-conventions" "$frontmatter"
}

# ---------- Test 3: tdd-plan SKILL.md exists ----------

function test_tdd_plan_skill_file_exists() {
  assert_file_exists "$TDD_PLAN_SKILL"
}

# ---------- Test 4: Planner body delegates convention loading ----------

function test_planner_body_delegates_convention_loading() {
  assert_file_contains "$PLANNER_FILE" "project-conventions"
}

function test_planner_body_has_research_methodology() {
  assert_file_contains "$PLANNER_FILE" "Research the codebase"
}

# ---------- Test 5: Planner body retains project detection ----------

function test_planner_body_has_dart_detection() {
  assert_file_contains "$PLANNER_FILE" "pubspec.yaml"
}

function test_planner_body_has_cpp_detection() {
  assert_file_contains "$PLANNER_FILE" "CMakeLists.txt"
}

function test_planner_body_identifies_test_frameworks() {
  assert_file_contains "$PLANNER_FILE" "test frameworks"
}
