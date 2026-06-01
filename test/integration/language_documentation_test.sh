#!/bin/bash

# Test suite for non-C language test-runner documentation: tdd-verifier.md, README.md
# Verifies the verifier still documents the Dart/Flutter and Bash/Shell test runners
# and that the README conveys the extensible / convention-pack framing (language-agnostic
# since v2.0). C/C++-specific doc assertions were retired in R14; C content lives in R1.

VERIFIER_MD="agents/tdd-verifier.md"
README_MD="README.md"

# ---------- Test 1: Verifier preserves Dart and Bash test-runner entries ----------

function test_verifier_still_has_flutter_test() {
  assert_file_contains "$VERIFIER_MD" "flutter test"
}

function test_verifier_still_has_bashunit() {
  assert_file_contains "$VERIFIER_MD" "bashunit"
}

function test_verifier_still_has_dart_analyze() {
  assert_file_contains "$VERIFIER_MD" "dart analyze"
}

function test_verifier_still_has_shellcheck() {
  assert_file_contains "$VERIFIER_MD" "shellcheck"
}

# ---------- C5: pack-aware framing (resolve binding, commands-only) ----------

function test_verifier_documents_pack_commands_resolution() {
  # Reconciled: the verifier resolves the active pack via the committed binding
  # and reads its commands (test/lint/coverage), rather than a hardcoded matrix.
  assert_file_contains "$VERIFIER_MD" ".commands"
}

function test_verifier_does_not_read_pack_standards_index() {
  # Blackbox stance (decision #2): commands-only — never standards.index.
  local hits
  hits=$(grep -nF 'standards.index' "$VERIFIER_MD" || true)
  assert_empty "$hits"
}

# ---------- Test 2: README overview conveys the extensible / convention framing ----------

function test_readme_overview_conveys_extensible_framing() {
  # De-brittled: the README must convey extensibility / a convention-pack model
  # somewhere (language-agnostic since v2.0), no longer tied to the first 10 lines.
  # Falsifiable: fails if the README stops documenting the extensible/convention framing.
  local content
  content=$(cat "$README_MD")
  assert_matches "extensible|convention" "$content"
}
