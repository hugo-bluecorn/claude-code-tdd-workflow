#!/bin/bash
# bump-version.sh <version> — propagate a version into version-bearing files.
#
# C5 versioning-authority split:
#   • .claude-plugin/plugin.json is bumped as a BUILT-IN (the plugin self-hosts
#     on it), independent of any language pack.
#   • All OTHER version-bearing files + their formats are PACK-DRIVEN, read from
#     the active pack's `versionFiles`: [{ "path", "pattern" }] where pattern is
#     a sed substitution carrying the {version} placeholder. Format knowledge
#     lives in the pack, not here.
#
# Active-pack resolution (C1): $TDD_ACTIVE_PACK (in-session fast-path), else the
# committed binding via resolve-active-pack.sh when present. No pack ⇒ only the
# self-host bump runs (PRIME-safe degrade — the old hardcoded ecosystem matrix
# is gone).
#
# Usage: bump-version.sh <version>   (prints the list of updated files)
set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: bump-version.sh <version>" >&2
  exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
updated=()

# ---- Built-in self-host: the plugin's own manifest ----
if [[ -f ".claude-plugin/plugin.json" ]]; then
  sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" .claude-plugin/plugin.json
  updated+=(".claude-plugin/plugin.json")
fi

# ---- Pack-driven version files (C5) ----
pack="${TDD_ACTIVE_PACK:-}"
if [[ -z "$pack" && -x "$SCRIPT_DIR/resolve-active-pack.sh" ]]; then
  pack="$("$SCRIPT_DIR/resolve-active-pack.sh" 2>/dev/null | head -1)"
fi

if [[ -n "$pack" && -f "$pack/pack.json" ]]; then
  count="$(jq -r '(.versionFiles // []) | length' "$pack/pack.json" 2>/dev/null || echo 0)"
  i=0
  while [[ "$i" -lt "$count" ]]; do
    vpath="$(jq -r ".versionFiles[$i].path // empty" "$pack/pack.json")"
    vpat="$(jq -r ".versionFiles[$i].pattern // empty" "$pack/pack.json")"
    if [[ -n "$vpath" && -n "$vpat" && -f "$vpath" ]]; then
      # pattern is pack-authored; substitute the {version} placeholder.
      sed -i "${vpat//\{version\}/$VERSION}" "$vpath"
      updated+=("$vpath")
    fi
    i=$((i + 1))
  done
fi

if [[ ${#updated[@]} -eq 0 ]]; then
  echo "no version files found — no files updated." >&2
  exit 0
fi

for file in "${updated[@]}"; do
  echo "Updated: $file"
done
