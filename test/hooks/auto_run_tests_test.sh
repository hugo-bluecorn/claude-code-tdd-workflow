#!/bin/bash

# Test suite for auto-run-tests.sh hook — .sh file support
# Tests that the hook correctly triggers bashunit for shell files.

HOOK="hooks/auto-run-tests.sh"
PROJECT_ROOT="$(pwd)"
HOOK_ABS="$PROJECT_ROOT/$HOOK"

# Helper: build PostToolUse JSON for a given file path
build_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"echo hello"}}\n' "$file_path"
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

# ---------- Test 4: Existing dart/cpp behavior unchanged ----------

function test_dart_file_still_triggers_flutter() {
  local output
  output=$(run_hook "lib/widget.dart")

  # Should reference flutter test, not bashunit
  assert_contains "systemMessage" "$output"
  assert_not_contains "bashunit" "$output"
}

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

# ---------- JSON Safety Test 4: No matching test file produces valid JSON ----------

function test_json_valid_for_no_matching_test_file() {
  local tmp_dir
  tmp_dir=$(create_tmp_env --with-bashunit)

  # Create a .dart source file with no matching test
  mkdir -p "$tmp_dir/lib"
  echo 'void main() {}' > "$tmp_dir/lib/orphan.dart"

  local output
  output=$(run_hook_in_tmp "$tmp_dir" "lib/orphan.dart")

  # Must be valid JSON
  echo "$output" | jq . > /dev/null 2>&1
  assert_exit_code 0

  # Must contain the expected message
  local msg
  msg=$(echo "$output" | jq -r '.systemMessage')
  assert_contains "No matching test file" "$msg"

  rm -rf "$tmp_dir"
}

# ---------- JSON Safety Test 5: bashunit not installed produces valid JSON ----------

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
# Slice 3 — FVM Detection, Dart/C++ Path Coverage, and Edge Cases
# Tests that the hook correctly detects FVM, maps Dart file paths,
# handles C++ files, and exits silently for non-source files.
# ==========================================================================

# ---------- FVM Test 1: fvmrc + fvm available uses fvm flutter ----------

function test_fvmrc_and_fvm_available_uses_fvm_flutter() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create .fvmrc so the hook detects FVM project
  echo '{"flutterSdkVersion": "3.24.0"}' > "$tmp_dir/.fvmrc"

  # Create Dart source and matching test file
  mkdir -p "$tmp_dir/lib/models"
  mkdir -p "$tmp_dir/test/models"
  echo 'void main() {}' > "$tmp_dir/lib/models/user.dart"
  echo 'void main() {}' > "$tmp_dir/test/models/user_test.dart"

  # Create stub fvm that outputs an identifiable marker
  mkdir -p "$tmp_dir/bin"
  cat > "$tmp_dir/bin/fvm" << 'STUB'
#!/bin/bash
echo "FVM_STUB_INVOKED: $*"
STUB
  chmod +x "$tmp_dir/bin/fvm"

  # Run with our stub on PATH (include /usr/bin for jq, tail, etc.)
  local json
  json=$(build_json "lib/models/user.dart")
  local output
  output=$(cd "$tmp_dir" && export PATH="$tmp_dir/bin:/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  # The output should contain FVM_STUB_INVOKED, proving fvm was called
  assert_contains "FVM_STUB_INVOKED" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- FVM Test 2: fvmrc present but fvm NOT available falls back to flutter ----------

function test_fvmrc_present_but_no_fvm_falls_back_to_flutter() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create .fvmrc
  echo '{"flutterSdkVersion": "3.24.0"}' > "$tmp_dir/.fvmrc"

  # Create Dart source and matching test file
  mkdir -p "$tmp_dir/lib/models"
  mkdir -p "$tmp_dir/test/models"
  echo 'void main() {}' > "$tmp_dir/lib/models/user.dart"
  echo 'void main() {}' > "$tmp_dir/test/models/user_test.dart"

  # Create stub flutter only (no fvm)
  mkdir -p "$tmp_dir/bin"
  cat > "$tmp_dir/bin/flutter" << 'STUB'
#!/bin/bash
echo "FLUTTER_STUB_INVOKED: $*"
STUB
  chmod +x "$tmp_dir/bin/flutter"

  # PATH has only our stubs + system essentials, no fvm
  local json
  json=$(build_json "lib/models/user.dart")
  local output
  output=$(cd "$tmp_dir" && export PATH="$tmp_dir/bin:/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  # Should use plain flutter, not fvm
  assert_contains "FLUTTER_STUB_INVOKED" "$output"
  assert_not_contains "FVM" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- FVM Test 3: No fvmrc uses plain flutter ----------

function test_no_fvmrc_uses_plain_flutter() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # No .fvmrc created

  # Create Dart source and matching test file
  mkdir -p "$tmp_dir/lib/models"
  mkdir -p "$tmp_dir/test/models"
  echo 'void main() {}' > "$tmp_dir/lib/models/user.dart"
  echo 'void main() {}' > "$tmp_dir/test/models/user_test.dart"

  # Create stub flutter
  mkdir -p "$tmp_dir/bin"
  cat > "$tmp_dir/bin/flutter" << 'STUB'
#!/bin/bash
echo "FLUTTER_PLAIN_INVOKED: $*"
STUB
  chmod +x "$tmp_dir/bin/flutter"

  # Also create fvm stub to ensure it is NOT used even if available
  cat > "$tmp_dir/bin/fvm" << 'STUB'
#!/bin/bash
echo "FVM_SHOULD_NOT_BE_USED: $*"
STUB
  chmod +x "$tmp_dir/bin/fvm"

  local json
  json=$(build_json "lib/models/user.dart")
  local output
  output=$(cd "$tmp_dir" && export PATH="$tmp_dir/bin:/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  # Should use plain flutter, not fvm
  assert_contains "FLUTTER_PLAIN_INVOKED" "$output"
  assert_not_contains "FVM_SHOULD_NOT_BE_USED" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Dart Mapping Test 4: lib/ to test/ mapping ----------

function test_dart_lib_to_test_mapping() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create Dart source and matching test file
  mkdir -p "$tmp_dir/lib/models"
  mkdir -p "$tmp_dir/test/models"
  echo 'void main() {}' > "$tmp_dir/lib/models/user.dart"
  echo 'void main() {}' > "$tmp_dir/test/models/user_test.dart"

  # Create stub flutter that echoes the test file path it receives
  mkdir -p "$tmp_dir/bin"
  cat > "$tmp_dir/bin/flutter" << 'STUB'
#!/bin/bash
echo "FLUTTER_TEST_PATH: $2"
STUB
  chmod +x "$tmp_dir/bin/flutter"

  local json
  json=$(build_json "lib/models/user.dart")
  local output
  output=$(cd "$tmp_dir" && export PATH="$tmp_dir/bin:/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  # Should map lib/models/user.dart -> test/models/user_test.dart
  assert_contains "test/models/user_test.dart" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
}

# ---------- Dart Mapping Test 5: _test.dart runs directly ----------

function test_dart_test_file_runs_directly() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create only the test file
  mkdir -p "$tmp_dir/test/models"
  echo 'void main() {}' > "$tmp_dir/test/models/user_test.dart"

  # Create stub flutter that echoes what it receives
  mkdir -p "$tmp_dir/bin"
  cat > "$tmp_dir/bin/flutter" << 'STUB'
#!/bin/bash
echo "FLUTTER_DIRECT_RUN: $2"
STUB
  chmod +x "$tmp_dir/bin/flutter"

  local json
  json=$(build_json "test/models/user_test.dart")
  local output
  output=$(cd "$tmp_dir" && export PATH="$tmp_dir/bin:/usr/bin:/bin" && echo "$json" | bash "$tmp_dir/$HOOK" 2>/dev/null)

  # Should use test/models/user_test.dart directly
  assert_contains "test/models/user_test.dart" "$output"
  assert_contains "systemMessage" "$output"

  rm -rf "$tmp_dir"
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
