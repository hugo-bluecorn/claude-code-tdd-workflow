#!/bin/bash

# Integration test suite for convention loading pipeline (Slice 7)
# Verifies: old test files removed, planner identity updated,
# doc tests updated, and end-to-end DCI pipeline works.

SCRIPT="$(pwd)/scripts/load-conventions.sh"

# ---------- Helpers ----------

create_tmp_dir() {
  mktemp -d
}

# Clone conventions repo to a temp dir for integration testing
clone_conventions_cache() {
  local cache_dir="$1"
  mkdir -p "$cache_dir/conventions"
  git clone --depth 1 --quiet \
    https://github.com/hugo-bluecorn/tdd-workflow-conventions \
    "$cache_dir/conventions/tdd-workflow-conventions" 2>/dev/null
}

# ---------- Test 1: Old convention skill test files removed ----------

function test_bash_testing_conventions_test_removed() {
  assert_file_not_exists "test/skills/bash_testing_conventions_test.sh"
}

function test_bashunit_patterns_test_removed() {
  assert_file_not_exists "test/skills/bashunit_patterns_test.sh"
}

function test_shellcheck_guide_test_removed() {
  assert_file_not_exists "test/skills/shellcheck_guide_test.sh"
}

function test_c_conventions_test_removed() {
  assert_file_not_exists "test/skills/c_conventions_test.sh"
}

function test_c_coding_standards_test_removed() {
  assert_file_not_exists "test/skills/c_coding_standards_test.sh"
}

function test_c_static_analysis_test_removed() {
  assert_file_not_exists "test/skills/c_static_analysis_test.sh"
}

function test_c_testing_patterns_test_removed() {
  assert_file_not_exists "test/skills/c_testing_patterns_test.sh"
}

# ---------- Test 2: Old integration test files removed ----------

function test_bash_agent_skills_integration_test_removed() {
  assert_file_not_exists "test/integration/bash_agent_skills_test.sh"
}

function test_c_agent_skills_integration_test_removed() {
  assert_file_not_exists "test/integration/c_agent_skills_test.sh"
}

# ---------- Test 3: Planner identity test has no old convention skill assertions ----------

function test_planner_identity_test_exists() {
  assert_file_exists "test/agents/tdd_planner_identity_test.sh"
}

function test_planner_identity_no_dart_flutter_conventions_assertion() {
  # The test file may use assert_not_contains with old names (that's correct — it's
  # verifying absence). We check that no POSITIVE assertion (assert_contains/assert_file_contains)
  # claims old convention skills are present.
  local content
  content=$(grep -v "assert_not_contains\|assert_not_matches" "test/agents/tdd_planner_identity_test.sh")
  assert_not_contains "dart-flutter-conventions" "$content"
}

function test_planner_identity_no_cpp_testing_conventions_assertion() {
  local content
  content=$(grep -v "assert_not_contains\|assert_not_matches" "test/agents/tdd_planner_identity_test.sh")
  assert_not_contains "cpp-testing-conventions" "$content"
}

function test_planner_identity_no_bash_testing_conventions_assertion() {
  local content
  content=$(grep -v "assert_not_contains\|assert_not_matches" "test/agents/tdd_planner_identity_test.sh")
  assert_not_contains "bash-testing-conventions" "$content"
}

function test_planner_identity_no_c_conventions_assertion() {
  local content
  content=$(grep -v "assert_not_contains\|assert_not_matches" "test/agents/tdd_planner_identity_test.sh")
  assert_not_contains "c-conventions" "$content"
}

function test_planner_identity_asserts_project_conventions() {
  local content
  content=$(cat "test/agents/tdd_planner_identity_test.sh")
  assert_contains "project-conventions" "$content"
}

# ---------- Test 4: End-to-end convention loading ----------

function test_end_to_end_dart_conventions_loaded() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Create a Dart project
  touch "$tmp_dir/pubspec.yaml"

  # Set up convention cache
  local cache_dir
  cache_dir=$(create_tmp_dir)
  clone_conventions_cache "$cache_dir"

  # Run load-conventions.sh
  local output
  output=$(cd "$tmp_dir" && CLAUDE_PLUGIN_DATA="$cache_dir" bash "$SCRIPT" 2>/dev/null)

  # Should contain real Dart convention content
  assert_contains "Riverpod" "$output"

  rm -rf "$tmp_dir" "$cache_dir"
}

# ---------- Test 5: Bash documentation test has no old skill name assertions ----------

function test_bash_doc_test_exists() {
  assert_file_exists "test/integration/bash_documentation_test.sh"
}

function test_bash_doc_test_no_bash_testing_conventions_in_claude_md_assert() {
  # Should not assert bash-testing-conventions in CLAUDE.md (skills table assertions removed)
  # CHANGELOG references are fine (historical entries)
  local claude_md_lines
  claude_md_lines=$(grep -n "CLAUDE_MD.*bash-testing-conventions\|bash-testing-conventions.*CLAUDE_MD" \
    "test/integration/bash_documentation_test.sh" || true)
  assert_empty "$claude_md_lines"
}

function test_bash_doc_test_no_bash_testing_conventions_in_readme_skills_assert() {
  # Should not assert bash-testing-conventions in README skills table
  local readme_skills_lines
  readme_skills_lines=$(grep -n "README_MD.*bash-testing-conventions\|bash-testing-conventions.*README" \
    "test/integration/bash_documentation_test.sh" || true)
  assert_empty "$readme_skills_lines"
}

# ---------- Test 6: C documentation test has no old skill name assertions ----------

function test_c_doc_test_exists() {
  assert_file_exists "test/integration/c_documentation_test.sh"
}

function test_c_doc_test_no_c_conventions_in_skills_table_assert() {
  local content
  content=$(cat "test/integration/c_documentation_test.sh")
  # Should not assert c-conventions is present in CLAUDE.md/README skills table
  assert_not_contains "c-conventions" "$content"
}

function test_c_doc_test_no_old_convention_skill_preservation_asserts() {
  local content
  content=$(cat "test/integration/c_documentation_test.sh")
  # Should not assert old convention skills still exist
  assert_not_contains "dart-flutter-conventions" "$content"
  assert_not_contains "cpp-testing-conventions" "$content"
  assert_not_contains "bash-testing-conventions" "$content"
}
