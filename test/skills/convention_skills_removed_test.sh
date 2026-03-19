#!/bin/bash

# Test: Convention skill directories have been removed from the plugin
# and tdd-update-context SKILL.md no longer references them.

SKILLS_DIR="$(pwd)/skills"
CONTEXT_SKILL="$SKILLS_DIR/tdd-update-context/SKILL.md"

# Helper: assert directory does NOT exist (assert_file_exists uses -f, not -d)
assert_directory_not_exists() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    assert_equals "directory should not exist" "$dir exists"
  else
    assert_equals "ok" "ok"
  fi
}

# Helper: assert directory DOES exist
assert_directory_exists() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    assert_equals "ok" "ok"
  else
    assert_equals "directory should exist: $dir" "directory missing"
  fi
}

function test_dart_flutter_conventions_directory_does_not_exist() {
  assert_directory_not_exists "$SKILLS_DIR/dart-flutter-conventions"
}

function test_cpp_testing_conventions_directory_does_not_exist() {
  assert_directory_not_exists "$SKILLS_DIR/cpp-testing-conventions"
}

function test_bash_testing_conventions_directory_does_not_exist() {
  assert_directory_not_exists "$SKILLS_DIR/bash-testing-conventions"
}

function test_c_conventions_directory_does_not_exist() {
  assert_directory_not_exists "$SKILLS_DIR/c-conventions"
}

function test_tdd_update_context_skill_no_convention_skill_paths() {
  local content
  content=$(cat "$CONTEXT_SKILL")

  assert_not_contains "skills/dart-flutter-conventions/" "$content"
  assert_not_contains "skills/cpp-testing-conventions/" "$content"
  assert_not_contains "skills/bash-testing-conventions/" "$content"
  assert_not_contains "skills/c-conventions/" "$content"
}

function test_workflow_skills_still_exist() {
  assert_directory_exists "$SKILLS_DIR/tdd-plan"
  assert_directory_exists "$SKILLS_DIR/tdd-implement"
  assert_directory_exists "$SKILLS_DIR/tdd-release"
  assert_directory_exists "$SKILLS_DIR/tdd-finalize-docs"
  assert_directory_exists "$SKILLS_DIR/tdd-update-context"
  assert_directory_exists "$SKILLS_DIR/project-conventions"
}
