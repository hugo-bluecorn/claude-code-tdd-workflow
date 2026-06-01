#!/bin/bash

# Tests for resolve-active-pack.sh: data-driven active-pack detection.
# Usage contract: resolve-active-pack.sh <project-dir> <pack-dir>...
#   Scans from <project-dir> UP to repo-root (the dir containing .git, or the
#   filesystem root if none) for marker files / source extensions declared by
#   each candidate pack's pack.json (detect.markers / detect.extensions, read via
#   read-pack.sh). Emits the dir of every candidate pack whose declared detect
#   data matches, ONE per line, in candidate order. No match -> empty stdout,
#   exit 0. A broken candidate (missing/malformed pack.json) is skipped, never
#   aborts, never suppresses a good match.
# Synthetic fixtures only (mktemp); no dependency on any real pack.

SCRIPT="$(pwd)/scripts/resolve-active-pack.sh"
LOAD_CONVENTIONS="$(pwd)/scripts/load-conventions.sh"

# Helper: run the resolver, suppressing stderr; stdout to caller via $(...)
run_resolve() {
  bash "$SCRIPT" "$@" 2>/dev/null
}

# Fixture: a candidate pack dir whose pack.json declares the given detect
# extensions/markers. Args: <ext-json-array> <markers-json-array> [name].
# e.g. make_pack '[".dart"]' '["pubspec.yaml"]' dart
make_pack() {
  local exts="$1" markers="$2" name="${3:-pack}"
  local dir
  dir=$(mktemp -d)
  cat >"$dir/pack.json" <<JSON
{
  "schemaVersion": 1,
  "name": "$name",
  "version": "1.0.0",
  "detect": {
    "extensions": $exts,
    "markers": $markers
  }
}
JSON
  echo "$dir"
}

# Fixture: an empty project dir (no markers, no source files).
make_project() {
  mktemp -d
}

# ---------- Test 1: Marker match ----------

function test_marker_match_selects_pack() {
  local proj dart
  proj=$(make_project)
  : >"$proj/pubspec.yaml"
  dart=$(make_pack '[".dart"]' '["pubspec.yaml"]' dart)

  assert_equals "$dart" "$(run_resolve "$proj" "$dart")"

  bash "$SCRIPT" "$proj" "$dart" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$proj" "$dart"
}

# ---------- Test 2: Extension match (no marker file present) ----------

function test_extension_match_selects_pack() {
  local proj dart
  proj=$(make_project)
  : >"$proj/foo.dart"
  dart=$(make_pack '[".dart"]' '["pubspec.yaml"]' dart)

  assert_equals "$dart" "$(run_resolve "$proj" "$dart")"

  rm -rf "$proj" "$dart"
}

# ---------- Test 3: Data-driven proof (non-standard marker token) ----------
# A pack whose marker is an arbitrary token is selected purely from its declared
# detect data -- proving there is no hardcoded language/marker list.

function test_data_driven_nonstandard_marker() {
  local proj custom
  proj=$(make_project)
  : >"$proj/my-custom.marker"
  custom=$(make_pack '[]' '["my-custom.marker"]' custom)

  assert_equals "$custom" "$(run_resolve "$proj" "$custom")"

  rm -rf "$proj" "$custom"
}

# ---------- Test 4: Walks cwd -> repo-root (marker at root, invoked in subdir) ----------

function test_walks_up_to_repo_root() {
  local root nested dart
  root=$(make_project)
  mkdir -p "$root/.git"
  : >"$root/pubspec.yaml"
  nested="$root/a/b/c"
  mkdir -p "$nested"
  dart=$(make_pack '[".dart"]' '["pubspec.yaml"]' dart)

  assert_equals "$dart" "$(run_resolve "$nested" "$dart")"

  rm -rf "$root" "$dart"
}

# ---------- Test 5: Multi-pack -> both emitted, one per line ----------

function test_multi_pack_both_emitted() {
  local proj dart cpp
  proj=$(make_project)
  : >"$proj/pubspec.yaml"
  : >"$proj/CMakeLists.txt"
  dart=$(make_pack '[".dart"]' '["pubspec.yaml"]' dart)
  cpp=$(make_pack '[".cpp"]' '["CMakeLists.txt"]' cpp)

  assert_equals "$dart
$cpp" "$(run_resolve "$proj" "$dart" "$cpp")"

  rm -rf "$proj" "$dart" "$cpp"
}

# ---------- Test 6 (edge): No match -> empty stdout, exit 0 ----------

function test_no_match_is_empty_exit_zero() {
  local proj dart
  proj=$(make_project)
  dart=$(make_pack '[".dart"]' '["pubspec.yaml"]' dart)

  assert_empty "$(run_resolve "$proj" "$dart")"

  bash "$SCRIPT" "$proj" "$dart" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$proj" "$dart"
}

# ---------- Test 7 (edge): Broken candidate skipped, good match still emitted ----------

function test_broken_candidate_skipped_good_match_survives() {
  local proj broken dart
  proj=$(make_project)
  : >"$proj/pubspec.yaml"
  # Broken candidate: a dir with a malformed pack.json.
  broken=$(mktemp -d)
  printf '{ not valid json' >"$broken/pack.json"
  dart=$(make_pack '[".dart"]' '["pubspec.yaml"]' dart)

  assert_equals "$dart" "$(run_resolve "$proj" "$broken" "$dart")"

  bash "$SCRIPT" "$proj" "$broken" "$dart" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$proj" "$broken" "$dart"
}

# ---------- Test 8 (guard): load-conventions.sh untouched ----------
# This slice adds the data-driven primitive WITHOUT rewiring the consumer.
# Assert load-conventions.sh still carries its existing hardcoded detection.

function test_load_conventions_still_hardcoded() {
  assert_file_exists "$LOAD_CONVENTIONS"
  assert_contains "dart-flutter-conventions" "$(cat "$LOAD_CONVENTIONS")"
  assert_contains "cpp-testing-conventions" "$(cat "$LOAD_CONVENTIONS")"
}

# ---------- Test 9: Script passes shellcheck ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  if ! command -v shellcheck >/dev/null 2>&1; then
    bashunit::skip "shellcheck not installed" && return
  fi

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}

# ---------- Test 10 (PRIME DIRECTIVE): no role-* reference ----------

function test_no_role_reference() {
  assert_file_exists "$SCRIPT"
  local matches
  matches=$(grep -c "role-" "$SCRIPT" || true)
  assert_equals "0" "$matches"
}
