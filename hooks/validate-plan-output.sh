#!/bin/bash
# Stop hook for tdd-planner: validates plan file existence, required sections,
# and checks for refactoring leaks. Reads JSON from stdin. Exit 2 = block (prevent stop).

INPUT=$(cat)

STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

PLAN_FILE=$(find planning/ -name "*.md" -mmin -30 -type f 2>/dev/null | sort -r | head -1)

if [ -z "$PLAN_FILE" ]; then
  echo "No plan file found in planning/ (modified in last 30 minutes). Save your plan before finishing." >&2
  exit 2
fi

# Check required sections
MISSING=""
grep -qiE '^#{1,3}\s*.*feature analysis' "$PLAN_FILE" || MISSING="$MISSING Feature-Analysis"
grep -qiE '^#{1,3}\s*.*test specification|^#{1,3}\s*slice' "$PLAN_FILE" || MISSING="$MISSING Test-Specification/Slices"

if [ -n "$MISSING" ]; then
  echo "Plan file $PLAN_FILE is missing required sections:$MISSING" >&2
  exit 2
fi

# Check for refactoring leak
if grep -qiE 'refactor:|refactoring phase|REFACTOR phase' "$PLAN_FILE"; then
  LEAKS=$(grep -niE 'refactor:|refactoring phase|REFACTOR phase' "$PLAN_FILE" | head -3)
  echo "REFACTORING LEAK in $PLAN_FILE:" >&2
  echo "$LEAKS" >&2
  exit 2
fi

exit 0
