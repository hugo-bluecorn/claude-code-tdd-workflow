#!/bin/bash
# read-pack.sh <pack-dir> <jq-path> — read one field from a pack's pack.json manifest.
#
# The shared field-reader every R1 consumer uses to data-drive off a language
# pack (detect / commands / testFilePattern / versionFiles / projectFiles …).
#
#   <pack-dir>  directory containing pack.json (trailing slash tolerated)
#   <jq-path>   dotted path into the manifest, e.g. commands.test.run,
#               commands.format, detect.markers[0]
#
# Blackbox-safe by contract: a missing manifest, missing/empty arguments, an
# absent field, or a null value all yield EMPTY output and exit 0 — never an
# error. Consumers treat empty as "no pack-provided value, fall back".
set -uo pipefail

pack_dir="${1:-}"
field="${2:-}"

# No pack dir or no field requested → nothing to read.
[ -n "$pack_dir" ] && [ -n "$field" ] || exit 0

manifest="${pack_dir%/}/pack.json"
[ -f "$manifest" ] || exit 0

# `(.<path>)?` suppresses type errors (e.g. indexing null); `// empty` maps a
# null/absent value to no output. The path is plugin-supplied (not user input).
jq -r "(.${field})? // empty" "$manifest" 2>/dev/null || true
