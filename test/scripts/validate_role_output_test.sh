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

# ========== Slice 3: Placeholder and Constraint Validation ==========

# ---------- Test 13: Exits non-zero when {placeholder} pattern found in body ----------

function test_exits_nonzero_when_placeholder_found_in_body() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a {some_placeholder} for testing.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "placeholder" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 14: Exits non-zero when TODO found in body ----------

function test_exits_nonzero_when_todo_found_in_body() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a test role. TODO fill in details later.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "TODO" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 15: Exits non-zero when TBD found in body ----------

function test_exits_nonzero_when_tbd_found_in_body() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a test role. This section is TBD.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "TBD" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 16: Exits non-zero when constraint uses permission phrasing ----------

function test_exits_nonzero_when_constraint_uses_permission_phrasing() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a test role.

## Constraints

Do write to the database when needed.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  # Should mention constraint or permission issue
  assert_contains "permission" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 17: Exits 0 when constraints use correct prohibition phrasing ----------

function test_exits_0_when_constraints_use_prohibition_phrasing() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a test role.

## Constraints

**Never** modify source code. This breaks the build.
**Do not** write to main. Deployment pipeline will fail.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 18: Curly braces in code blocks do not trigger placeholder detection ----------

function test_curly_braces_in_code_blocks_do_not_trigger_placeholder() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'OUTER'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a test role.

Example code:

```bash
echo "${variable_name}"
for item in "${array[@]}"; do
  echo "{item}"
done
```
OUTER

  run_validate "$tmp_dir/role.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 19: Exits non-zero when constraint lacks a consequence ----------

function test_exits_nonzero_when_constraint_lacks_consequence() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a test role.

## Constraints

**Never** modify tests.
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 1

  local stderr_output
  stderr_output=$(run_validate_stderr "$tmp_dir/role.md")
  assert_contains "consequence" "$stderr_output"

  rm -rf "$tmp_dir"
}

# ---------- Test 20: File with no Constraints section passes constraint validation ----------

function test_exits_0_when_no_constraints_section() {
  local tmp_dir
  tmp_dir=$(create_tmp_dir)

  cat > "$tmp_dir/role.md" <<'EOF'
---
role: test-role
name: Test Role
type: session
---

## Identity

You are a test role with no constraints section at all.

## Tools

- Read files
- Write files
EOF

  run_validate "$tmp_dir/role.md"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}
