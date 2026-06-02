#!/bin/bash
# Propagates a version string into the version-bearing files of the CURRENT
# directory. Pack-driven: the set of files to rewrite comes from the active
# convention pack's top-level `versionFiles[]` (resolved via active-pack.sh for
# $PWD). `.claude-plugin/plugin.json` is a BUILT-IN self-host that always bumps
# regardless of pack (so this plugin can version itself with no pack bound).
#
# Usage: bump-version.sh <version>          (positional CLI — decision #4)
# Outputs the list of updated files to stdout. Pack-optional: with no pack and
# no built-in target, it prints a "no version files" notice and exits 0 (never
# hard-blocks the caller).
#
# versionFiles encoding (each array element is EITHER):
#   - a BARE PATH STRING — rewritten by a default heuristic keyed by extension:
#       .yaml / .yml  ->  s/^version: .*/version: <V>/
#       .json         ->  s/"version": "[^"]*"/"version": "<V>"/
#       .toml         ->  0,/^version = "[^"]*"/s//version = "<V>"/   (first only)
#   - a {path, pattern} OBJECT — `pattern` is a sed script containing the literal
#     token `{version}`; the token is replaced with <V> and the resulting sed
#     script is run against `path`. Used for irregular files (e.g. CMake
#     `project(... VERSION ...)`).
#
# Resolution uses scripts/active-pack.sh (NOT raw parse-binding tuple parsing).
# This is plumbing only: it never references or requires any role file.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: bump-version.sh <version>" >&2
  exit 1
fi

VERSION="$1"
updated=()

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
active_pack="${script_dir}/active-pack.sh"

# Rewrite a bare-path version file using the extension-keyed default heuristic.
# Unknown extensions are skipped (no rewrite, not an error).
bump_bare_path() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  case "$file" in
    *.yaml | *.yml)
      if [[ "$VERSION" == *+* ]]; then
        # Explicit +build supplied by the caller -> write it verbatim.
        sed -i "s/^version: .*/version: $VERSION/" "$file"
      else
        # Bare semver -> preserve any existing +build in the file (Flutter
        # pubspec). Rewrite only the semver portion; \1 reattaches a trailing
        # +build when present, and is empty when absent.
        sed -i -E "s/^version: [^+[:space:]]*(\+[^[:space:]]*)?/version: $VERSION\1/" "$file"
      fi
      ;;
    *.json)
      sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$file"
      ;;
    *.toml)
      sed -i "0,/^version = \"[^\"]*\"/s//version = \"$VERSION\"/" "$file"
      ;;
    *)
      return 0
      ;;
  esac
  updated+=("$file")
}

# Rewrite an object-form {path, pattern} entry: substitute {version} -> $VERSION
# in the sed script, then run it against the target file.
bump_with_pattern() {
  local file="$1" pattern="$2"
  [[ -f "$file" ]] || return 0
  local script="${pattern//\{version\}/$VERSION}"
  sed -i "$script" "$file"
  updated+=("$file")
}

# Resolve the active pack for $PWD and bump each of its versionFiles entries.
# Pack-optional: no pack -> nothing read here (the built-in self-host still runs).
pack_dir="$(bash "$active_pack" "$PWD" 2>/dev/null | head -n1)"
if [[ -n "$pack_dir" && -f "${pack_dir%/}/pack.json" ]]; then
  manifest="${pack_dir%/}/pack.json"
  # Emit one line per entry. Object form -> "obj\t<path>\t<pattern>"; bare
  # string -> "str\t<path>". A TAB separator keeps paths/patterns intact.
  while IFS=$'\t' read -r kind path pattern; do
    [[ -n "$kind" ]] || continue
    case "$kind" in
      str) bump_bare_path "$path" ;;
      obj) bump_with_pattern "$path" "$pattern" ;;
    esac
  # NOTE: do NOT use @tsv here — it escapes backslashes, which would corrupt a
  # BRE sed `pattern` (e.g. \( \) \1). Join with a literal TAB via string concat
  # so the pattern reaches sed verbatim.
  done < <(jq -r '
    (.versionFiles // [])[]
    | if type == "object"
      then "obj\t" + (.path // "") + "\t" + (.pattern // "")
      else "str\t" + .
      end
  ' "$manifest" 2>/dev/null)
fi

# Built-in self-host: .claude-plugin/plugin.json always bumps (pack-independent),
# unless a pack already listed it (avoid double-processing / duplicate report).
plugin_manifest=".claude-plugin/plugin.json"
if [[ -f "$plugin_manifest" ]]; then
  already=0
  for f in "${updated[@]:-}"; do
    [[ "$f" == "$plugin_manifest" ]] && already=1 && break
  done
  if [[ "$already" -eq 0 ]]; then
    sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$plugin_manifest"
    updated+=("$plugin_manifest")
  fi
fi

# Report results.
if [[ ${#updated[@]} -eq 0 ]]; then
  echo "no version files found — no files updated." >&2
  exit 0
fi

for file in "${updated[@]}"; do
  echo "Updated: $file"
done
