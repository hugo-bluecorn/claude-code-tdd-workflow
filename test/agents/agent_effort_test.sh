#!/bin/bash

# Test suite for R6 — pin `effort` tier on every present agent.
# Three core agents get explicit tiers asserted by name; every other
# present agent is reached anonymously via a dynamic glob-and-exclude
# loop and must declare a valid effort value. No fixed agent list is
# hard-coded and no role-* basename is named anywhere in this file.

VERIFIER="agents/tdd-verifier.md"
PLANNER="agents/tdd-planner.md"
IMPLEMENTER="agents/tdd-implementer.md"

# Helper: extract YAML frontmatter (between --- markers, excluding markers)
get_frontmatter() {
  local file="$1"
  sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Helper: extract body (everything after closing --- of frontmatter)
get_body() {
  local file="$1"
  sed -n '/^---$/,/^---$/d; p' "$file" | sed '/./,$!d'
}

# Helper: extract the trimmed effort scalar value from a file's frontmatter.
# Reads the `effort:` line, strips the key, and trims surrounding whitespace.
get_effort_value() {
  local file="$1"
  get_frontmatter "$file" \
    | grep -E '^effort:' \
    | head -n 1 \
    | sed -E 's/^effort:[[:space:]]*//' \
    | sed -E 's/[[:space:]]+$//'
}

# ===== Test 1: tdd-verifier declares effort low in frontmatter =====

function test_verifier_effort_is_low() {
  local fm
  fm=$(get_frontmatter "$VERIFIER")
  assert_contains "effort: low" "$fm"
}

# ===== Test 2: tdd-planner declares effort high in frontmatter =====

function test_planner_effort_is_high() {
  local fm
  fm=$(get_frontmatter "$PLANNER")
  assert_contains "effort: high" "$fm"
}

# ===== Test 3: tdd-implementer declares effort high in frontmatter =====

function test_implementer_effort_is_high() {
  local fm
  fm=$(get_frontmatter "$IMPLEMENTER")
  assert_contains "effort: high" "$fm"
}

# ===== Test 4: every other present agent declares a valid effort value =====
# Glob agents/*.md dynamically, exclude the three core tiered basenames,
# and assert each remaining file's effort value is one of low/medium/high.

function test_other_agents_have_valid_effort() {
  local file value
  for file in agents/*.md; do
    case "$(basename "$file")" in
      tdd-verifier.md|tdd-planner.md|tdd-implementer.md) continue ;;
    esac
    value=$(get_effort_value "$file")
    # value must be exactly one of the valid tiers
    assert_matches "^(low|medium|high)$" "$value"
  done
}

# ===== Test 5: effort field is inside frontmatter, not the body =====

function test_effort_is_in_frontmatter_not_body() {
  local body
  body=$(get_body "$VERIFIER")
  assert_not_contains "effort:" "$body"
}

# ===== Test 6: dynamic "others" set is non-empty (anti-vacuous) =====

function test_other_agents_set_is_non_empty() {
  local file base count=0
  for file in agents/*.md; do
    base=$(basename "$file")
    case "$base" in
      tdd-verifier.md|tdd-planner.md|tdd-implementer.md) continue ;;
    esac
    count=$((count + 1))
  done
  assert_greater_or_equal_than "1" "$count"
}

# ===== Test 7: effort value contains no trailing inline content =====
# The extracted value must match exactly low/medium/high — a trailing
# comment such as `medium  # tbd` must NOT pass.

function test_effort_value_is_clean_scalar() {
  local file base value
  for file in agents/*.md; do
    base=$(basename "$file")
    value=$(get_effort_value "$file")
    # Skip files that declare no effort (handled by other tests).
    [ -z "$value" ] && continue
    assert_matches "^(low|medium|high)$" "$value"
  done
}
