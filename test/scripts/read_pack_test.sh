#!/bin/bash

# Tests for read-pack.sh: pack.json field reader.
# Usage contract: read-pack.sh <pack-dir> <field-path>
# Reads <pack-dir>/pack.json and prints the requested dotted field to stdout.
# Synthetic fixtures only (mktemp); no dependency on any real pack.

SCRIPT="$(pwd)/scripts/read-pack.sh"

# Helper: run the reader, suppressing stderr; stdout to caller via $(...)
run_read() {
  local dir="$1" field="$2"
  bash "$SCRIPT" "$dir" "$field" 2>/dev/null
}

# Helper: capture stderr while suppressing stdout
# shellcheck disable=SC2069
run_read_stderr() {
  local dir="$1" field="$2"
  bash "$SCRIPT" "$dir" "$field" 2>&1 >/dev/null
}

# Fixture: dart-shaped pack (single-step test command, NO setup/variants)
make_dart_pack() {
  local dir
  dir=$(mktemp -d)
  cat >"$dir/pack.json" <<'JSON'
{
  "schemaVersion": 1,
  "name": "dart-flutter-conventions",
  "version": "1.0.0",
  "language": "Dart/Flutter",
  "detect": {
    "extensions": [".dart"],
    "markers": ["pubspec.yaml"]
  },
  "commands": {
    "test": {
      "granularity": "file",
      "run": "flutter test {file}",
      "passOn": "exitZero"
    },
    "lint": "flutter analyze",
    "format": "dart format .",
    "coverage": "flutter test --coverage"
  },
  "testFilePattern": "**/*_test.dart",
  "implToTestMap": "lib/{path}.dart -> test/{path}_test.dart",
  "versionFiles": ["pubspec.yaml"],
  "projectFiles": ["pubspec.yaml", "analysis_options.yaml"],
  "standards": {
    "index": "STANDARDS.md",
    "dir": "standards"
  }
}
JSON
  echo "$dir"
}

# Fixture: cpp-shaped pack (granularity suite, setup[], variants[])
make_cpp_pack() {
  local dir
  dir=$(mktemp -d)
  cat >"$dir/pack.json" <<'JSON'
{
  "schemaVersion": 1,
  "name": "cpp-conventions",
  "version": "2.1.0",
  "language": "C++",
  "detect": {
    "extensions": [".cpp", ".hpp"],
    "markers": ["CMakeLists.txt"]
  },
  "commands": {
    "test": {
      "granularity": "suite",
      "setup": ["cmake --preset {variant}", "cmake --build build-{variant}"],
      "run": "ctest --preset {variant} --output-on-failure",
      "passOn": "exitZero",
      "variants": [
        {"name": "tdd-asan", "default": true},
        {"name": "tdd-tsan"}
      ]
    },
    "lint": "clang-tidy",
    "format": "clang-format -i",
    "coverage": "ctest -T Coverage"
  },
  "testFilePattern": "**/*_test.cpp",
  "implToTestMap": "src/{path}.cpp -> test/{path}_test.cpp",
  "versionFiles": ["CMakeLists.txt"],
  "projectFiles": ["CMakeLists.txt", "conanfile.txt"],
  "standards": {
    "index": "STANDARDS.md",
    "dir": "standards"
  }
}
JSON
  echo "$dir"
}

# ---------- Test 1: Reads top-level scalar fields ----------

function test_reads_top_level_scalars() {
  local dir
  dir=$(make_dart_pack)

  assert_equals "dart-flutter-conventions" "$(run_read "$dir" name)"
  assert_equals "1.0.0" "$(run_read "$dir" version)"
  assert_equals "Dart/Flutter" "$(run_read "$dir" language)"
  assert_equals "1" "$(run_read "$dir" schemaVersion)"

  rm -rf "$dir"
}

# ---------- Test 2: Reads nested detect arrays newline-delimited ----------

function test_reads_detect_arrays() {
  local dir
  dir=$(make_cpp_pack)

  assert_equals ".cpp
.hpp" "$(run_read "$dir" detect.extensions)"
  assert_equals "CMakeLists.txt" "$(run_read "$dir" detect.markers)"

  rm -rf "$dir"
}

# ---------- Test 3: Reads the rich commands.test object fields ----------

function test_reads_commands_test_object() {
  local dir
  dir=$(make_cpp_pack)

  assert_equals "suite" "$(run_read "$dir" commands.test.granularity)"
  assert_equals "cmake --preset {variant}
cmake --build build-{variant}" "$(run_read "$dir" commands.test.setup)"
  assert_equals "ctest --preset {variant} --output-on-failure" "$(run_read "$dir" commands.test.run)"
  assert_equals "exitZero" "$(run_read "$dir" commands.test.passOn)"

  rm -rf "$dir"
}

# ---------- Test 4: Reads sibling command + top-level mapping/version fields ----------

function test_reads_sibling_and_top_level_fields() {
  local dir
  dir=$(make_dart_pack)

  assert_equals "flutter analyze" "$(run_read "$dir" commands.lint)"
  assert_equals "dart format ." "$(run_read "$dir" commands.format)"
  assert_equals "flutter test --coverage" "$(run_read "$dir" commands.coverage)"
  assert_equals "**/*_test.dart" "$(run_read "$dir" testFilePattern)"
  assert_equals "lib/{path}.dart -> test/{path}_test.dart" "$(run_read "$dir" implToTestMap)"
  assert_equals "pubspec.yaml" "$(run_read "$dir" versionFiles)"
  assert_equals "pubspec.yaml
analysis_options.yaml" "$(run_read "$dir" projectFiles)"
  assert_equals "STANDARDS.md" "$(run_read "$dir" standards.index)"
  assert_equals "standards" "$(run_read "$dir" standards.dir)"

  rm -rf "$dir"
}

# ---------- Test 5: Reads variant names in order ----------
# Accessor shape: commands.test.variants emits the variant NAMES, one per line,
# in declared order (the array-of-objects is projected down to .name).

function test_reads_variant_names_in_order() {
  local dir
  dir=$(make_cpp_pack)

  assert_equals "tdd-asan
tdd-tsan" "$(run_read "$dir" commands.test.variants)"

  rm -rf "$dir"
}

# ---------- Test 6: Absent optional field yields empty output, exit 0 ----------

function test_absent_optional_field_is_empty_not_error() {
  local dir
  dir=$(make_dart_pack)

  local output
  output=$(run_read "$dir" commands.test.setup)
  assert_empty "$output"

  bash "$SCRIPT" "$dir" commands.test.setup >/dev/null 2>&1
  assert_exit_code 0

  rm -rf "$dir"
}

# ---------- Test 7: Missing pack.json fails non-zero with diagnostic ----------

function test_missing_pack_json_fails() {
  local dir
  dir=$(mktemp -d)

  bash "$SCRIPT" "$dir" name >/dev/null 2>&1
  assert_exit_code 1

  local err
  err=$(run_read_stderr "$dir" name)
  assert_contains "pack.json" "$err"

  rm -rf "$dir"
}

# ---------- Test 8: Malformed JSON fails non-zero with diagnostic ----------

function test_malformed_json_fails() {
  local dir
  dir=$(mktemp -d)
  printf '{ this is not valid json' >"$dir/pack.json"

  bash "$SCRIPT" "$dir" name >/dev/null 2>&1
  assert_exit_code 1

  local err
  err=$(run_read_stderr "$dir" name)
  assert_contains "parse" "$err"

  rm -rf "$dir"
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
