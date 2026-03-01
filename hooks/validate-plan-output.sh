#!/bin/bash
# Standalone plan structure validator.
# Validates required sections and checks for refactoring leaks.
# Usage: validate-plan-output.sh [plan-file-path]

PLAN_FILE="${1:-}"

if [ -z "$PLAN_FILE" ]; then
  PLAN_FILE=$(find planning/ -name "*.md" -mmin -30 -type f 2>/dev/null | sort -r | head -1)
fi

if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "No plan file found. Provide a file path or ensure a recent file exists in planning/." >&2
  exit 2
fi

# Check required sections — accept both tdd-task-template headings (Feature Analysis)
# and feature-notes-template headings (Overview, Requirements Analysis)
MISSING=""
grep -qiE '^#{1,3}\s*.*(feature analysis|overview|requirements analysis)' "$PLAN_FILE" || MISSING="$MISSING Feature-Analysis/Overview"
grep -qiE '^#{1,3}\s*.*test specification|^#{1,3}\s*slice' "$PLAN_FILE" || MISSING="$MISSING Test-Specification/Slices"

if [ -n "$MISSING" ]; then
  echo "Plan file $PLAN_FILE is missing required sections:$MISSING" >&2
  exit 2
fi

# Check for refactoring leak — exclude markdown headers and phase tracking boilerplate
# (e.g., "### Iteration 3 (REFACTOR Phase)" and "- **REFACTOR:** pending" are template content)
LEAK_LINES=$(grep -niE 'refactor:|refactoring phase|REFACTOR phase' "$PLAN_FILE" \
  | grep -vE '^[0-9]+:\s*#' \
  | grep -vE '^[0-9]+:\s*-\s*\*\*REFACTOR' \
  | head -3)
if [ -n "$LEAK_LINES" ]; then
  echo "REFACTORING LEAK in $PLAN_FILE:" >&2
  echo "$LEAK_LINES" >&2
  exit 2
fi

exit 0
