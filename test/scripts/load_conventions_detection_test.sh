#!/bin/bash

# Fast, fixture-driven tests for scripts/load-conventions.sh DETECTION track.
#
# These prove detection is DATA-DRIVEN via the C0 foundation (active-pack.sh)
# rather than the four hardcoded literal dirnames the script used to carry
# (dart-flutter-conventions / cpp-testing-conventions / bash-testing-conventions
# / c-conventions). They use synthetic packs bound as DEV packs with the env var
# UNSET (committed-binding fallback) and assert the resolved pack's standards
# content reaches stdout. No network: the slow real-clone CONTENT track lives in
# load_conventions_test.sh / load_conventions_config_test.sh.
#
# Floor: every test makes >=1 assertion (fail-on-risky enforced).

SCRIPT="$(pwd)/scripts/load-conventions.sh"

# ---------- Helpers ----------

make_dir() {
  local dir
  dir=$(mktemp -d)
  TMP_DIRS+=("$dir")
  echo "$dir"
}

# Build a synthetic pack dir whose detect data matches a Dart project and whose
# standards content carries a UNIQUE marker string. The pack dirname is
# deliberately NOT one of the four legacy literals, so emitting its content
# proves the resolution path is data-driven (derived from the pack), not a
# hardcoded dirname lookup.
make_dart_pack() {
  local root pack
  root=$(make_dir)
  pack="$root/totally-not-a-legacy-dirname"
  mkdir -p "$pack/standards"
  cat >"$pack/pack.json" <<'EOF'
{
  "schemaVersion": 1,
  "name": "synthetic-dart-pack",
  "version": "1.0.0",
  "language": "Dart/Flutter",
  "detect": { "extensions": [".dart"], "markers": ["pubspec.yaml"] },
  "commands": { "test": { "granularity": "file", "run": "flutter test {file}" } },
  "testFilePattern": "*_test.dart",
  "standards": { "index": "SKILL.md", "dir": "standards/" }
}
EOF
  printf 'SYNTHETIC_INDEX_MARKER dart standards index\n' >"$pack/SKILL.md"
  printf 'SYNTHETIC_REFERENCE_MARKER dart reference content\n' \
    >"$pack/standards/guide.md"
  echo "$pack"
}

# Write a dev-pack binding for the given pack source path(s).
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

# Run load-conventions.sh inside <dir>, env var unset, stderr suppressed.
run_load_in_dir() {
  local dir="$1"
  (cd "$dir" && unset TDD_ACTIVE_PACK && bash "$SCRIPT" 2>/dev/null)
}

# ---------- Suite setup / teardown ----------

function set_up() {
  TMP_DIRS=()
  unset TDD_ACTIVE_PACK
}

function tear_down() {
  local dir
  for dir in "${TMP_DIRS[@]:-}"; do
    [ -n "$dir" ] && rm -rf "$dir"
  done
  unset TDD_ACTIVE_PACK
}

# ---------- Test 1: data-driven detection (env unset, committed binding) ----------

function test_detection_is_data_driven_from_active_pack() {
  local pack proj output
  pack=$(make_dart_pack)
  proj=$(make_dir)
  : >"$proj/pubspec.yaml"
  write_dev_binding "$proj" "$pack"

  output=$(run_load_in_dir "$proj")

  # The resolved pack's index + reference content is emitted...
  assert_contains "SYNTHETIC_INDEX_MARKER" "$output"
  assert_contains "SYNTHETIC_REFERENCE_MARKER" "$output"
  # ...and it works for a pack whose dirname is NOT a legacy literal, proving
  # the resolution path does not hardcode dart-flutter-conventions.
  assert_not_contains "dart-flutter-conventions" "$output"
}

# ---------- Test 2: bash project, no pack -> degrades cleanly ----------

function test_bash_project_no_pack_degrades_cleanly() {
  local proj output rc
  proj=$(make_dir)
  : >"$proj/my_test.sh"
  # No binding, no CLAUDE_PLUGIN_DATA cache -> nothing resolves.
  output=$(cd "$proj" && unset TDD_ACTIVE_PACK CLAUDE_PLUGIN_DATA && bash "$SCRIPT" 2>/dev/null)
  rc=$?

  assert_equals 0 "$rc"
  assert_empty "$output"
}

# ---------- Test 3 (edge): no detected type -> empty stdout, exit 0 ----------

function test_no_detected_type_emits_nothing() {
  local proj output rc
  proj=$(make_dir)
  : >"$proj/README.txt"
  output=$(cd "$proj" && unset TDD_ACTIVE_PACK CLAUDE_PLUGIN_DATA && bash "$SCRIPT" 2>/dev/null)
  rc=$?

  assert_equals 0 "$rc"
  assert_empty "$output"
}

# ---------- Test 4 (edge): malformed binding -> falls back, exit 0 ----------

function test_malformed_binding_falls_back_without_aborting() {
  local proj rc
  proj=$(make_dir)
  : >"$proj/pubspec.yaml"
  mkdir -p "$proj/.claude"
  printf 'not valid json {{{\n' >"$proj/.claude/tdd-conventions.json"

  # No cache to fall back into either -> empty, but crucially exit 0 (no abort).
  (cd "$proj" && unset TDD_ACTIVE_PACK CLAUDE_PLUGIN_DATA && bash "$SCRIPT" >/dev/null 2>&1)
  rc=$?

  assert_equals 0 "$rc"
}

# ---------- Test 5: script passes shellcheck ----------

function test_passes_shellcheck() {
  assert_file_exists "$SCRIPT"
  shellcheck -S warning "$SCRIPT"
  assert_exit_code 0
}

# ---------- Test 6: no role file referenced (PRIME directive) ----------

function test_references_no_role_file() {
  local hits
  hits=$(grep -E 'role[-_]' "$SCRIPT" || true)
  assert_empty "$hits"
}
