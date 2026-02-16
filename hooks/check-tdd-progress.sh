#!/bin/bash
# Stop hook: prevents session end while TDD slices remain
# Reads JSON from stdin. Exit 0 = allow stop (or block via JSON decision).

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')

# Prevent infinite loops — if we're already continuing from a stop hook, allow stop
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

PROGRESS_FILE=".tdd-progress.md"

# No progress file means no TDD session — allow stop
if [ ! -f "$PROGRESS_FILE" ]; then
  exit 0
fi

# Count slices that are NOT in a terminal state
# Terminal states: PASS, DONE, COMPLETE, FAIL, SKIP (case-insensitive)
# Non-terminal: anything else (PENDING, IN_PROGRESS, IN PROGRESS, RED, GREEN, etc.)
TOTAL_SLICES=$(grep -ciE '^\s*##\s*(slice|step)\s+[0-9]' "$PROGRESS_FILE" 2>/dev/null || true)
TOTAL_SLICES=${TOTAL_SLICES:-0}
TERMINAL_SLICES=$(grep -ciE 'status:\*{0,2}\s*(pass|done|complete|fail|skip)' "$PROGRESS_FILE" 2>/dev/null || true)
TERMINAL_SLICES=${TERMINAL_SLICES:-0}

if [ "$TOTAL_SLICES" -eq 0 ]; then
  exit 0  # No slices found, allow stop
fi

REMAINING=$((TOTAL_SLICES - TERMINAL_SLICES))

if [ "$REMAINING" -gt 0 ]; then
  jq -n --arg reason "TDD session has $REMAINING of $TOTAL_SLICES slices remaining. Continue implementing." \
    '{"decision": "block", "reason": $reason}'
  exit 0
fi

# All slices in terminal state — allow stop
exit 0
