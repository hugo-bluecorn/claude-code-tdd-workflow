#!/bin/bash
# SessionStart hook: fetches/refreshes convention packs into a local cache.
# NEVER blocks session start — always exits 0.
#
# Binding source: <project>/.claude/tdd-conventions.json, parsed via Slice 2's
# scripts/parse-binding.sh into TAB tuples "<source>\t<version>\t<dev>".
#
# Three cases per tuple (mirrors parse-binding's normalization):
#   1. dev marker present ("dev")        -> LOCAL pack, skip fetch entirely.
#   2. version == "legacy"               -> LEGACY behavior (back-compat):
#        fetchable source (http(s)://, file://) -> clone/pull conventions/<repo>
#        bare local path (no scheme)            -> skip (no fetch).
#   3. real version (any other value)    -> VERSIONED resolve:
#        cache key  conventions/<repo>@<version> (version is part of the key, so
#        upgrades never clobber). Scheme-less sources (e.g. github.com/org/pack,
#        per §8.6) are normalized to https://<source>; file:// and https:// clone
#        as-is. Clone the source then check out the tag (git clone --branch). A
#        pinned tag already cached is idempotent (tags are immutable — no pull).
#
# repo_name = basename(source) with a trailing ".git" stripped.
#
# Preserves the legacy guards: CLAUDE_PLUGIN_DATA unset -> exit 0; no config ->
# exit 0; failures log to stderr but never block. This hook does NOT reference,
# check for, or require any role file.

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

# Resolve the parse-binding helper (Slice 2) relative to this hook.
hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parse_binding="${hook_dir}/../scripts/parse-binding.sh"

# True for sources we can hand to `git clone` directly.
is_fetchable_url() {
  local src="$1"
  [[ "$src" == http://* ]] || [[ "$src" == https://* ]] || [[ "$src" == file://* ]]
}

# Derive a clean repo name: basename with trailing ".git" stripped.
repo_name_of() {
  basename "$1" .git
}

# Legacy clone-or-pull into conventions/<repo_name>.
fetch_legacy() {
  local source="$1"
  local repo_name cache_path
  repo_name=$(repo_name_of "$source")
  cache_path="${conventions_dir}/${repo_name}"

  if [ -d "$cache_path/.git" ]; then
    if ! git -C "$cache_path" pull --quiet; then
      echo "fetch-conventions: failed to pull $source" >&2
    fi
  else
    if ! git clone --quiet "$source" "$cache_path"; then
      echo "fetch-conventions: failed to clone $source" >&2
    fi
  fi
}

# Versioned resolve into conventions/<repo_name>@<version>, pinned to the tag.
fetch_versioned() {
  local source="$1" version="$2"
  local clone_url="$source"

  # Normalize a scheme-less source (e.g. github.com/org/pack) to https.
  if ! is_fetchable_url "$source"; then
    clone_url="https://${source}"
  fi

  local repo_name cache_path
  repo_name=$(repo_name_of "$source")
  cache_path="${conventions_dir}/${repo_name}@${version}"

  # Already cached at this immutable tag — nothing to do.
  if [ -d "$cache_path/.git" ]; then
    return 0
  fi

  if ! git clone --quiet --branch "$version" "$clone_url" "$cache_path"; then
    echo "fetch-conventions: failed to clone $source at version $version" >&2
    # Leave no partial cache dir behind.
    rm -rf "$cache_path"
  fi
}

# Stream normalized tuples from parse-binding and resolve each.
while IFS=$'\t' read -r source version dev; do
  [ -n "$source" ] || continue

  # Case 1: dev pack -> local, never fetched.
  if [ "$dev" = "dev" ]; then
    continue
  fi

  if [ "$version" = "legacy" ]; then
    # Case 2: legacy. Fetch only real URLs; skip bare local paths.
    if is_fetchable_url "$source"; then
      fetch_legacy "$source"
    fi
    continue
  fi

  # Case 3: real version -> versioned resolve.
  if [ -n "$version" ]; then
    fetch_versioned "$source" "$version"
  fi
done < <(bash "$parse_binding" "." 2>/dev/null)

exit 0
