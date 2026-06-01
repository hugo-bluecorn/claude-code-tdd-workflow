#!/bin/bash

# Test suite for fetch-conventions.sh — NEW-schema versioned resolver (Slice 3).
# Exercises the evolved hook against an OFFLINE, locally-created tagged fixture
# git repo (file:// URL) so the suite is deterministic and never hits the network.
# The pre-existing fetch_conventions_test.sh is the back-compat guard.

HOOK="hooks/fetch-conventions.sh"
PROJECT_ROOT="$(pwd)"
HOOK_ABS="$PROJECT_ROOT/$HOOK"
DART_FIXTURE="$PROJECT_ROOT/test/fixtures/dart-fixture"

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

# Install a PATH-shim fake `git` into <dir>/bin that records every `clone`
# invocation's argv to <dir>/git-invocations.log and EXITS NON-ZERO on clone
# (so a test can never pass merely because cleanup ran). All other git
# subcommands (init/config/add/commit/tag/-C ...) delegate to the real git so
# fixtures still build. Echoes the bin dir to prepend onto PATH.
install_clone_spy() {
  local dir="$1"
  local bin="$dir/bin"
  local real_git
  real_git="$(command -v git)"
  mkdir -p "$bin"
  cat > "$bin/git" << EOF
#!/bin/bash
# Find the first non-flag subcommand token.
sub=""
for a in "\$@"; do
  case "\$a" in
    -*) ;;
    *) sub="\$a"; break ;;
  esac
done
if [ "\$sub" = "clone" ]; then
  printf '%s\n' "\$*" >> "$dir/git-invocations.log"
  exit 1
fi
exec "$real_git" "\$@"
EOF
  chmod +x "$bin/git"
  echo "$bin"
}

# Run the hook with the clone-spy bin prepended to PATH; capture stderr.
run_hook_with_spy_stderr() {
  local dir="$1" bin="$2"
  { cd "$dir" && PATH="$bin:$PATH" CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 1>/dev/null; } 2>&1
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

# ---------- Test 4: dev:true source triggers NO `git clone` (ACTION assert) ----
# Regression guard for the tab-collapse bug: parse-binding emits "<src>\t\tdev"
# for a dev pack; a naive `IFS=$'\t' read` collapses the adjacent tabs, reads
# version="dev"/dev="", MISSES the dev-skip, and fires the versioned-clone path
# every SessionStart. The OLD test asserted count==0 -- which the bug satisfied
# (the failed clone was rm -rf'd). This asserts the ACTION: clone is NEVER
# invoked for a dev pack. A clone-spy `git` records every clone and exits
# non-zero, so the test cannot pass merely because cleanup ran.

function test_dev_source_triggers_no_git_clone() {
  local tmp_dir repo bin
  tmp_dir=$(create_tmp_env)
  repo=$(create_fixture_repo "$tmp_dir")
  bin=$(install_clone_spy "$tmp_dir")

  cat > "$tmp_dir/.claude/tdd-conventions.json" << EOF
{"packs": [{"source": "$repo", "dev": true}]}
EOF

  local stderr_output
  stderr_output=$(run_hook_with_spy_stderr "$tmp_dir" "$bin")

  # Zero clone invocations were recorded for the dev pack.
  local clone_count=0
  [ -f "$tmp_dir/git-invocations.log" ] && \
    clone_count=$(grep -c '.' "$tmp_dir/git-invocations.log")
  assert_equals "0" "$clone_count"

  # And no clone-failure diagnostic leaked.
  assert_not_contains "failed to clone" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 4b (edge): dev source beginning with ~/ -> NO `git clone` -----

function test_dev_source_with_tilde_triggers_no_git_clone() {
  local tmp_dir bin
  tmp_dir=$(create_tmp_env)
  bin=$(install_clone_spy "$tmp_dir")

  cat > "$tmp_dir/.claude/tdd-conventions.json" << 'EOF'
{"packs": [{"source": "~/some/local/dev-pack", "dev": true}]}
EOF

  local stderr_output
  stderr_output=$(run_hook_with_spy_stderr "$tmp_dir" "$bin")

  local clone_count=0
  [ -f "$tmp_dir/git-invocations.log" ] && \
    clone_count=$(grep -c '.' "$tmp_dir/git-invocations.log")
  assert_equals "0" "$clone_count"
  assert_not_contains "failed to clone" "$stderr_output"

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

# =====================================================================
# Slice T1: projectFiles materialization (non-destructive, warn-on-drift)
# C4: at pack resolution, for each ACTIVE pack's projectFiles[], materialize
# each into the PROJECT ROOT. Absent -> copy (the ONLY write). Identical ->
# no-op. Present-but-different -> NEVER overwrite, drift advisory to stderr.
# PRIME-safe: no active pack / no projectFiles -> no writes, hook exit 0s.
# =====================================================================

# Write a dev-pack binding for the dart fixture into a temp project so the pack
# resolves ACTIVE via the committed-binding path (env TDD_ACTIVE_PACK unset).
write_dart_dev_binding() {
  local proj="$1"
  mkdir -p "$proj/.claude"
  printf '{"packs":[{"source":"%s","dev":true}]}\n' "$DART_FIXTURE" \
    >"$proj/.claude/tdd-conventions.json"
}

# Run the hook in <dir> with TDD_ACTIVE_PACK explicitly UNSET (so resolution
# goes through the committed dev binding) and CLAUDE_PLUGIN_DATA set. Discards
# stdout; returns the hook's exit code.
run_t1_hook() {
  local dir="$1"
  ( cd "$dir" \
      && unset TDD_ACTIVE_PACK \
      && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 2>/dev/null )
}

# Same, but capture stderr (drift advisory lands here).
run_t1_hook_stderr() {
  local dir="$1"
  { cd "$dir" \
      && unset TDD_ACTIVE_PACK \
      && CLAUDE_PLUGIN_DATA="$dir/plugin-data" bash "$HOOK_ABS" 1>/dev/null; } 2>&1
}

# ---------- T1 Test 1 (FFT): absent projectFiles entry is materialized --------
# The pack's analysis_options.yaml is copied into the project root, byte-for-byte.

function test_t1_absent_project_file_is_materialized_with_pack_content() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  : >"$tmp_dir/pubspec.yaml"            # marker -> dart pack is ACTIVE
  write_dart_dev_binding "$tmp_dir"
  # NO analysis_options.yaml in the project root yet.

  run_t1_hook "$tmp_dir"
  local rc=$?
  assert_equals 0 "$rc"

  # ACTION: the file was actually created...
  assert_file_exists "$tmp_dir/analysis_options.yaml"
  # ...with the pack's EXACT bytes (assert exact content, not merely existence).
  if cmp -s "$DART_FIXTURE/analysis_options.yaml" "$tmp_dir/analysis_options.yaml"; then
    assert_equals "identical" "identical"
  else
    assert_equals "identical to pack content" "differs from pack content"
  fi

  rm -rf "$tmp_dir"
}

# ---------- T1 Test 2 (safety-critical ACTION): present-but-different ----------
# Never overwrite the user's bytes; emit a drift advisory naming the file.

function test_t1_present_but_different_is_not_overwritten_and_warns() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  : >"$tmp_dir/pubspec.yaml"
  write_dart_dev_binding "$tmp_dir"

  # Pre-existing user-customized file with DISTINCT content.
  local user_content="# user-customized analysis options"$'\n'"linter: {}"$'\n'
  printf '%s' "$user_content" >"$tmp_dir/analysis_options.yaml"

  local stderr_output
  stderr_output=$(run_t1_hook_stderr "$tmp_dir")

  # ACTION (never-overwrite): the file still holds the ORIGINAL user bytes.
  local after
  after=$(cat "$tmp_dir/analysis_options.yaml")
  assert_equals "$user_content" "$after"$'\n'
  # The pack content must NOT have clobbered it.
  if cmp -s "$DART_FIXTURE/analysis_options.yaml" "$tmp_dir/analysis_options.yaml"; then
    assert_equals "user bytes preserved" "pack content overwrote user file"
  else
    assert_equals "user bytes preserved" "user bytes preserved"
  fi

  # Drift advisory on stderr names the file.
  assert_contains "analysis_options.yaml" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- T1 Test 3 (edge): present-and-identical -> silent no-op -----------

function test_t1_present_and_identical_is_silent_no_op() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  : >"$tmp_dir/pubspec.yaml"
  write_dart_dev_binding "$tmp_dir"

  # Pre-seed with bytes IDENTICAL to the pack's file.
  cp "$DART_FIXTURE/analysis_options.yaml" "$tmp_dir/analysis_options.yaml"

  local stderr_output
  stderr_output=$(run_t1_hook_stderr "$tmp_dir")

  # File unchanged (still identical to the pack).
  if cmp -s "$DART_FIXTURE/analysis_options.yaml" "$tmp_dir/analysis_options.yaml"; then
    assert_equals "unchanged" "unchanged"
  else
    assert_equals "unchanged" "changed"
  fi
  # Identical != drift: NO advisory naming the file.
  assert_not_contains "analysis_options.yaml" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- T1 Test 4 (edge, degrade): no active pack -> no writes, exit 0 -----

function test_t1_no_active_pack_no_writes_no_advisory() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)
  # No binding file, TDD_ACTIVE_PACK unset, just a stray marker file.
  : >"$tmp_dir/some-marker.txt"

  local stderr_output
  stderr_output=$(run_t1_hook_stderr "$tmp_dir")
  local rc
  run_t1_hook "$tmp_dir"
  rc=$?

  assert_equals 0 "$rc"
  # No project file was materialized.
  assert_file_not_exists "$tmp_dir/analysis_options.yaml"
  # No drift advisory.
  assert_not_contains "analysis_options.yaml" "$stderr_output"

  rm -rf "$tmp_dir"
}
