#!/bin/bash

# Tests for Slice V1: bump-version.sh — pack-driven (versionFiles + plugin.json self-host).
#
# bump-version.sh keeps its positional CLI (`bump-version.sh <version>`, decision #4)
# but is now pack-driven INTERNALLY: it resolves the active convention pack for the
# CURRENT directory via scripts/active-pack.sh and reads the pack's top-level
# `versionFiles[]` to decide which files to rewrite. `.claude-plugin/plugin.json`
# is a BUILT-IN self-host that always bumps regardless of pack (pack-optional).
#
# versionFiles encoding (one array element is either):
#   - a BARE PATH STRING (default heuristic keyed by extension):
#       .yaml/.yml -> s/^version: .*/version: <V>/
#       .json      -> s/"version": "[^"]*"/"version": "<V>"/
#       .toml      -> 0,/^version = "[^"]*"/s//version = "<V>"/   (first only)
#   - a {path, pattern} OBJECT: pattern is a sed script with a literal {version}
#     token; {version} is substituted with <V> and the sed run on path.

SCRIPT="$(pwd)/scripts/bump-version.sh"
FIXTURES="$(pwd)/test/fixtures"
DART_FIXTURE="${FIXTURES}/dart-fixture"

# Run bump-version.sh inside <dir>, env-fast-path TDD_ACTIVE_PACK forwarded if set.
# stderr suppressed; stdout reaches the caller via $(...).
run_bump_in_dir() {
  local dir="$1"
  shift
  (cd "$dir" && bash "$SCRIPT" "$@" 2>/dev/null)
}

# Run capturing stderr (suppress stdout) — for usage/diagnostic assertions.
run_bump_in_dir_stderr() {
  local dir="$1"
  shift
  # shellcheck disable=SC2069  # intentional: capture stderr, suppress stdout
  (cd "$dir" && bash "$SCRIPT" "$@" 2>&1 >/dev/null)
}

# Run capturing BOTH streams merged — for "no version" degrade message.
run_bump_in_dir_all() {
  local dir="$1"
  shift
  (cd "$dir" && bash "$SCRIPT" "$@" 2>&1)
}

# Write a local dev-pack binding into <project>/.claude/tdd-conventions.json.
write_dev_binding() {
  local proj="$1" src="$2"
  mkdir -p "$proj/.claude"
  printf '{"packs":[{"source":"%s","dev":true}]}\n' "$src" >"$proj/.claude/tdd-conventions.json"
}

function set_up() {
  TMP_DIRS=()
  unset TDD_ACTIVE_PACK
}

function tear_down() {
  local d
  for d in "${TMP_DIRS[@]:-}"; do
    [ -n "$d" ] && rm -rf "$d"
  done
  unset TDD_ACTIVE_PACK
}

mk() {
  local d
  d=$(mktemp -d)
  TMP_DIRS+=("$d")
  echo "$d"
}

# ---------- Test 1: pack-driven bump via TDD_ACTIVE_PACK fast-path ----------
# Project bound to the dart fixture (versionFiles:["pubspec.yaml"]); pubspec
# bumps, exit 0, stdout lists the file. A package.json present but NOT listed in
# versionFiles must be LEFT UNTOUCHED — proving the sweep is pack-driven, not the
# old hardcoded ecosystem matrix.

function test_pack_driven_bump_via_env_fast_path() {
  local proj
  proj=$(mk)
  cat > "$proj/pubspec.yaml" << 'EOF'
name: my_app
version: 1.0.0
description: A sample app
EOF
  # package.json is NOT in the dart fixture's versionFiles -> must stay at 1.0.0.
  cat > "$proj/package.json" << 'EOF'
{
  "name": "my-app",
  "version": "1.0.0"
}
EOF

  export TDD_ACTIVE_PACK="$DART_FIXTURE"
  local out
  out=$(run_bump_in_dir "$proj" "1.2.0")
  assert_exit_code 0

  assert_file_contains "$proj/pubspec.yaml" "version: 1.2.0"
  assert_contains "pubspec.yaml" "$out"
  # Not listed in versionFiles -> unchanged (proves pack-driven, not hardcoded matrix).
  assert_file_contains "$proj/package.json" '"version": "1.0.0"'
}

# ---------- Test 2: plugin.json self-host bumps with NO pack bound ----------

function test_plugin_json_self_host_no_pack() {
  local proj
  proj=$(mk)
  mkdir -p "$proj/.claude-plugin"
  cat > "$proj/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0"
}
EOF

  local out
  out=$(run_bump_in_dir "$proj" "1.5.0")
  assert_exit_code 0

  assert_file_contains "$proj/.claude-plugin/plugin.json" '"version": "1.5.0"'
  assert_contains "plugin.json" "$out"
}

# ---------- Test 3: env-unset committed-binding resolution ----------
# $TDD_ACTIVE_PACK UNSET; committed dev-binding -> local pack whose
# versionFiles is ["pubspec.yaml"]; pubspec bumps via committed binding.

function test_env_unset_committed_binding_resolution() {
  local proj pack
  proj=$(mk)
  pack=$(mk)

  # versionFiles uses a NON-standard name the old hardcoded matrix never knew
  # about, so a passing result can only come from reading the pack.
  cat > "$pack/pack.json" << 'EOF'
{
  "schemaVersion": 1,
  "name": "local-dart",
  "version": "1.0.0",
  "language": "Dart/Flutter",
  "detect": { "extensions": [".dart"], "markers": ["pubspec.yaml"] },
  "versionFiles": ["pubspec.yaml", "VERSION.yaml"]
}
EOF

  cat > "$proj/pubspec.yaml" << 'EOF'
name: my_app
version: 1.0.0
EOF
  cat > "$proj/VERSION.yaml" << 'EOF'
version: 1.0.0
EOF
  write_dev_binding "$proj" "$pack"

  unset TDD_ACTIVE_PACK
  run_bump_in_dir "$proj" "2.0.0"
  assert_exit_code 0
  assert_file_contains "$proj/pubspec.yaml" "version: 2.0.0"
  # Pack-listed non-standard file proves resolution drove the sweep.
  assert_file_contains "$proj/VERSION.yaml" "version: 2.0.0"
}

# ---------- Test 4: object-form {path,pattern} rewrite ----------

function test_object_form_path_pattern_rewrite() {
  local proj pack
  proj=$(mk)
  pack=$(mk)

  # detect marker is CMakeLists.txt (so the pack resolves) but the versionFiles
  # OBJECT targets a DIFFERENT, non-standard file (build.cmake) the old hardcoded
  # matrix never touched — proving the {path,pattern} object drove the rewrite.
  cat > "$pack/pack.json" << 'EOF'
{
  "schemaVersion": 1,
  "name": "local-cmake",
  "version": "1.0.0",
  "language": "C/C++",
  "detect": { "extensions": [".cpp"], "markers": ["CMakeLists.txt"] },
  "versionFiles": [
    { "path": "build.cmake", "pattern": "s/\\(project([^ ]* VERSION \\)[^ )]*/\\1{version}/" }
  ]
}
EOF

  : > "$proj/CMakeLists.txt"
  cat > "$proj/build.cmake" << 'EOF'
project(myapp VERSION 1.0.0)
EOF
  write_dev_binding "$proj" "$pack"

  unset TDD_ACTIVE_PACK
  run_bump_in_dir "$proj" "1.3.0"
  assert_exit_code 0
  assert_file_contains "$proj/build.cmake" "project(myapp VERSION 1.3.0)"
}

# ---------- Test 5: missing argument -> exit 1, stderr usage (CLI preserved) ----------

function test_missing_argument_exits_1_with_usage() {
  local proj
  proj=$(mk)
  cat > "$proj/pubspec.yaml" << 'EOF'
name: my_app
version: 1.0.0
EOF

  run_bump_in_dir "$proj"
  assert_exit_code 1

  local err
  err=$(run_bump_in_dir_stderr "$proj")
  assert_contains "usage" "$err"
}

# ---------- Test 6: no pack + no version files -> "no version", exit 0 ----------

function test_no_pack_no_version_files_degrades() {
  local proj
  proj=$(mk)

  run_bump_in_dir "$proj" "1.0.0"
  assert_exit_code 0

  local all
  all=$(run_bump_in_dir_all "$proj" "1.0.0")
  assert_contains "no version" "$all"
}

# ---------- Test 7: multiple versionFiles (pack pubspec + built-in plugin.json) ----------

function test_multiple_version_files_one_invocation() {
  local proj pack
  proj=$(mk)
  pack=$(mk)

  cat > "$pack/pack.json" << 'EOF'
{
  "schemaVersion": 1,
  "name": "local-dart",
  "version": "1.0.0",
  "language": "Dart/Flutter",
  "detect": { "extensions": [".dart"], "markers": ["pubspec.yaml"] },
  "versionFiles": ["pubspec.yaml"]
}
EOF

  cat > "$proj/pubspec.yaml" << 'EOF'
name: my_app
version: 1.0.0
EOF
  mkdir -p "$proj/.claude-plugin"
  cat > "$proj/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0"
}
EOF
  # Cargo.toml is NOT in versionFiles -> must NOT bump (old hardcoded matrix would).
  cat > "$proj/Cargo.toml" << 'EOF'
[package]
name = "my-crate"
version = "1.0.0"
EOF
  write_dev_binding "$proj" "$pack"

  unset TDD_ACTIVE_PACK
  run_bump_in_dir "$proj" "2.0.0"
  assert_exit_code 0
  assert_file_contains "$proj/pubspec.yaml" "version: 2.0.0"
  assert_file_contains "$proj/.claude-plugin/plugin.json" '"version": "2.0.0"'
  assert_file_contains "$proj/Cargo.toml" 'version = "1.0.0"'
}

# ---------- Test 9: bare semver preserves an existing +build (Flutter pubspec) ----------
# Falsifier for BF-003: the bare-path .yaml heuristic must NOT drop a Flutter
# `+build` suffix when the supplied version omits one. `version: 0.1.0+1` bumped
# with a bare `0.2.0` must land at `version: 0.2.0+1` — the +1 is preserved.

function test_bare_semver_preserves_existing_build() {
  local proj
  proj=$(mk)
  cat > "$proj/pubspec.yaml" << 'EOF'
name: my_app
version: 0.1.0+1
EOF

  export TDD_ACTIVE_PACK="$DART_FIXTURE"
  run_bump_in_dir "$proj" "0.2.0"
  assert_exit_code 0

  assert_file_contains "$proj/pubspec.yaml" "version: 0.2.0+1"
  # Tight falsifier: the build-stripped line must NOT be present.
  # (assert_file_not_contains greps a BRE per line -> anchor to end-of-line.)
  assert_file_not_contains "$proj/pubspec.yaml" "^version: 0.2.0$"
}

# ---------- Test 10: explicit +build in the argument wins ----------
# When the supplied version carries an explicit `+build`, it overrides the file's.

function test_explicit_build_argument_wins() {
  local proj
  proj=$(mk)
  cat > "$proj/pubspec.yaml" << 'EOF'
name: my_app
version: 0.1.0+1
EOF

  export TDD_ACTIVE_PACK="$DART_FIXTURE"
  run_bump_in_dir "$proj" "0.2.0+5"
  assert_exit_code 0

  assert_file_contains "$proj/pubspec.yaml" "version: 0.2.0+5"
}

# ---------- Test 11: no build present, none added (unchanged behavior) ----------

function test_bare_semver_no_build_adds_none() {
  local proj
  proj=$(mk)
  cat > "$proj/pubspec.yaml" << 'EOF'
name: my_app
version: 0.1.0
EOF

  export TDD_ACTIVE_PACK="$DART_FIXTURE"
  run_bump_in_dir "$proj" "0.2.0"
  assert_exit_code 0

  assert_file_contains "$proj/pubspec.yaml" "version: 0.2.0"
  # No spurious +build introduced: the line is exactly the bare semver.
  assert_file_not_contains "$proj/pubspec.yaml" "version: 0.2.0+"
}

# ---------- Test 8: shellcheck clean ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}
