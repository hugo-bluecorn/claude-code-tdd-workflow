#!/bin/bash
# PreToolUse hook: allowlists read-only commands for the tdd-planner agent.
# Reads JSON from stdin. Exit 0 = allow, exit 2 = block.

INPUT=$(cat)

# agent_type guard: when invoked from hooks.json (session-level), agent_type
# identifies the calling agent. Pass through for non-planner agents.
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -z "$AGENT_TYPE" ] \
  || { [ "$AGENT_TYPE" != "tdd-planner" ] \
    && [ "$AGENT_TYPE" != "tdd-workflow:tdd-planner" ]; }; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Block empty commands
if [ -z "$COMMAND" ]; then
  echo "BLOCKED: Empty command is not in the planner's allowlist." >&2
  exit 2
fi

# Strip leading env var assignments (e.g., FOO=bar BAZ=qux cmd ...)
# Pattern: words matching VAR=VALUE at the start
STRIPPED="$COMMAND"
while [[ "$STRIPPED" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*) ]]; do
  STRIPPED="${BASH_REMATCH[1]}"
done

# Extract the base command (first word)
BASE_CMD="${STRIPPED%% *}"

# Check whether a write target path is in the allowed set.
# Returns 0 if allowed, 1 if blocked.
is_allowed_target() {
  case "$1" in
    /dev/null) return 0 ;;
    *)         return 1 ;;
  esac
}

# Built-in safe floor: an advisory allowlist of read-only / git / language
# tooling. This floor is PRIME-safe and ALWAYS holds, even with no pack bound.
readonly ALLOWED="find grep rg cat head tail wc ls tree file stat du df git flutter dart fvm test command which type pwd echo"

# UNION the floor with the leading binary of each command declared by the
# resolved active pack (commands.test.run, each commands.test.setup[] step,
# commands.lint, commands.format, commands.coverage). The pack only ADDS
# binaries; it never removes a floor entry. With no pack bound this collects
# nothing and the floor stands alone (never opens up to arbitrary binaries).
#
# Sibling scripts live beside this hook (same idiom as fetch-conventions.sh).
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVE_PACK_SH="${HOOK_DIR}/../scripts/active-pack.sh"
READ_PACK_SH="${HOOK_DIR}/../scripts/read-pack.sh"

# Echo the leading binary token of a command template, with any leading
# env-var assignments stripped. {placeholders} after the binary are irrelevant
# since only the first token is taken.
leading_binary() {
  local tmpl="$1"
  while [[ "$tmpl" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*) ]]; do
    tmpl="${BASH_REMATCH[1]}"
  done
  printf '%s\n' "${tmpl%% *}"
}

PACK_ALLOWED=""
if [ -f "$ACTIVE_PACK_SH" ] && [ -f "$READ_PACK_SH" ]; then
  PACK_DIR=$(bash "$ACTIVE_PACK_SH" "$(pwd)" 2>/dev/null | head -1)
  if [ -n "$PACK_DIR" ]; then
    for field in commands.test.run commands.test.setup commands.lint \
                 commands.format commands.coverage; do
      while IFS= read -r tmpl; do
        [ -n "$tmpl" ] || continue
        bin="$(leading_binary "$tmpl")"
        [ -n "$bin" ] && PACK_ALLOWED="$PACK_ALLOWED $bin"
      done < <(bash "$READ_PACK_SH" "$PACK_DIR" "$field" 2>/dev/null)
    done
  fi
fi

for cmd in $ALLOWED $PACK_ALLOWED; do
  if [ "$BASE_CMD" = "$cmd" ]; then
    # Check for output redirection to disallowed targets
    if echo "$COMMAND" | grep -q '>'; then
      REDIR_TARGET=$(echo "$COMMAND" | sed 's/.*>//;s/^[[:space:]]*//' | cut -d' ' -f1)
      if ! is_allowed_target "$REDIR_TARGET"; then
        echo "BLOCKED: Output redirection to disallowed target." >&2
        exit 2
      fi
    fi
    # Check for pipe-to-file via tee or sponge
    if echo "$COMMAND" | grep -qE '\|\s*(tee|sponge)\s'; then
      PIPE_TARGET=$(echo "$COMMAND" | sed -E 's/.*\|\s*(tee|sponge)\s+//' | cut -d' ' -f1)
      if ! is_allowed_target "$PIPE_TARGET"; then
        echo "BLOCKED: Pipe to file outside allowed targets." >&2
        exit 2
      fi
    fi
    exit 0
  fi
done

echo "BLOCKED: '$BASE_CMD' is not in the planner's allowlist." >&2
exit 2
