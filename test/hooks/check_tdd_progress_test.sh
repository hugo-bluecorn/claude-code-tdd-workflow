#!/bin/bash

# Test suite for check-tdd-progress.sh hook — stop hook that blocks session end
# while TDD slices remain unfinished.
# Retroactive coverage: the implementation already exists and must NOT be modified.

HOOK_ABS="$(pwd)/hooks/check-tdd-progress.sh"

# Helper: build Stop hook JSON with stop_hook_active flag
build_json() {
  local stop_active="$1"
  printf '{"stop_hook_active": %s}\n' "$stop_active"
}

# Helper: create an isolated temp directory with the hook script copied in
create_tmp_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)

  cp "$HOOK_ABS" "$tmp_dir/"

  echo "$tmp_dir"
}

# Helper: run hook inside a given directory, piping JSON via stdin
run_hook_in_dir() {
  local dir="$1"
  local json="$2"
  (cd "$dir" && echo "$json" | bash "$dir/check-tdd-progress.sh" 2>/dev/null)
}

# ---------- Test 1: stop_hook_active=true exits 0 with empty stdout ----------

function test_stop_hook_active_true_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "true")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_stop_hook_active_true_produces_empty_stdout() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "true")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json")

  assert_empty "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 2: No progress file exits 0 with empty stdout ----------

function test_no_progress_file_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # No .tdd-progress.md created in tmp_dir
  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_no_progress_file_produces_empty_stdout() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json
  json=$(build_json "false")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json")

  assert_empty "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 3: No slices found exits 0 ----------

function test_no_slices_found_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Progress file exists but has no ## Slice or ## Step headers
  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
# TDD Progress

Some general notes about this session.
No slice headers here.
EOF

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 4: Block when slices remain ----------

function test_block_when_slices_remain_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # 3 slice headers, only 1 in terminal state
  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
## Slice 1: Setup
Status: done

## Slice 2: Core logic
Status: in_progress

## Slice 3: Cleanup
Status: pending
EOF

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_block_when_slices_remain_outputs_block_decision() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
## Slice 1: Setup
Status: done

## Slice 2: Core logic
Status: in_progress

## Slice 3: Cleanup
Status: pending
EOF

  local json
  json=$(build_json "false")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json")

  # Should contain a JSON block decision
  local decision
  decision=$(echo "$output" | jq -r '.decision')
  assert_equals "block" "$decision"

  rm -rf "$tmp_dir"
}

function test_block_when_slices_remain_reason_contains_count() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
## Slice 1: Setup
Status: done

## Slice 2: Core logic
Status: in_progress

## Slice 3: Cleanup
Status: pending
EOF

  local json
  json=$(build_json "false")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json")

  local reason
  reason=$(echo "$output" | jq -r '.reason')
  assert_contains "2 of 3" "$reason"

  rm -rf "$tmp_dir"
}

# ---------- Test 5: All terminal exits 0 ----------

function test_all_terminal_slices_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
## Slice 1: Setup
Status: done

## Slice 2: Core logic
Status: pass
EOF

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_all_terminal_slices_produces_no_block_output() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
## Slice 1: Setup
Status: done

## Slice 2: Core logic
Status: pass
EOF

  local json
  json=$(build_json "false")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json")

  assert_empty "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 6: Case-insensitive status ----------

function test_case_insensitive_status_recognized() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
## Slice 1: Setup
Status: DONE

## Slice 2: Core logic
Status: PASS
EOF

  local json
  json=$(build_json "false")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json")

  # Both uppercase statuses should be recognized as terminal -> no block
  assert_empty "$output"

  rm -rf "$tmp_dir"
}

# ---------- Test 7: All terminal states recognized ----------

function test_all_terminal_states_recognized() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
## Slice 1: First
Status: pass

## Slice 2: Second
Status: done

## Slice 3: Third
Status: complete

## Slice 4: Fourth
Status: fail

## Slice 5: Fifth
Status: skip
EOF

  local json
  json=$(build_json "false")

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json")

  # All 5 are terminal, so no block output expected
  assert_empty "$output"

  rm -rf "$tmp_dir"
}

function test_all_terminal_states_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  cat > "$tmp_dir/.tdd-progress.md" <<'EOF'
## Slice 1: First
Status: pass

## Slice 2: Second
Status: done

## Slice 3: Third
Status: complete

## Slice 4: Fourth
Status: fail

## Slice 5: Fifth
Status: skip
EOF

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 8: Empty progress file ----------

function test_empty_progress_file_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # Create a zero-byte progress file
  : > "$tmp_dir/.tdd-progress.md"

  local json
  json=$(build_json "false")

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

# ---------- Test 9: Missing stop_hook_active field ----------

function test_missing_stop_hook_active_field_exits_zero() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  # JSON with no stop_hook_active field, no progress file
  local json='{}'

  run_hook_in_dir "$tmp_dir" "$json"
  assert_exit_code 0

  rm -rf "$tmp_dir"
}

function test_missing_stop_hook_active_field_produces_empty_stdout() {
  local tmp_dir
  tmp_dir=$(create_tmp_env)

  local json='{}'

  local output
  output=$(run_hook_in_dir "$tmp_dir" "$json")

  assert_empty "$output"

  rm -rf "$tmp_dir"
}
