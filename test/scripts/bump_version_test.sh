#!/bin/bash

# Tests for bump-version.sh (R1 Wave 0, V1 — C5 versioning-authority split).
#
# .claude-plugin/plugin.json is bumped as a BUILT-IN (the plugin self-hosts on
# it). All OTHER version-bearing files + their formats are PACK-DRIVEN: read
# from the active pack's `versionFiles` ([{path, pattern}], pattern = a sed
# substitution carrying the {version} placeholder), resolved via
# $TDD_ACTIVE_PACK (in-session) or the committed binding. The previously
# hardcoded 6-ecosystem matrix is removed — its format knowledge now lives in
# the pack.

SCRIPT="$(pwd)/scripts/bump-version.sh"

create_tmp_dir() { mktemp -d; }

run_bump_in_dir() {
  local dir="$1"
  shift
  (cd "$dir" && bash "$SCRIPT" "$@" 2>/dev/null)
}

run_bump_in_dir_stderr() {
  local dir="$1"
  shift
  # shellcheck disable=SC2069  # intentional: capture stderr, suppress stdout
  (cd "$dir" && bash "$SCRIPT" "$@" 2>&1 >/dev/null)
}

# ---------- Test 1: plugin.json is a built-in self-host bump (no pack needed) ----------

function test_plugin_json_bumped_builtin_without_pack() {
  local tmp
  tmp=$(create_tmp_dir)
  mkdir -p "$tmp/.claude-plugin"
  cat > "$tmp/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0"
}
EOF

  run_bump_in_dir "$tmp" "1.5.0"
  assert_exit_code 0
  assert_file_contains "$tmp/.claude-plugin/plugin.json" '"version": "1.5.0"'

  rm -rf "$tmp"
}

# ---------- Test 2: a pack versionFile bumps a file the core never hardcoded ----------

function test_pack_versionfile_bumps_properties_file() {
  local tmp pack
  tmp=$(create_tmp_dir)
  pack=$(create_tmp_dir)
  # version.properties was never in the hardcoded matrix — only a pack reaches it.
  printf 'name=demo\nversion=1.0.0\n' > "$tmp/version.properties"
  cat > "$pack/pack.json" << 'EOF'
{ "versionFiles": [
  { "path": "version.properties", "pattern": "s/^version=.*/version={version}/" }
] }
EOF

  (cd "$tmp" && TDD_ACTIVE_PACK="$pack" bash "$SCRIPT" "2.0.0")
  assert_file_contains "$tmp/version.properties" "version=2.0.0"

  rm -rf "$tmp" "$pack"
}

# ---------- Test 3: format is pack-owned — a different pattern works the same way ----------

function test_pack_versionfile_bumps_yaml_release_key() {
  local tmp pack
  tmp=$(create_tmp_dir)
  pack=$(create_tmp_dir)
  printf 'release: 1.0.0\n' > "$tmp/meta.yaml"
  cat > "$pack/pack.json" << 'EOF'
{ "versionFiles": [
  { "path": "meta.yaml", "pattern": "s/^release: .*/release: {version}/" }
] }
EOF

  (cd "$tmp" && TDD_ACTIVE_PACK="$pack" bash "$SCRIPT" "3.1.4")
  assert_file_contains "$tmp/meta.yaml" "release: 3.1.4"

  rm -rf "$tmp" "$pack"
}

# ---------- Test 4: REMOVAL PROOF — with no pack, a consumer version file is untouched ----------

function test_no_pack_leaves_consumer_file_untouched() {
  local tmp
  tmp=$(create_tmp_dir)
  # pubspec.yaml used to be hardcoded; now without a pack it is left as-is.
  printf 'name: my_app\nversion: 1.0.0\n' > "$tmp/pubspec.yaml"

  run_bump_in_dir "$tmp" "2.0.0"
  assert_file_contains "$tmp/pubspec.yaml" "version: 1.0.0"

  rm -rf "$tmp"
}

# ---------- Test 5: plugin.json (built-in) and a pack file bump together ----------

function test_plugin_json_and_pack_file_bump_together() {
  local tmp pack
  tmp=$(create_tmp_dir)
  pack=$(create_tmp_dir)
  mkdir -p "$tmp/.claude-plugin"
  cat > "$tmp/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0"
}
EOF
  printf 'name: my_app\nversion: 1.0.0\n' > "$tmp/pubspec.yaml"
  cat > "$pack/pack.json" << 'EOF'
{ "versionFiles": [
  { "path": "pubspec.yaml", "pattern": "s/^version: .*/version: {version}/" }
] }
EOF

  (cd "$tmp" && TDD_ACTIVE_PACK="$pack" bash "$SCRIPT" "2.0.0")
  assert_file_contains "$tmp/.claude-plugin/plugin.json" '"version": "2.0.0"'
  assert_file_contains "$tmp/pubspec.yaml" "version: 2.0.0"

  rm -rf "$tmp" "$pack"
}

# ---------- Test 6: exits 1 with usage message when no argument provided ----------

function test_exits_1_with_usage_when_no_argument() {
  local tmp
  tmp=$(create_tmp_dir)

  run_bump_in_dir "$tmp"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_bump_in_dir_stderr "$tmp")
  assert_contains "usage" "$stderr_output"

  rm -rf "$tmp"
}

# ---------- Test 7: exits 0 with informational message when nothing to update ----------

function test_exits_0_when_no_version_files() {
  local tmp all_output
  tmp=$(create_tmp_dir)

  all_output=$(cd "$tmp" && bash "$SCRIPT" "1.0.0" 2>&1)
  assert_exit_code 0
  assert_contains "no version" "$all_output"

  rm -rf "$tmp"
}

# ---------- Test 8: outputs the list of updated files (built-in + pack) ----------

function test_outputs_list_of_updated_files() {
  local tmp pack output
  tmp=$(create_tmp_dir)
  pack=$(create_tmp_dir)
  mkdir -p "$tmp/.claude-plugin"
  cat > "$tmp/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0"
}
EOF
  printf 'name: my_app\nversion: 1.0.0\n' > "$tmp/pubspec.yaml"
  cat > "$pack/pack.json" << 'EOF'
{ "versionFiles": [
  { "path": "pubspec.yaml", "pattern": "s/^version: .*/version: {version}/" }
] }
EOF

  output=$(cd "$tmp" && TDD_ACTIVE_PACK="$pack" bash "$SCRIPT" "1.5.0")
  assert_contains "plugin.json" "$output"
  assert_contains "pubspec.yaml" "$output"

  rm -rf "$tmp" "$pack"
}

# ---------- Test 9: passes shellcheck ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}
