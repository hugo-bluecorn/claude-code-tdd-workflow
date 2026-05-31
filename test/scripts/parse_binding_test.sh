#!/bin/bash

# Tests for parse-binding.sh (R1 Wave 0, F2) — normalizes the project binding
# (.claude/tdd-conventions.json) into uniform "<source>\t<version>" lines, one
# per pack. Supports the new {packs:[{source,version}]} form AND the legacy
# {conventions:[url|abspath]} form (empty version = back-compat / HEAD).

SCRIPT="$(pwd)/scripts/parse-binding.sh"

# Helper: write stdin as a binding into a temp project; echo the project dir.
make_binding() {
  local dir
  dir=$(mktemp -d)
  mkdir -p "$dir/.claude"
  cat > "$dir/.claude/tdd-conventions.json"
  echo "$dir"
}

run_parse() { (cd "$1" && bash "$SCRIPT"); }

# ---------- Test 1: new {packs} form yields source<TAB>version ----------
function test_parses_new_packs_source_and_version() {
  local proj
  proj=$(echo '{"packs":[{"source":"github.com/o/dart-conv","version":"1.2.0"}]}' | make_binding)
  assert_equals $'github.com/o/dart-conv\t1.2.0' "$(run_parse "$proj")"
}

# ---------- Test 2: legacy {conventions:[url]} still parses, empty version ----------
function test_parses_legacy_conventions_url_empty_version() {
  local proj
  proj=$(echo '{"conventions":["https://github.com/hugo-bluecorn/tdd-workflow-conventions"]}' | make_binding)
  assert_equals $'https://github.com/hugo-bluecorn/tdd-workflow-conventions\t' "$(run_parse "$proj")"
}

# ---------- Test 3: legacy absolute path still parses (dev back-compat) ----------
function test_parses_legacy_abspath() {
  local proj
  proj=$(echo '{"conventions":["/opt/conv/dart"]}' | make_binding)
  assert_equals $'/opt/conv/dart\t' "$(run_parse "$proj")"
}

# ---------- Test 4: multiple packs → one line each ----------
function test_parses_multiple_packs() {
  local proj out
  proj=$(echo '{"packs":[{"source":"a","version":"1.0.0"},{"source":"b","version":"2.0.0"}]}' | make_binding)
  out=$(run_parse "$proj")
  assert_contains $'a\t1.0.0' "$out"
  assert_contains $'b\t2.0.0' "$out"
}

# ---------- Test 5: a packs entry without a version → empty version field ----------
function test_pack_without_version_is_empty() {
  local proj
  proj=$(echo '{"packs":[{"source":"c"}]}' | make_binding)
  assert_equals $'c\t' "$(run_parse "$proj")"
}

# ---------- Test 6: missing binding file → empty output, exit 0 ----------
function test_missing_binding_is_empty_exit_zero() {
  local proj out rc
  proj=$(mktemp -d)
  out=$(run_parse "$proj")
  rc=$?
  assert_equals "0" "$rc"
  assert_equals "" "$out"
}

# ---------- Test 7: the new {packs} form is preferred when both keys present ----------
function test_packs_preferred_over_legacy_conventions() {
  local proj
  proj=$(echo '{"packs":[{"source":"new","version":"1.0.0"}],"conventions":["legacy"]}' | make_binding)
  assert_equals $'new\t1.0.0' "$(run_parse "$proj")"
}
