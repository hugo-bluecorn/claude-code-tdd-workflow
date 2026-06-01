#!/bin/bash
# Reads a single field from a language convention pack manifest (pack.json).
# Usage: read-pack.sh <pack-dir> <field-path>
#   <field-path> is a dotted key into pack.json, e.g.:
#     name, version, language, schemaVersion
#     detect.extensions, detect.markers          (arrays -> one element per line)
#     commands.test.granularity, commands.test.setup, commands.test.run
#     commands.test.passOn, commands.test.variants
#     commands.lint, commands.format, commands.coverage
#     testFilePattern, implToTestMap, versionFiles, projectFiles
#     standards.index, standards.dir
#
# Output: the requested field's value to stdout.
#   - scalars print verbatim (placeholders like {variant}/{file} preserved literally)
#   - arrays print one element per line in declared order
#   - an absent OPTIONAL field prints nothing and exits 0 (absent is not an error)
#
# Accessor shape for variant objects:
#   commands.test.variants is an array of objects; this reader projects it to the
#   variant NAMES, one per line, in declared order (i.e. .commands.test.variants[].name).
#
# Errors (hard failures — this reader does NOT degrade silently):
#   missing pack.json   -> exit 1, stderr names the missing manifest
#   malformed pack.json -> exit 1, stderr indicates a parse/read failure
#
# This is a pure data accessor: it never references or requires any role file.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: read-pack.sh <pack-dir> <field-path>" >&2
  exit 1
fi

pack_dir="$1"
field_path="$2"
manifest="${pack_dir%/}/pack.json"

if [[ ! -f "$manifest" ]]; then
  echo "read-pack: manifest not found: $manifest" >&2
  exit 1
fi

# Validate the JSON up front so a malformed manifest yields a clear diagnostic
# rather than a bare jq stack trace.
if ! jq empty "$manifest" >/dev/null 2>&1; then
  echo "read-pack: failed to parse JSON manifest: $manifest" >&2
  exit 1
fi

# Build the jq filter. The variants path is projected down to names; every other
# path is read directly. Arrays are emitted one element per line via jq's
# default array iteration; scalars print as-is. `// empty` makes an absent
# optional field yield no output (and exit 0).
case "$field_path" in
  commands.test.variants)
    filter='.commands.test.variants[]?.name // empty'
    ;;
  *)
    # Dotted path is interpolated as a jq path expression: a.b.c -> .a.b.c
    filter=".${field_path} | if type == \"array\" then .[] else . end // empty"
    ;;
esac

jq -r "$filter" "$manifest"
