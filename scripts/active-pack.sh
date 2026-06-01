#!/bin/bash
# Shared active-pack resolve-chain helper.
# Usage: active-pack.sh <project-dir>
#   Echoes the ACTIVE pack dir(s) for <project-dir> -- each a directory
#   containing a pack.json -- or nothing. One match per line.
#
# Resolution order:
#   1. Fast-path: if $TDD_ACTIVE_PACK is set and non-empty, echo it verbatim and
#      exit 0. This is the in-session hook fast-path; the resolve chain is NOT
#      invoked. (No consumer depends on env->subagent propagation, so the chain
#      below must also work with this env var UNSET.)
#   2. Committed-binding path (works with $TDD_ACTIVE_PACK UNSET): parse
#      <project-dir>/.claude/tdd-conventions.json via scripts/parse-binding.sh
#      into TAB tuples "<source>\t<version>\t<dev>". For each tuple, locate its
#      local pack dir:
#        - dev source (3rd field == "dev") -> LOCAL path, used directly (a
#          leading ~ is expanded).
#        - non-dev source -> resolved cache dir under
#          $CLAUDE_PLUGIN_DATA/conventions: versioned "<repo>@<version>" per the
#          foundation resolver, falling back to "<repo>" for legacy/unversioned.
#          If CLAUDE_PLUGIN_DATA is unset or the cache dir is absent, the
#          candidate is skipped (no fetch here -- resolution only).
#      The collected candidate dirs are handed to scripts/resolve-active-pack.sh,
#      which echoes the detect-matching one(s).
#   3. Degrade: no binding / no candidates / malformed binding / no match -> echo
#      nothing, exit 0. PRIME-safe: never abort the caller.
#
# This is a pure data accessor: it never references or requires any role file.

set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: active-pack.sh <project-dir>" >&2
  exit 1
fi

# --- 1. Fast-path: in-session env override wins, chain not invoked. -----------
if [[ -n "${TDD_ACTIVE_PACK:-}" ]]; then
  printf '%s\n' "$TDD_ACTIVE_PACK"
  exit 0
fi

project_dir="$1"

# Sibling scripts live beside this one (same idiom as hooks/fetch-conventions.sh).
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
resolve_active="${script_dir}/resolve-active-pack.sh"

# Shared binding-iteration helper. SOURCE it so the tuple split (which must
# preserve a dev pack's EMPTY version field) lives in ONE place, shared with
# hooks/fetch-conventions.sh -- no more divergent hand-rolled split here.
# shellcheck source=./iterate-binding.sh
. "${script_dir}/iterate-binding.sh"

# Derive a clean repo name: basename with a trailing ".git" stripped.
repo_name_of() {
  basename "$1" .git
}

# Map one binding tuple to its local pack dir, or nothing if it cannot be
# located (no fetch here). Echoes a dir on success; echoes nothing otherwise.
candidate_dir_for() {
  local source="$1" version="$2" dev="$3"

  # dev pack -> local path, used directly. Expand a leading ~.
  if [[ "$dev" == "dev" ]]; then
    printf '%s\n' "${source/#\~/$HOME}"
    return 0
  fi

  # Non-dev -> resolved cache dir under $CLAUDE_PLUGIN_DATA/conventions.
  [[ -n "${CLAUDE_PLUGIN_DATA:-}" ]] || return 0
  local conventions_dir="${CLAUDE_PLUGIN_DATA}/conventions"
  local repo_name versioned legacy
  repo_name="$(repo_name_of "$source")"
  versioned="${conventions_dir}/${repo_name}@${version}"
  legacy="${conventions_dir}/${repo_name}"

  # Prefer the versioned cache key; fall back to the unversioned dir.
  if [[ -n "$version" && "$version" != "legacy" && -d "$versioned" ]]; then
    printf '%s\n' "$versioned"
  elif [[ -d "$legacy" ]]; then
    printf '%s\n' "$legacy"
  fi
}

# --- 2. Committed-binding path. Collect candidate dirs from the binding. ------
# iterate_binding streams the binding's tuples with the fields split correctly
# (preserving a dev pack's EMPTY version), invoking the callback per tuple.
candidates=()
collect_candidate() {
  local cand
  cand="$(candidate_dir_for "$1" "$2" "$3")"
  [[ -n "$cand" ]] && candidates+=("$cand")
}
iterate_binding "$project_dir" collect_candidate

# --- 3. No candidates -> degrade to empty (PRIME-safe). -----------------------
[[ "${#candidates[@]}" -gt 0 ]] || exit 0

# Hand candidates to the data-driven resolver; it echoes the detect match(es).
bash "$resolve_active" "$project_dir" "${candidates[@]}" 2>/dev/null

exit 0
