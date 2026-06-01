#!/bin/bash
# PreToolUse hook: blocks implementation writes before a failing test exists.
# Reads JSON from stdin. Exit 0 = allow, exit 2 = block.
#
# Test-file recognition and source-language recognition are DATA-DRIVEN from the
# active convention pack (resolved via scripts/active-pack.sh -> the pack's
# testFilePattern + detect.extensions). The pack is OPTIONAL:
#   - bashunit (.sh) is the built-in default: *_test.sh / test_*.sh / anything
#     under a test/ directory is recognized as a test, and a .sh source is a
#     known-language source, with NO pack required.
#   - an UNKNOWN extension with no pack bound -> PASS-THROUGH (exit 0); the hook
#     degrades and never blocks a language it has no pack/built-in for.
# This hook never references or requires any role file.

INPUT=$(cat)

# agent_type guard: when invoked from hooks.json (session-level), agent_type
# identifies the calling agent. Pass through for non-implementer agents.
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -z "$AGENT_TYPE" ] \
  || { [ "$AGENT_TYPE" != "tdd-implementer" ] \
    && [ "$AGENT_TYPE" != "tdd-workflow:tdd-implementer" ]; }; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# Empty path -> nothing to enforce.
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Resolve sibling scripts relative to this hook (same idiom as auto-run-tests.sh).
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVE_PACK_SH="${HOOK_DIR}/../scripts/active-pack.sh"
READ_PACK_SH="${HOOK_DIR}/../scripts/read-pack.sh"

# Resolve the active pack for this project (pack-optional). Empty when no pack.
PACK_DIR=""
if [ -f "$ACTIVE_PACK_SH" ]; then
  PACK_DIR=$(bash "$ACTIVE_PACK_SH" "$(pwd)" 2>/dev/null | head -1)
fi

# --- Test-file recognition (allow) -------------------------------------------
# Built-in bashunit default (no pack needed): *_test.sh / test_*.sh basenames,
# or any path under a test/ directory.
BASENAME="${FILE_PATH##*/}"
if [[ "$BASENAME" == *_test.sh ]] \
  || [[ "$BASENAME" == test_*.sh ]] \
  || echo "$FILE_PATH" | grep -qE '(^|/)test/'; then
  exit 0
fi

# Pack-driven recognition: a path whose basename matches the active pack's
# testFilePattern (e.g. *_test.dart) is a test -> allow.
if [ -n "$PACK_DIR" ] && [ -f "$READ_PACK_SH" ]; then
  TEST_PATTERN=$(bash "$READ_PACK_SH" "$PACK_DIR" testFilePattern 2>/dev/null)
  if [ -n "$TEST_PATTERN" ]; then
    # shellcheck disable=SC2053  # intentional glob match of basename vs pattern
    if [[ "$BASENAME" == $TEST_PATTERN ]]; then
      exit 0
    fi
  fi
fi

# --- Source-language recognition ---------------------------------------------
# The file is a KNOWN-LANGUAGE source if its extension is the .sh built-in or is
# among the active pack's detect.extensions. An unknown extension with no pack
# bound is NOT known -> pass through (degrade, never block).
FILE_EXT=".${FILE_PATH##*.}"
KNOWN_SOURCE=0
if [ "$FILE_EXT" = ".sh" ]; then
  KNOWN_SOURCE=1
elif [ -n "$PACK_DIR" ] && [ -f "$READ_PACK_SH" ]; then
  PACK_EXTS=$(bash "$READ_PACK_SH" "$PACK_DIR" detect.extensions 2>/dev/null)
  if echo "$PACK_EXTS" | grep -qxF "$FILE_EXT"; then
    KNOWN_SOURCE=1
  fi
fi

# Unknown language (no pack / not a pack extension and not .sh) -> pass through.
if [ "$KNOWN_SOURCE" -eq 0 ]; then
  exit 0
fi

# --- RED-first enforcement for a known-language source -----------------------
# Allow the write only if test files have been staged/changed in this slice.
RECENT_TEST_FILES=$(git diff --name-only HEAD 2>/dev/null \
  | grep -c -E '_test\.[A-Za-z0-9]+$|(^|/)test_|(^|/)test/')

if [ "$RECENT_TEST_FILES" -eq 0 ]; then
  echo "BLOCKED: No test files have been written yet in this slice. Write a failing test first (RED phase)." >&2
  exit 2
fi

exit 0
