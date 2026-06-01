#!/bin/bash

# Test suite for fetch-conventions.sh — C3 no-pack warn-and-proceed floor (Slice 5).
#
# When a NON-bash language marker is detected in the project but NO convention
# pack resolves for it, the SessionStart hook emits the advisory
#   "no convention pack for <lang>; TDD will proceed on training data + session
#    context only"
# to stderr and PROCEEDS (exit 0). It never hard-stops and never emits a
# hardcoded fallback test/lint/format command. bashunit stays the built-in
# default, so bash-only and marker-less projects never warn.
#
# All fixtures are offline (mktemp -d / locally-created tagged file:// repos).

HOOK="hooks/fetch-conventions.sh"
PROJECT_ROOT="$(pwd)"
HOOK_ABS="$PROJECT_ROOT/$HOOK"

# ---------- shared helpers ----------

# Create a tmp env: project dir with .claude config dir + plugin-data cache dir.
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/.claude"
  mkdir -p "$tmp_dir/plugin-data"
  echo "$tmp_dir"
}

# Run the hook inside a project dir, capturing STDERR only (stdout discarded).
run_hook_stderr() {
  local dir="$1"
  { cd "$dir" && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 1>/dev/null; } 2>&1
}

# Run the hook capturing STDOUT only (stderr discarded).
run_hook_stdout() {
  local dir="$1"
  (cd "$dir" && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 2>/dev/null)
}

# Run the hook discarding all output; returns its exit code.
run_hook_rc() {
  local dir="$1"
  (cd "$dir" && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" >/dev/null 2>&1)
}

# Build a bare-cloneable fixture git repo whose pack.json declares the given
# detect.markers so it RESOLVES for a project containing that marker. Echoes the
# repo path. Tagged v1.0.0.
create_resolving_pack_repo() {
  local base="$1" marker="$2"
  local repo="$base/fixture-pack"
  mkdir -p "$repo"
  git -C "$repo" init --quiet
  git -C "$repo" config user.email "fixture@example.com"
  git -C "$repo" config user.name "Fixture"
  git -C "$repo" config commit.gpgsign false

  cat > "$repo/pack.json" << EOF
{"schemaVersion":1,"name":"fixture-conventions","version":"1.0.0","language":"Dart/Flutter","detect":{"markers":["$marker"],"extensions":[]}}
EOF
  git -C "$repo" add pack.json
  git -C "$repo" commit --quiet -m "pack v1.0.0"
  git -C "$repo" tag v1.0.0

  echo "$repo"
}

# ---------- Test 1: non-bash marker, no resolved pack -> advisory + proceed ----------

function test_non_bash_marker_no_pack_emits_advisory_and_proceeds() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  # A non-bash marker present, but NO binding resolves a pack for it.
  : > "$tmp_dir/pubspec.yaml"

  local stderr_output
  stderr_output=$(run_hook_stderr "$tmp_dir")

  assert_contains "no convention pack" "$stderr_output"
  assert_contains "Dart" "$stderr_output"

  run_hook_rc "$tmp_dir"
  assert_equals 0 "$?"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: advisory names the detected language (C/C++) ----------

function test_advisory_names_detected_language() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  : > "$tmp_dir/CMakeLists.txt"

  local stderr_output
  stderr_output=$(run_hook_stderr "$tmp_dir")

  assert_contains "no convention pack" "$stderr_output"
  # The <lang> label comes from the advisory map (filled from detection), so a
  # CMake project must name C/C++ — proving it is not a fixed string.
  assert_contains "C/C++" "$stderr_output"
  # And must NOT name the other language.
  assert_not_contains "Dart" "$stderr_output"

  run_hook_rc "$tmp_dir"
  assert_equals 0 "$?"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: a resolved pack suppresses the warning ----------

function test_resolved_pack_suppresses_warning() {
  local tmp_dir repo
  tmp_dir=$(create_tmp_env)
  : > "$tmp_dir/pubspec.yaml"
  repo=$(create_resolving_pack_repo "$tmp_dir" "pubspec.yaml")

  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "file://$repo", "version": "v1.0.0"}]}
EOF

  local stderr_output
  stderr_output=$(run_hook_stderr "$tmp_dir")

  # A pack resolved for pubspec.yaml — no no-pack advisory must fire.
  assert_not_contains "no convention pack" "$stderr_output"

  run_hook_rc "$tmp_dir"
  assert_equals 0 "$?"

  rm -rf "$tmp_dir"
}

# ---------- Test 4 (edge): bash-only project never triggers the advisory ----------

function test_bash_only_never_warns() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  # Only a bash test file; no non-bash marker.
  : > "$tmp_dir/example_test.sh"

  local stderr_output
  stderr_output=$(run_hook_stderr "$tmp_dir")

  assert_not_contains "no convention pack" "$stderr_output"

  run_hook_rc "$tmp_dir"
  assert_equals 0 "$?"

  rm -rf "$tmp_dir"
}

# ---------- Test 5 (edge): no recognizable marker at all -> silent ----------

function test_no_marker_is_silent() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  # Empty project: no markers, no binding.

  local stderr_output
  stderr_output=$(run_hook_stderr "$tmp_dir")

  assert_not_contains "no convention pack" "$stderr_output"

  run_hook_rc "$tmp_dir"
  assert_equals 0 "$?"

  rm -rf "$tmp_dir"
}

# ---------- Test 6 (edge): advisory does not block / no fallback chain ----------

function test_advisory_emits_no_fallback_command() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  : > "$tmp_dir/pubspec.yaml"

  # Under the warn condition the ONLY extra action is the stderr advisory:
  # no hardcoded test/lint/format command may be printed to stdout or executed.
  local stdout_output
  stdout_output=$(run_hook_stdout "$tmp_dir")

  assert_not_contains "flutter test" "$stdout_output"
  assert_not_contains "ctest" "$stdout_output"
  assert_not_contains "cmake" "$stdout_output"
  assert_not_contains "dart test" "$stdout_output"

  run_hook_rc "$tmp_dir"
  assert_equals 0 "$?"

  rm -rf "$tmp_dir"
}
