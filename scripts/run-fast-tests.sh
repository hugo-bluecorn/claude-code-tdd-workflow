#!/bin/bash
# Fast test-subset runner — the full bashunit suite MINUS the slow
# network-integration tests (real git clones). Used by per-slice TDD
# verification so the inner loop stays fast and offline. The FULL suite
# (including the slow tests) runs via `./lib/bashunit test/` at release/CI.
#
# Usage:
#   scripts/run-fast-tests.sh           run the fast subset
#   scripts/run-fast-tests.sh --list    print the test files it would run (no run)
#
# To gate a new network test, add its repo-relative path to SLOW_TESTS below.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

# Slow tests that do real network git clones — excluded from the fast subset,
# but kept and run in full at release/CI.
SLOW_TESTS=(
  "test/integration/external_conventions_repo_test.sh"
  "test/integration/convention_loading_integration_test.sh"
  "test/scripts/load_conventions_test.sh"
  "test/scripts/load_conventions_config_test.sh"
  "test/hooks/fetch_conventions_test.sh"
)

is_slow() {
  local candidate="$1" slow
  for slow in "${SLOW_TESTS[@]}"; do
    [[ "$candidate" == "$slow" ]] && return 0
  done
  return 1
}

fast_files=()
while IFS= read -r f; do
  f="${f#./}"
  is_slow "$f" || fast_files+=("$f")
done < <(find test -name '*_test.sh' | sort)

if [[ "${1:-}" == "--list" ]]; then
  printf '%s\n' "${fast_files[@]}"
  exit 0
fi

# --parallel: the fast subset excludes the stateful network files, so it is
# parallel-safe and ~10x faster. (The FULL release/CI suite stays sequential —
# its network files share set_up_before_script state that races under parallel.)
exec ./lib/bashunit "${fast_files[@]}" --parallel
