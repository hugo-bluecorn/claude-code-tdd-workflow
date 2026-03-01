#!/bin/bash

# Test suite for tdd-planner.md — pure research agent identity
# Verifies the description, frontmatter, and body content match
# the research-only agent role (no approval flow, no file writing).

AGENT_FILE="agents/tdd-planner.md"

# Helper: extract only the YAML frontmatter block (between --- markers),
# excluding the markers themselves. This prevents body content from
# causing false negatives on negation tests.
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$AGENT_FILE" | sed '1d;$d'
}

# Helper: extract body content (everything after the closing --- of frontmatter),
# stripping leading blank lines.
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$AGENT_FILE" | sed '/./,$!d'
}

# ===== Slice 4: Pure Research Agent Identity =====

# ---------- Test 1: Description identifies as research agent ----------

function test_planner_description_contains_research() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "research" "$frontmatter"
}

function test_planner_description_does_not_contain_autonomous() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "Autonomous" "$frontmatter"
}

function test_planner_description_does_not_contain_approval() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "approval" "$frontmatter"
}

function test_planner_description_does_not_contain_writes() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "writes" "$frontmatter"
}

# ---------- Test 2: Tools excludes AskUserQuestion ----------

function test_planner_tools_excludes_ask_user_question() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "AskUserQuestion" "$frontmatter"
}

function test_planner_tools_includes_read_glob_grep_bash() {
  assert_file_contains "$AGENT_FILE" "tools: Read, Glob, Grep, Bash"
}

# ---------- Test 3: No Stop hook ----------

function test_planner_no_stop_hook() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "Stop:" "$frontmatter"
}

function test_planner_no_validate_plan_output_in_frontmatter() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "validate-plan-output" "$frontmatter"
}

# ---------- Test 4: No disallowedTools ----------

function test_planner_no_disallowed_tools() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "disallowedTools" "$frontmatter"
}

# ---------- Test 5: Body has no approval/lock content ----------

function test_planner_body_no_mandatory_approval_sequence() {
  local body
  body=$(get_body)
  assert_not_contains "Mandatory approval sequence" "$body"
}

function test_planner_body_no_ask_user_question() {
  local body
  body=$(get_body)
  assert_not_contains "AskUserQuestion" "$body"
}

function test_planner_body_no_tdd_plan_locked() {
  local body
  body=$(get_body)
  assert_not_contains ".tdd-plan-locked" "$body"
}

function test_planner_body_no_compaction_guard() {
  local body
  body=$(get_body)
  assert_not_contains "COMPACTION GUARD" "$body"
}

function test_planner_body_no_tool_use_reminder() {
  local body
  body=$(get_body)
  assert_not_contains "Tool Use Reminder" "$body"
}

# ---------- Test 6: Body contains output format specification ----------

function test_planner_body_contains_given_when_then_template() {
  local body
  body=$(get_body)
  assert_contains "Given:" "$body"
  assert_contains "When:" "$body"
  assert_contains "Then:" "$body"
}

function test_planner_body_contains_self_check() {
  local body
  body=$(get_body)
  assert_contains "Self-check" "$body"
}

# ---------- Test 7: PreToolUse bash guard preserved ----------

function test_planner_pretooluse_hook_preserved() {
  assert_file_contains "$AGENT_FILE" "PreToolUse:"
  assert_file_contains "$AGENT_FILE" "planner-bash-guard.sh"
}

# ---------- Test 8: Skills, memory, model, permissionMode preserved ----------

function test_planner_preserved_fields() {
  assert_file_contains "$AGENT_FILE" "dart-flutter-conventions"
  assert_file_contains "$AGENT_FILE" "cpp-testing-conventions"
  assert_file_contains "$AGENT_FILE" "bash-testing-conventions"
  assert_file_contains "$AGENT_FILE" "memory: project"
  assert_file_contains "$AGENT_FILE" "model: opus"
  assert_file_contains "$AGENT_FILE" "permissionMode: plan"
}

# ---------- Test 9: Body contains research methodology ----------

function test_planner_body_contains_detect_project_context() {
  local body
  body=$(get_body)
  assert_contains "detect-project-context.sh" "$body"
}

function test_planner_body_contains_planning_process() {
  local body
  body=$(get_body)
  assert_contains "## Planning Process" "$body"
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
