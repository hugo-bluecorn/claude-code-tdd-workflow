#!/bin/bash
# Stop hook: prevents tdd-releaser from stopping before branch is pushed to remote.
# Reads JSON from stdin. Exit 0 = allow stop, Exit 2 = block stop.

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')

# Prevent infinite loops — if we're already continuing from a stop hook, allow stop
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Not inside a git repository — allow stop gracefully
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# Check if branch has an upstream tracking branch
if ! git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
  echo "Branch has no upstream tracking branch. Push your branch before stopping." >&2
  exit 2
fi

# Compare HEAD with upstream
LOCAL_HEAD=$(git rev-parse HEAD)
UPSTREAM_HEAD=$(git rev-parse '@{upstream}')

if [ "$LOCAL_HEAD" = "$UPSTREAM_HEAD" ]; then
  exit 0
fi

echo "Branch has unpushed commits. Push your branch before stopping." >&2
exit 2
