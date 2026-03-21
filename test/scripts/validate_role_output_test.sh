#!/bin/bash

# Tests for validate-role-output.sh: YAML Frontmatter Validation (Slice 1)
# Verifies required frontmatter fields, missing delimiters, and argument handling.

SCRIPT="$(pwd)/scripts/validate-role-output.sh"

# Helper: create an isolated temp directory
create_tmp_dir() {
  mktemp -d
}

# Helper: run validation script (suppress stderr)
run_validate() {
  local file_path="${1:-}"
  bash "$SCRIPT" "$file_path" 2>/dev/null
}

# Helper: run validation script capturing stderr
run_validate_stderr() {
  local file_path="${1:-}"
  # shellcheck disable=SC2069
  bash "$SCRIPT" "$file_path" 2>&1 >/dev/null
}

# Helper: write a valid role file with all required frontmatter fields
write_valid_role_file() {
  local file_path="$1"
  cat > "$file_path" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a test role for validation purposes.
EOF
}

# ---------- Test 1: Exits 0 for valid role file with required frontmatter fields ----------

function test_exits_0_for_valid_role_file() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  write_valid_role_file "$tmp_dir/role.md"

  run_validate "$tmp_dir/role.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 2: Exits non-zero when role field is missing ----------

function test_exits_nonzero_when_role_field_missing() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
name: Test Role
type: session
---

## Identity

You are a test role.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "role" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: Exits non-zero when name field is missing ----------

function test_exits_nonzero_when_name_field_missing() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
type: session
---

## Identity

You are a test role.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "name" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 4: Exits non-zero when type field is missing ----------

function test_exits_nonzero_when_type_field_missing() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
---

## Identity

You are a test role.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "type" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 5: Exits non-zero when no frontmatter delimiters exist ----------

function test_exits_nonzero_when_no_frontmatter_delimiters() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
# Just a plain markdown file

No YAML frontmatter here at all.

## Identity

You are a test role.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "frontmatter" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 6: Exits non-zero when file path argument is missing ----------

function test_exits_nonzero_when_no_argument_provided() {
  bash "$SCRIPT" 2>/dev/null
  assert_exit_code 1

  local stderr_output
  # shellcheck disable=SC2069
  stderr_output=$(bash "$SCRIPT" 2>&1 >/dev/null)
  assert_contains "Usage" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 7: Exits non-zero when file does not exist ----------

function test_exits_nonzero_when_file_does_not_exist() {
  run_validate "/tmp/nonexistent_role_file_$(date +%s).md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "/tmp/nonexistent_role_file_$(date +%s).md")
  assert_contains "not found" "$stderr_output"
}
