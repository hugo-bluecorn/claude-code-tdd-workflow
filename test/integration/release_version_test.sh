#!/bin/bash

# Test suite for CHANGELOG and version bump: verifies CHANGELOG has the latest
# version section with correct entries and plugin.json version matches.

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

function test_plugin_json_version_is_1_11_0() {
  # The version field in plugin.json must be 1.11.0
  local version
  version=$(grep '"version"' "$PLUGIN_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/')
  assert_equals "1.11.0" "$version"
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

# ---------- Test 4: CHANGELOG has 1.9.0 section with doc-finalizer entries ----------

function test_changelog_has_1_9_0_section() {
  assert_file_contains "$CHANGELOG_MD" "## [1.9.0]"
}

function test_changelog_1_9_0_has_added_section() {
  local section_1_9_0
  section_1_9_0=$(sed -n '/## \[1\.9\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "### Added" "$section_1_9_0"
}

function test_changelog_1_9_0_mentions_tdd_doc_finalizer_agent() {
  local section_1_9_0
  section_1_9_0=$(sed -n '/## \[1\.9\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "tdd-doc-finalizer" "$section_1_9_0"
}

function test_changelog_1_9_0_mentions_tdd_finalize_docs_skill() {
  local section_1_9_0
  section_1_9_0=$(sed -n '/## \[1\.9\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "/tdd-finalize-docs" "$section_1_9_0"
}

# ---------- Test 6: CHANGELOG has 1.10.0 section ----------

function test_changelog_has_1_10_0_section() {
  assert_file_contains "$CHANGELOG_MD" "## [1.10.0]"
}

function test_changelog_1_10_0_has_added_section() {
  local section_1_10_0
  section_1_10_0=$(sed -n '/## \[1\.10\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "### Added" "$section_1_10_0"
}

function test_changelog_1_10_0_has_fixed_section() {
  local section_1_10_0
  section_1_10_0=$(sed -n '/## \[1\.10\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "### Fixed" "$section_1_10_0"
}

function test_changelog_1_10_0_has_changed_section() {
  local section_1_10_0
  section_1_10_0=$(sed -n '/## \[1\.10\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "### Changed" "$section_1_10_0"
}

function test_changelog_1_10_0_mentions_agent_colors() {
  local section_1_10_0
  section_1_10_0=$(sed -n '/## \[1\.10\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "color" "$section_1_10_0"
}

function test_changelog_1_10_0_mentions_reference_docs() {
  local section_1_10_0
  section_1_10_0=$(sed -n '/## \[1\.10\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "docs/reference" "$section_1_10_0"
}

function test_changelog_1_10_0_mentions_detect_project_context_move() {
  local section_1_10_0
  section_1_10_0=$(sed -n '/## \[1\.10\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "detect-project-context.sh" "$section_1_10_0"
}

# ---------- Test 7: CHANGELOG has 1.11.0 section with inline orchestration entries ----------

function test_changelog_has_1_11_0_section() {
  assert_file_contains "$CHANGELOG_MD" "## [1.11.0]"
}

function test_changelog_1_11_0_has_changed_section() {
  local section_1_11_0
  section_1_11_0=$(sed -n '/## \[1\.11\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "### Changed" "$section_1_11_0"
}

function test_changelog_1_11_0_has_removed_section() {
  local section_1_11_0
  section_1_11_0=$(sed -n '/## \[1\.11\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "### Removed" "$section_1_11_0"
}

function test_changelog_1_11_0_mentions_tdd_planner_restructure() {
  local section_1_11_0
  section_1_11_0=$(sed -n '/## \[1\.11\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "tdd-planner" "$section_1_11_0"
}

function test_changelog_1_11_0_mentions_inline_orchestration() {
  local section_1_11_0
  section_1_11_0=$(sed -n '/## \[1\.11\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "inline" "$section_1_11_0"
}

function test_changelog_1_11_0_mentions_hooks_json_change() {
  local section_1_11_0
  section_1_11_0=$(sed -n '/## \[1\.11\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains "hooks.json" "$section_1_11_0"
}

function test_changelog_1_11_0_mentions_lock_removal() {
  local section_1_11_0
  section_1_11_0=$(sed -n '/## \[1\.11\.0\]/,/## \[/p' "$CHANGELOG_MD")
  assert_contains ".tdd-plan-locked" "$section_1_11_0"
}

# ---------- Edge Case Test 5: Previous CHANGELOG entries unchanged ----------

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
