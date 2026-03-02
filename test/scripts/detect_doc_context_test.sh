#!/bin/bash

# Tests for Slice 4: detect-doc-context.sh script
# Discovers documentation files and outputs key=value pairs.

SCRIPT="$(pwd)/scripts/detect-doc-context.sh"

# Helper: create a temp directory for isolated testing
create_tmp_dir() {
  mktemp -d
}

# Helper: run detect-doc-context.sh in a given directory (suppress stderr)
run_detect_in_dir() {
  local dir="$1"
  (cd "$dir" && bash "$SCRIPT" 2>/dev/null)
}

# ---------- Test 1: Script outputs readme key when README.md exists ----------

function test_outputs_readme_key_when_readme_exists() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/README.md"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "readme=README.md" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: Script outputs claude_md key when CLAUDE.md exists ----------

function test_outputs_claude_md_key_when_claude_md_exists() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/CLAUDE.md"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "claude_md=CLAUDE.md" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Script outputs docs_dir key when docs/ directory exists ----------

function test_outputs_docs_dir_key_when_docs_directory_exists() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  mkdir -p "$tmp_dir/docs"
  touch "$tmp_dir/docs/guide.md"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "docs_dir=docs" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 4: Script outputs changelog key when CHANGELOG.md exists ----------

function test_outputs_changelog_key_when_changelog_exists() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/CHANGELOG.md"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "changelog=CHANGELOG.md" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 5: Script omits keys for files that do not exist ----------

function test_omits_keys_for_missing_files() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_not_contains "readme=" "$output"
  assert_not_contains "claude_md=" "$output"
  assert_not_contains "docs_dir=" "$output"
  assert_not_contains "changelog=" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 6: Script lists individual doc files in docs/ directory ----------

function test_lists_individual_doc_files_in_docs_directory() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  mkdir -p "$tmp_dir/docs"
  touch "$tmp_dir/docs/user-guide.md"
  touch "$tmp_dir/docs/api-reference.md"

  local output
  output=$(run_detect_in_dir "$tmp_dir")

  assert_contains "doc_files=" "$output"
  assert_contains "docs/user-guide.md" "$output"
  assert_contains "docs/api-reference.md" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 7: Script exits 0 even when no documentation files found ----------

function test_exits_0_when_no_docs_found() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  run_detect_in_dir "$tmp_dir"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 8: Script passes shellcheck ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}
