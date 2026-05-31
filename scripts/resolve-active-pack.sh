#!/bin/bash
# resolve-active-pack.sh — emit the directory of each language pack ACTIVE for
# the current project, one per line.
#
# The data-driven detection engine (R1 F4). For every pack bound in
# .claude/tdd-conventions.json it resolves the pack to a local dir and matches
# the current directory against that pack's pack.json detect.markers (any
# marker file present) / detect.extensions (any file with the extension).
# Replaces the four hardcoded dirnames in load-conventions.sh.
#
# No binding, no resolvable pack, or no match → no output, exit 0 (PRIME-safe:
# an unconfigured project simply has no active pack). Callers wanting the
# in-session fast-path may `export TDD_ACTIVE_PACK="$(resolve-active-pack.sh | head -1)"`.
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parse_binding="${script_dir}/parse-binding.sh"
read_pack="${script_dir}/read-pack.sh"
binding=".claude/tdd-conventions.json"

[ -f "$binding" ] || exit 0
conventions_dir="${CLAUDE_PLUGIN_DATA:-}/conventions"

# source + version → the pack's local directory (cache for URLs, in place for
# local paths). Echoes empty when a URL pack can't be located (no cache root).
resolve_dir() {
  local source="$1" version="$2" repo
  case "$source" in
    /*|./*|../*) echo "$source" ;;
    "~"/*)       echo "${HOME}/${source#"~"/}" ;;
    *)
      [ -n "${CLAUDE_PLUGIN_DATA:-}" ] || { echo ""; return; }
      repo="$(basename "$source" .git)"
      if [ -n "$version" ]; then
        echo "${conventions_dir}/${repo}@${version}"
      else
        echo "${conventions_dir}/${repo}"
      fi
      ;;
  esac
}

# Returns 0 if the pack at $1 matches the current directory (marker or extension).
pack_matches_cwd() {
  local dir="$1" i m ext n
  n="$(jq -r '(.detect.markers // []) | length' "$dir/pack.json" 2>/dev/null || echo 0)"
  i=0
  while [ "$i" -lt "$n" ]; do
    m="$("$read_pack" "$dir" "detect.markers[$i]")"
    [ -n "$m" ] && [ -e "$m" ] && return 0
    i=$((i + 1))
  done
  n="$(jq -r '(.detect.extensions // []) | length' "$dir/pack.json" 2>/dev/null || echo 0)"
  i=0
  while [ "$i" -lt "$n" ]; do
    ext="$("$read_pack" "$dir" "detect.extensions[$i]")"
    if [ -n "$ext" ] && [ -n "$(find . -name "*${ext}" -not -path './.git/*' 2>/dev/null | head -1)" ]; then
      return 0
    fi
    i=$((i + 1))
  done
  return 1
}

while IFS=$'\t' read -r source version; do
  [ -n "$source" ] || continue
  dir="$(resolve_dir "$source" "$version")"
  [ -n "$dir" ] && [ -f "$dir/pack.json" ] || continue
  if pack_matches_cwd "$dir"; then
    echo "$dir"
  fi
done < <("$parse_binding" "$binding" 2>/dev/null)

exit 0
