#!/bin/bash

# Tests for resolve-active-pack.sh (R1 Wave 0, F4) — the data-driven detection
# engine. For each pack bound in .claude/tdd-conventions.json, it matches the
# current directory against that pack's pack.json detect.markers /
# detect.extensions and emits the dir of each active pack. Replaces the four
# hardcoded dirnames. No binding / no match → empty output, exit 0 (PRIME-safe).

SCRIPT="$(pwd)/scripts/resolve-active-pack.sh"

# Helper: a local fixture pack dir with the given detect block; echoes its dir.
make_pack() {
  local dir
  dir=$(mktemp -d)
  cat > "$dir/pack.json"
  echo "$dir"
}

# Helper: a project bound (legacy local-path form) to a given pack dir.
make_project_bound_to() {
  local pack="$1" dir
  dir=$(mktemp -d)
  mkdir -p "$dir/.claude"
  echo "{\"conventions\":[\"$pack\"]}" > "$dir/.claude/tdd-conventions.json"
  echo "$dir"
}

run_resolve() { (cd "$1" && bash "$SCRIPT"); }

# ---------- Test 1: a marker file present in cwd activates the pack ----------
function test_resolves_pack_by_marker() {
  local pack proj
  pack=$(echo '{"detect":{"markers":["pubspec.yaml"],"extensions":[".dart"]}}' | make_pack)
  proj=$(make_project_bound_to "$pack")
  touch "$proj/pubspec.yaml"
  assert_equals "$pack" "$(run_resolve "$proj")"
  rm -rf "$pack" "$proj"
}

# ---------- Test 2: a file with a detect extension activates the pack ----------
function test_resolves_pack_by_extension() {
  local pack proj
  pack=$(echo '{"detect":{"markers":["pubspec.yaml"],"extensions":[".dart"]}}' | make_pack)
  proj=$(make_project_bound_to "$pack")
  touch "$proj/lib_main.dart"
  assert_equals "$pack" "$(run_resolve "$proj")"
  rm -rf "$pack" "$proj"
}

# ---------- Test 3: no marker / no matching extension → nothing, exit 0 ----------
function test_no_match_emits_nothing() {
  local pack proj out rc
  pack=$(echo '{"detect":{"markers":["pubspec.yaml"],"extensions":[".dart"]}}' | make_pack)
  proj=$(make_project_bound_to "$pack")
  out=$(run_resolve "$proj")
  rc=$?
  assert_equals "0" "$rc"
  assert_equals "" "$out"
  rm -rf "$pack" "$proj"
}

# ---------- Test 4: no binding at all → nothing, exit 0 (PRIME-safe) ----------
function test_no_binding_emits_nothing() {
  local proj out rc
  proj=$(mktemp -d)
  out=$(run_resolve "$proj")
  rc=$?
  assert_equals "0" "$rc"
  assert_equals "" "$out"
  rm -rf "$proj"
}

# ---------- Test 5: multi-pack — only the pack whose marker matches is emitted ----------
function test_multipack_emits_only_matching() {
  local dartpack cpppack proj dir
  dartpack=$(echo '{"detect":{"markers":["pubspec.yaml"]}}' | make_pack)
  cpppack=$(echo '{"detect":{"markers":["CMakeLists.txt"]}}' | make_pack)
  proj=$(mktemp -d)
  mkdir -p "$proj/.claude"
  echo "{\"conventions\":[\"$dartpack\",\"$cpppack\"]}" > "$proj/.claude/tdd-conventions.json"
  touch "$proj/CMakeLists.txt"
  assert_equals "$cpppack" "$(run_resolve "$proj")"
  rm -rf "$dartpack" "$cpppack" "$proj"
}
