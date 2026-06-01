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

# ---------- Test 4: Existing cpp behavior unchanged (C++ path is C3's slice) ----------

function test_cpp_file_still_triggers_cmake() {
  local output
  output=$(run_hook "src/parser.cpp")

  # Should reference cmake/build, not bashunit
  assert_contains "systemMessage" "$output"
  assert_not_contains "bashunit" "$output"
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

# ---------- C++ Test 6: C++ with build dir runs cmake ----------

function test_cpp_with_build_dir_runs_cmake() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create C++ source and build directory
  mkdir -p "$tmp_dir/src"
  echo 'int main() {}' > "$tmp_dir/src/parser.cpp"
  mkdir -p "$tmp_dir/build"

  # Create stub cmake
  mkdir -p "$tmp_dir/bin"
  cat > "$tmp_dir/bin/cmake" << 'STUB'
#!/bin/bash
echo "CMAKE_STUB_INVOKED: $*"
STUB
  chmod +x "$tmp_dir/bin/cmake"

  local json
  json=$(build_json "src/parser.cpp")
  local output
  output=$(cd "$tmp_dir" && export PATH="$tmp_dir/bin:/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  assert_contains "CMAKE_STUB_INVOKED" "$output"
  assert_contains "systemMessage" "$output"

  # Validate JSON
  echo "$output" | jq . > /dev/null 2>&1
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- C++ Test 7: C++ without build dir reports error ----------

function test_cpp_without_build_dir_reports_error() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create C++ source but NO build directory
  mkdir -p "$tmp_dir/src"
  echo 'int main() {}' > "$tmp_dir/src/parser.cpp"

  local json
  json=$(build_json "src/parser.cpp")
  local output
  output=$(cd "$tmp_dir" && export PATH="/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  assert_contains "No build directory found" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- C++ Test 8: .hpp handled as C++ ----------

function test_hpp_handled_as_cpp() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create .hpp source but NO build directory
  mkdir -p "$tmp_dir/src"
  echo '#pragma once' > "$tmp_dir/src/types.hpp"

  local json
  json=$(build_json "src/types.hpp")
  local output
  output=$(cd "$tmp_dir" && export PATH="/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  # Should enter C++ branch and report no build directory
  assert_contains "No build directory found" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
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
