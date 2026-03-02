#!/bin/bash

# Tests for Slice 1: version-control.md moved to skills/tdd-release/reference/

README_MD="README.md"
USER_GUIDE="docs/user-guide.md"
VCI_MD="docs/version-control-integration.md"

# ---------- Test 1: version-control.md exists at new location ----------

function test_version_control_exists_at_new_location() {
  assert_file_exists "skills/tdd-release/reference/version-control.md"
}

# ---------- Test 2: version-control.md does NOT exist at old location ----------

function test_version_control_not_at_old_location() {
  assert_file_not_exists "docs/version-control.md"
}

# ---------- Test 3: README file structure tree shows new path ----------

function test_readme_file_structure_shows_new_version_control_path() {
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  # The tdd-release section must have a reference/ subdirectory with version-control.md
  # Extract from "tdd-release/" up to the next skill directory at the same indentation level
  local tdd_release_section
  tdd_release_section=$(echo "$file_structure" | awk '/tdd-release\//{found=1} found{print} found && /tdd-finalize-docs\//{exit}')
  assert_contains "reference/" "$tdd_release_section"
  assert_contains "version-control.md" "$tdd_release_section"
}

function test_readme_file_structure_does_not_show_version_control_under_docs() {
  # Extract only the docs/ section of the file structure tree
  local docs_section
  docs_section=$(sed -n '/## File Structure/,/^##/p' "$README_MD" | sed -n '/docs\//,/^[^ │├└]/p')
  # version-control.md should NOT appear in the docs/ subtree
  assert_not_contains "version-control.md" "$docs_section"
}

# ---------- Test 4: README documentation links section points to new path ----------

function test_readme_documentation_link_points_to_new_path() {
  local doc_section
  doc_section=$(sed -n '/## Documentation/,/^##/p' "$README_MD")
  assert_contains "skills/tdd-release/reference/version-control.md" "$doc_section"
}

function test_readme_documentation_link_not_old_path() {
  local doc_section
  doc_section=$(sed -n '/## Documentation/,/^##/p' "$README_MD")
  assert_not_contains "docs/version-control.md" "$doc_section"
}

# ---------- Test 5: user-guide.md references updated path ----------

function test_user_guide_references_new_version_control_path() {
  local matches
  matches=$(grep "version-control.md" "$USER_GUIDE" || true)
  # All references must use the new path
  assert_contains "skills/tdd-release/reference/version-control.md" "$matches"
}

function test_user_guide_no_old_version_control_path() {
  local old_matches
  old_matches=$(grep -c "docs/version-control.md" "$USER_GUIDE" || true)
  assert_equals "0" "$old_matches"
}

# ---------- Test 6: version-control-integration.md references updated path ----------

function test_vci_references_new_version_control_path() {
  # Should NOT point to docs/version-control.md
  local old_matches
  old_matches=$(grep -c "docs/version-control.md" "$VCI_MD" || true)
  assert_equals "0" "$old_matches"
}

# ---------- Test 7: No stale docs/version-control.md reference in non-planning .md files ----------

function test_no_stale_docs_version_control_reference_outside_planning() {
  local stale_count
  # Search all .md files except those under planning/ and .tdd-progress.md
  stale_count=$(grep -rl "docs/version-control.md" --include="*.md" . \
    | grep -v "^./planning/" \
    | grep -v "^./.tdd-progress.md" \
    | wc -l || true)
  assert_equals "0" "$stale_count"
}
