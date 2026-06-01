#!/bin/bash

# Test-speed gate — verifies the fast-subset runner (scripts/run-fast-tests.sh)
# excludes the slow network-integration tests (real git clones) so per-slice
# verification runs fast and offline, while the full suite (release/CI, plain
# `./lib/bashunit test/`) still runs everything. The slow files are KEPT, just
# not run by the fast subset.
#
# All checks here are fast and offline: they inspect the runner's --list output
# and file presence; they never invoke the slow tests.

ROOT="$(pwd)"
RUNNER="$ROOT/scripts/run-fast-tests.sh"

# The slow files the fast subset must exclude (kept; run in full at release/CI).
SLOW_FILES=(
  "test/integration/external_conventions_repo_test.sh"
  "test/integration/convention_loading_integration_test.sh"
  "test/scripts/load_conventions_test.sh"
  "test/scripts/load_conventions_config_test.sh"
  "test/hooks/fetch_conventions_test.sh"
)

# ---------- The runner exists and is usable ----------

function test_fast_runner_exists_and_is_executable() {
  assert_file_exists "$RUNNER"
  test -x "$RUNNER"
  assert_exit_code 0
}

# ---------- The fast subset EXCLUDES every slow file ----------

function test_fast_subset_excludes_slow_network_files() {
  local listing
  listing=$(cd "$ROOT" && bash "$RUNNER" --list 2>&1)
  local slow
  for slow in "${SLOW_FILES[@]}"; do
    assert_not_contains "$slow" "$listing"
  done
}

# ---------- The fast subset is non-empty (includes fast files) ----------

function test_fast_subset_includes_fast_files() {
  local listing
  listing=$(cd "$ROOT" && bash "$RUNNER" --list 2>&1)
  # A representative fast unit test must be present.
  assert_contains "test/scripts/read_pack_test.sh" "$listing"
  # The gate's own test is a fast test and should be in the subset.
  assert_contains "test/integration/test_speed_gate_test.sh" "$listing"
}

# ---------- The slow files are KEPT (not deleted) ----------

function test_slow_files_are_kept() {
  local slow
  for slow in "${SLOW_FILES[@]}"; do
    assert_file_exists "$ROOT/$slow"
  done
}

# ---------- The verifier consumes the fast subset ----------

function test_verifier_doc_wires_fast_runner() {
  # Per-slice verification must run the fast subset, so the verifier doc has to
  # reference the runner. Release/CI runs the plain command (full suite).
  local doc="$ROOT/agents/tdd-verifier.md"
  assert_file_exists "$doc"
  assert_contains "run-fast-tests.sh" "$(cat "$doc")"
}
