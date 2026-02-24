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

# ===== Slice 2: Identity & Invocation Guard =====

# Helper: extract body content (everything after the closing --- of frontmatter),
# stripping leading blank lines.
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$AGENT_FILE" | sed '/./,$!d'
}

# ---------- Test S2-1: Body contains Identity section heading ----------

function test_planner_body_contains_identity_section_heading() {
  local body
  body=$(get_body)
  assert_contains "## Identity" "$body"
}

# ---------- Test S2-2: Identity section declares agent is NOT research-only ----------

function test_planner_identity_declares_not_research_only() {
  local body
  body=$(get_body)
  assert_contains "NOT a research-only helper" "$body"
}

# ---------- Test S2-3: Identity section contains invocation detection instruction ----------

function test_planner_identity_contains_process_detection_instruction() {
  local body
  body=$(get_body)
  assert_contains '## Process' "$body"
}

# ---------- Test S2-4: Identity section contains fallback behavior ----------

function test_planner_identity_contains_fallback_behavior() {
  local body
  body=$(get_body)
  assert_contains "return only raw research findings as a fallback" "$body"
}

# ---------- Test S2-5: Existing body sections preserved ----------

function test_planner_body_preserves_planning_process() {
  local body
  body=$(get_body)
  assert_contains "## Planning Process" "$body"
}

function test_planner_body_preserves_key_principles() {
  local body
  body=$(get_body)
  assert_contains "## Key Principles" "$body"
}

function test_planner_body_preserves_output_section() {
  local body
  body=$(get_body)
  assert_contains "## Output" "$body"
}

function test_planner_body_preserves_mandatory_approval_sequence() {
  local body
  body=$(get_body)
  assert_contains "### Mandatory approval sequence" "$body"
}

# ---------- Test S2-6: Identity section appears before Planning Process ----------

function test_planner_identity_appears_before_planning_process() {
  local identity_line planning_line
  identity_line=$(grep -n "## Identity" "$AGENT_FILE" | head -1 | cut -d: -f1)
  planning_line=$(grep -n "## Planning Process" "$AGENT_FILE" | head -1 | cut -d: -f1)

  assert_not_empty "$identity_line"
  assert_not_empty "$planning_line"

  if [[ "$identity_line" -ge "$planning_line" ]]; then
    fail "## Identity (line $identity_line) should appear before ## Planning Process (line $planning_line)"
  fi
}

# ===== Slice 3: CLAUDE.md Documentation Updates =====

CLAUDE_FILE="CLAUDE.md"

# Helper: extract only the tdd-planner row from the Plugin Architecture table.
# This isolates the row so negation checks do not match other rows.
get_planner_table_row() {
  grep "tdd-planner" "$CLAUDE_FILE"
}

# ---------- Test S3-1: Architecture table tdd-planner row no longer contains "Read-only" ----------

function test_claude_md_planner_row_does_not_contain_read_only() {
  local planner_row
  planner_row=$(get_planner_table_row)
  assert_not_empty "$planner_row"
  assert_not_contains "Read-only" "$planner_row"
}

# ---------- Test S3-2: Architecture table tdd-planner row describes full planning lifecycle ----------

function test_claude_md_planner_row_contains_approval_lifecycle() {
  local planner_row
  planner_row=$(get_planner_table_row)
  assert_not_empty "$planner_row"
  assert_contains "approval" "$planner_row"
}

# ---------- Test S3-3: CLAUDE.md contains invocation warning about Task tool ----------

function test_claude_md_contains_invocation_warning_about_task_tool() {
  assert_file_contains "$CLAUDE_FILE" "Do NOT manually invoke"
  assert_file_contains "$CLAUDE_FILE" "tdd-planner"
}

# ---------- Test S3-4: Invocation warning mentions /tdd-plan as correct invocation path ----------

function test_claude_md_invocation_warning_mentions_tdd_plan() {
  # The warning block must contain /tdd-plan in the context of the warning.
  # We check that the line containing "Do NOT manually invoke" is near a line
  # containing "/tdd-plan". Since they are in the same blockquote, we extract
  # the warning block and verify both are present.
  local warning_block
  warning_block=$(sed -n '/Do NOT manually invoke/,/absent\./p' "$CLAUDE_FILE")
  assert_not_empty "$warning_block"
  assert_contains "/tdd-plan" "$warning_block"
}

# ---------- Test S3-5: Other architecture table rows preserved ----------

function test_claude_md_preserves_other_architecture_rows() {
  assert_file_contains "$CLAUDE_FILE" "tdd-implementer"
  assert_file_contains "$CLAUDE_FILE" "tdd-verifier"
  assert_file_contains "$CLAUDE_FILE" "tdd-releaser"
  assert_file_contains "$CLAUDE_FILE" "context-updater"
  # Verify tdd-verifier still has its original Read-only mode
  local verifier_row
  verifier_row=$(grep "tdd-verifier" "$CLAUDE_FILE")
  assert_contains "Read-only" "$verifier_row"
}

# ---------- Test S3-6: Available Commands section preserved ----------

function test_claude_md_preserves_available_commands() {
  assert_file_contains "$CLAUDE_FILE" "/tdd-plan"
  assert_file_contains "$CLAUDE_FILE" "/tdd-implement"
  assert_file_contains "$CLAUDE_FILE" "/tdd-release"
  assert_file_contains "$CLAUDE_FILE" "/tdd-update-context"
}
