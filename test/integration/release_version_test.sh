#!/bin/bash

# Test suite for CHANGELOG and version bump: verifies CHANGELOG has a [1.6.6]
# section with correct entries and plugin.json version is bumped to 1.6.6.

CHANGELOG_MD="CHANGELOG.md"
PLUGIN_JSON=".claude-plugin/plugin.json"

# ---------- Test 1: CHANGELOG has entry for new version ----------

function test_changelog_exists() {
  assert_file_exists "$CHANGELOG_MD"
}

function test_changelog_has_1_6_0_section() {
  # A section header must exist for ## [1.6.0]
  assert_file_contains "$CHANGELOG_MD" "## [1.6.0]"
}

function test_changelog_1_6_0_has_added_section() {
  # The 1.6.0 section must contain an "Added" subsection
  local section_1_6_0
  section_1_6_0=$(sed -n '/## \[1\.6\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "### Added" "$section_1_6_0"
}

function test_changelog_1_6_0_mentions_tdd_release_skill() {
  # The Added entries must mention /tdd-release
  local section_1_6_0
  section_1_6_0=$(sed -n '/## \[1\.6\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "/tdd-release" "$section_1_6_0"
}

function test_changelog_1_6_0_mentions_tdd_releaser_agent() {
  # The Added entries must mention tdd-releaser
  local section_1_6_0
  section_1_6_0=$(sed -n '/## \[1\.6\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "tdd-releaser" "$section_1_6_0"
}

function test_changelog_1_6_0_mentions_check_release_complete_hook() {
  # The Added entries must mention check-release-complete.sh
  local section_1_6_0
  section_1_6_0=$(sed -n '/## \[1\.6\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "check-release-complete.sh" "$section_1_6_0"
}

# ---------- Test 2: plugin.json version bumped ----------

function test_plugin_json_exists() {
  assert_file_exists "$PLUGIN_JSON"
}

function test_plugin_json_version_is_1_6_6() {
  # The version field in plugin.json must be 1.6.6
  local version
  version=$(grep '"version"' "$PLUGIN_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/')
  assert_equals "1.6.6" "$version"
}

# ---------- Test 3: CHANGELOG version matches plugin.json version ----------

function test_changelog_latest_version_matches_plugin_json() {
  # The latest CHANGELOG version and plugin.json version must both be 1.6.0
  local changelog_version
  changelog_version=$(grep -oP '## \[\K[0-9]+\.[0-9]+\.[0-9]+' "$CHANGELOG_MD" | head -1)
  local plugin_version
  plugin_version=$(grep '"version"' "$PLUGIN_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/')
  assert_equals "$changelog_version" "$plugin_version"
}

# ---------- Edge Case Test 4: Previous CHANGELOG entries unchanged ----------

function test_changelog_still_has_1_5_0_section() {
  # The [1.5.0] section must still be present
  assert_file_contains "$CHANGELOG_MD" "## [1.5.0]"
}

function test_changelog_1_5_0_still_has_git_auto_commit_entry() {
  # The 1.5.0 section must still contain its original content
  local section_1_5_0
  section_1_5_0=$(sed -n '/## \[1\.5\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "Git auto-commit workflow" "$section_1_5_0"
}

function test_changelog_1_5_0_still_has_feature_branch_entry() {
  # The 1.5.0 section must still contain the feature branch creation entry
  local section_1_5_0
  section_1_5_0=$(sed -n '/## \[1\.5\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "Feature branch creation" "$section_1_5_0"
}

function test_changelog_still_has_1_0_0_section() {
  # The [1.0.0] initial release section must still be present
  assert_file_contains "$CHANGELOG_MD" "## [1.0.0]"
}

function test_changelog_still_has_all_previous_versions() {
  # All previous version sections must still be present
  assert_file_contains "$CHANGELOG_MD" "## [1.4.0]"
  assert_file_contains "$CHANGELOG_MD" "## [1.3.1]"
  assert_file_contains "$CHANGELOG_MD" "## [1.3.0]"
  assert_file_contains "$CHANGELOG_MD" "## [1.2.0]"
  assert_file_contains "$CHANGELOG_MD" "## [1.1.0]"
}
