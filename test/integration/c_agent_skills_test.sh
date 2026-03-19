#!/bin/bash

# Test suite for agent frontmatter and planner body — project-conventions integration
# Originally tested c-conventions addition; updated for project-conventions migration.

PLANNER_FILE="agents/tdd-planner.md"
IMPLEMENTER_FILE="agents/tdd-implementer.md"
CONTEXT_UPDATER_FILE="agents/context-updater.md"

# ---------- Helper: extract frontmatter (between first two --- lines) ----------

extract_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$1" | sed '1d;$d'
}

# ---------- Helper: extract body (after second --- line) ----------

extract_body() {
  sed '1{/^---$/!q};1,/^---$/d' "$1"
}

# ---------- Test 1: Planner uses project-conventions ----------

function test_planner_skills_include_project_conventions() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$PLANNER_FILE")
  assert_contains "project-conventions" "$frontmatter"
}

# ---------- Test 2: Implementer uses project-conventions ----------

function test_implementer_skills_include_project_conventions() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$IMPLEMENTER_FILE")
  assert_contains "project-conventions" "$frontmatter"
}

# ---------- Test 3: Context-updater has no convention skills ----------

function test_context_updater_no_convention_skills() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$CONTEXT_UPDATER_FILE")
  assert_not_contains "dart-flutter-conventions" "$frontmatter"
  assert_not_contains "cpp-testing-conventions" "$frontmatter"
  assert_not_contains "bash-testing-conventions" "$frontmatter"
  assert_not_contains "c-conventions" "$frontmatter"
  assert_not_contains "project-conventions" "$frontmatter"
}

# ---------- Test 4: Planner body includes C project detection ----------

function test_planner_body_has_c_project_detection() {
  local body
  body=$(extract_body "$PLANNER_FILE")
  assert_matches '\.c[^a-zA-Z+]' "$body"
}

# ---------- Test 5: Planner body includes *_test.c in find command ----------

function test_planner_body_has_test_c_in_find_command() {
  local body
  body=$(extract_body "$PLANNER_FILE")
  assert_matches '\*_test\.c[^p]' "$body"
}

# ---------- Test 6: Planner body still has Dart and C++ detection ----------

function test_planner_body_still_has_dart_and_cpp_detection() {
  local body
  body=$(extract_body "$PLANNER_FILE")
  assert_contains "pubspec.yaml" "$body"
  assert_contains "CMakeLists.txt" "$body"
}
