#!/bin/bash
# PreToolUse hook: allowlists read-only commands for the tdd-planner agent.
# Reads JSON from stdin. Exit 0 = allow, exit 2 = block.

INPUT=$(cat)
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

# Allowlist of read-only commands
readonly ALLOWED="find grep rg cat head tail wc ls tree file stat du df git flutter dart fvm test command which type pwd echo"

for cmd in $ALLOWED; do
  if [ "$BASE_CMD" = "$cmd" ]; then
    # Check for output redirection to disallowed targets
    if echo "$COMMAND" | grep -q '>'; then
      # Extract the final redirection target (text after last >)
      REDIR_TARGET=$(echo "$COMMAND" | sed 's/.*>//;s/^[[:space:]]*//' | cut -d' ' -f1)
      case "$REDIR_TARGET" in
        /dev/null) ;;
        planning/*) ;;
        ./planning/*) ;;
        *)
          echo "BLOCKED: Output redirection outside planning/ directory." >&2
          exit 2
          ;;
      esac
    fi
    # Check for pipe-to-file via tee or sponge
    if echo "$COMMAND" | grep -qE '\|\s*(tee|sponge)\s'; then
      PIPE_TARGET=$(echo "$COMMAND" | sed -E 's/.*\|\s*(tee|sponge)\s+//' | cut -d' ' -f1)
      case "$PIPE_TARGET" in
        /dev/null) ;;
        planning/*) ;;
        ./planning/*) ;;
        *)
          echo "BLOCKED: Pipe to file outside planning/ directory." >&2
          exit 2
          ;;
      esac
    fi
    exit 0
  fi
done

echo "BLOCKED: '$BASE_CMD' is not in the planner's allowlist." >&2
exit 2
