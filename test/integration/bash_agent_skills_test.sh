#!/bin/bash

# Test suite for agent frontmatter and tdd-plan SKILL.md bash-testing-conventions integration

PLANNER_FILE="agents/tdd-planner.md"
IMPLEMENTER_FILE="agents/tdd-implementer.md"
TDD_PLAN_SKILL="skills/tdd-plan/SKILL.md"

# ---------- Test 1: Planner agent references bash-testing-conventions ----------

function test_planner_file_exists() {
  assert_file_exists "$PLANNER_FILE"
}

function test_planner_skills_include_bash_testing_conventions() {
  # The skills list in frontmatter must include bash-testing-conventions
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$PLANNER_FILE")
  assert_contains "bash-testing-conventions" "$frontmatter"
}

function test_planner_still_has_dart_flutter_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$PLANNER_FILE")
  assert_contains "dart-flutter-conventions" "$frontmatter"
}

function test_planner_still_has_cpp_testing_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$PLANNER_FILE")
  assert_contains "cpp-testing-conventions" "$frontmatter"
}

# ---------- Test 2: Implementer agent references bash-testing-conventions ----------

function test_implementer_file_exists() {
  assert_file_exists "$IMPLEMENTER_FILE"
}

function test_implementer_skills_include_bash_testing_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$IMPLEMENTER_FILE")
  assert_contains "bash-testing-conventions" "$frontmatter"
}

function test_implementer_still_has_dart_flutter_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$IMPLEMENTER_FILE")
  assert_contains "dart-flutter-conventions" "$frontmatter"
}

function test_implementer_still_has_cpp_testing_conventions() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$IMPLEMENTER_FILE")
  assert_contains "cpp-testing-conventions" "$frontmatter"
}

# ---------- Test 3: tdd-plan SKILL.md exists and delegates to planner ----------

function test_tdd_plan_skill_file_exists() {
  assert_file_exists "$TDD_PLAN_SKILL"
}

# After the inline orchestration rewrite, project detection and framework
# listing live in the planner agent body, not the skill. Verify the planner
# agent body has them instead.

function test_planner_body_has_bash_project_detection() {
  # Planner agent body should detect bash projects (via _test.sh files)
  assert_file_contains "$PLANNER_FILE" "_test.sh"
}

function test_planner_body_loads_bash_testing_conventions_reference() {
  # Planner agent body should instruct loading bash-testing-conventions reference files
  assert_file_contains "$PLANNER_FILE" "skills/bash-testing-conventions/reference/"
}

function test_planner_body_references_bash_testing() {
  # Planner agent body should reference bash testing (via .bashunit.yml or _test.sh)
  assert_file_contains "$PLANNER_FILE" ".bashunit.yml"
}

# ---------- Edge Cases: Additive-only ----------

function test_planner_no_existing_skills_removed() {
  # Verify all three skills are present in the frontmatter skills list
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$PLANNER_FILE")
  assert_contains "dart-flutter-conventions" "$frontmatter"
  assert_contains "cpp-testing-conventions" "$frontmatter"
  assert_contains "bash-testing-conventions" "$frontmatter"
}

function test_implementer_no_existing_skills_removed() {
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$IMPLEMENTER_FILE")
  assert_contains "dart-flutter-conventions" "$frontmatter"
  assert_contains "cpp-testing-conventions" "$frontmatter"
  assert_contains "bash-testing-conventions" "$frontmatter"
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
