#!/bin/bash

# Test suite for agent frontmatter and planner body c-conventions integration

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

# ---------- Test 1: Planner agent skills list includes c-conventions ----------

function test_planner_skills_include_c_conventions() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$PLANNER_FILE")
  assert_contains "c-conventions" "$frontmatter"
}

# ---------- Test 2: Implementer agent skills list includes c-conventions ----------

function test_implementer_skills_include_c_conventions() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$IMPLEMENTER_FILE")
  assert_contains "c-conventions" "$frontmatter"
}

# ---------- Test 3: Context-updater agent skills list includes c-conventions ----------

function test_context_updater_skills_include_c_conventions() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$CONTEXT_UPDATER_FILE")
  assert_contains "c-conventions" "$frontmatter"
}

# ---------- Test 4: Planner body includes C project detection ----------

function test_planner_body_has_c_project_detection() {
  local body
  body=$(extract_body "$PLANNER_FILE")
  # Must reference .c files for detection (distinct from .cpp/.css etc)
  # Match *.c or .c followed by a non-alphanumeric character
  assert_matches '\.c[^a-zA-Z+]' "$body"
  # Must reference c-conventions reference directory
  assert_contains "skills/c-conventions/reference/" "$body"
}

# ---------- Test 5: Planner body includes *_test.c in find command ----------

function test_planner_body_has_test_c_in_find_command() {
  local body
  body=$(extract_body "$PLANNER_FILE")
  # Must match *_test.c as a distinct pattern (not just a substring of *_test.cpp)
  # The regex ensures .c is followed by a quote, not by 'p' (which would be .cpp)
  assert_matches '\*_test\.c[^p]' "$body"
}

# ---------- Test 6: Existing skills not removed from planner ----------

function test_planner_existing_skills_preserved() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$PLANNER_FILE")
  assert_contains "dart-flutter-conventions" "$frontmatter"
  assert_contains "cpp-testing-conventions" "$frontmatter"
  assert_contains "bash-testing-conventions" "$frontmatter"
}

# ---------- Test 7: Existing skills not removed from implementer ----------

function test_implementer_existing_skills_preserved() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$IMPLEMENTER_FILE")
  assert_contains "dart-flutter-conventions" "$frontmatter"
  assert_contains "cpp-testing-conventions" "$frontmatter"
  assert_contains "bash-testing-conventions" "$frontmatter"
}

# ---------- Test 8: Existing skills not removed from context-updater ----------

function test_context_updater_existing_skills_preserved() {
  local frontmatter
  frontmatter=$(extract_frontmatter "$CONTEXT_UPDATER_FILE")
  assert_contains "dart-flutter-conventions" "$frontmatter"
  assert_contains "cpp-testing-conventions" "$frontmatter"
  assert_contains "bash-testing-conventions" "$frontmatter"
}

# ---------- Test 9: Planner body still has Dart and C++ detection ----------

function test_planner_body_still_has_dart_and_cpp_detection() {
  local body
  body=$(extract_body "$PLANNER_FILE")
  assert_contains "pubspec.yaml" "$body"
  assert_contains "CMakeLists.txt" "$body"
}
