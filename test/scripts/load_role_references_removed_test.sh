#!/bin/bash

# Test: The dead load-role-references.sh script has been removed from the plugin,
# its orphaned test is gone, and the developer-context doc no longer references it.
# Permanent regression guard so the dead script cannot silently return.

DEV_CONTEXT_DOC="$(pwd)/docs/plugin-developer-context.md"

function test_load_role_references_script_is_absent() {
  assert_file_not_exists "$(pwd)/scripts/load-role-references.sh"
}

function test_orphaned_load_role_references_test_is_absent() {
  assert_file_not_exists "$(pwd)/test/scripts/load_role_references_test.sh"
}

function test_developer_context_doc_does_not_reference_script() {
  local content
  content=$(cat "$DEV_CONTEXT_DOC")

  assert_not_contains "load-role-references.sh" "$content"
}
