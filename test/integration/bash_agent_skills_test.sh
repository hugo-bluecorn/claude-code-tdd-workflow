#!/bin/bash

# Test suite for agent frontmatter and tdd-plan SKILL.md bash-testing-conventions integration

PLANNER_FILE="agents/tdd-planner.md"
IMPLEMENTER_FILE="agents/tdd-implementer.md"
TDD_PLAN_SKILL="skills/tdd-plan/SKILL.md"

# ---------- Test 1: Planner agent references bash-testing-conventions ----------

function test_planner_file_exists() {
  assert_file_exists "$PLANNER_FILE"
}

function test_planner_skills_include_project_conventions() {
  # The skills list in frontmatter must include project-conventions (replaces individual convention skills)
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$PLANNER_FILE")
  assert_contains "project-conventions" "$frontmatter"
}

# ---------- Test 2: Implementer agent references bash-testing-conventions ----------

function test_implementer_file_exists() {
  assert_file_exists "$IMPLEMENTER_FILE"
}

function test_implementer_skills_include_project_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$IMPLEMENTER_FILE")
  assert_contains "project-conventions" "$frontmatter"
}

# ---------- Test 3: tdd-plan SKILL.md exists and delegates to planner ----------

function test_tdd_plan_skill_file_exists() {
  assert_file_exists "$TDD_PLAN_SKILL"
}

# After the inline orchestration rewrite, project detection and framework
# listing live in the planner agent body, not the skill. Verify the planner
# agent body has them instead.

function test_planner_body_delegates_convention_loading() {
  # Planner agent body delegates convention loading to project-conventions skill
  assert_file_contains "$PLANNER_FILE" "project-conventions"
}

function test_planner_body_delegates_to_project_conventions() {
  # Planner agent body delegates convention loading to project-conventions skill
  assert_file_contains "$PLANNER_FILE" "project-conventions"
}

function test_planner_body_has_research_methodology() {
  # Planner agent body should have research methodology section
  assert_file_contains "$PLANNER_FILE" "Research the codebase"
}

# ---------- Edge Cases: Additive-only ----------

function test_planner_uses_project_conventions_skill() {
  # Verify project-conventions replaces individual convention skills
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$PLANNER_FILE")
  assert_contains "project-conventions" "$frontmatter"
}

function test_implementer_uses_project_conventions_skill() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$IMPLEMENTER_FILE")
  assert_contains "project-conventions" "$frontmatter"
}

function test_planner_body_has_dart_detection() {
  # Planner agent body should have Dart/Flutter detection (pubspec.yaml)
  assert_file_contains "$PLANNER_FILE" "pubspec.yaml"
}

function test_planner_body_has_cpp_detection() {
  # Planner agent body should have C++ detection (CMakeLists.txt)
  assert_file_contains "$PLANNER_FILE" "CMakeLists.txt"
}

function test_planner_body_identifies_test_frameworks() {
  # Planner agent body should instruct identifying test frameworks
  assert_file_contains "$PLANNER_FILE" "test frameworks"
}
