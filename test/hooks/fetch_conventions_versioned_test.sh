#!/bin/bash

# Test suite for fetch-conventions.sh — NEW-schema versioned resolver (Slice 3).
# Exercises the evolved hook against an OFFLINE, locally-created tagged fixture
# git repo (file:// URL) so the suite is deterministic and never hits the network.
# The pre-existing fetch_conventions_test.sh is the back-compat guard.

HOOK="hooks/fetch-conventions.sh"
PROJECT_ROOT="$(pwd)"
HOOK_ABS="$PROJECT_ROOT/$HOOK"

# ---------- shared helpers ----------

# Assert a directory exists (bashunit's assert_file_exists uses -f, not -d).
assert_directory_exists() {
  local dir="$1"
  if [ -d "$dir" ]; then
    assert_equals "exists" "exists"
  else
    assert_equals "directory $dir exists" "directory $dir does not exist"
  fi
}

assert_directory_absent() {
  local dir="$1"
  if [ -d "$dir" ]; then
    assert_equals "absent" "directory $dir present"
  else
    assert_equals "absent" "absent"
  fi
}

# Create a tmp env: .claude config dir + plugin-data cache dir.
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/.claude"
  mkdir -p "$tmp_dir/plugin-data"
  echo "$tmp_dir"
}

# Build a bare-cloneable fixture git repo named "fixture-pack" with two tags
# (v1.0.0 and v1.1.0) whose pack.json content differs. Echoes the repo path.
create_fixture_repo() {
  local base="$1"
  local repo="$base/fixture-pack"
  mkdir -p "$repo"
  git -C "$repo" init --quiet
  git -C "$repo" config user.email "fixture@example.com"
  git -C "$repo" config user.name "Fixture"
  git -C "$repo" config commit.gpgsign false

  printf '{"version":"1.0.0"}\n' > "$repo/pack.json"
  git -C "$repo" add pack.json
  git -C "$repo" commit --quiet -m "pack v1.0.0"
  git -C "$repo" tag v1.0.0

  printf '{"version":"1.1.0"}\n' > "$repo/pack.json"
  git -C "$repo" add pack.json
  git -C "$repo" commit --quiet -m "pack v1.1.0"
  git -C "$repo" tag v1.1.0

  echo "$repo"
}

# Run the hook inside a project dir with the plugin-data cache configured.
run_hook_in_dir() {
  local dir="$1"
  (cd "$dir" && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 2>/dev/null)
}

run_hook_in_dir_stderr() {
  local dir="$1"
  { cd "$dir" && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 1>/dev/null; } 2>&1
}

# ---------- Test 1: new-schema versioned source -> <repo>@<version> cache ----------

function test_versioned_source_creates_versioned_cache_dir() {
  local tmp_dir repo
  tmp_dir=$(create_tmp_env)
  repo=$(create_fixture_repo "$tmp_dir")

  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "file://$repo", "version": "v1.0.0"}]}
EOF

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"
  assert_directory_exists "$tmp_dir/plugin-data/conventions/fixture-pack@v1.0.0/.git"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: checked out at requested tag (real pin, not HEAD) ----------

function test_versioned_source_checks_out_requested_tag() {
  local tmp_dir repo
  tmp_dir=$(create_tmp_env)
  repo=$(create_fixture_repo "$tmp_dir")

  # Bind at the OLDER tag; its pack.json must be 1.0.0, not the HEAD 1.1.0.
  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "file://$repo", "version": "v1.0.0"}]}
EOF

  run_hook_in_dir "$tmp_dir"

  local content
  content=$(cat "$tmp_dir/plugin-data/conventions/fixture-pack@v1.0.0/pack.json")
  assert_contains '"version":"1.0.0"' "$content"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: versions coexist side by side ----------

function test_versions_coexist_side_by_side() {
  local tmp_dir repo
  tmp_dir=$(create_tmp_env)
  repo=$(create_fixture_repo "$tmp_dir")

  # First run pins v1.0.0
  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "file://$repo", "version": "v1.0.0"}]}
EOF
  run_hook_in_dir "$tmp_dir"

  # Second run pins v1.1.0 (an "upgrade")
  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "file://$repo", "version": "v1.1.0"}]}
EOF
  run_hook_in_dir "$tmp_dir"

  # Both cache dirs must exist side by side — upgrades don't clobber.
  assert_directory_exists "$tmp_dir/plugin-data/conventions/fixture-pack@v1.0.0/.git"
  assert_directory_exists "$tmp_dir/plugin-data/conventions/fixture-pack@v1.1.0/.git"

  # And each holds its own pinned content.
  local old new
  old=$(cat "$tmp_dir/plugin-data/conventions/fixture-pack@v1.0.0/pack.json")
  new=$(cat "$tmp_dir/plugin-data/conventions/fixture-pack@v1.1.0/pack.json")
  assert_contains '"version":"1.0.0"' "$old"
  assert_contains '"version":"1.1.0"' "$new"

  rm -rf "$tmp_dir"
}

# ---------- Test 4: dev:true / local new-schema source is NOT fetched ----------

function test_dev_source_is_not_fetched() {
  local tmp_dir repo
  tmp_dir=$(create_tmp_env)
  repo=$(create_fixture_repo "$tmp_dir")

  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "$repo", "dev": true}]}
EOF

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"

  # No clone into the dev path, and no versioned cache dir for it.
  assert_directory_absent "$repo/.git/refs/conventions-cache-marker"
  local count
  count=$(find "$tmp_dir/plugin-data/conventions" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
  assert_equals "0" "$count"

  rm -rf "$tmp_dir"
}

# ---------- Test 5 (edge): missing tag / fetch failure does NOT block ----------

function test_missing_tag_does_not_block() {
  local tmp_dir repo
  tmp_dir=$(create_tmp_env)
  repo=$(create_fixture_repo "$tmp_dir")

  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "file://$repo", "version": "v9.9.9-nonexistent"}]}
EOF

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"

  rm -rf "$tmp_dir"
}

function test_missing_tag_logs_diagnostic_naming_source_and_version() {
  local tmp_dir repo
  tmp_dir=$(create_tmp_env)
  repo=$(create_fixture_repo "$tmp_dir")

  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "file://$repo", "version": "v9.9.9-nonexistent"}]}
EOF

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir")

  assert_contains "v9.9.9-nonexistent" "$stderr_output"
  assert_contains "fixture-pack" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 6 (edge): legacy back-compat — unversioned cache path ----------

function test_legacy_schema_routes_to_unversioned_path() {
  local tmp_dir repo
  tmp_dir=$(create_tmp_env)
  repo=$(create_fixture_repo "$tmp_dir")

  # Legacy shape with a file:// source so it stays offline. Legacy http(s)/file
  # sources clone to conventions/<repo-name> with NO @version suffix.
  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"conventions": ["file://$repo"]}
EOF

  run_hook_in_dir "$tmp_dir"
  local rc=$?

  assert_equals 0 "$rc"

  # Unversioned path exists; no @version path was created for the legacy entry.
  assert_directory_exists "$tmp_dir/plugin-data/conventions/fixture-pack/.git"
  assert_directory_absent "$tmp_dir/plugin-data/conventions/fixture-pack@legacy"

  rm -rf "$tmp_dir"
}

# ---------- Test 7 (edge): scheme-less new-schema source normalized to https ----------

function test_schemeless_source_normalized_to_https() {
  # A scheme-less, non-dev new-schema source (e.g. github.com/org/pack) must be
  # normalized to https:// before cloning. We can't clone github offline, so we
  # assert the failure DIAGNOSTIC reflects the normalized https URL — proving the
  # resolver took the versioned-clone path rather than skipping it as a local path.
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.claude/tdd-conventions.json" << 'EOF'
{"packs": [{"source": "github.com/nonexistent-org/nonexistent-pack-xyz", "version": "v1.0.0"}]}
EOF

  local stderr_output
  stderr_output=$(run_hook_in_dir_stderr "$tmp_dir")
  local rc=$?

  assert_equals 0 "$rc"
  # Diagnostic must name the source and version (clone of normalized URL failed).
  assert_contains "nonexistent-pack-xyz" "$stderr_output"
  assert_contains "v1.0.0" "$stderr_output"

  rm -rf "$tmp_dir"
}
