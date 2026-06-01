#!/bin/bash
# Data-driven active-pack detection.
#
# Usage: resolve-active-pack.sh <project-dir> <pack-dir>...
#   <project-dir>  the project / working directory to detect from.
#   <pack-dir>...  one or more candidate resolved pack dirs, each containing a
#                  pack.json with detect.markers / detect.extensions.
#
# For each candidate pack, in the order given, this script reads its declared
# detect data (detect.markers and detect.extensions, via scripts/read-pack.sh)
# and scans from <project-dir> UP to repo-root for a match:
#   - a marker matches when a file of that name exists in any dir on the walk;
#   - an extension matches when any file with that suffix exists on the walk.
# A candidate that matches is emitted (its dir, verbatim) to stdout, one per
# line, in candidate order. Detection is purely data-driven: nothing here
# hardcodes a language or marker list -- the candidates' pack.json declarations
# are the sole source of truth (this is the data-driven replacement for the
# hardcoded dirnames in scripts/load-conventions.sh).
#
# Repo-root: the nearest ancestor directory (inclusive of <project-dir>)
# containing a .git entry. If none is found, the filesystem root "/" bounds the
# walk. The walk visits <project-dir> first, then ancestors up to and including
# repo-root.
#
# Degrade contract: a broken candidate (missing or malformed pack.json) is
# skipped -- it never aborts the script and never suppresses a good match from
# another candidate. No matches at all -> empty stdout, exit 0.
#
# This is a pure data accessor: it never references or requires any role file.

set -uo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: resolve-active-pack.sh <project-dir> <pack-dir>..." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
read_pack="${script_dir}/read-pack.sh"

project_dir="$1"
shift

# Build the list of directories to scan: project_dir, then each ancestor up to
# and including the dir that contains .git (repo-root). If no .git is found the
# walk terminates at the filesystem root "/".
build_scan_dirs() {
  local start="$1"
  local dir
  dir="$(cd "$start" 2>/dev/null && pwd)" || return 0
  while true; do
    printf '%s\n' "$dir"
    [[ -e "$dir/.git" ]] && break
    [[ "$dir" == "/" ]] && break
    dir="$(dirname "$dir")"
  done
}

mapfile -t scan_dirs < <(build_scan_dirs "$project_dir")

# Returns 0 if a file named "$1" exists in any scan dir.
marker_present() {
  local marker="$1" dir
  for dir in "${scan_dirs[@]}"; do
    [[ -f "$dir/$marker" ]] && return 0
  done
  return 1
}

# Returns 0 if any file with extension "$1" (e.g. ".dart") exists in any scan
# dir. The .git tree is excluded so VCS internals never trigger a match.
extension_present() {
  local ext="$1" dir
  for dir in "${scan_dirs[@]}"; do
    if find "$dir" -maxdepth 1 -type f -name "*${ext}" -not -path "*/.git/*" \
        2>/dev/null | head -1 | grep -q .; then
      return 0
    fi
  done
  return 1
}

# Returns 0 if any declared marker (newline-list on stdin) matches.
any_marker_matches() {
  local marker
  while IFS= read -r marker; do
    [[ -n "$marker" ]] || continue
    marker_present "$marker" && return 0
  done
  return 1
}

# Returns 0 if any declared extension (newline-list on stdin) matches.
any_extension_matches() {
  local ext
  while IFS= read -r ext; do
    [[ -n "$ext" ]] || continue
    extension_present "$ext" && return 0
  done
  return 1
}

for pack_dir in "$@"; do
  # Read this candidate's declared detect data. A broken pack.json makes
  # read-pack.sh exit non-zero; tolerate it and skip the candidate.
  if ! markers="$(bash "$read_pack" "$pack_dir" detect.markers 2>/dev/null)"; then
    continue
  fi
  if ! extensions="$(bash "$read_pack" "$pack_dir" detect.extensions 2>/dev/null)"; then
    continue
  fi

  if any_marker_matches <<<"$markers" || any_extension_matches <<<"$extensions"; then
    printf '%s\n' "$pack_dir"
  fi
done

exit 0
