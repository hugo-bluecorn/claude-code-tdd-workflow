#!/bin/bash

# Test suite for role-creator agent definition
# Verifies frontmatter, body content, and CLAUDE.md documentation.

AGENT_FILE="agents/role-creator.md"

# Helper: extract YAML frontmatter (between --- delimiters)
get_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$AGENT_FILE" | sed '1d;$d'
}

# Helper: extract body (after frontmatter)
get_body() {
  sed -n '/^---$/,/^---$/d; p' "$AGENT_FILE" | sed '/./,$!d'
}

# ========== Slice 1: Agent Frontmatter ==========

# ---------- Test 1: Agent file exists at correct path ----------

function test_agent_file_exists() {
  assert_file_exists "$AGENT_FILE"
}

# ---------- Test 2: Frontmatter name field is "role-creator" ----------

function test_frontmatter_name_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "name: role-creator" "$frontmatter"
}

# ---------- Test 3: Frontmatter description mentions role creation ----------

function test_frontmatter_description_mentions_role() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "description:" "$frontmatter"
  assert_contains "role" "$frontmatter"
}

# ---------- Test 4: Tools field includes Read, Bash, Glob, Grep, WebSearch, WebFetch ----------

function test_tools_includes_required_tools() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "Read" "$frontmatter"
  assert_contains "Bash" "$frontmatter"
  assert_contains "Glob" "$frontmatter"
  assert_contains "Grep" "$frontmatter"
  assert_contains "WebSearch" "$frontmatter"
  assert_contains "WebFetch" "$frontmatter"
}

# ---------- Test 5: Tools field does NOT include Write or Edit ----------

function test_tools_excludes_write_edit() {
  local tools_line
  tools_line=$(get_frontmatter | grep '^tools:')
  assert_not_contains "Write" "$tools_line"
  assert_not_contains "Edit" "$tools_line"
}

# ---------- Test 6: No disallowedTools field ----------

function test_no_disallowed_tools_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "disallowedTools" "$frontmatter"
}

# ---------- Test 7: Model field is set ----------

function test_model_field_present() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_contains "model:" "$frontmatter"
}

# ---------- Test 8: No memory field ----------

function test_no_memory_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "memory:" "$frontmatter"
}

# ---------- Test 9: No hooks in frontmatter ----------

function test_no_hooks_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "hooks:" "$frontmatter"
}

# ---------- Test 10: No skills in frontmatter ----------

function test_no_skills_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "skills:" "$frontmatter"
}

# ---------- Test 11: No context or agent field in frontmatter ----------

function test_no_context_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "context:" "$frontmatter"
}

function test_no_agent_field() {
  local frontmatter
  frontmatter=$(get_frontmatter)
  assert_not_contains "agent:" "$frontmatter"
}

# ========== Slice 2: Agent Body Content ==========

# ---------- Test 1: Body instructs reading cr-role-creator.md via Bash cat ----------

function test_body_reads_cr_role_via_bash_cat() {
  local body
  body=$(get_body)
  assert_contains "cat" "$body"
  assert_contains "CLAUDE_PLUGIN_ROOT" "$body"
  assert_contains "cr-role-creator.md" "$body"
}

# ---------- Test 2: Body instructs reading role-format.md via Bash cat ----------

function test_body_reads_format_spec_via_bash_cat() {
  local body
  body=$(get_body)
  assert_contains "cat" "$body"
  assert_contains "role-format.md" "$body"
}

# ---------- Test 3: CLAUDE_PLUGIN_ROOT used in Bash context not Read tool ----------

function test_plugin_root_in_bash_context() {
  local body
  body=$(get_body)
  # Should have CLAUDE_PLUGIN_ROOT in body
  assert_contains "CLAUDE_PLUGIN_ROOT" "$body"
  # Should NOT instruct Read tool with CLAUDE_PLUGIN_ROOT
  assert_not_contains 'Read("${CLAUDE_PLUGIN_ROOT}' "$body"
  assert_not_contains "Use the Read tool" "$body"
}

# ---------- Test 4: Body instructs running validate-role-output.sh via Bash ----------

function test_body_runs_validate_script() {
  local body
  body=$(get_body)
  assert_contains "validate-role-output.sh" "$body"
}

# ---------- Test 5: Body does NOT contain DCI commands ----------

function test_body_no_dci_commands() {
  local body
  body=$(get_body)
  assert_not_contains '!`' "$body"
}

# ---------- Test 6: Body does NOT instruct using Write or Edit tools ----------

function test_body_no_write_edit_instructions() {
  local body
  body=$(get_body)
  # Agent should not instruct USING Write/Edit — "Do NOT use" is fine
  assert_not_contains "Use the Write tool" "$body"
  assert_not_contains "Use the Edit tool" "$body"
}

# ---------- Test 7: Body contains research instructions ----------

function test_body_contains_research_instructions() {
  local body
  body=$(get_body)
  assert_contains "CLAUDE.md" "$body"
  assert_contains "research" "$body"
}

# ---------- Test 8: Body contains critique step ----------

function test_body_contains_critique() {
  local body
  body=$(get_body)
  # Case-insensitive check
  local lower_body
  lower_body=$(echo "$body" | tr '[:upper:]' '[:lower:]')
  assert_contains "critique" "$lower_body"
}

# ---------- Test 9: Body instructs setting generator field to /role-cr ----------

function test_body_sets_generator_field() {
  local body
  body=$(get_body)
  assert_contains "generator" "$body"
  assert_contains "/role-cr" "$body"
}

# ---------- Test 10: Body does NOT contain approval gate ----------

function test_body_no_approval_gate() {
  local body
  body=$(get_body)
  assert_not_contains "AskUserQuestion" "$body"
}

# ---------- Test 11: Body does NOT instruct creating .claude/skills/ directories ----------

function test_body_no_output_path_writing() {
  local body
  body=$(get_body)
  assert_not_contains "mkdir" "$body"
  # Agent should not have positive write instructions to .claude/skills/
  # "Do NOT write to .claude/skills/" is fine — we check for mkdir as the real indicator
}

# ========== Slice 5: CLAUDE.md Documentation ==========

CLAUDE_FILE="CLAUDE.md"

# ---------- Test 1: Architecture table contains role-creator row ----------

function test_claude_md_has_role_creator_row() {
  assert_file_contains "$CLAUDE_FILE" "role-creator"
}

# ---------- Test 2: Role-creator row shows Read-only mode ----------

function test_role_creator_row_read_only() {
  local row
  row=$(grep "role-creator" "$CLAUDE_FILE")
  assert_contains "Read-only" "$row"
}

# ---------- Test 3: Role-creator description mentions role creation ----------

function test_role_creator_row_describes_role_creation() {
  local row
  row=$(grep "role-creator" "$CLAUDE_FILE")
  assert_contains "role" "$row"
}

# ---------- Test 4: Existing architecture rows preserved ----------

function test_existing_agent_rows_preserved() {
  assert_file_contains "$CLAUDE_FILE" "tdd-planner"
  assert_file_contains "$CLAUDE_FILE" "tdd-implementer"
  assert_file_contains "$CLAUDE_FILE" "tdd-verifier"
  assert_file_contains "$CLAUDE_FILE" "tdd-releaser"
  assert_file_contains "$CLAUDE_FILE" "context-updater"
  assert_file_contains "$CLAUDE_FILE" "tdd-doc-finalizer"
}

# ---------- Test 5: Available Commands section includes /role-cr ----------

function test_available_commands_has_role_cr() {
  assert_file_contains "$CLAUDE_FILE" "/role-cr"
}

# ---------- Test 6: No duplicate role-creator entries in table ----------

function test_no_duplicate_role_creator_rows() {
  local count
  count=$(grep -c '| \*\*role-creator\*\*' "$CLAUDE_FILE" || true)
  assert_equals "1" "$count"
}
