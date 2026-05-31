#!/bin/bash

# Test suite for R3 — plugin manifest metadata fields.
# Verifies .claude-plugin/plugin.json carries author/repository/license/$schema
# alongside the existing name/description/version, with falsifiable value checks.

PLUGIN_JSON=".claude-plugin/plugin.json"

# ---------- Test 1: manifest is valid JSON ----------

function test_manifest_is_valid_json() {
  jq -e . "$PLUGIN_JSON" >/dev/null
  assert_exit_code 0
}

# ---------- Test 2: existing core fields preserved ----------

function test_core_name_preserved() {
  local name
  name=$(jq -r '.name' "$PLUGIN_JSON")
  assert_equals "tdd-workflow" "$name"
}

function test_core_description_non_empty() {
  jq -e '.description != null and .description != ""' "$PLUGIN_JSON" >/dev/null
  assert_exit_code 0
}

function test_core_version_is_semver() {
  local version
  version=$(jq -r '.version' "$PLUGIN_JSON")
  assert_matches "^[0-9]+\.[0-9]+\.[0-9]+" "$version"
}

# ---------- Test 3: author object with non-empty name + email ----------

function test_author_name_non_empty() {
  jq -e '.author.name != null and .author.name != ""' "$PLUGIN_JSON" >/dev/null
  assert_exit_code 0
}

function test_author_name_value() {
  local name
  name=$(jq -r '.author.name' "$PLUGIN_JSON")
  assert_equals "Hugo Garcia" "$name"
}

function test_author_email_value() {
  local email
  email=$(jq -r '.author.email' "$PLUGIN_JSON")
  assert_equals "hugo.a.garcia@gmail.com" "$email"
}

# ---------- Test 4: repository is the expected https GitHub URL ----------

function test_repository_non_empty() {
  local repo
  repo=$(jq -er '.repository' "$PLUGIN_JSON")
  assert_not_empty "$repo"
}

function test_repository_value() {
  local repo
  repo=$(jq -er '.repository' "$PLUGIN_JSON")
  assert_matches "^https://github\.com/hugo-bluecorn/claude-code-tdd-workflow" "$repo"
}

# ---------- Test 5: license equals SPDX Apache-2.0 ----------

function test_license_non_empty() {
  local license
  license=$(jq -er '.license' "$PLUGIN_JSON")
  assert_not_empty "$license"
}

function test_license_value() {
  local license
  license=$(jq -er '.license' "$PLUGIN_JSON")
  assert_equals "Apache-2.0" "$license"
}

# ---------- Test 6: $schema is the exact canonical URL ----------

function test_schema_non_empty() {
  local schema
  schema=$(jq -er '."$schema"' "$PLUGIN_JSON")
  assert_not_empty "$schema"
}

function test_schema_is_https() {
  local schema
  schema=$(jq -er '."$schema"' "$PLUGIN_JSON")
  assert_matches "^https://" "$schema"
}

function test_schema_exact_canonical_url() {
  local schema
  schema=$(jq -er '."$schema"' "$PLUGIN_JSON")
  assert_equals "https://json.schemastore.org/claude-code-plugin-manifest.json" "$schema"
}

# ---------- Test 7: empty/null falsifiability guard ----------

function test_author_name_falsifiability_guard() {
  jq -e '.author.name != null and .author.name != ""' "$PLUGIN_JSON" >/dev/null
  assert_exit_code 0
}

function test_repository_falsifiability_guard() {
  jq -e '.repository != null and .repository != ""' "$PLUGIN_JSON" >/dev/null
  assert_exit_code 0
}

function test_license_falsifiability_guard() {
  jq -e '.license != null and .license != ""' "$PLUGIN_JSON" >/dev/null
  assert_exit_code 0
}

function test_schema_falsifiability_guard() {
  jq -e '."$schema" != null and ."$schema" != ""' "$PLUGIN_JSON" >/dev/null
  assert_exit_code 0
}

# ---------- Test 8: no role-* coupling (PRIME-neutral manifest) ----------

function test_manifest_has_no_role_coupling() {
  ! grep -q "role-" "$PLUGIN_JSON"
  assert_exit_code 0
}
