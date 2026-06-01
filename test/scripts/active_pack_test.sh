#!/bin/bash

# Tests for active-pack.sh: the shared resolve-chain helper (Slice C0).
# Usage contract: active-pack.sh <project-dir>
#   Echoes the ACTIVE pack dir (a dir containing pack.json) for that project, or
#   nothing. Resolution order:
#     1. Fast-path: $TDD_ACTIVE_PACK set & non-empty -> echo it verbatim, exit 0
#        (resolve chain NOT invoked).
#     2. Committed-binding path (works with $TDD_ACTIVE_PACK UNSET): parse
#        <project-dir>/.claude/tdd-conventions.json via parse-binding.sh; for
#        each bound source determine its local pack dir (dev -> local path;
#        non-dev -> cache dir under $CLAUDE_PLUGIN_DATA/conventions, skipped if
#        absent), then resolve-active-pack.sh picks the detect-matching one(s).
#     3. Degrade: no binding / no candidates / malformed / no match -> empty
#        stdout, exit 0 (PRIME-safe; never abort the caller).
# Synthetic fixtures only (the committed test/fixtures packs + mktemp projects).

SCRIPT="$(pwd)/scripts/active-pack.sh"
FIXTURES="$(pwd)/test/fixtures"
DART_FIXTURE="${FIXTURES}/dart-fixture"
CPP_FIXTURE="${FIXTURES}/cpp-fixture"

# Run the helper, suppressing stderr; stdout reaches the caller via $(...).
run_active_pack() {
  bash "$SCRIPT" "$@" 2>/dev/null
}

# Make a temp project dir; record it for teardown.
make_project() {
  local dir
  dir=$(mktemp -d)
  TMP_PROJECTS+=("$dir")
  echo "$dir"
}

# Write a dev-pack binding into <project-dir>/.claude/tdd-conventions.json for
# the given pack source path(s). Each path is bound as a local dev pack.
write_dev_binding() {
  local proj="$1"
  shift
  local packs="" src
  mkdir -p "$proj/.claude"
  for src in "$@"; do
    [ -n "$packs" ] && packs="${packs},"
    packs="${packs}{\"source\":\"${src}\",\"dev\":true}"
  done
  printf '{"packs":[%s]}\n' "$packs" >"$proj/.claude/tdd-conventions.json"
}

function set_up() {
  TMP_PROJECTS=()
  unset TDD_ACTIVE_PACK
}

function tear_down() {
  local dir
  for dir in "${TMP_PROJECTS[@]:-}"; do
    [ -n "$dir" ] && rm -rf "$dir"
  done
  unset TDD_ACTIVE_PACK
}

# ---------- Test 1: committed binding resolves with env UNSET ----------

function test_committed_binding_resolves_with_env_unset() {
  local proj
  proj=$(make_project)
  : >"$proj/pubspec.yaml"
  write_dev_binding "$proj" "$DART_FIXTURE"

  assert_same "$DART_FIXTURE" "$(run_active_pack "$proj")"

  bash "$SCRIPT" "$proj" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 2: $TDD_ACTIVE_PACK fast-path ----------

function test_env_var_fast_path_is_honored() {
  local proj
  # A project with NO resolvable binding: proves the fast-path short-circuits
  # before the resolve chain (chain would otherwise echo nothing).
  proj=$(make_project)
  export TDD_ACTIVE_PACK="$CPP_FIXTURE"

  assert_same "$CPP_FIXTURE" "$(run_active_pack "$proj")"

  bash "$SCRIPT" "$proj" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 3: data-driven match picks dart, not cpp ----------

function test_data_driven_match_picks_marker_pack() {
  local proj
  proj=$(make_project)
  : >"$proj/pubspec.yaml"
  write_dev_binding "$proj" "$DART_FIXTURE" "$CPP_FIXTURE"

  assert_same "$DART_FIXTURE" "$(run_active_pack "$proj")"
}

# ---------- Test 4 (edge): no binding + env unset -> empty, exit 0 ----------

function test_no_binding_env_unset_degrades_empty() {
  local proj
  proj=$(make_project)

  assert_empty "$(run_active_pack "$proj")"

  bash "$SCRIPT" "$proj" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 5 (edge): malformed binding never aborts ----------

function test_malformed_binding_degrades_empty() {
  local proj
  proj=$(make_project)
  mkdir -p "$proj/.claude"
  printf '{ this is not valid json ' >"$proj/.claude/tdd-conventions.json"

  assert_empty "$(run_active_pack "$proj")"

  bash "$SCRIPT" "$proj" >/dev/null 2>&1
  assert_exit_code 0
}

# ---------- Test 6: helper references no role file ----------

function test_helper_references_no_role_file() {
  assert_not_contains "role-" "$(cat "$SCRIPT")"
  assert_not_contains "role_" "$(cat "$SCRIPT")"
}
