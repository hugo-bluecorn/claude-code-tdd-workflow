#!/bin/bash

# Test suite for tdd-verifier.md bash support and settings.local.json permissions

VERIFIER_FILE="agents/tdd-verifier.md"
SETTINGS_FILE=".claude/settings.local.json"

# ---------- Test 1: Verifier mentions bashunit as test runner for bash ----------

function test_verifier_mentions_bashunit_for_bash() {
  assert_file_exists "$VERIFIER_FILE"
  assert_file_contains "$VERIFIER_FILE" "bashunit"
}

function test_verifier_mentions_shellcheck_for_bash() {
  assert_file_exists "$VERIFIER_FILE"
  assert_file_contains "$VERIFIER_FILE" "shellcheck"
}

function test_verifier_still_has_flutter_test() {
  assert_file_contains "$VERIFIER_FILE" "flutter test"
}

function test_verifier_still_has_dart_analyze() {
  assert_file_contains "$VERIFIER_FILE" "dart analyze"
}

function test_verifier_still_has_cpp_test_references() {
  # The verifier references ctest or similar C++ test commands
  assert_file_contains "$VERIFIER_FILE" "ctest"
}

# ---------- Test 2: settings.local.json includes shellcheck and bashunit permissions ----------

function test_settings_file_exists() {
  assert_file_exists "$SETTINGS_FILE"
}

function test_settings_has_shellcheck_permission_space_syntax() {
  # Must use space syntax: "Bash(shellcheck *)" not colon syntax
  local perms
  perms=$(jq -r '.permissions.allow[]' "$SETTINGS_FILE")
  assert_contains "Bash(shellcheck *)" "$perms"
}

function test_settings_has_bashunit_permission_space_syntax() {
  # Must use space syntax: "Bash(bashunit *)" not colon syntax
  local perms
  perms=$(jq -r '.permissions.allow[]' "$SETTINGS_FILE")
  assert_contains "Bash(bashunit *)" "$perms"
}

function test_settings_retains_dart_analyze() {
  local perms
  perms=$(jq -r '.permissions.allow[]' "$SETTINGS_FILE")
  assert_contains "Bash(dart analyze:" "$perms"
}

function test_settings_retains_flutter_analyze() {
  local perms
  perms=$(jq -r '.permissions.allow[]' "$SETTINGS_FILE")
  assert_contains "Bash(flutter analyze:" "$perms"
}

function test_settings_retains_git_push() {
  local perms
  perms=$(jq -r '.permissions.allow[]' "$SETTINGS_FILE")
  assert_contains "Bash(git push:" "$perms"
}

# ---------- Test 3: Existing verifier dart/cpp checks unchanged ----------
# These deliberately re-check the same content as Test 1 to confirm
# adding bash support did not remove or alter existing entries.

function test_verifier_dart_flutter_test_entry_unchanged() {
  assert_file_contains "$VERIFIER_FILE" "Dart/Flutter: \`flutter test\`"
}

function test_verifier_dart_analyze_entry_unchanged() {
  assert_file_contains "$VERIFIER_FILE" "Dart: \`dart analyze\`"
}

function test_verifier_cpp_ctest_entry_unchanged() {
  assert_file_contains "$VERIFIER_FILE" "ctest"
}

# ---------- Edge Cases: JSON validity and permission format ----------

function test_settings_json_is_valid() {
  jq . "$SETTINGS_FILE" > /dev/null 2>&1
  assert_exit_code 0
}

function test_no_existing_permissions_removed() {
  # Verify critical existing entries still present
  local perms
  perms=$(jq -r '.permissions.allow[]' "$SETTINGS_FILE")

  assert_contains "Bash(dart analyze:" "$perms"
  assert_contains "Bash(flutter analyze:" "$perms"
  assert_contains "Bash(git push:" "$perms"
  assert_contains "Bash(git add:" "$perms"
  assert_contains "Bash(git commit:" "$perms"
  assert_contains "WebFetch(domain:docs.anthropic.com)" "$perms"
  assert_contains "Bash(curl:" "$perms"
}

function test_new_permissions_use_space_syntax() {
  # Ensure the new entries use space syntax, not colon syntax
  # e.g. "Bash(shellcheck *)" with space, not "Bash(shellcheck:*)"
  local perms
  perms=$(jq -r '.permissions.allow[]' "$SETTINGS_FILE")

  # Should have space-based entries
  assert_contains "Bash(shellcheck *)" "$perms"
  assert_contains "Bash(bashunit *)" "$perms"

  # Verify they are NOT using colon syntax (these should not exist as NEW entries)
  # Note: we do NOT check for absence of "Bash(shellcheck:*)" because the existing
  # file may have had "Bash(shellcheck:*)" from before. The key test is that the
  # space-syntax versions exist.
}
