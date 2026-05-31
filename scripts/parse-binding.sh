#!/bin/bash
# parse-binding.sh [binding-file] — normalize the project binding into
# "<source>\t<version>" lines (one per pack), for the resolver (F3) and the
# detection engine (F4) to consume.
#
#   • New form:    {"packs":[{"source":"github.com/o/x","version":"1.2.0"}, …]}
#   • Legacy form: {"conventions":["url-or-abspath", …]}  → empty version (HEAD)
#
# The new `packs` key is preferred when both are present. A missing or empty
# binding yields no output and exit 0 (PRIME-safe: an unconfigured project just
# has no bound packs). Default binding path is the committed
# .claude/tdd-conventions.json in the current directory.
set -uo pipefail

binding="${1:-.claude/tdd-conventions.json}"
[ -f "$binding" ] || exit 0

if [ "$(jq -r 'has("packs")' "$binding" 2>/dev/null)" = "true" ]; then
  jq -r '.packs[]? | [.source, (.version // "")] | @tsv' "$binding" 2>/dev/null || true
else
  jq -r '(.conventions // [])[]? | [., ""] | @tsv' "$binding" 2>/dev/null || true
fi
