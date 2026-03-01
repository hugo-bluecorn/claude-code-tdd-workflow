#!/bin/bash

# Test suite for documentation updates: /tdd-release skill, tdd-releaser agent,
# check-release-complete.sh hook across 5 documentation files.

README_MD="README.md"
CLAUDE_MD="CLAUDE.md"
USER_GUIDE="docs/user-guide.md"
AUDIT_MD="docs/tdd-workflow-extensibility-audit.md"
VCI_MD="docs/version-control-integration.md"

# ---------- Test 1: README mentions /tdd-release skill ----------

function test_readme_exists() {
  assert_file_exists "$README_MD"
}

function test_readme_skills_table_has_tdd_release() {
  # The Skills table must include /tdd-release
  local skills_section
  skills_section=$(sed -n '/### Skills/,/^###/p' "$README_MD")
  assert_contains "/tdd-release" "$skills_section"
}

function test_readme_agents_table_has_tdd_releaser() {
  # The Agents table must include tdd-releaser
  local agents_section
  agents_section=$(sed -n '/### Agents/,/^###/p' "$README_MD")
  assert_contains "tdd-releaser" "$agents_section"
}

function test_readme_hooks_table_has_check_release_complete() {
  # The Hooks table must include check-release-complete.sh
  local hooks_section
  hooks_section=$(sed -n '/### Hooks/,/^##/p' "$README_MD")
  assert_contains "check-release-complete.sh" "$hooks_section"
}

function test_readme_file_structure_has_tdd_releaser_agent() {
  # File Structure section shows tdd-releaser.md
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  assert_contains "tdd-releaser.md" "$file_structure"
}

function test_readme_file_structure_has_tdd_release_skill() {
  # File Structure section shows tdd-release/ directory
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  assert_contains "tdd-release/" "$file_structure"
}

function test_readme_file_structure_has_check_release_complete_hook() {
  # File Structure section shows check-release-complete.sh
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  assert_contains "check-release-complete.sh" "$file_structure"
}

# ---------- Test 2: README workflow diagram includes release phase ----------

function test_readme_workflow_diagram_has_tdd_releaser() {
  # The ASCII workflow diagram must include tdd-releaser after the verify loop
  local diagram
  diagram=$(sed -n '/## How It Works/,/^##/p' "$README_MD")
  assert_contains "tdd-releaser" "$diagram"
}

# ---------- Test 3: CLAUDE.md mentions /tdd-release ----------

function test_claude_md_exists() {
  assert_file_exists "$CLAUDE_MD"
}

function test_claude_md_available_commands_has_tdd_release() {
  # The Available Commands section must include /tdd-release
  local commands_section
  commands_section=$(sed -n '/### Available Commands/,/^###/p' "$CLAUDE_MD")
  assert_contains "/tdd-release" "$commands_section"
}

# ---------- Test 4: user-guide.md documents the release workflow ----------

function test_user_guide_exists() {
  assert_file_exists "$USER_GUIDE"
}

function test_user_guide_has_release_section() {
  # A section about /tdd-release or "Release" workflow must exist
  assert_file_contains "$USER_GUIDE" "/tdd-release"
}

function test_user_guide_release_describes_what_it_does() {
  # The release section must describe what the command does
  local release_section
  release_section=$(sed -n '/tdd-release/,/^---/p' "$USER_GUIDE")
  assert_contains "CHANGELOG" "$release_section"
}

function test_user_guide_release_mentions_approval_gates() {
  # The release section must mention approval gates
  local release_section
  release_section=$(sed -n '/tdd-release/,/^---/p' "$USER_GUIDE")
  assert_matches "[Aa]pproval|[Aa]pprove" "$release_section"
}

function test_user_guide_release_mentions_pr() {
  # The release section must mention PR creation
  local release_section
  release_section=$(sed -n '/tdd-release/,/^---/p' "$USER_GUIDE")
  assert_matches "PR|pull request" "$release_section"
}

# ---------- Test 5: extensibility-audit.md N6 updated ----------

function test_audit_exists() {
  assert_file_exists "$AUDIT_MD"
}

function test_audit_n6_has_applied_marker() {
  # N6 row must include a completion marker
  local n6_line
  n6_line=$(grep "N6" "$AUDIT_MD" | grep -i "release")
  assert_matches "Applied|v1[.]6[.]0" "$n6_line"
}

# ---------- Test 6: version-control-integration.md Layer 3 marked as implemented ----------

function test_vci_exists() {
  assert_file_exists "$VCI_MD"
}

function test_vci_layer3_says_implemented() {
  # Layer 3 section must contain "IMPLEMENTED" (not "NOT YET IMPLEMENTED")
  local layer3_heading
  layer3_heading=$(grep -i "Layer 3" "$VCI_MD" | head -1)
  assert_contains "IMPLEMENTED" "$layer3_heading"
  assert_not_contains "NOT YET IMPLEMENTED" "$layer3_heading"
}

function test_vci_layer3_has_version_reference() {
  # Layer 3 section must reference v1.6.0
  local layer3_heading
  layer3_heading=$(grep -i "Layer 3" "$VCI_MD" | head -1)
  assert_contains "v1.6.0" "$layer3_heading"
}

function test_vci_summary_table_tdd_release_done() {
  # Summary table row for /tdd-release must show completion
  local summary_table
  summary_table=$(sed -n '/## Summary/,/^---/p' "$VCI_MD")
  local release_row
  release_row=$(echo "$summary_table" | grep "tdd-release")
  assert_matches "Done|v1[.]6[.]0" "$release_row"
}

function test_vci_summary_table_tdd_releaser_done() {
  # Summary table row for tdd-releaser must show completion
  local summary_table
  summary_table=$(sed -n '/## Summary/,/^---/p' "$VCI_MD")
  local releaser_row
  releaser_row=$(echo "$summary_table" | grep "tdd-releaser")
  assert_matches "Done|v1[.]6[.]0" "$releaser_row"
}

function test_vci_summary_table_check_release_hook_done() {
  # Summary table row for check-release-complete.sh must show completion
  local summary_table
  summary_table=$(sed -n '/## Summary/,/^---/p' "$VCI_MD")
  local hook_row
  hook_row=$(echo "$summary_table" | grep "check-release-complete")
  assert_matches "Done|v1[.]6[.]0" "$hook_row"
}

# ---------- Test 7: Audit directory structure includes new files ----------

function test_audit_directory_has_tdd_releaser() {
  # Directory listing in audit must include tdd-releaser.md
  local dir_section
  dir_section=$(sed -n '/Directory Structure/,/^---/p' "$AUDIT_MD")
  assert_contains "tdd-releaser.md" "$dir_section"
}

function test_audit_directory_has_tdd_release_skill() {
  # Directory listing in audit must include tdd-release/
  local dir_section
  dir_section=$(sed -n '/Directory Structure/,/^---/p' "$AUDIT_MD")
  assert_contains "tdd-release/" "$dir_section"
}

function test_audit_directory_has_check_release_complete() {
  # Directory listing in audit must include check-release-complete.sh
  local dir_section
  dir_section=$(sed -n '/Directory Structure/,/^---/p' "$AUDIT_MD")
  assert_contains "check-release-complete.sh" "$dir_section"
}

# ---------- Test 8: README mentions tdd-doc-finalizer agent ----------

function test_readme_agents_table_has_tdd_doc_finalizer() {
  local agents_section
  agents_section=$(sed -n '/### Agents/,/^###/p' "$README_MD")
  assert_contains "tdd-doc-finalizer" "$agents_section"
}

function test_readme_skills_table_has_tdd_finalize_docs() {
  local skills_section
  skills_section=$(sed -n '/### Skills/,/^###/p' "$README_MD")
  assert_contains "/tdd-finalize-docs" "$skills_section"
}

function test_readme_file_structure_has_tdd_doc_finalizer_agent() {
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  assert_contains "tdd-doc-finalizer.md" "$file_structure"
}

function test_readme_file_structure_has_tdd_finalize_docs_skill() {
  local file_structure
  file_structure=$(sed -n '/## File Structure/,/^##/p' "$README_MD")
  assert_contains "tdd-finalize-docs/" "$file_structure"
}

function test_readme_workflow_diagram_has_tdd_doc_finalizer() {
  local diagram
  diagram=$(sed -n '/## How It Works/,/^##/p' "$README_MD")
  assert_contains "tdd-doc-finalizer" "$diagram"
}

# ---------- Test 9: CLAUDE.md mentions /tdd-finalize-docs ----------

function test_claude_md_available_commands_has_tdd_finalize_docs() {
  local commands_section
  commands_section=$(sed -n '/### Available Commands/,/^###/p' "$CLAUDE_MD")
  assert_contains "/tdd-finalize-docs" "$commands_section"
}

function test_claude_md_architecture_table_has_tdd_doc_finalizer() {
  local arch_section
  arch_section=$(sed -n '/### Plugin Architecture/,/^###/p' "$CLAUDE_MD")
  assert_contains "tdd-doc-finalizer" "$arch_section"
}

# ---------- Test 10: user-guide.md documents /tdd-finalize-docs ----------

function test_user_guide_has_finalize_docs_section() {
  assert_file_contains "$USER_GUIDE" "/tdd-finalize-docs"
}

function test_user_guide_finalize_docs_mentions_version_bump() {
  local finalize_section
  finalize_section=$(sed -n '/tdd-finalize-docs/,/^---/p' "$USER_GUIDE")
  assert_matches "version|plugin.json" "$finalize_section"
}

function test_user_guide_finalize_docs_mentions_push() {
  local finalize_section
  finalize_section=$(sed -n '/tdd-finalize-docs/,/^---/p' "$USER_GUIDE")
  assert_matches "push|PR auto-updates" "$finalize_section"
}

# ---------- Test 11: README and user-guide reflect inline orchestration (1.11.0) ----------

function test_readme_workflow_diagram_describes_inline_orchestration() {
  local diagram
  diagram=$(sed -n '/## How It Works/,/^##/p' "$README_MD")
  assert_contains "Inline" "$diagram"
}

function test_readme_agents_table_planner_is_read_only() {
  local agents_section
  agents_section=$(sed -n '/### Agents/,/^###/p' "$README_MD")
  local planner_row
  planner_row=$(echo "$agents_section" | grep "tdd-planner")
  assert_contains "Read-only" "$planner_row"
}

function test_readme_skills_table_tdd_plan_is_inline() {
  local skills_section
  skills_section=$(sed -n '/### Skills/,/^###/p' "$README_MD")
  local plan_row
  plan_row=$(echo "$skills_section" | grep "/tdd-plan")
  assert_matches "[Ii]nline" "$plan_row"
}

function test_readme_hooks_table_validate_plan_is_standalone() {
  local hooks_section
  hooks_section=$(sed -n '/### Hooks/,/^##/p' "$README_MD")
  local validate_row
  validate_row=$(echo "$hooks_section" | grep "validate-plan-output")
  assert_contains "standalone" "$validate_row"
}

function test_user_guide_starting_section_describes_inline_skill() {
  local start_section
  start_section=$(sed -n '/### 2\. What happens next/,/^###/p' "$USER_GUIDE")
  assert_contains "inline" "$start_section"
}

function test_user_guide_review_section_uses_modify_not_revise() {
  local review_section
  review_section=$(sed -n '/### 3\. Review the plan/,/^###/p' "$USER_GUIDE")
  assert_contains "Modify" "$review_section"
}

# ---------- Edge Cases: Additive-only ----------

function test_readme_still_has_tdd_planner() {
  # Existing agents must still be present
  assert_file_contains "$README_MD" "tdd-planner"
}

function test_readme_still_has_tdd_implementer() {
  assert_file_contains "$README_MD" "tdd-implementer"
}

function test_readme_still_has_tdd_verifier() {
  assert_file_contains "$README_MD" "tdd-verifier"
}

function test_claude_md_still_has_tdd_plan_command() {
  assert_file_contains "$CLAUDE_MD" "/tdd-plan"
}

function test_claude_md_still_has_tdd_implement_command() {
  assert_file_contains "$CLAUDE_MD" "/tdd-implement"
}

function test_vci_layer1_still_implemented() {
  local layer1_heading
  layer1_heading=$(grep -i "Layer 1" "$VCI_MD" | head -1)
  assert_contains "IMPLEMENTED" "$layer1_heading"
}

function test_vci_layer2_still_implemented() {
  local layer2_heading
  layer2_heading=$(grep -i "Layer 2" "$VCI_MD" | head -1)
  assert_contains "IMPLEMENTED" "$layer2_heading"
}
