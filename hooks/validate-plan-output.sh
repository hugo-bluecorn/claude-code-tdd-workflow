#!/bin/bash
# Stop hook for tdd-planner: validates plan file existence, required sections,
# and checks for refactoring leaks. Reads JSON from stdin. Exit 2 = block (prevent stop).

INPUT=$(cat)

STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Layer 1: stop_hook_active — clean up everything and allow stop
if [ "$STOP_ACTIVE" = "true" ]; then
  rm -f .tdd-plan-locked 2>/dev/null
  rm -f .tdd-plan-approval-retries 2>/dev/null
  exit 0
fi

# Layer 2: Approval enforcement gate — lock present means agent never called AskUserQuestion
if [ -f ".tdd-plan-locked" ]; then
  RETRIES=0
  if [ -f ".tdd-plan-approval-retries" ]; then
    RETRIES=$(cat .tdd-plan-approval-retries)
  fi

  if [ "$RETRIES" -ge 2 ]; then
    # Max retries reached — clean up and allow stop to prevent infinite blocking
    rm -f .tdd-plan-locked 2>/dev/null
    rm -f .tdd-plan-approval-retries 2>/dev/null
    echo "WARNING: Max approval retries reached. Cleaning up lock and allowing stop." >&2
    exit 0
  fi

  # Increment retry counter and block
  RETRIES=$((RETRIES + 1))
  echo "$RETRIES" > .tdd-plan-approval-retries
  echo "BLOCKED: You MUST call the AskUserQuestion tool to present the plan for approval. Choose Approve to accept or Discard to abandon. Do NOT output text asking for approval — use the tool." >&2
  exit 2
fi

# Layer 3: No lock — clean up stale retry counter and proceed to normal validation
rm -f .tdd-plan-approval-retries 2>/dev/null

PLAN_FILE=$(find planning/ -name "*.md" -mmin -30 -type f 2>/dev/null | sort -r | head -1)

if [ -z "$PLAN_FILE" ]; then
  # No recent plan file. If .tdd-progress.md also doesn't exist, the user
  # likely discarded the plan or the planner didn't finish. Allow the stop.
  if [ ! -f ".tdd-progress.md" ]; then
    exit 0
  fi
  echo "No plan file found in planning/ (modified in last 30 minutes), but .tdd-progress.md exists. Save the planning archive before finishing." >&2
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
