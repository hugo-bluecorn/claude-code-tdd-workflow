#!/bin/bash

# Test suite for tdd-planner.md frontmatter description accuracy
# Verifies the description matches the agent's actual capabilities:
# autonomous planning, approval flow, and file-writing.

AGENT_FILE="agents/tdd-planner.md"

# Helper: extract only the YAML frontmatter block (between --- markers),
# excluding the markers themselves. This prevents body content from
# causing false negatives on negation tests.
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$AGENT_FILE" | sed '1d;$d'
}

# ---------- Test 1: Description contains "Autonomous" identifier ----------

function test_planner_description_contains_autonomous_identifier() {
  assert_file_exists "$AGENT_FILE"
  assert_file_contains "$AGENT_FILE" "Autonomous TDD planning agent"
}

# ---------- Test 2: Description no longer contains "Read-only" ----------

function test_planner_description_does_not_contain_read_only() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "Read-only" "$frontmatter"
}

# ---------- Test 3: Description no longer contains "research agent" ----------

function test_planner_description_does_not_contain_research_agent() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "research agent" "$frontmatter"
}

# ---------- Test 4: Description mentions invocation via /tdd-plan ----------

function test_planner_description_mentions_tdd_plan_invocation() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "tdd-plan" "$frontmatter"
}

# ---------- Test 5: Existing frontmatter fields preserved ----------

function test_planner_frontmatter_preserves_name() {
  assert_file_contains "$AGENT_FILE" "name: tdd-planner"
}

function test_planner_frontmatter_preserves_tools_with_ask_user() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "AskUserQuestion" "$frontmatter"
}

function test_planner_frontmatter_preserves_model_opus() {
  assert_file_contains "$AGENT_FILE" "model: opus"
}

function test_planner_frontmatter_preserves_pretooluse_bash_guard_hook() {
  assert_file_contains "$AGENT_FILE" "planner-bash-guard.sh"
}

function test_planner_frontmatter_preserves_stop_validate_plan_hook() {
  assert_file_contains "$AGENT_FILE" "validate-plan-output.sh"
}

# ---------- Test 6: Description mentions approval and .tdd-progress.md ----------

function test_planner_description_mentions_approval() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "approval" "$frontmatter"
}

function test_planner_description_mentions_tdd_progress_file() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains ".tdd-progress.md" "$frontmatter"
}
