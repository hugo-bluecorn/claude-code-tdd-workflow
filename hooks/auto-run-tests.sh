#!/bin/bash
# PostToolUse hook: auto-runs tests after file changes
# Returns test output as systemMessage for immediate feedback

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# Only run for source/test files
if ! echo "$FILE_PATH" | grep -qE '\.(dart|cpp|cc|h|hpp|sh)$'; then
  exit 0
fi

# Detect and run appropriate test command
if echo "$FILE_PATH" | grep -qE '\.dart$'; then
  # Find matching test file
  if echo "$FILE_PATH" | grep -qE '_test\.dart$'; then
    TEST_FILE="$FILE_PATH"
  else
    TEST_FILE=$(echo "$FILE_PATH" | sed 's|lib/|test/|;s|\.dart$|_test.dart|')
  fi
  if [ -f "$TEST_FILE" ]; then
    # Use fvm if available (check for .fvmrc in project root)
    if [ -f ".fvmrc" ] && command -v fvm &>/dev/null; then
      FLUTTER_CMD="fvm flutter"
    else
      FLUTTER_CMD="flutter"
    fi
    RESULT=$($FLUTTER_CMD test "$TEST_FILE" 2>&1 | tail -10)
  else
    RESULT="No matching test file found for $FILE_PATH"
  fi
elif echo "$FILE_PATH" | grep -qE '\.(cpp|cc|h|hpp)$'; then
  if [ -d "build" ]; then
    RESULT=$(cmake --build build/ 2>&1 | tail -10)
  else
    RESULT="No build directory found. Run cmake first."
  fi
elif echo "$FILE_PATH" | grep -qE '\.sh$'; then
  # Find matching test file
  if echo "$FILE_PATH" | grep -qE '_test\.sh$'; then
    TEST_FILE="$FILE_PATH"
  else
    # Map source to test: prepend test/, insert _test before .sh
    TEST_FILE=$(echo "$FILE_PATH" | sed 's|^|test/|;s|\.sh$|_test.sh|')
  fi
  # Check for bashunit availability
  if [ -x "./lib/bashunit" ]; then
    BASHUNIT_CMD="./lib/bashunit"
  elif command -v bashunit &>/dev/null; then
    BASHUNIT_CMD="bashunit"
  else
    BASHUNIT_CMD=""
  fi
  if [ -z "$BASHUNIT_CMD" ]; then
    RESULT="bashunit is not installed. Install it to run shell tests."
  elif [ -f "$TEST_FILE" ]; then
    RESULT=$($BASHUNIT_CMD "$TEST_FILE" 2>&1 | tail -10)
  else
    RESULT="No matching test file found for $FILE_PATH"
  fi
fi

# Return as system message (informational, doesn't block)
jq -n --arg msg "Auto-test: $RESULT" '{"systemMessage": $msg}'
