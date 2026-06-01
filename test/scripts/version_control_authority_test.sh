#!/bin/bash

# Tests for Slice V3: version-control.md authority split (C5) + never-squash fix.
#
# (1) SemVer MAJOR/MINOR/PATCH semantics are owned by CORE (not fragmented across packs).
# (2) Version-bearing files + ecosystem command/format come from the active PACK
#     (versionFiles / pack-driven bump-version.sh).
# (3) The `### Merging` guidance prescribes a merge commit (never squash) and states the
#     commit-trail rationale (preserving the test:->feat:->refactor: TDD trail).
# (4) No residual "Squash and merge" preferred recommendation anywhere in the doc.

VC_MD="skills/tdd-release/reference/version-control.md"

# ---------- Test 1: SemVer semantics declared core-owned ----------

function test_semver_semantics_declared_core_owned() {
  assert_file_exists "$VC_MD"
  local body
  body=$(cat "$VC_MD")
  # The doc must state the SemVer (MAJOR/MINOR/PATCH) decision is owned by core
  # and not fragmented across convention packs.
  assert_matches "MAJOR/MINOR/PATCH|MAJOR\\.MINOR\\.PATCH|SemVer|Semantic Versioning" "$body"
  assert_matches "owned by core|core-owned|owned by the core|core owns|the core workflow" "$body"
}

function test_semver_not_fragmented_across_packs() {
  assert_file_exists "$VC_MD"
  local body
  body=$(cat "$VC_MD")
  # Must explicitly state the semantics are NOT delegated/fragmented to packs.
  assert_matches "not fragmented|not delegated|not owned by|never the pack|not the pack|not pack" "$body"
}

# ---------- Test 2: Version-bearing files declared pack-owned ----------

function test_version_files_declared_pack_owned() {
  assert_file_exists "$VC_MD"
  local body
  body=$(cat "$VC_MD")
  # Version-bearing files + ecosystem command/format come from the active pack.
  assert_matches "version-bearing files|version files|version-bearing" "$body"
  assert_matches "active convention pack|active pack|convention pack|the pack" "$body"
}

function test_version_files_reference_versionfiles_and_bump_version() {
  assert_file_exists "$VC_MD"
  local body
  body=$(cat "$VC_MD")
  # Must name the pack mechanism: versionFiles and the pack-driven bump-version.sh.
  assert_contains "versionFiles" "$body"
  assert_contains "bump-version.sh" "$body"
}

# ---------- Test 3: Never-squash replaces the squash recommendation ----------

function test_merging_prescribes_merge_commit_no_squash() {
  assert_file_exists "$VC_MD"
  # Isolate the ### Merging section.
  local merging
  merging=$(sed -n '/^### Merging/,/^##[^#]/p' "$VC_MD")
  assert_not_empty "$merging"
  # Must prescribe a merge commit via gh pr merge --merge.
  assert_contains "gh pr merge --merge" "$merging"
  # Must explicitly say not to squash.
  assert_matches "not --squash|never squash|never-squash|no squash|not squash" "$merging"
}

function test_merging_states_commit_trail_rationale() {
  assert_file_exists "$VC_MD"
  local merging
  merging=$(sed -n '/^### Merging/,/^##[^#]/p' "$VC_MD")
  # Rationale: preserving the test:->feat:->refactor: TDD commit trail.
  assert_matches "test:.*feat:.*refactor:|commit trail|commit history|per-slice|RED.*GREEN.*REFACTOR" "$merging"
}

# ---------- Test 4 (edge): No residual squash-preferred recommendation ----------

function test_no_residual_squash_preferred_recommendation() {
  assert_file_exists "$VC_MD"
  local pref_squash
  # Count lines that recommend "Squash and merge" as Preferred.
  pref_squash=$(grep -c "Preferred:.*Squash and merge" "$VC_MD" || true)
  assert_equals "0" "$pref_squash"
}

function test_no_standalone_squash_and_merge_recommendation() {
  assert_file_exists "$VC_MD"
  local squash_lines
  # "Squash and merge" must only appear (if at all) in a never-squash / prohibition
  # context, never as a bare recommendation. Easiest invariant: it must not appear
  # as a "**Preferred:**" or "Recommended" recommendation.
  squash_lines=$(grep -cE "(Preferred|Recommended|Use).*[Ss]quash (and )?merge" "$VC_MD" || true)
  assert_equals "0" "$squash_lines"
}
