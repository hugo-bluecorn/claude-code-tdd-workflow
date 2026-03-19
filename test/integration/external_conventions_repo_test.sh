#!/bin/bash

# Integration tests for external conventions repo (hugo-bluecorn/tdd-workflow-conventions)
# These tests verify the repo exists, is public, and contains all 4 convention skill directories.

REPO="hugo-bluecorn/tdd-workflow-conventions"
CLONE_DIR=""

# Clone once for all file-based tests
setup() {
  CLONE_DIR=$(mktemp -d)
  git clone --depth 1 "https://github.com/${REPO}.git" "$CLONE_DIR/repo" 2>/dev/null
}

teardown() {
  rm -rf "$CLONE_DIR"
}

# Test 1: Repo exists and is publicly accessible
function test_repo_exists_and_is_accessible() {
  local output
  output=$(gh repo view "$REPO" --json name 2>&1)
  assert_contains '"name":"tdd-workflow-conventions"' "$output"
}

# Test 2: dart-flutter-conventions directory exists with SKILL.md
function test_dart_flutter_conventions_skill_md_exists() {
  local skill_file="$CLONE_DIR/repo/dart-flutter-conventions/SKILL.md"
  assert_file_exists "$skill_file"
  local content
  content=$(cat "$skill_file")
  assert_contains "name: dart-flutter-conventions" "$content"
}

# Test 3: cpp-testing-conventions directory exists with SKILL.md
function test_cpp_testing_conventions_skill_md_exists() {
  local skill_file="$CLONE_DIR/repo/cpp-testing-conventions/SKILL.md"
  assert_file_exists "$skill_file"
  local content
  content=$(cat "$skill_file")
  assert_contains "name: cpp-testing-conventions" "$content"
}

# Test 4: bash-testing-conventions directory exists with SKILL.md
function test_bash_testing_conventions_skill_md_exists() {
  local skill_file="$CLONE_DIR/repo/bash-testing-conventions/SKILL.md"
  assert_file_exists "$skill_file"
  local content
  content=$(cat "$skill_file")
  assert_contains "name: bash-testing-conventions" "$content"
}

# Test 5: c-conventions directory exists with SKILL.md
function test_c_conventions_skill_md_exists() {
  local skill_file="$CLONE_DIR/repo/c-conventions/SKILL.md"
  assert_file_exists "$skill_file"
  local content
  content=$(cat "$skill_file")
  assert_contains "name: c-conventions" "$content"
}

# Test 6: Reference files are present and non-empty in each convention directory
function test_reference_files_present_and_nonempty() {
  local conventions=("dart-flutter-conventions" "cpp-testing-conventions" "bash-testing-conventions" "c-conventions")
  for conv in "${conventions[@]}"; do
    local ref_dir="$CLONE_DIR/repo/$conv/reference"
    assert_file_exists "$ref_dir"

    # Check at least one .md file exists and is non-empty
    local md_count
    md_count=$(find "$ref_dir" -name "*.md" -size +0c 2>/dev/null | wc -l)
    assert_greater_or_equal_than 1 "$md_count"
  done
}

# Test 7: Root index file lists available conventions
function test_root_index_lists_all_conventions() {
  # Check for README.md or CONVENTIONS.md at root
  local index_file=""
  if [[ -f "$CLONE_DIR/repo/README.md" ]]; then
    index_file="$CLONE_DIR/repo/README.md"
  elif [[ -f "$CLONE_DIR/repo/CONVENTIONS.md" ]]; then
    index_file="$CLONE_DIR/repo/CONVENTIONS.md"
  fi

  # Index file must exist
  assert_not_empty "$index_file"

  local content
  content=$(cat "$index_file")
  assert_contains "dart-flutter-conventions" "$content"
  assert_contains "cpp-testing-conventions" "$content"
  assert_contains "bash-testing-conventions" "$content"
  assert_contains "c-conventions" "$content"
}

# Test 8: No unfilled template placeholders in any SKILL.md
function test_no_template_placeholders_in_skill_md() {
  local conventions=("dart-flutter-conventions" "cpp-testing-conventions" "bash-testing-conventions" "c-conventions")
  for conv in "${conventions[@]}"; do
    local skill_file="$CLONE_DIR/repo/$conv/SKILL.md"
    assert_file_exists "$skill_file"
    local content
    content=$(cat "$skill_file")
    # Check for {placeholder} patterns (curly braces with word inside)
    assert_not_matches '\{[a-zA-Z_]+\}' "$content"
  done
}
