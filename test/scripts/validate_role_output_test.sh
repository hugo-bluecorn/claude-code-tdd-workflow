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

# ========== Slice 2: Identity Section and Line Count ==========

# ---------- Test 8: Exits 0 when Identity section is present ----------

function test_exits_0_when_identity_section_present() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  write_valid_role_file "$tmp_dir/role.md"

  run_validate "$tmp_dir/role.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 9: Exits non-zero when Identity section is missing ----------

function test_exits_nonzero_when_identity_section_missing() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

You are a test role with no Identity heading.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "Identity" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 10: Exits 0 when file is exactly 400 lines ----------

function test_exits_0_when_file_is_exactly_400_lines() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Write frontmatter (5 lines) + blank + Identity heading + blank + content
  # Total must be exactly 400 lines
  {
    echo "---"
    echo "role: test-role"
    echo "name: Test Role"
    echo "type: session"
    echo "---"
    echo ""
    echo "## Identity"
    echo ""
    echo "You are a test role."
    # Lines 1-9 written, need 391 more to reach 400
    for i in $(seq 1 391); do
      echo "Line $i of padding content."
    done
  } > "$tmp_dir/role.md"

  # Verify we got exactly 400 lines
  local line_count
  line_count=$(wc -l < "$tmp_dir/role.md")
  assert_equals "400" "$line_count"

  run_validate "$tmp_dir/role.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 11: Exits non-zero when file exceeds 400 lines ----------

function test_exits_nonzero_when_file_exceeds_400_lines() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Write a 401-line file
  {
    echo "---"
    echo "role: test-role"
    echo "name: Test Role"
    echo "type: session"
    echo "---"
    echo ""
    echo "## Identity"
    echo ""
    echo "You are a test role."
    # Lines 1-9 written, need 392 more to reach 401
    for i in $(seq 1 392); do
      echo "Line $i of padding content."
    done
  } > "$tmp_dir/role.md"

  # Verify we got 401 lines
  local line_count
  line_count=$(wc -l < "$tmp_dir/role.md")
  assert_equals "401" "$line_count"

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "400" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 12: Identity heading at different markdown levels accepted ----------

function test_identity_heading_at_different_levels_accepted() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  # Test with # Identity (h1)
  cat > "$tmp_dir/role_h1.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

# Identity

You are a test role.
EOF

  run_validate "$tmp_dir/role_h1.md"
  assert_exit_code 0

  # Test with ### Identity (h3)
  cat > "$tmp_dir/role_h3.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

### Identity

You are a test role.
EOF

  run_validate "$tmp_dir/role_h3.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}
