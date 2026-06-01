#!/bin/bash

# Tests for parse-binding.sh: binding-file parser.
# Usage contract: parse-binding.sh <project-dir>
#   Resolves <project-dir>/.claude/tdd-conventions.json and emits normalized
#   (source, version, dev) tuples, ONE per line, TAB-delimited, in declared order.
#     field 1: source   (pack source string / URL / local path)
#     field 2: version  (new-schema version; "legacy" sentinel for legacy entries;
#                        empty when a new-schema pack omits version)
#     field 3: dev      (the literal "dev" when dev:true, else empty)
#   Missing file / empty packs / malformed JSON -> empty stdout, exit 0 (non-fatal).
# Synthetic fixtures only (mktemp); no dependency on any real binding.

SCRIPT="$(pwd)/scripts/parse-binding.sh"

# Helper: run the parser, suppressing stderr; stdout to caller via $(...)
run_parse() {
  local dir="$1"
  bash "$SCRIPT" "$dir" 2>/dev/null
}

# Helper: write a binding file with the given JSON body into <dir>/.claude/
make_binding() {
  local dir="$1" body="$2"
  mkdir -p "$dir/.claude"
  printf '%s' "$body" >"$dir/.claude/tdd-conventions.json"
}

# ---------- Test 1: New-schema single pack ----------

function test_new_schema_single_pack() {
  local dir
  dir=$(mktemp -d)
  make_binding "$dir" '{"packs":[{"source":"github.com/hugo-bluecorn/dart-flutter-conventions","version":"1.0.0"}]}'

  assert_equals "github.com/hugo-bluecorn/dart-flutter-conventions	1.0.0	" "$(run_parse "$dir")"

  bash "$SCRIPT" "$dir" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$dir"
}

# ---------- Test 2: New-schema multiple packs, order preserved ----------

function test_new_schema_multiple_packs_order_preserved() {
  local dir
  dir=$(mktemp -d)
  make_binding "$dir" '{"packs":[{"source":"github.com/x/dart","version":"1.0.0"},{"source":"github.com/x/cpp","version":"2.1.0"}]}'

  assert_equals "github.com/x/dart	1.0.0	
github.com/x/cpp	2.1.0	" "$(run_parse "$dir")"

  rm -rf "$dir"
}

# ---------- Test 3: Legacy {conventions:[...]} -> sentinel version "legacy" ----------

function test_legacy_conventions_get_sentinel_version() {
  local dir
  dir=$(mktemp -d)
  make_binding "$dir" '{"conventions":["/abs/path/to/conventions","https://github.com/x/y"]}'

  assert_equals "/abs/path/to/conventions	legacy	
https://github.com/x/y	legacy	" "$(run_parse "$dir")"

  rm -rf "$dir"
}

# ---------- Test 4: dev:true flagged (version may be omitted) ----------

function test_dev_flag_surfaced_with_empty_version() {
  local dir
  dir=$(mktemp -d)
  make_binding "$dir" '{"packs":[{"source":"~/bluecorn/claude/langpacks/dart-flutter-conventions","dev":true}]}'

  assert_equals "~/bluecorn/claude/langpacks/dart-flutter-conventions		dev" "$(run_parse "$dir")"

  rm -rf "$dir"
}

# ---------- Test 5: Missing binding file -> empty, exit 0 ----------

function test_missing_binding_file_is_empty_not_error() {
  local dir
  dir=$(mktemp -d)

  local output
  output=$(run_parse "$dir")
  assert_empty "$output"

  bash "$SCRIPT" "$dir" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$dir"
}

# ---------- Test 6a: Empty {"packs":[]} -> empty, exit 0 ----------

function test_empty_packs_array_is_empty() {
  local dir
  dir=$(mktemp -d)
  make_binding "$dir" '{"packs":[]}'

  local output
  output=$(run_parse "$dir")
  assert_empty "$output"

  bash "$SCRIPT" "$dir" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$dir"
}

# ---------- Test 6b: Empty {"conventions":[]} -> empty, exit 0 ----------

function test_empty_conventions_array_is_empty() {
  local dir
  dir=$(mktemp -d)
  make_binding "$dir" '{"conventions":[]}'

  local output
  output=$(run_parse "$dir")
  assert_empty "$output"

  bash "$SCRIPT" "$dir" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$dir"
}

# ---------- Test 7: Malformed JSON -> empty stdout, exit 0 (non-fatal) ----------
# Must not abort a sourcing caller: align with hooks/fetch-conventions.sh which
# tolerates malformed config and exits 0.

function test_malformed_json_is_non_fatal_and_empty() {
  local dir
  dir=$(mktemp -d)
  make_binding "$dir" '{ this is not valid json'

  local output
  output=$(run_parse "$dir")
  assert_empty "$output"

  bash "$SCRIPT" "$dir" >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$dir"
}

# ---------- Test 8: Script passes shellcheck ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"

  if ! command -v shellcheck >/dev/null 2>&1; then
    bashunit::skip "shellcheck not installed" && return
  fi

  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}
