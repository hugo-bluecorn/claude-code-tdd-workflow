#!/bin/bash

# Tests for iterate-binding.sh: the shared binding-iteration helper (Slice H1).
# It is SOURCED and exposes `iterate_binding <project-dir> <callback>`, which
# streams parse-binding's TAB tuples "<source>\t<version>\t<dev>" and invokes
# <callback> once per tuple with the THREE fields split CORRECTLY -- crucially
# preserving an EMPTY version field for a dev pack (the tab-collapse trap that
# a naive `IFS=$'\t' read` falls into, mis-reading version="dev").
#
# Synthetic fixtures only (mktemp project dirs with a committed binding).

SCRIPT="$(pwd)/scripts/iterate-binding.sh"

# Make a temp project dir; record it for teardown.
make_project() {
  local dir
  dir=$(mktemp -d)
  TMP_PROJECTS+=("$dir")
  echo "$dir"
}

# Write a raw binding JSON into <project-dir>/.claude/tdd-conventions.json.
write_binding() {
  local proj="$1" json="$2"
  mkdir -p "$proj/.claude"
  printf '%s\n' "$json" >"$proj/.claude/tdd-conventions.json"
}

function set_up() {
  TMP_PROJECTS=()
}

function tear_down() {
  local dir
  for dir in "${TMP_PROJECTS[@]:-}"; do
    [ -n "$dir" ] && rm -rf "$dir"
  done
  return 0
}

# ---------- Test 1 (FFT): dev pack preserves an EMPTY version field ----------

function test_dev_pack_preserves_empty_version() {
  local proj
  proj=$(make_project)
  write_binding "$proj" '{"packs":[{"source":"/some/local/pack","dev":true}]}'

  # Capture the callback's three args, one field per line, using a sentinel so
  # an EMPTY version is observable.
  local out
  out=$(
    # shellcheck source=/dev/null
    source "$SCRIPT"
    capture() { printf 'SRC=[%s]\nVER=[%s]\nDEV=[%s]\n' "$1" "$2" "$3"; }
    iterate_binding "$proj" capture
  )

  assert_contains "SRC=[/some/local/pack]" "$out"
  # version MUST be the empty string, NOT the literal "dev" (tab-collapse bug).
  assert_contains "VER=[]" "$out"
  assert_contains "DEV=[dev]" "$out"
}

# ---------- Test 2: versioned tuple intact ----------

function test_versioned_tuple_intact() {
  local proj
  proj=$(make_project)
  write_binding "$proj" '{"packs":[{"source":"file:///x/pack","version":"v1.2.0"}]}'

  local out
  out=$(
    # shellcheck source=/dev/null
    source "$SCRIPT"
    capture() { printf 'SRC=[%s]\nVER=[%s]\nDEV=[%s]\n' "$1" "$2" "$3"; }
    iterate_binding "$proj" capture
  )

  assert_contains "SRC=[file:///x/pack]" "$out"
  assert_contains "VER=[v1.2.0]" "$out"
  assert_contains "DEV=[]" "$out"
}

# ---------- Test 3 (edge): leading-tab / empty source line is skipped ---------

function test_no_binding_invokes_callback_zero_times() {
  local proj
  proj=$(make_project)
  # No binding file at all -> parse-binding emits nothing -> no callback.

  local out
  out=$(
    # shellcheck source=/dev/null
    source "$SCRIPT"
    capture() { printf 'CALLED\n'; }
    iterate_binding "$proj" capture
  )

  assert_empty "$out"
}
