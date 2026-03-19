#!/bin/bash

# Tests for scripts/load-conventions.sh: config file reading from .claude/tdd-conventions.json
# Validates config-based convention loading against real convention repo content

SCRIPT="$(pwd)/scripts/load-conventions.sh"

# Shared clone of the conventions repo (cloned once in setup)
CONVENTIONS_CLONE=""

# ---------- Helpers ----------

create_tmp_dir() {
  mktemp -d
}

# Clone the conventions repo once for the test suite
setup_conventions_cache() {
  local cache_dir
  cache_dir=$(create_tmp_dir)
  git clone --depth 1 --quiet \
    https://github.com/hugo-bluecorn/tdd-workflow-conventions.git \
    "$cache_dir/tdd-workflow-conventions" 2>/dev/null
  echo "$cache_dir"
}

# Run load-conventions.sh in a given directory with a conventions cache
run_load_in_dir() {
  local dir="$1"
  local plugin_data="$2"
  (cd "$dir" && CLAUDE_PLUGIN_DATA="$plugin_data" bash "$SCRIPT" 2>/dev/null)
}

# ---------- Suite setup ----------

function set_up() {
  if [ -z "$CONVENTIONS_CLONE" ]; then
    CONVENTIONS_CLONE=$(setup_conventions_cache)
  fi
}

# ---------- Test 1: Reads convention sources from config file ----------

function test_reads_conventions_from_config_file() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Create project with pubspec.yaml (Dart project)
  touch "$tmp_dir/pubspec.yaml"

  # Create .claude/tdd-conventions.json pointing to local clone
  mkdir -p "$tmp_dir/.claude"
  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"conventions": ["$CONVENTIONS_CLONE/tdd-workflow-conventions"]}
EOF

  # Create a minimal plugin data dir (should NOT be used when config exists)
  local empty_plugin_data
  empty_plugin_data=$(create_tmp_dir)
  mkdir -p "$empty_plugin_data/conventions"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$empty_plugin_data")

  # Should contain Dart convention content from the configured local path
  assert_contains "dart-flutter-conventions" "$output"
  assert_contains "Riverpod" "$output"

  rm -rf "$tmp_dir" "$empty_plugin_data"
}

# ---------- Test 2: Falls back to CLAUDE_PLUGIN_DATA cache when no config ----------

function test_falls_back_to_cache_when_no_config() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Create project with pubspec.yaml (Dart project) — no .claude/ dir
  touch "$tmp_dir/pubspec.yaml"

  # Set up a proper conventions cache
  local cache_dir
  cache_dir=$(create_tmp_dir)
  mkdir -p "$cache_dir/conventions"
  cp -r "$CONVENTIONS_CLONE/tdd-workflow-conventions" "$cache_dir/conventions/"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$cache_dir")

  # Should load from the cache fallback
  assert_contains "dart-flutter-conventions" "$output"
  assert_contains "Riverpod" "$output"

  rm -rf "$tmp_dir" "$cache_dir"
}

# ---------- Test 3: Local path conventions read directly ----------

function test_local_path_conventions_read_directly() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Create Bash project
  touch "$tmp_dir/my_test.sh"

  # Config points to local clone
  mkdir -p "$tmp_dir/.claude"
  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"conventions": ["$CONVENTIONS_CLONE/tdd-workflow-conventions"]}
EOF

  local empty_plugin_data
  empty_plugin_data=$(create_tmp_dir)
  mkdir -p "$empty_plugin_data/conventions"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$empty_plugin_data")

  # Should contain bashunit patterns from local path
  assert_contains "bash-testing-conventions" "$output"
  assert_contains "assert_equals" "$output"

  rm -rf "$tmp_dir" "$empty_plugin_data"
}

# ---------- Test 4: Malformed JSON config handled gracefully ----------

function test_malformed_json_config_falls_back_to_cache() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/pubspec.yaml"

  # Malformed JSON
  mkdir -p "$tmp_dir/.claude"
  echo "not valid json {{{" > "$tmp_dir/.claude/tdd-conventions.json"

  # Set up a proper conventions cache for fallback
  local cache_dir
  cache_dir=$(create_tmp_dir)
  mkdir -p "$cache_dir/conventions"
  cp -r "$CONVENTIONS_CLONE/tdd-workflow-conventions" "$cache_dir/conventions/"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$cache_dir")
  local rc=$?

  # Should fall back to cache and exit 0
  assert_equals 0 "$rc"
  assert_contains "dart-flutter-conventions" "$output"

  rm -rf "$tmp_dir" "$cache_dir"
}

# ---------- Test 5: Empty conventions array ----------

function test_empty_conventions_array() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/pubspec.yaml"

  mkdir -p "$tmp_dir/.claude"
  echo '{"conventions": []}' > "$tmp_dir/.claude/tdd-conventions.json"

  local empty_plugin_data
  empty_plugin_data=$(create_tmp_dir)
  mkdir -p "$empty_plugin_data/conventions"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$empty_plugin_data")
  local rc=$?

  # Empty array means no conventions loaded
  assert_equals 0 "$rc"
  assert_empty "$output"

  rm -rf "$tmp_dir" "$empty_plugin_data"
}

# ---------- Test 6: Config path that does not exist is skipped ----------

function test_nonexistent_config_path_skipped() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  touch "$tmp_dir/pubspec.yaml"

  mkdir -p "$tmp_dir/.claude"
  cat > "$tmp_dir/.claude/tdd-conventions.json" << 'EOF'
{"conventions": ["/nonexistent/path/that/does/not/exist"]}
EOF

  local empty_plugin_data
  empty_plugin_data=$(create_tmp_dir)
  mkdir -p "$empty_plugin_data/conventions"

  local output
  output=$(run_load_in_dir "$tmp_dir" "$empty_plugin_data")
  local rc=$?

  # Should skip nonexistent path and exit 0
  assert_equals 0 "$rc"

  rm -rf "$tmp_dir" "$empty_plugin_data"
}

# ---------- Cleanup ----------

function tear_down_after_script() {
  if [ -n "$CONVENTIONS_CLONE" ] && [ -d "$CONVENTIONS_CLONE" ]; then
    rm -rf "$CONVENTIONS_CLONE"
  fi
}
