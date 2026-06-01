#!/bin/bash
# Detects project context for tdd-plan SKILL.md dynamic injection.
# Called via ! backtick preprocessing (cwd'd into the project). Outputs
# key=value lines.
#
# test_runner and test_count are PACK-DRIVEN (R1 C6): both derive from the
# active convention pack resolved via scripts/active-pack.sh (the C0 resolve
# chain), degrading to a built-in floor when no pack is bound:
#   - test_runner: the active pack's commands.test.run with {placeholders}
#     stripped (e.g. "flutter test"); falls back to a command -v flutter/dart
#     ladder when no pack resolves.
#   - test_count: a glob built from the pack's testFilePattern PLUS the .sh
#     built-in; falls back to the built-in *_test.{dart,cpp,sh,c} glob when no
#     pack resolves.
# Pack-optional: a missing/malformed binding never crashes -- the floor always
# emits sensible values. This script references no role file.

set -uo pipefail

# Sibling scripts live beside this one.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
active_pack_sh="${script_dir}/active-pack.sh"
read_pack_sh="${script_dir}/read-pack.sh"

# Resolve the active pack dir for the current project ($PWD). Empty if none.
active_pack="$(bash "$active_pack_sh" "$PWD" 2>/dev/null | head -n1)"

# ---------- test_runner ----------
runner=""
if [ -n "$active_pack" ]; then
  # Derive the runner from the pack's commands.test.run: drop {placeholder}
  # tokens and squeeze surrounding whitespace (e.g. "flutter test {file}" ->
  # "flutter test", "ctest --preset {variant} ..." -> "ctest --preset ...").
  run_cmd="$(bash "$read_pack_sh" "$active_pack" commands.test.run 2>/dev/null || true)"
  if [ -n "$run_cmd" ]; then
    runner="$(printf '%s' "$run_cmd" | sed -E 's/\{[^}]*\}//g; s/[[:space:]]+/ /g; s/^ //; s/ $//')"
  fi
fi
if [ -n "$runner" ]; then
  echo "test_runner=$runner"
elif command -v flutter >/dev/null 2>&1; then
  echo "test_runner=flutter test"
elif command -v dart >/dev/null 2>&1; then
  echo "test_runner=dart test"
else
  echo "test_runner=not detected"
fi

# ---------- test_count ----------
# Build the set of find -name patterns. With a pack: the pack's testFilePattern
# plus the .sh built-in. Without a pack: the built-in *_test.{dart,cpp,sh,c}.
pack_pattern=""
if [ -n "$active_pack" ]; then
  pack_pattern="$(bash "$read_pack_sh" "$active_pack" testFilePattern 2>/dev/null || true)"
fi

if [ -n "$pack_pattern" ]; then
  # Pack-derived pattern set: the pack's testFilePattern + the .sh built-in.
  find_args=(-name "$pack_pattern" -o -name "*_test.sh")
else
  # Built-in floor glob (also the pack-less fallback).
  find_args=(-name "*_test.dart" -o -name "*_test.cpp" -o -name "*_test.sh" -o -name "*_test.c")
fi

COUNT=$(find . \( "${find_args[@]}" \) 2>/dev/null | wc -l | tr -d ' ')
echo "test_count=$COUNT"

# ---------- branch ----------
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "branch=$BRANCH"

# ---------- uncommitted changes ----------
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
echo "dirty_files=$DIRTY"

# ---------- FVM detection ----------
if [ -f ".fvmrc" ] && command -v fvm >/dev/null 2>&1; then
  echo "fvm=yes (use fvm flutter)"
else
  echo "fvm=no"
fi
