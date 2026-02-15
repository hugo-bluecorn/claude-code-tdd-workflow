#!/bin/bash
# PreToolUse hook: blocks implementation writes before failing test exists
# Reads JSON from stdin. Exit 0 = allow, exit 2 = block.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# Allow test files always
if echo "$FILE_PATH" | grep -qE '_test\.(dart|cpp|cc|h|sh)$|test_.*\.(dart|cpp|cc|h|sh)$|(^|/)test/'; then
  exit 0
fi

# Allow non-source files (configs, pubspec, cmake, etc.)
if ! echo "$FILE_PATH" | grep -qE '\.(dart|cpp|cc|h|hpp|sh)$'; then
  exit 0
fi

# Check if test files have been modified in this session
RECENT_TEST_FILES=$(git diff --name-only HEAD 2>/dev/null | grep -c -E '_test\.(dart|cpp|cc|h|sh)$|test_')

if [ "$RECENT_TEST_FILES" -eq 0 ]; then
  echo "BLOCKED: No test files have been written yet in this slice. Write a failing test first (RED phase)." >&2
  exit 2
fi

exit 0
