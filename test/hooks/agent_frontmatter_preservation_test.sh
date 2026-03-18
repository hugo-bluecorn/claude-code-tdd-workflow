#!/bin/bash

# Test suite for agent frontmatter preservation — validates that all previous
# Issue 004 slices did NOT accidentally remove any agent frontmatter hooks.
# This is a regression guard: all tests should pass against unmodified agents.

AGENTS_DIR="$(pwd)/agents"

# ---------- Test 1: Planner frontmatter still contains PreToolUse Bash hook ----------

function test_planner_has_pretooluse_hook() {
  assert_file_exists "$AGENTS_DIR/tdd-planner.md"

  local content
  content=$(cat "$AGENTS_DIR/tdd-planner.md")

  assert_contains "PreToolUse:" "$content"
  assert_contains 'matcher: "Bash"' "$content"
  assert_contains "planner-bash-guard.sh" "$content"
}

# ---------- Test 2: Implementer frontmatter still contains PreToolUse and PostToolUse hooks ----------

function test_implementer_has_pretooluse_and_posttooluse_hooks() {
  assert_file_exists "$AGENTS_DIR/tdd-implementer.md"

  local content
  content=$(cat "$AGENTS_DIR/tdd-implementer.md")

  assert_contains "PreToolUse:" "$content"
  assert_contains "PostToolUse:" "$content"
  assert_contains "validate-tdd-order.sh" "$content"
  assert_contains "auto-run-tests.sh" "$content"
}

# ---------- Test 3: Verifier frontmatter still contains Stop hook ----------

function test_verifier_has_stop_hook() {
  assert_file_exists "$AGENTS_DIR/tdd-verifier.md"

  local content
  content=$(cat "$AGENTS_DIR/tdd-verifier.md")

  assert_contains "Stop:" "$content"
  assert_contains "COMPLETE" "$content"
}

# ---------- Test 4: Context-updater frontmatter still contains Stop hook ----------

function test_context_updater_has_stop_hook() {
  assert_file_exists "$AGENTS_DIR/context-updater.md"

  local content
  content=$(cat "$AGENTS_DIR/context-updater.md")

  assert_contains "Stop:" "$content"
  assert_contains "framework versions" "$content"
}

# ---------- Test 5: At least 4 agent files contain hooks: in frontmatter ----------

function test_at_least_four_agents_have_hooks_frontmatter() {
  local count=0

  for agent_file in "$AGENTS_DIR"/*.md; do
    if grep -q "^hooks:" "$agent_file"; then
      count=$((count + 1))
    fi
  done

  assert_greater_or_equal_than 4 "$count"
}
