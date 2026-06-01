#!/bin/bash
# PostToolUse hook: auto-runs tests after file changes
# Returns test output as systemMessage for immediate feedback

INPUT=$(cat)

# agent_type guard: when invoked from hooks.json (session-level), agent_type
# identifies the calling agent. Pass through silently for non-implementer agents.
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -z "$AGENT_TYPE" ] \
  || { [ "$AGENT_TYPE" != "tdd-implementer" ] \
    && [ "$AGENT_TYPE" != "tdd-workflow:tdd-implementer" ]; }; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# Resolve sibling scripts relative to this hook (same idiom as fetch-conventions.sh).
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVE_PACK_SH="${HOOK_DIR}/../scripts/active-pack.sh"
READ_PACK_SH="${HOOK_DIR}/../scripts/read-pack.sh"

# Derive the test file for a file-granularity command: a *_test.<ext> path is
# used as-is; otherwise map lib/ -> test/ and insert _test before the suffix.
derive_test_file() {
  local file="$1" ext="$2"
  if [[ "$file" == *_test"$ext" ]]; then
    printf '%s\n' "$file"
  else
    printf '%s\n' "$(echo "$file" | sed "s|lib/|test/|;s|${ext//./\\.}\$|_test${ext}|")"
  fi
}

# Only run for source/test files
if ! echo "$FILE_PATH" | grep -qE '\.(dart|cpp|cc|h|hpp|sh)$'; then
  exit 0
fi

# --- Pack-driven, file-granularity path (data-driven, pack-optional). ---------
# Resolve the active pack for this project. If one resolves, the edited file's
# extension is among its detect.extensions, and its test granularity is "file",
# run the pack's commands.test.run with {file} substituted to the derived test
# file. No pack / no match -> fall through to the built-in branches below; a
# pack EXTENSION with no active pack degrades silently (no fabricated command).
PACK_DIR=""
if [ -f "$ACTIVE_PACK_SH" ]; then
  PACK_DIR=$(bash "$ACTIVE_PACK_SH" "$(pwd)" 2>/dev/null | head -1)
fi

if [ -n "$PACK_DIR" ] && [ -f "$READ_PACK_SH" ]; then
  FILE_EXT=".${FILE_PATH##*.}"
  PACK_EXTS=$(bash "$READ_PACK_SH" "$PACK_DIR" detect.extensions 2>/dev/null)
  if echo "$PACK_EXTS" | grep -qxF "$FILE_EXT"; then
    GRANULARITY=$(bash "$READ_PACK_SH" "$PACK_DIR" commands.test.granularity 2>/dev/null)
    if [ "$GRANULARITY" = "file" ]; then
      RUN_TMPL=$(bash "$READ_PACK_SH" "$PACK_DIR" commands.test.run 2>/dev/null)
      TEST_FILE=$(derive_test_file "$FILE_PATH" "$FILE_EXT")
      if [ -n "$RUN_TMPL" ]; then
        TEST_CMD="${RUN_TMPL//\{file\}/$TEST_FILE}"
        if [ -f "$TEST_FILE" ]; then
          RESULT=$(eval "$TEST_CMD" 2>&1 | tail -10)
        else
          RESULT="No matching test file found for $FILE_PATH"
        fi
        # Emit informational systemMessage and stop (never blocks).
        jq -n --arg msg "Auto-test: $RESULT" '{"systemMessage": $msg}'
        exit 0
      fi
    fi
  fi
  # Pack resolved but this file is a non-pack extension -> fall through to the
  # built-in branches (e.g. .sh) below.
fi

# A pack EXTENSION with no resolved pack degrades silently (no built-in dart
# command, no fabricated command). bashunit (.sh) keeps its built-in default.
if echo "$FILE_PATH" | grep -qE '\.dart$'; then
  exit 0
fi

# Detect and run appropriate test command (built-in C++/suite + bash defaults).
if echo "$FILE_PATH" | grep -qE '\.(cpp|cc|h|hpp)$'; then
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
