#!/bin/bash

# Tests for read-pack.sh (R1 Wave 0, F1) — the pack.json manifest field-reader
# that every R1 consumer uses. Reads a field by jq path from a pack's manifest.
# Blackbox-safe: a missing manifest, field, or value yields empty output + exit 0.

SCRIPT="$(pwd)/scripts/read-pack.sh"

# Helper: create a temp pack dir, writing stdin to its pack.json; echo the dir.
create_pack() {
  local dir
  dir=$(mktemp -d)
  cat > "$dir/pack.json"
  echo "$dir"
}

# Canonical dart-shaped fixture manifest (RATIFIED G0 schema):
# commands.test is the rich object; lint/format/coverage are string siblings.
DART_PACK='{
  "schemaVersion": 1,
  "name": "fix-dart", "version": "1.0.0", "language": "Dart",
  "detect": { "extensions": [".dart"], "markers": ["pubspec.yaml"] },
  "commands": {
    "test": { "granularity": "file", "run": "flutter test {file}", "passOn": "exitZero" },
    "lint": "dart analyze", "format": "dart format .", "coverage": "flutter test --coverage"
  },
  "testFilePattern": "*_test.dart",
  "implToTestMap": "lib/{n}.dart->test/{n}_test.dart",
  "versionFiles": ["pubspec.yaml"],
  "projectFiles": ["analysis_options.yaml"],
  "standards": { "index": "SKILL.md", "dir": "standards/" }
}'

# ---------- Test 1: reads a nested field inside the rich commands.test object ----------
function test_reads_nested_test_run_command() {
  local pack
  pack=$(echo "$DART_PACK" | create_pack)
  assert_equals "flutter test {file}" "$(bash "$SCRIPT" "$pack" "commands.test.run")"
}

# ---------- Test 2: reads a sibling string command ----------
function test_reads_sibling_format_command() {
  local pack
  pack=$(echo "$DART_PACK" | create_pack)
  assert_equals "dart format ." "$(bash "$SCRIPT" "$pack" "commands.format")"
}

# ---------- Test 3: reads an array element (detect marker) ----------
function test_reads_detect_marker_array_element() {
  local pack
  pack=$(echo "$DART_PACK" | create_pack)
  assert_equals "pubspec.yaml" "$(bash "$SCRIPT" "$pack" "detect.markers[0]")"
}

# ---------- Test 4: missing field → empty output + exit 0 (blackbox-safe) ----------
function test_missing_field_is_empty_and_exit_zero() {
  local pack out rc
  pack=$(echo '{"schemaVersion":1}' | create_pack)
  out=$(bash "$SCRIPT" "$pack" "commands.lint")
  rc=$?
  assert_equals "0" "$rc"
  assert_equals "" "$out"
}

# ---------- Test 5: missing manifest → empty output + exit 0 (degrade, no pack) ----------
function test_missing_manifest_is_empty_and_exit_zero() {
  local dir out rc
  dir=$(mktemp -d)
  out=$(bash "$SCRIPT" "$dir" "commands.test.run")
  rc=$?
  assert_equals "0" "$rc"
  assert_equals "" "$out"
}

# ---------- Test 6: trailing slash on the pack dir is tolerated ----------
function test_trailing_slash_on_pack_dir() {
  local pack
  pack=$(echo "$DART_PACK" | create_pack)
  assert_equals "dart analyze" "$(bash "$SCRIPT" "${pack}/" "commands.lint")"
}
