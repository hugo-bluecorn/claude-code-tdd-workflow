#!/bin/bash

# Tests for load-role-references.sh: outputs CR role and format spec content
# for the role-creator agent.

SCRIPT="$(pwd)/scripts/load-role-references.sh"

# ---------- Test 1: Script file exists and is executable ----------

function test_script_file_exists() {
  assert_file_exists "$SCRIPT"
}

function test_script_is_executable() {
  local perms
  perms=$(stat -c "%a" "$SCRIPT")
  assert_matches "^7[0-7][0-7]$" "$perms"
}

# ---------- Test 2: Script outputs cr-role-creator.md content ----------

function test_output_contains_cr_role_content() {
  local output
  output=$(bash "$SCRIPT" 2>/dev/null)

  assert_contains "Role Creator" "$output"
  assert_contains "## Identity" "$output"
}

# ---------- Test 3: Script outputs role-format.md content ----------

function test_output_contains_format_spec_content() {
  local output
  output=$(bash "$SCRIPT" 2>/dev/null)

  assert_contains "Role File Format" "$output"
  assert_contains "Section Menu" "$output"
}

# ---------- Test 4: Script outputs both files with separator ----------

function test_output_has_separator_and_correct_order() {
  local output
  output=$(bash "$SCRIPT" 2>/dev/null)

  # Both files present
  assert_contains "Role Creator" "$output"
  assert_contains "Role File Format" "$output"

  # Separator exists
  assert_contains "---" "$output"

  # CR role appears before format spec
  local cr_line format_line
  cr_line=$(echo "$output" | grep -n "Role Creator" | head -1 | cut -d: -f1)
  format_line=$(echo "$output" | grep -n "Role File Format" | head -1 | cut -d: -f1)
  assert_greater_or_equal_than "$cr_line" "$format_line"
}

# ---------- Test 5: Script exits with status 0 ----------

function test_script_exits_with_status_0() {
  bash "$SCRIPT" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 6: Script passes shellcheck ----------

function test_script_passes_shellcheck() {
  shellcheck -S warning "$SCRIPT" 2>&1
  assert_exit_code 0
}

# ---------- Test 7: Script resolves paths relative to its own location ----------

function test_script_works_from_different_directory() {
  local output
  output=$(cd /tmp && bash "$SCRIPT" 2>/dev/null)

  assert_contains "Role Creator" "$output"
  assert_contains "Role File Format" "$output"
}
