#!/bin/bash
# SessionStart hook: fetches/refreshes convention repos into local cache.
# Reads .claude/tdd-conventions.json for URLs; clones or pulls as needed.
# NEVER blocks session start — always exits 0.

# Exit gracefully if CLAUDE_PLUGIN_DATA is not set
if [ -z "${CLAUDE_PLUGIN_DATA:-}" ]; then
  exit 0
fi

conventions_dir="${CLAUDE_PLUGIN_DATA}/conventions"
config_file=".claude/tdd-conventions.json"

# Ensure conventions cache directory exists
mkdir -p "$conventions_dir"

# If no config file, just ensure empty cache dir exists and exit
if [ ! -f "$config_file" ]; then
  exit 0
fi

# Parse convention sources from config
sources=$(jq -r '.conventions[]?' "$config_file" 2>/dev/null) || exit 0
[ -n "$sources" ] || exit 0

while IFS= read -r source; do
  [ -n "$source" ] || continue

  # Skip local paths — no fetch needed
  if [[ "$source" != http://* ]] && [[ "$source" != https://* ]]; then
    continue
  fi

  # Extract repo name from URL
  repo_name=$(basename "$source" .git)
  cache_path="${conventions_dir}/${repo_name}"

  if [ -d "$cache_path/.git" ]; then
    # Existing cache: refresh via pull
    if ! git -C "$cache_path" pull --quiet; then
      echo "fetch-conventions: failed to pull $source" >&2
    fi
  else
    # Fresh clone
    if ! git clone --quiet "$source" "$cache_path"; then
      echo "fetch-conventions: failed to clone $source" >&2
    fi
  fi
done <<< "$sources"

exit 0
