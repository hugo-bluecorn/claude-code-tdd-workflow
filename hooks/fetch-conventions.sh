#!/bin/bash
# SessionStart hook: resolves the project binding into the per-machine cache.
#
# Evolved (R1 F3) into the resolver. Reads the binding via parse-binding.sh,
# which normalizes BOTH the new {packs:[{source,version}]} form and the legacy
# {conventions:[url|abspath]} form into "<source>\t<version>" lines:
#   • versioned source  → cache at <repo>@<version>, checked out to the tag
#   • unversioned source (legacy) → cache at <repo>, clone/pull HEAD
#   • local path        → used in place, never fetched
#
# NEVER blocks session start — always exits 0.

# Exit gracefully if CLAUDE_PLUGIN_DATA is not set
if [ -z "${CLAUDE_PLUGIN_DATA:-}" ]; then
  exit 0
fi

conventions_dir="${CLAUDE_PLUGIN_DATA}/conventions"
config_file=".claude/tdd-conventions.json"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parse_binding="${script_dir}/../scripts/parse-binding.sh"
resolve_active="${script_dir}/../scripts/resolve-active-pack.sh"

# Ensure conventions cache directory exists
mkdir -p "$conventions_dir"

# Resolve bound packs into the cache (only when a binding exists). The
# warn-and-proceed check below runs regardless, so an unconfigured project
# still gets advised.
if [ -f "$config_file" ]; then
while IFS=$'\t' read -r source version; do
  [ -n "$source" ] || continue

  # Classify the source: local paths are used in place (never fetched).
  case "$source" in
    /*|~/*|./*|../*) continue ;;          # local path
    *://*)           url="$source" ;;     # explicit scheme (http/https/file/ssh/git)
    *.*/*)           url="https://$source" ;;  # schemeless git URL (host.tld/path)
    *)               continue ;;          # bare token → treat as local/in place
  esac

  repo_name="$(basename "$source" .git)"
  if [ -n "$version" ]; then
    cache_path="${conventions_dir}/${repo_name}@${version}"
  else
    cache_path="${conventions_dir}/${repo_name}"
  fi

  if [ -d "$cache_path/.git" ]; then
    # A pinned tag is immutable — leave it. Unversioned (legacy) caches refresh.
    if [ -z "$version" ]; then
      if ! git -C "$cache_path" pull --quiet; then
        echo "fetch-conventions: failed to pull $source" >&2
      fi
    fi
  else
    if git clone --quiet "$url" "$cache_path"; then
      if [ -n "$version" ]; then
        if ! git -C "$cache_path" checkout --quiet "$version" 2>/dev/null; then
          echo "fetch-conventions: failed to checkout $version of $source" >&2
        fi
      fi
    else
      echo "fetch-conventions: failed to clone $source" >&2
    fi
  fi
done < <("$parse_binding" "$config_file" 2>/dev/null)
fi

# Warn-and-proceed (C3): a known-ecosystem marker is present but no pack
# resolves for the project. Advisory only — never blocks. bashunit is the
# built-in default and is intentionally absent from this list.
active_dirs=""
[ -x "$resolve_active" ] && active_dirs="$("$resolve_active" 2>/dev/null)"
if [ -z "$active_dirs" ]; then
  while read -r marker label; do
    [ -e "$marker" ] || continue
    echo "tdd-workflow: no convention pack for $label ($marker present); TDD will proceed on training data + session context only." >&2
  done <<'MARKERS'
pubspec.yaml Dart/Flutter
CMakeLists.txt C/C++
Cargo.toml Rust
package.json Node.js
pyproject.toml Python
MARKERS
fi

exit 0
