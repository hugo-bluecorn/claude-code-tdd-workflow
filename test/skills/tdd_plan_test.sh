#!/bin/bash

# Test suite for tdd-plan SKILL.md — inline orchestration
# Verifies the skill runs inline (no fork), spawns planner via Agent tool,
# handles approval flow, and writes files after approval.

SKILL_FILE="skills/tdd-plan/SKILL.md"

# Helper: extract YAML frontmatter
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d'
}

# Helper: extract body (after frontmatter)
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$SKILL_FILE" | sed '/./,$!d'
}

# ---------- Test 1: No fork context or agent reference ----------

function test_no_fork_context() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "context:" "$frontmatter"
}

function test_no_agent_reference() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "agent:" "$frontmatter"
}

# ---------- Test 2: Body contains Agent tool spawning ----------

function test_body_contains_agent_tool_spawn() {
  local body
  body=$(get_body)
  assert_contains "Agent tool" "$body"
  assert_contains "tdd-planner" "$body"
}

# ---------- Test 3: Body contains AskUserQuestion approval ----------

function test_body_contains_ask_user_question() {
  local body
  body=$(get_body)
  assert_contains "AskUserQuestion" "$body"
}

function test_body_contains_approve_option() {
  local body
  body=$(get_body)
  assert_contains "Approve" "$body"
}

function test_body_contains_modify_option() {
  local body
  body=$(get_body)
  assert_contains "Modify" "$body"
}

function test_body_contains_discard_option() {
  local body
  body=$(get_body)
  assert_contains "Discard" "$body"
}

# ---------- Test 4: Body contains file writing after approval ----------

function test_body_contains_write_tdd_progress() {
  local body
  body=$(get_body)
  assert_contains ".tdd-progress.md" "$body"
}

function test_body_contains_write_planning_archive() {
  local body
  body=$(get_body)
  assert_contains "planning/" "$body"
}

# ---------- Test 5: Modify flow references Agent tool resume ----------

function test_body_contains_resume_parameter() {
  local body
  body=$(get_body)
  assert_contains "resume" "$body"
}

# ---------- Test 6: File writing after approval section ----------

function test_write_instruction_after_approval() {
  local approval_line write_line
  approval_line=$(grep -n "AskUserQuestion" "$SKILL_FILE" | head -1 | cut -d: -f1)
  write_line=$(grep -n "Write.*\.tdd-progress\.md\|\.tdd-progress\.md.*write\|Write Files" "$SKILL_FILE" | head -1 | cut -d: -f1)
  assert_not_empty "$approval_line"
  assert_not_empty "$write_line"
  if [[ "$write_line" -le "$approval_line" ]]; then
    fail "Write instruction (line $write_line) should appear after AskUserQuestion (line $approval_line)"
  fi
}

# ---------- Test 7: Approved timestamp instruction ----------

function test_body_contains_approved_timestamp() {
  local body
  body=$(get_body)
  assert_contains "Approved:" "$body"
  assert_contains "ISO 8601" "$body"
}

# ---------- Test 8: No lock file references ----------

function test_no_lock_file_references() {
  local full_content
  full_content=$(cat "$SKILL_FILE")
  assert_not_contains ".tdd-plan-locked" "$full_content"
  assert_not_contains ".tdd-plan-approval-retries" "$full_content"
}

# ---------- Test 9: Skill does NOT duplicate format instructions ----------

function test_no_convention_loading_instructions() {
  local body
  body=$(get_body)
  assert_not_contains "detect-project-context.sh" "$body"
}

function test_no_given_when_then_template() {
  local body
  body=$(get_body)
  # The Given/When/Then template is in the planner body, not the skill
  assert_not_contains "Given: {precondition}" "$body"
}

# ---------- Test 10: Incomplete planner output handling ----------

function test_body_contains_incomplete_output_handling() {
  local body
  body=$(get_body)
  assert_contains "complete plan" "$body"
  assert_contains "STOP" "$body"
}

# ---------- Preserved frontmatter fields ----------

function test_preserves_disable_model_invocation() {
  assert_file_contains "$SKILL_FILE" "disable-model-invocation: true"
}

function test_preserves_argument_hint() {
  assert_file_contains "$SKILL_FILE" "argument-hint:"
}

function test_preserves_name() {
  assert_file_contains "$SKILL_FILE" "name: tdd-plan"
}
