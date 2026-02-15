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

# ---------- Test 3: tdd-plan SKILL.md includes bash project detection ----------

function test_tdd_plan_skill_file_exists() {
  assert_file_exists "$TDD_PLAN_SKILL"
}

function test_step0_has_bash_project_detection() {
  # Step 0 should detect bash projects (via _test.sh files or similar indicator)
  assert_file_contains "$TDD_PLAN_SKILL" "_test.sh"
}

function test_step0_loads_bash_testing_conventions_reference() {
  # Step 0 should instruct loading bash-testing-conventions reference files
  assert_file_contains "$TDD_PLAN_SKILL" "skills/bash-testing-conventions/reference/"
}

function test_step2_lists_bashunit_framework() {
  # Step 2 should list bashunit alongside flutter_test and GoogleTest
  assert_file_contains "$TDD_PLAN_SKILL" "bashunit"
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

function test_skill_md_still_has_dart_detection() {
  # Existing Dart/Flutter detection (pubspec.yaml) must still be present
  assert_file_contains "$TDD_PLAN_SKILL" "pubspec.yaml"
}

function test_skill_md_still_has_cpp_detection() {
  # Existing C++ detection (CMakeLists.txt) must still be present
  assert_file_contains "$TDD_PLAN_SKILL" "CMakeLists.txt"
}

function test_skill_md_still_has_flutter_test_framework() {
  # Step 2 should still list flutter_test
  assert_file_contains "$TDD_PLAN_SKILL" "flutter_test"
}

function test_skill_md_still_has_googletest_framework() {
  # Step 2 should still list GoogleTest
  assert_file_contains "$TDD_PLAN_SKILL" "GoogleTest"
}
