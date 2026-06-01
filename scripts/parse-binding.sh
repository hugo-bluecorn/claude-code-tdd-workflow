#!/bin/bash
# Parses a project's convention binding file into normalized pack tuples.
# Usage: parse-binding.sh <project-dir>
#   Resolves <project-dir>/.claude/tdd-conventions.json and emits one tuple per
#   declared pack, in declared order, to stdout.
#
# Output format: one tuple per line, fields separated by a literal TAB:
#     <source><TAB><version><TAB><dev>
#   field 1: source   -- pack source string (URL or local path)
#   field 2: version  -- the pack's version. For a NEW-schema pack this is the
#                        declared "version" (EMPTY when omitted, e.g. a dev pack).
#                        For a LEGACY entry this is the sentinel literal "legacy",
#                        marking it as version-less.
#   field 3: dev      -- the literal "dev" when the pack declares "dev": true,
#                        otherwise EMPTY (resolver treats "dev" as a local,
#                        no-fetch path).
#
# Schemas accepted:
#   NEW    (§8.6): {"packs":[{"source":..,"version"?:..,"dev"?:true}, ...]}
#   LEGACY        : {"conventions":["<source>", ...]}   (each entry -> version "legacy")
#
# Degrade contract (aligned with hooks/fetch-conventions.sh, which tolerates a
# malformed/missing config and exits 0): a missing binding file, an empty packs
# list, or MALFORMED JSON all yield EMPTY stdout and exit 0. This parser is never
# stricter than its consumer (the Slice 3 resolver) needs -- "no binding = no
# packs" is a normal PRIME-safe state, not an error. A diagnostic MAY go to stderr.
#
# This is a pure data accessor: it never references or requires any role file.

set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: parse-binding.sh <project-dir>" >&2
  exit 1
fi

project_dir="$1"
binding="${project_dir%/}/.claude/tdd-conventions.json"

# Missing binding -> no packs (normal, non-fatal).
if [[ ! -f "$binding" ]]; then
  exit 0
fi

# Malformed JSON -> empty stdout, non-fatal (do not abort a sourcing caller).
if ! jq empty "$binding" >/dev/null 2>&1; then
  echo "parse-binding: failed to parse JSON binding: $binding" >&2
  exit 0
fi

# Emit normalized tuples. The NEW schema is tried first; if it has no packs the
# LEGACY schema is read. Each branch prints <source>\t<version>\t<dev> per entry.
#   - new packs: version defaults to "" when absent; dev -> "dev" when true.
#   - legacy entries: the string IS the source; version is the "legacy" sentinel;
#     dev is always empty.
jq -r '
  if (.packs | type) == "array" and (.packs | length) > 0 then
    .packs[]
    | [ (.source // ""),
        (.version // ""),
        (if .dev == true then "dev" else "" end) ]
    | @tsv
  elif (.conventions | type) == "array" and (.conventions | length) > 0 then
    .conventions[]
    | [ ., "legacy", "" ]
    | @tsv
  else
    empty
  end
' "$binding" 2>/dev/null

exit 0
