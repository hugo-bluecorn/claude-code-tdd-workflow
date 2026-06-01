#!/bin/bash
# Shared binding-iteration helper. SOURCE this file; it defines one function:
#
#   iterate_binding <project-dir> <callback>
#     Streams scripts/parse-binding.sh's TAB tuples "<source>\t<version>\t<dev>"
#     for <project-dir> and invokes <callback> ONCE per non-empty tuple with the
#     three fields split CORRECTLY as positional args:  callback "$source"
#     "$version" "$dev".
#
# Why this exists (the tab-collapse trap):
#   parse-binding emits "<source>\t<version>\t<dev>" via jq @tsv. For a DEV pack
#   the version field is EMPTY, so the line is "<source>\t\tdev" -- two adjacent
#   tabs. A naive `while IFS=$'\t' read -r source version dev` COLLAPSES those
#   adjacent tabs (TAB is IFS-whitespace), mis-reading version="dev"/dev="" and
#   silently dropping the dev-skip. Splitting by hand with parameter expansion
#   preserves the empty field. Both fetch-conventions.sh and active-pack.sh
#   route through this ONE implementation so the split can never diverge again.
#
# This is a pure data accessor: it never references or requires any role file.

# Resolve the sibling parse-binding.sh relative to THIS file (works regardless
# of the sourcing caller's location -- same ${BASH_SOURCE[0]} idiom the
# consumers use to find their siblings).
__iterate_binding_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__iterate_binding_parser="${__iterate_binding_dir}/parse-binding.sh"

iterate_binding() {
  local project_dir="$1" callback="$2"
  local tab=$'\t'
  local line source rest version dev

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    # Split on the FIRST two tabs by hand. `read`/array splitting with
    # IFS=$'\t' collapses adjacent tabs (TAB is IFS-whitespace), which would
    # misalign a dev pack's EMPTY version field. Parameter expansion preserves
    # empty fields.
    source="${line%%"$tab"*}"
    rest="${line#*"$tab"}"
    version="${rest%%"$tab"*}"
    dev="${rest#*"$tab"}"
    [ -n "$source" ] || continue
    "$callback" "$source" "$version" "$dev"
  done < <(bash "$__iterate_binding_parser" "$project_dir" 2>/dev/null)
}
