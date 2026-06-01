#!/bin/bash

# Test suite for auto-run-tests.sh hook — .sh file support
# Tests that the hook correctly triggers bashunit for shell files.

HOOK="hooks/auto-run-tests.sh"
PROJECT_ROOT="$(pwd)"
HOOK_ABS="$PROJECT_ROOT/$HOOK"

# Helper: build PostToolUse JSON for a given file path
build_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"echo hello"},"agent_type":"tdd-workflow:tdd-implementer"}\n' "$file_path"
}

# Helper: run the hook with a given file path from the project root
run_hook() {
  local file_path="$1"
  local json
  json=$(build_json "$file_path")
  echo "$json" | bash "$HOOK_ABS" 2>/dev/null
}

# Helper: create a tmp dir with the hook copied in, return the path
# Usage: tmp_dir=$(create_tmp_env [--with-bashunit])
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/hooks"
  cp "$HOOK_ABS" "$tmp_dir/$HOOK"
  if [[ "${1:-}" == "--with-bashunit" ]]; then
    mkdir -p "$tmp_dir/lib"
    cp "$PROJECT_ROOT/lib/bashunit" "$tmp_dir/lib/bashunit"
    chmod +x "$tmp_dir/lib/bashunit"
  fi
  echo "$tmp_dir"
}

# Helper: run the hook inside a tmp dir
run_hook_in_tmp() {
  local tmp_dir="$1"
  local file_path="$2"
  local json
  json=$(build_json "$file_path")
  (cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
}

# ---------- Test 1: Detects .sh file changes and triggers bashunit ----------

function test_sh_file_triggers_bashunit() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source and matching test file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/my_script.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "hooks/my_script.sh")

  assert_contains "bashunit" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: Detects _test.sh directly and runs bashunit on it ----------

function test_test_sh_file_runs_bashunit_directly() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create only the test file (simulating editing a test directly)
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "test/hooks/my_script_test.sh")

  assert_contains "bashunit" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Reports when no matching test file found ----------

function test_sh_no_matching_test_file() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source file but no matching test file
  echo '#!/bin/bash' > "$tmp_dir/hooks/orphan.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "hooks/orphan.sh")

  assert_contains "systemMessage" "$output"
  assert_contains "No matching test file" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 4: C++ suite pack runs ctest (FALSE-GREEN FIX), not bashunit ----------

function test_cpp_suite_pack_runs_ctest_not_bashunit() {
  local proj
  proj=$(make_cpp_project)

  local json output
  json=$(build_json "src/parser.cpp")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$CPP_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # FALSE-GREEN FIX PROOF: a ctest invocation occurs; the hook no longer
  # builds-only via cmake without running the test runner.
  assert_contains "CTEST_STUB_INVOKED" "$output"
  assert_contains "systemMessage" "$output"
  assert_not_contains "bashunit" "$output"

  rm -rf "$proj"
}

# ---------- Edge Case: bashunit not installed ----------

function test_sh_file_when_bashunit_not_installed() {
  local tmp_dir
  # Create env WITHOUT bashunit (no --with-bashunit flag)
  tmp_dir=$(create_tmp_env)

  # Create source and matching test file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/my_script.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local json
  json=$(build_json "hooks/my_script.sh")
  local output
  local exit_code
  # Restrict PATH so bashunit is not found on PATH either
  output=$(cd "$tmp_dir" && PATH="/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
  exit_code=$?

  assert_contains "systemMessage" "$output"
  assert_contains "not installed" "$output"
  assert_equals 0 "$exit_code"

  rm -rf "$tmp_dir"
}

# ==========================================================================
# Slice 2 — JSON Output Safety Tests
# Tests that the hook produces valid JSON even when RESULT contains
# special characters (double quotes, newlines, backslashes).
# ==========================================================================

# ---------- JSON Safety Test 1: Double quotes in RESULT ----------

function test_json_valid_with_double_quotes_in_result() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/quotey.sh"

  # Create test file whose output contains double-quote characters
  cat > "$tmp_dir/test/hooks/quotey_test.sh" << 'TESTEOF'
#!/bin/bash
function test_with_quotes() {
  echo 'Value is "hello world"'
  assert_equals 1 1
}
TESTEOF
  chmod +x "$tmp_dir/test/hooks/quotey_test.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "hooks/quotey.sh")

  # The output must be valid JSON parseable by jq
  echo "$output" | jq . > /dev/null 2>&1
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- JSON Safety Test 2: Newlines in RESULT ----------

function test_json_valid_with_newlines_in_result() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/newliney.sh"

  # Create test file whose output contains newlines
  cat > "$tmp_dir/test/hooks/newliney_test.sh" << 'TESTEOF'
#!/bin/bash
function test_with_newlines() {
  printf 'Line1\nLine2\nLine3\n'
  assert_equals 1 1
}
TESTEOF
  chmod +x "$tmp_dir/test/hooks/newliney_test.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "hooks/newliney.sh")

  # The output must be valid JSON parseable by jq
  echo "$output" | jq . > /dev/null 2>&1
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- JSON Safety Test 3: Backslashes in RESULT ----------

function test_json_valid_with_backslashes_in_result() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/slashy.sh"

  # Create test file whose output contains backslash characters
  cat > "$tmp_dir/test/hooks/slashy_test.sh" << 'TESTEOF'
#!/bin/bash
function test_with_backslashes() {
  printf 'path\\to\\file\n'
  assert_equals 1 1
}
TESTEOF
  chmod +x "$tmp_dir/test/hooks/slashy_test.sh"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "hooks/slashy.sh")

  # The output must be valid JSON parseable by jq
  echo "$output" | jq . > /dev/null 2>&1
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- JSON Safety Test 4: bashunit not installed produces valid JSON ----------

function test_json_valid_for_bashunit_not_installed() {
  local tmp_dir
  # Create env WITHOUT bashunit
  tmp_dir=$(create_tmp_env)

  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/no_runner.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/no_runner_test.sh"

  local json
  json=$(build_json "hooks/no_runner.sh")
  local output
  output=$(cd "$tmp_dir" && PATH="/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  # Must be valid JSON
  echo "$output" | jq . > /dev/null 2>&1
  assert_exit_code 0

  # Must mention "not installed"
  local msg
  msg=$(echo "$output" | jq -r '.systemMessage')
  assert_contains "not installed" "$msg"

  rm -rf "$tmp_dir"
}

# ---------- JSON Safety Test 6: Non-source file exits silently ----------

function test_non_source_file_exits_silently() {
  local output
  local exit_code
  output=$(run_hook "docs/readme.txt")
  exit_code=$?

  assert_equals 0 "$exit_code"
  assert_equals "" "$output"
}

# ==========================================================================
# Slice C2 — Pack-driven test command (file-granularity / dart path)
# Tests that the hook resolves the active pack via scripts/active-pack.sh,
# reads commands.test.run, substitutes {file} with the derived test file, and
# emits the resulting command in the informational systemMessage. The .sh
# bashunit built-in default and the C++/suite path are NOT touched here.
# ==========================================================================

DART_FIXTURE="$PROJECT_ROOT/test/fixtures/dart-fixture"
CPP_FIXTURE="$PROJECT_ROOT/test/fixtures/cpp-fixture"

# Helper: scaffold a temp C++ project (CMakeLists.txt marker + a .cpp source)
# with stub `cmake` and `ctest` on PATH. Each stub appends an identifiable
# marker plus its args to "$proj/invocations.log" (preserving call ORDER) and
# also echoes to stdout. Echoes the project dir.
make_cpp_project() {
  local proj
  proj=$(mktemp -d)
  echo 'cmake_minimum_required(VERSION 3.20)' > "$proj/CMakeLists.txt"
  mkdir -p "$proj/src"
  echo 'int main() {}' > "$proj/src/parser.cpp"
  mkdir -p "$proj/bin"
  cat > "$proj/bin/cmake" << STUB
#!/bin/bash
echo "CMAKE_STUB_INVOKED: \$*" | tee -a "$proj/invocations.log"
STUB
  cat > "$proj/bin/ctest" << STUB
#!/bin/bash
echo "CTEST_STUB_INVOKED: \$*" | tee -a "$proj/invocations.log"
STUB
  chmod +x "$proj/bin/cmake" "$proj/bin/ctest"
  printf '%s\n' "$proj"
}

# Helper: scaffold a temp dart project with a derivable test file + a stub
# `flutter` that echoes an identifiable marker plus its args. Echoes the dir.
make_dart_project() {
  local proj
  proj=$(mktemp -d)
  # A pubspec.yaml marker so detection (committed-binding path) matches.
  echo 'name: tmp_app' > "$proj/pubspec.yaml"
  mkdir -p "$proj/lib/models" "$proj/test/models"
  echo 'void main() {}' > "$proj/lib/models/user.dart"
  echo 'void main() {}' > "$proj/test/models/user_test.dart"
  # Stub flutter so the pack command "flutter test {file}" is observable.
  mkdir -p "$proj/bin"
  cat > "$proj/bin/flutter" << 'STUB'
#!/bin/bash
echo "FLUTTER_STUB_INVOKED: $*"
STUB
  chmod +x "$proj/bin/flutter"
  printf '%s\n' "$proj"
}

# ---------- C2 Test 1: Pack-driven command (TDD_ACTIVE_PACK fast-path) ----------

function test_dart_pack_driven_command_via_env_fast_path() {
  local proj
  proj=$(make_dart_project)

  local json output
  json=$(build_json "lib/models/user.dart")
  # Run the REAL hook (so ../scripts/active-pack.sh resolves) from inside the
  # temp project. TDD_ACTIVE_PACK fast-path points the resolver at the dart pack.
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$DART_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # The pack's commands.test.run is "flutter test {file}" -> the stub fires and
  # {file} is substituted to the derived test path.
  assert_contains "FLUTTER_STUB_INVOKED" "$output"
  assert_contains "test/models/user_test.dart" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$proj"
}

# ---------- C2 Test 2: Pack-driven command via committed binding, env unset ----------

function test_dart_pack_driven_command_via_committed_binding_env_unset() {
  local proj
  proj=$(make_dart_project)

  # Bind the dart fixture as a DEV pack so active-pack.sh resolves it with the
  # env var UNSET (committed-binding fallback).
  mkdir -p "$proj/.claude"
  cat > "$proj/.claude/tdd-conventions.json" << JSON
{ "packs": [ { "source": "$DART_FIXTURE", "dev": true } ] }
JSON

  local json output
  json=$(build_json "lib/models/user.dart")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && unset TDD_ACTIVE_PACK \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # Same pack-driven command appears via the committed binding (no env).
  assert_contains "FLUTTER_STUB_INVOKED" "$output"
  assert_contains "test/models/user_test.dart" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$proj"
}

# ---------- C2 Test 3 (edge): Pack extension, no active pack degrades silently ----------

function test_dart_no_active_pack_degrades_silently() {
  local proj
  proj=$(make_dart_project)
  # No binding file, no TDD_ACTIVE_PACK -> no pack resolves.

  local json output exit_code
  json=$(build_json "lib/models/user.dart")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && unset TDD_ACTIVE_PACK \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)
  exit_code=$?

  # Graceful no-op: exit 0, and no fabricated command was run.
  assert_equals 0 "$exit_code"
  assert_not_contains "FLUTTER_STUB_INVOKED" "$output"
  # If anything is emitted it must be valid JSON (never a decision:block).
  if [[ -n "$output" ]]; then
    echo "$output" | jq -e 'has("systemMessage") and (has("decision") | not)' > /dev/null 2>&1
    assert_exit_code 0
  fi

  rm -rf "$proj"
}

# ---------- C2 Test 4: Output is informational systemMessage, never decision:block ----------

function test_pack_driven_output_is_informational_never_block() {
  local proj
  proj=$(make_dart_project)

  local json output
  json=$(build_json "lib/models/user.dart")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$DART_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # Valid JSON carrying systemMessage, with no decision/block field.
  echo "$output" | jq -e 'has("systemMessage") and (has("decision") | not) and (has("block") | not)' > /dev/null 2>&1
  assert_exit_code 0

  rm -rf "$proj"
}

# ---------- C++ Test 6: setup[] steps run BEFORE the test command, in order ----------

function test_cpp_suite_setup_runs_before_ctest_in_order() {
  local proj
  proj=$(make_cpp_project)

  local json output
  json=$(build_json "src/parser.cpp")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$CPP_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # The invocation log records call ORDER: both cmake setup steps must precede
  # the ctest run. Lines (in order): cmake --preset, cmake --build, ctest.
  local log="$proj/invocations.log"
  assert_file_exists "$log"

  local first_cmake_line build_line ctest_line
  first_cmake_line=$(grep -n 'CMAKE_STUB_INVOKED: --preset' "$log" | head -1 | cut -d: -f1)
  build_line=$(grep -n 'CMAKE_STUB_INVOKED: --build' "$log" | head -1 | cut -d: -f1)
  ctest_line=$(grep -n 'CTEST_STUB_INVOKED' "$log" | head -1 | cut -d: -f1)

  # Both setup steps appear, and both precede ctest.
  assert_not_equals "" "$first_cmake_line"
  assert_not_equals "" "$build_line"
  assert_not_equals "" "$ctest_line"
  assert_equals 1 "$(( first_cmake_line < ctest_line ? 1 : 0 ))"
  assert_equals 1 "$(( build_line < ctest_line ? 1 : 0 ))"
  assert_equals 1 "$(( first_cmake_line < build_line ? 1 : 0 ))"

  rm -rf "$proj"
}

# ---------- C++ Test 7: {variant} substituted from the pack's default variant ----------

function test_cpp_suite_substitutes_default_variant() {
  local proj
  proj=$(make_cpp_project)

  local json output
  json=$(build_json "src/parser.cpp")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$CPP_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # The cpp fixture's default variant is "tdd-asan". The emitted/logged commands
  # must contain that name, never the literal "{variant}" placeholder.
  local log="$proj/invocations.log"
  assert_file_contains "$log" "tdd-asan"
  assert_not_contains "{variant}" "$(cat "$log")"

  rm -rf "$proj"
}

# ---------- C++ Test 8: single-step (file-granularity) pack runs ONLY run, no setup ----------

function test_file_granularity_pack_runs_only_run_no_setup() {
  local proj
  proj=$(make_dart_project)

  local json output
  json=$(build_json "lib/models/user.dart")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$DART_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # The dart fixture has NO setup[] and granularity "file": only the run command
  # (flutter test) fires; no setup steps are fabricated (preserves C2).
  assert_contains "FLUTTER_STUB_INVOKED" "$output"
  assert_not_contains "cmake" "$output"
  assert_not_contains "ctest" "$output"

  rm -rf "$proj"
}

# ---------- C++ Test 9: C++ project with no pack degrades (no fabricated command) ----------

function test_cpp_no_pack_degrades_no_fabricated_command() {
  local proj
  proj=$(make_cpp_project)
  # No binding file, no TDD_ACTIVE_PACK -> no pack resolves.

  local json output exit_code
  json=$(build_json "src/parser.cpp")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && unset TDD_ACTIVE_PACK \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)
  exit_code=$?

  # Graceful: exit 0, no built-in C++ default, no fabricated cmake/ctest run.
  assert_equals 0 "$exit_code"
  assert_not_contains "CTEST_STUB_INVOKED" "$output"
  assert_not_contains "CMAKE_STUB_INVOKED" "$output"
  # No invocation log was written (no command fired).
  assert_file_not_exists "$proj/invocations.log"

  rm -rf "$proj"
}

# ==========================================================================
# Slice H2 — Polyglot pack selection (iterate all matches, not head-1)
# A repo with BOTH a dart pack and a cpp pack bound (dart declared FIRST) must
# select the pack whose detect.extensions claims the EDITED file's extension,
# not merely the first resolved pack. The FFT proves ctest ACTUALLY FIRES for a
# .cpp edit despite dart being first — guarding against the C3 false-green
# resurrection (a fall-through to the built-in cmake-only branch runs no ctest).
# ==========================================================================

# Helper: scaffold a temp POLYGLOT project carrying BOTH markers (pubspec.yaml
# AND CMakeLists.txt) plus derivable dart + cpp sources, a committed binding
# that lists BOTH dev fixtures with dart FIRST, and PATH stubs for cmake/ctest/
# flutter (each records an identifiable marker + argv to stdout and to
# "$proj/invocations.log"). Echoes the project dir. TDD_ACTIVE_PACK is NOT used
# here — both packs must resolve through the committed-binding resolve chain so
# the multi-match path (not head-1) is exercised.
make_polyglot_project() {
  local proj
  proj=$(mktemp -d)
  # Both detection markers present so both packs resolve.
  echo 'name: tmp_app' > "$proj/pubspec.yaml"
  echo 'cmake_minimum_required(VERSION 3.20)' > "$proj/CMakeLists.txt"
  # Derivable sources + matching test files for each language.
  mkdir -p "$proj/lib/models" "$proj/test/models" "$proj/src"
  echo 'void main() {}' > "$proj/lib/models/user.dart"
  echo 'void main() {}' > "$proj/test/models/user_test.dart"
  echo 'int main() {}' > "$proj/src/parser.cpp"
  # Committed binding: dart FIRST, cpp second — both dev packs.
  mkdir -p "$proj/.claude"
  cat > "$proj/.claude/tdd-conventions.json" << JSON
{ "packs": [
  { "source": "$DART_FIXTURE", "dev": true },
  { "source": "$CPP_FIXTURE", "dev": true }
] }
JSON
  # PATH stubs recording call order to invocations.log.
  mkdir -p "$proj/bin"
  cat > "$proj/bin/cmake" << STUB
#!/bin/bash
echo "CMAKE_STUB_INVOKED: \$*" | tee -a "$proj/invocations.log"
STUB
  cat > "$proj/bin/ctest" << STUB
#!/bin/bash
echo "CTEST_STUB_INVOKED: \$*" | tee -a "$proj/invocations.log"
STUB
  cat > "$proj/bin/flutter" << STUB
#!/bin/bash
echo "FLUTTER_STUB_INVOKED: \$*" | tee -a "$proj/invocations.log"
STUB
  chmod +x "$proj/bin/cmake" "$proj/bin/ctest" "$proj/bin/flutter"
  printf '%s\n' "$proj"
}

# ---------- H2 Test 1 (FFT): polyglot, dart-first, .cpp edit RUNS ctest ----------

function test_polyglot_dart_first_cpp_edit_runs_ctest() {
  local proj
  proj=$(make_polyglot_project)

  local json output
  json=$(build_json "src/parser.cpp")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && unset TDD_ACTIVE_PACK \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # ACTION assert: ctest ACTUALLY FIRED for the .cpp edit even though the dart
  # pack is declared FIRST. A head-1 truncation would pick dart, find .cpp not
  # in dart's detect.extensions, and fall through to the built-in cmake-only
  # branch (no ctest) — that false-green is what this guards against.
  assert_contains "CTEST_STUB_INVOKED" "$output"
  assert_contains "systemMessage" "$output"
  # The cpp pack's suite command fired; the actual ctest run is recorded.
  assert_file_contains "$proj/invocations.log" "CTEST_STUB_INVOKED"

  rm -rf "$proj"
}

# ---------- H2 Test 2: polyglot, .dart edit still runs the dart pack command ----------

function test_polyglot_dart_edit_runs_flutter_not_ctest() {
  local proj
  proj=$(make_polyglot_project)

  local json output
  json=$(build_json "lib/models/user.dart")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && unset TDD_ACTIVE_PACK \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # The dart pack (file-granularity "flutter test {file}") is selected for the
  # .dart edit, with {file} substituted to the derived test path. ctest must NOT
  # fire — the correct pack is chosen per edited extension, not declared order.
  assert_contains "FLUTTER_STUB_INVOKED" "$output"
  assert_contains "test/models/user_test.dart" "$output"
  assert_not_contains "CTEST_STUB_INVOKED" "$output"

  rm -rf "$proj"
}

# ---------- H2 Test 3 (edge): .sh edit falls through to bashunit built-in ----------

function test_polyglot_sh_edit_falls_through_to_bashunit() {
  local proj
  proj=$(make_polyglot_project)
  # Provide a derivable shell source + matching test so the bashunit built-in
  # has something to reference, and bashunit on PATH for the runner lookup.
  mkdir -p "$proj/scripts" "$proj/test/scripts" "$proj/lib"
  echo '#!/bin/bash' > "$proj/scripts/util.sh"
  echo '#!/bin/bash' > "$proj/test/scripts/util_test.sh"
  cp "$PROJECT_ROOT/lib/bashunit" "$proj/lib/bashunit"
  chmod +x "$proj/lib/bashunit"

  local json output
  json=$(build_json "scripts/util.sh")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && unset TDD_ACTIVE_PACK \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # Neither pack claims .sh -> built-in bashunit branch handles it.
  assert_contains "bashunit" "$output"
  assert_not_contains "CTEST_STUB_INVOKED" "$output"
  assert_not_contains "FLUTTER_STUB_INVOKED" "$output"

  rm -rf "$proj"
}

# ==========================================================================
# Slice H3 — derive_test_file: anchored lib/ -> test/ substitution
# An UNANCHORED sed rewrote the FIRST "lib/" anywhere in the path, so a nested
# package path "packages/mylib/lib/foo.dart" mangled to "packages/mytest/lib/..."
# (the "lib/" inside "myLIB/"), yielding "No matching test file found". The fix
# anchors the substitution to a full path segment (start-of-string or after a
# "/"). These FFTs assert the EXACT derived path string the emitted command
# carries — the precise correct path AND the absence of the mangled one.
# ==========================================================================

# Helper: scaffold a temp dart project with a NESTED package source + matching
# nested test file. "packages/mylib/lib/foo.dart" must derive to
# "packages/mylib/test/foo_test.dart" (NOT "packages/mytest/lib/foo_test.dart").
# Stubs flutter so "flutter test {file}" is observable. Echoes the dir.
make_nested_dart_project() {
  local proj
  proj=$(mktemp -d)
  echo 'name: tmp_app' > "$proj/pubspec.yaml"
  mkdir -p "$proj/packages/mylib/lib" "$proj/packages/mylib/test"
  echo 'void main() {}' > "$proj/packages/mylib/lib/foo.dart"
  echo 'void main() {}' > "$proj/packages/mylib/test/foo_test.dart"
  mkdir -p "$proj/bin"
  cat > "$proj/bin/flutter" << 'STUB'
#!/bin/bash
echo "FLUTTER_STUB_INVOKED: $*"
STUB
  chmod +x "$proj/bin/flutter"
  printf '%s\n' "$proj"
}

# ---------- H3 Test 1 (FFT): nested package path derives the EXACT test path ----------

function test_nested_lib_derives_exact_test_path_not_mangled() {
  local proj
  proj=$(make_nested_dart_project)

  local json output
  json=$(build_json "packages/mylib/lib/foo.dart")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$DART_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # ACTION assert: the emitted command carries the EXACT correct derived path
  # (lib/ anchored as a whole segment) AND never the mangled "packages/mytest/".
  assert_contains "FLUTTER_STUB_INVOKED" "$output"
  assert_contains "packages/mylib/test/foo_test.dart" "$output"
  assert_not_contains "packages/mytest/" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$proj"
}

# ---------- H3 Test 2 (no-regression): top-level lib/ still maps to test/ ----------

function test_top_level_lib_still_maps_to_test() {
  local proj
  proj=$(make_dart_project)

  local json output
  json=$(build_json "lib/models/user.dart")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$DART_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # The anchored substitution must still rewrite a leading "lib/" segment.
  assert_contains "FLUTTER_STUB_INVOKED" "$output"
  assert_contains "test/models/user_test.dart" "$output"

  rm -rf "$proj"
}

# ---------- H3 Test 3 (edge): a *_test.dart path edited directly is used verbatim ----------

function test_nested_test_file_edited_directly_used_verbatim() {
  local proj
  proj=$(make_nested_dart_project)

  local json output
  json=$(build_json "packages/mylib/test/foo_test.dart")
  output=$(cd "$proj" \
    && export PATH="$proj/bin:/usr/bin:/bin" \
    && export TDD_ACTIVE_PACK="$DART_FIXTURE" \
    && echo "$json" | bash "$HOOK_ABS" 2>/dev/null)

  # The early-return branch (a *_test.dart path) is untouched by the anchor fix:
  # the path is used verbatim, with no segment rewriting.
  assert_contains "FLUTTER_STUB_INVOKED" "$output"
  assert_contains "packages/mylib/test/foo_test.dart" "$output"
  assert_not_contains "packages/mytest/" "$output"

  rm -rf "$proj"
}

# ---------- Edge Case Test 9: Non-source file (.md) exits silently ----------

function test_markdown_file_exits_silently() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  mkdir -p "$tmp_dir/docs"
  echo '# Hello' > "$tmp_dir/docs/readme.md"

  local json
  json=$(build_json "docs/readme.md")
  local output
  local exit_code
  output=$(cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
  exit_code=$?

  assert_equals 0 "$exit_code"
  assert_equals "" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Edge Case Test 10: Empty file_path exits silently ----------

function test_empty_file_path_exits_silently() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "")
  local output
  local exit_code
  output=$(cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
  exit_code=$?

  assert_equals 0 "$exit_code"
  assert_equals "" "$output"

  rm -rf "$tmp_dir"
}

# ==========================================================================
# Slice 4 — agent_type Guard Tests
# Tests that the hook filters by agent_type when invoked from hooks.json,
# only running auto-test logic for tdd-implementer agents.
# ==========================================================================

# Helper: build PostToolUse JSON with an agent_type field
build_json_with_agent_type() {
  local file_path="$1"
  local agent_type="$2"
  printf '{"tool_name":"Write","agent_type":"%s","tool_input":{"file_path":"%s","content":"echo hello"}}\n' "$agent_type" "$file_path"
}

# ---------- Guard Test 1: Namespaced implementer agent_type preserves auto-test behavior ----------

function test_namespaced_implementer_agent_type_preserves_auto_test() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source and matching test file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/my_script.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local json
  json=$(build_json_with_agent_type "hooks/my_script.sh" "tdd-workflow:tdd-implementer")
  local output
  output=$(cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  assert_contains "systemMessage" "$output"
  assert_contains "bashunit" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Guard Test 2: Plain implementer agent_type preserves auto-test behavior ----------

function test_plain_implementer_agent_type_preserves_auto_test() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source and matching test file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/my_script.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local json
  json=$(build_json_with_agent_type "hooks/my_script.sh" "tdd-implementer")
  local output
  output=$(cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Guard Test 3: Non-implementer agent_type passes through silently ----------

function test_non_implementer_agent_type_passes_through_silently() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source and matching test file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/my_script.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  local json
  json=$(build_json_with_agent_type "hooks/my_script.sh" "tdd-workflow:tdd-planner")
  local output
  local exit_code
  output=$(cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
  exit_code=$?

  assert_equals 0 "$exit_code"
  assert_equals "" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Guard Test 4: Empty agent_type passes through silently (main thread) ----------

function test_empty_agent_type_passes_through_silently() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create source and matching test file
  mkdir -p "$tmp_dir/test/hooks"
  echo '#!/bin/bash' > "$tmp_dir/hooks/my_script.sh"
  echo '#!/bin/bash' > "$tmp_dir/test/hooks/my_script_test.sh"

  # JSON with no agent_type field at all — main thread should pass through
  local json
  json='{"tool_name":"Write","tool_input":{"file_path":"hooks/my_script.sh","content":"echo hello"}}'
  local output
  local exit_code
  output=$(cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
  exit_code=$?

  assert_equals 0 "$exit_code"
  assert_equals "" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Guard Test 5: Non-source file with non-implementer agent_type exits silently ----------

function test_non_source_file_with_non_implementer_exits_silently() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  mkdir -p "$tmp_dir/docs"
  echo '# Hello' > "$tmp_dir/docs/readme.md"

  local json
  json=$(build_json_with_agent_type "docs/readme.md" "tdd-workflow:tdd-verifier")
  local output
  local exit_code
  output=$(cd "$tmp_dir" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)
  exit_code=$?

  assert_equals 0 "$exit_code"
  assert_equals "" "$output"

  rm -rf "$tmp_dir"
}
