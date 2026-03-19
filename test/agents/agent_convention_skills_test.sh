#!/bin/bash

# Test suite for agent convention skills migration (Slice 4)
# Verifies planner and implementer use project-conventions,
# context-updater has no convention skills, and other fields preserved.

PLANNER="agents/tdd-planner.md"
IMPLEMENTER="agents/tdd-implementer.md"
CONTEXT_UPDATER="agents/context-updater.md"

# Helper: extract YAML frontmatter (between --- markers, excluding markers)
get_frontmatter() {
  local file="$1"
  sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Helper: extract body (everything after closing --- of frontmatter)
get_body() {
  local file="$1"
  sed -n '/^---$/,/^---$/d; p' "$file" | sed '/./,$!d'
}

# ===== Test 1: Planner skills field contains project-conventions =====

function test_planner_skills_contains_project_conventions() {
  local fm
  fm=$(get_frontmatter "$PLANNER")
  assert_contains "project-conventions" "$fm"
}

# ===== Test 2: Planner skills field does not contain old convention skills =====

function test_planner_no_dart_flutter_conventions() {
  local fm
  fm=$(get_frontmatter "$PLANNER")
  assert_not_contains "dart-flutter-conventions" "$fm"
}

function test_planner_no_cpp_testing_conventions() {
  local fm
  fm=$(get_frontmatter "$PLANNER")
  assert_not_contains "cpp-testing-conventions" "$fm"
}

function test_planner_no_bash_testing_conventions() {
  local fm
  fm=$(get_frontmatter "$PLANNER")
  assert_not_contains "bash-testing-conventions" "$fm"
}

function test_planner_no_c_conventions() {
  local fm
  fm=$(get_frontmatter "$PLANNER")
  assert_not_contains "c-conventions" "$fm"
}

# ===== Test 3: Implementer skills field contains project-conventions =====

function test_implementer_skills_contains_project_conventions() {
  local fm
  fm=$(get_frontmatter "$IMPLEMENTER")
  assert_contains "project-conventions" "$fm"
}

# ===== Test 4: Implementer skills field does not contain old convention skills =====

function test_implementer_no_dart_flutter_conventions() {
  local fm
  fm=$(get_frontmatter "$IMPLEMENTER")
  assert_not_contains "dart-flutter-conventions" "$fm"
}

function test_implementer_no_cpp_testing_conventions() {
  local fm
  fm=$(get_frontmatter "$IMPLEMENTER")
  assert_not_contains "cpp-testing-conventions" "$fm"
}

function test_implementer_no_bash_testing_conventions() {
  local fm
  fm=$(get_frontmatter "$IMPLEMENTER")
  assert_not_contains "bash-testing-conventions" "$fm"
}

function test_implementer_no_c_conventions() {
  local fm
  fm=$(get_frontmatter "$IMPLEMENTER")
  assert_not_contains "c-conventions" "$fm"
}

# ===== Test 5: Context-updater skills field does not contain project-conventions =====

function test_context_updater_no_project_conventions() {
  local fm
  fm=$(get_frontmatter "$CONTEXT_UPDATER")
  assert_not_contains "project-conventions" "$fm"
}

# ===== Test 6: Context-updater skills field does not contain any convention skills =====

function test_context_updater_no_dart_flutter_conventions() {
  local fm
  fm=$(get_frontmatter "$CONTEXT_UPDATER")
  assert_not_contains "dart-flutter-conventions" "$fm"
}

function test_context_updater_no_cpp_testing_conventions() {
  local fm
  fm=$(get_frontmatter "$CONTEXT_UPDATER")
  assert_not_contains "cpp-testing-conventions" "$fm"
}

function test_context_updater_no_bash_testing_conventions() {
  local fm
  fm=$(get_frontmatter "$CONTEXT_UPDATER")
  assert_not_contains "bash-testing-conventions" "$fm"
}

function test_context_updater_no_c_conventions() {
  local fm
  fm=$(get_frontmatter "$CONTEXT_UPDATER")
  assert_not_contains "c-conventions" "$fm"
}

# ===== Test 7: Planner other frontmatter fields preserved =====

function test_planner_preserves_model() {
  assert_file_contains "$PLANNER" "model: opus"
}

function test_planner_preserves_memory() {
  assert_file_contains "$PLANNER" "memory: project"
}

function test_planner_preserves_permission_mode() {
  assert_file_contains "$PLANNER" "permissionMode: plan"
}

function test_planner_preserves_tools() {
  assert_file_contains "$PLANNER" "tools: Read, Glob, Grep, Bash"
}

# ===== Test 8: Implementer other frontmatter fields preserved =====

function test_implementer_preserves_model() {
  assert_file_contains "$IMPLEMENTER" "model: opus"
}

function test_implementer_preserves_memory() {
  assert_file_contains "$IMPLEMENTER" "memory: project"
}

# ===== Test 9: Context-updater other frontmatter fields preserved =====

function test_context_updater_preserves_model() {
  assert_file_contains "$CONTEXT_UPDATER" "model: opus"
}

function test_context_updater_preserves_memory() {
  assert_file_contains "$CONTEXT_UPDATER" "memory: project"
}

# ===== Test 10: Planner body no longer references convention skill directories =====

function test_planner_body_no_dart_flutter_reference_path() {
  local body
  body=$(get_body "$PLANNER")
  assert_not_contains "skills/dart-flutter-conventions/reference/" "$body"
}

function test_planner_body_no_cpp_testing_reference_path() {
  local body
  body=$(get_body "$PLANNER")
  assert_not_contains "skills/cpp-testing-conventions/reference/" "$body"
}

function test_planner_body_no_bash_testing_reference_path() {
  local body
  body=$(get_body "$PLANNER")
  assert_not_contains "skills/bash-testing-conventions/reference/" "$body"
}

function test_planner_body_no_c_conventions_reference_path() {
  local body
  body=$(get_body "$PLANNER")
  assert_not_contains "skills/c-conventions/reference/" "$body"
}

# ===== Test 11: Planner body still has detect-project-context.sh reference =====

function test_planner_body_contains_detect_project_context() {
  local body
  body=$(get_body "$PLANNER")
  assert_contains "detect-project-context.sh" "$body"
}
