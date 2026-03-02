#!/bin/bash

# Tests for Slice 2: bump-version.sh script
# Propagates a version string into all version-bearing files in the current directory.

SCRIPT="$(pwd)/scripts/bump-version.sh"

# Helper: create a temp directory for isolated testing
create_tmp_dir() {
  mktemp -d
}

# Helper: run bump-version.sh in a given directory with arguments
run_bump_in_dir() {
  local dir="$1"
  shift
  (cd "$dir" && bash "$SCRIPT" "$@" 2>/dev/null)
}

# Helper: run bump-version.sh capturing stderr (suppress stdout)
run_bump_in_dir_stderr() {
  local dir="$1"
  shift
  # shellcheck disable=SC2069  # intentional: capture stderr, suppress stdout
  (cd "$dir" && bash "$SCRIPT" "$@" 2>&1 >/dev/null)
}

# ---------- Test 1: Script exits 0 and updates pubspec.yaml version field ----------

function test_updates_pubspec_yaml_version() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/pubspec.yaml" << 'EOF'
name: my_app
version: 1.0.0
description: A sample app
EOF

  run_bump_in_dir "$tmp_dir" "1.2.0"
  assert_exit_code 0

  assert_file_contains "$tmp_dir/pubspec.yaml" "version: 1.2.0"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: Script updates package.json version field ----------

function test_updates_package_json_version() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/package.json" << 'EOF'
{
  "name": "my-app",
  "version": "1.0.0",
  "description": "A sample app"
}
EOF

  run_bump_in_dir "$tmp_dir" "2.0.0"

  assert_file_contains "$tmp_dir/package.json" '"version": "2.0.0"'

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Script updates plugin.json version field ----------

function test_updates_plugin_json_version() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  mkdir -p "$tmp_dir/.claude-plugin"
  cat > "$tmp_dir/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0"
}
EOF

  run_bump_in_dir "$tmp_dir" "1.5.0"

  assert_file_contains "$tmp_dir/.claude-plugin/plugin.json" '"version": "1.5.0"'

  rm -rf "$tmp_dir"
}

# ---------- Test 4: Script updates Cargo.toml version field ----------

function test_updates_cargo_toml_version() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/Cargo.toml" << 'EOF'
[package]
name = "my-crate"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
EOF

  run_bump_in_dir "$tmp_dir" "0.2.0"

  # The package section version should be updated
  local package_section
  package_section=$(sed -n '/\[package\]/,/^\[/p' "$tmp_dir/Cargo.toml")
  assert_contains 'version = "0.2.0"' "$package_section"

  rm -rf "$tmp_dir"
}

# ---------- Test 5: Script updates pyproject.toml version field ----------

function test_updates_pyproject_toml_version() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/pyproject.toml" << 'EOF'
[project]
name = "my-project"
version = "1.0.0"
description = "A sample project"
EOF

  run_bump_in_dir "$tmp_dir" "1.1.0"

  assert_file_contains "$tmp_dir/pyproject.toml" 'version = "1.1.0"'

  rm -rf "$tmp_dir"
}

# ---------- Test 6: Script updates CMakeLists.txt project VERSION ----------

function test_updates_cmakelists_project_version() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.14)
project(myapp VERSION 1.0.0)
set(CMAKE_CXX_STANDARD 17)
EOF

  run_bump_in_dir "$tmp_dir" "1.3.0"

  assert_file_contains "$tmp_dir/CMakeLists.txt" "project(myapp VERSION 1.3.0)"

  rm -rf "$tmp_dir"
}

# ---------- Test 7: Script updates multiple version files in one invocation ----------

function test_updates_multiple_version_files() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/pubspec.yaml" << 'EOF'
name: my_app
version: 1.0.0
EOF

  mkdir -p "$tmp_dir/.claude-plugin"
  cat > "$tmp_dir/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0"
}
EOF

  run_bump_in_dir "$tmp_dir" "2.0.0"

  assert_file_contains "$tmp_dir/pubspec.yaml" "version: 2.0.0"
  assert_file_contains "$tmp_dir/.claude-plugin/plugin.json" '"version": "2.0.0"'

  rm -rf "$tmp_dir"
}

# ---------- Test 8: Script exits 1 with usage message when no argument provided ----------

function test_exits_1_with_usage_when_no_argument() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/pubspec.yaml" << 'EOF'
name: my_app
version: 1.0.0
EOF

  run_bump_in_dir "$tmp_dir"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_bump_in_dir_stderr "$tmp_dir")
  assert_contains "usage" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 9: Script exits 0 with informational message when no version files found ----------

function test_exits_0_when_no_version_files_found() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  local output
  output=$(run_bump_in_dir "$tmp_dir" "1.0.0")
  assert_exit_code 0

  # Should indicate no version files were found (in stdout or stderr)
  local all_output
  all_output=$(cd "$tmp_dir" && bash "$SCRIPT" "1.0.0" 2>&1)
  assert_contains "no version" "$all_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 10: Script outputs list of updated files ----------

function test_outputs_list_of_updated_files() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/pubspec.yaml" << 'EOF'
name: my_app
version: 1.0.0
EOF

  cat > "$tmp_dir/package.json" << 'EOF'
{
  "name": "my-app",
  "version": "1.0.0"
}
EOF

  local output
  output=$(run_bump_in_dir "$tmp_dir" "1.5.0")

  assert_contains "pubspec.yaml" "$output"
  assert_contains "package.json" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 11: Script passes shellcheck ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}
