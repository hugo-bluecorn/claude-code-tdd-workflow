#!/bin/bash

# Test suite for R2 — context-updater denylist drift (Task -> Agent).
# The subagent-spawning tool was renamed Task->Agent, so denying a bare
# `Task` token is a no-op. The denylist must deny `Agent` instead, while
# keeping `MultiEdit` and `NotebookEdit`. Reuses the get_frontmatter sed
# helper pattern from test/agents/agent_effort_test.sh, parameterized by
# file. No role-* component is named anywhere (PRIME=core).

CONTEXT_UPDATER="agents/context-updater.md"

# Helper: extract YAML frontmatter (between --- markers, excluding markers)
get_frontmatter() {
  local file="$1"
  sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Helper: extract the trimmed disallowedTools scalar value from frontmatter.
get_disallowed_tools_value() {
  local file="$1"
  get_frontmatter "$file" \
    | grep -E '^disallowedTools:' \
    | head -n 1 \
    | sed -E 's/^disallowedTools:[[:space:]]*//' \
    | sed -E 's/[[:space:]]+$//'
}

# ===== Test 1: disallowedTools denies the renamed Agent tool =====

function test_disallowed_tools_contains_agent() {
  local value
  value=$(get_disallowed_tools_value "$CONTEXT_UPDATER")
  assert_contains "Agent" "$value"
}

# ===== Test 2: the stale bare Task denial is gone =====
# Tokenize on commas/whitespace and assert no standalone token equals `Task`
# (a substring like `TaskFoo` must NOT trigger a failure).

function test_disallowed_tools_has_no_standalone_task_token() {
  local value token found="no"
  value=$(get_disallowed_tools_value "$CONTEXT_UPDATER")
  # Split on commas and whitespace into standalone tokens.
  for token in ${value//,/ }; do
    if [ "$token" = "Task" ]; then
      found="yes"
    fi
  done
  assert_equals "no" "$found"
}

# ===== Test 3: the other denied tools are preserved =====

function test_disallowed_tools_preserves_multiedit_and_notebookedit() {
  local value
  value=$(get_disallowed_tools_value "$CONTEXT_UPDATER")
  assert_contains "MultiEdit" "$value"
  assert_contains "NotebookEdit" "$value"
}

# ===== Test 4: frontmatter remains well-formed after the edit =====

function test_frontmatter_remains_well_formed() {
  local fm
  fm=$(get_frontmatter "$CONTEXT_UPDATER")
  assert_contains "name: context-updater" "$fm"
  assert_contains "model: opus" "$fm"
}
