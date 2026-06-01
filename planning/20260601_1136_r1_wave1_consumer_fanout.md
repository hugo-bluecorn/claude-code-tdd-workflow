# Feature Notes: R1 Wave 1 — Consumer Fan-out (C0–C7)

**Created:** 2026-06-01T09:36:39Z
**Status:** Planning

> Read-only planning archive produced by the tdd-planner. Live status is tracked
> in `.tdd-progress.md`.

---

## Overview

### Purpose
R1 re-platforms the plugin from a language-agnostic core + hardcoded language
matrix into a core that reads per-language `pack.json` manifests. Wave 0 (the
foundation primitives) shipped to `main` as v2.5.0. **Wave 1 rewires the 7
consumers** that still branch on hardcoded language names so they read the active
pack instead, while the core degrades pack-optional (bashunit default;
warn-and-proceed; never hard-block).

### Use Cases
- A bound dart pack drives `auto-run-tests` (`flutter test {file}`),
  `validate-tdd-order` (`testFilePattern`), the verifier's test command, project
  detection's `test_runner`, the planner allowlist, and convention loading — all
  from one `pack.json`, no hardcoded dirnames.
- A bound cpp pack runs `setup[]` then `ctest` (fixing the C++ false-green where
  the old hook built but never ran tests).
- A project with no pack still works: bashunit is the built-in script default;
  unknown languages pass through; nothing hard-blocks.

### Context
The merged foundation provides `read-pack.sh`, `parse-binding.sh`,
`resolve-active-pack.sh`, and the evolved `fetch-conventions.sh` resolver — but no
`$TDD_ACTIVE_PACK` export. Wave 1 closes that with a shared `active-pack.sh`
helper (C0) the consumers compose, so each resolves the active pack the same way.

---

## Requirements Analysis

### Functional Requirements
1. A shared resolve-chain helper (`active-pack.sh`) with an env fast-path and a committed-binding fallback.
2. Each of the 7 consumers reads the active pack instead of hardcoded language names.
3. The C++ test command actually runs the tests (`setup[]` then `ctest`).
4. Pack-optional degrade everywhere: bashunit default; unknown language pass-through; warn-and-proceed.

### Non-Functional Requirements
- Suite floor 0 failed AND 0 risky (fail-on-risky enforced).
- Every changed `.sh` shellcheck-clean.
- No consumer references a role file (PRIME DIRECTIVE).

### Integration Points
- Reads `.claude/tdd-conventions.json` (committed binding) + the per-machine cache via the foundation scripts.
- Feeds the in-session hooks (auto-run-tests, validate-tdd-order, planner-bash-guard), the loader, project detection, and the verifier agent doc.
- No dependency on env→subagent propagation (committed-binding fallback proven env-unset).

---

## Implementation Details

### Architectural Approach
A single shared helper (C0) performs the resolve chain (parse-binding → locate the
bound source's cache dir → resolve-active-pack → echo the active pack dir), with an
optional `$TDD_ACTIVE_PACK` fast-path for the in-session hook. Consumers call the
helper, then `read-pack.sh` for the field they need. This avoids duplicating the
chain across five consumers and gives one place to prove the env-unset fallback.
The verifier (a subagent) resolves the committed binding itself and reads
`jq '.commands'` only — never `standards.index` — preserving its blackbox stance.

### Design Patterns
- **Shared resolver seam (C0):** one helper, many consumers — chosen to prevent
  drift and to centralize the env-unset fallback proof.
- **Union-not-replace floors (C7, and bashunit default):** built-in safe floors
  are unioned with pack data, never replaced — PRIME-safe, works pack-less.
- **Removal-sweep:** each slice that removes a hardcoded site rewrites the tests
  that asserted the old behavior to assert the new data-driven behavior.

### File Structure
```
scripts/active-pack.sh                              [NEW, C0]
test/fixtures/ (dart + cpp pack.json)               [NEW, C0]
test/scripts/active_pack_test.sh                    [NEW, C0]
test/scripts/load_conventions_detection_test.sh     [NEW, C1 fast track]
scripts/load-conventions.sh                         [C1]
hooks/auto-run-tests.sh                             [C2, C3]
hooks/validate-tdd-order.sh                         [C4]
agents/tdd-verifier.md                              [C5]
scripts/detect-project-context.sh                   [C6]
hooks/planner-bash-guard.sh                         [C7]
# rewritten sweeps: load_conventions(_config)_test, auto_run_tests_test,
# validate_tdd_order_test, tdd_verifier_bash_test, language_documentation_test,
# detect_project_context_test, planner_bash_guard_test
```

### Naming Conventions
New scripts in `scripts/`; tests mirror source with `_test.sh`; fixtures under
`test/fixtures/`; `mktemp -d` temp projects with `rm -rf` teardown; the
`bashunit::skip "reason" && return` idiom inline where needed.

---

## TDD Approach

### Slice Decomposition
Each slice runs RED -> GREEN -> REFACTOR. Full Given/When/Then live in
`.tdd-progress.md`.

**Test Framework:** bashunit 0.36.0
**Test Command:** `scripts/run-fast-tests.sh` (per-slice) / `./lib/bashunit test/` (full)

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| C0 | active-pack.sh helper + fixtures | None |
| C1 | load-conventions.sh detection | C0 |
| C2 | auto-run-tests.sh pack command | C0 |
| C3 | auto-run-tests.sh C++ ctest fix | C2 |
| C4 | validate-tdd-order.sh testFilePattern | C0 |
| C5 | tdd-verifier.md commands-only | C0 (concept) |
| C6 | detect-project-context.sh test_runner | C0 |
| C7 | planner-bash-guard.sh union floor | C0 |

---

## Dependencies

### External Packages
- `jq`, `git` — already plugin dependencies.

### Internal Dependencies
- C1/C2/C4/C6/C7 consume C0's `active-pack.sh`; C3 depends on C2; C5 is doc-only.
- All consume the foundation scripts read-only.

---

## Known Limitations / Trade-offs

### Limitations
- **Packs deferred:** real dart/cpp packs are built elsewhere; Wave 1 is tested
  against synthetic fixtures (and C1's content track against the real conventions clone).
- **C5 is doc/instruction only:** the verifier is a model; its "reads commands"
  behavior is asserted via doc-anchor tests, not executable code.

### Trade-offs Made
- **Shared C0 helper vs inline-per-consumer:** one helper adds a dependency edge
  but removes five copies of the resolve chain and one place to prove env-unset —
  chosen for DRY + a single fallback proof.
- **Whole-file content track stays on the real clone (C1):** keeps real-content
  coverage at the cost of those tests staying in the slow/full suite, not the fast subset.

---

## Implementation Notes

### Key Decisions
- **No env→subagent propagation dependency (decision #1):** committed-binding
  fallback proven with `TDD_ACTIVE_PACK` unset on every consumer slice.
- **Verifier commands-only (decision #2):** `jq '.commands'`, never `standards.index`.
- **C++ false-green fix (C3):** `setup[]` then `ctest` — the root cause was a flat
  command that could not encode the 3-step build; the rich `commands.test` object fixes it.

### Future Improvements
- Wave 2 (V1–V4 version authority) and Wave 3 (T1 projectFiles, T2 CLAUDE.md
  cleanup) follow in their own cycles/PRs.

### Potential Refactoring
- A thin "resolve then read a command field" accessor over C0 if the idiom repeats
  across consumers — left for the implementer to decide once tests pass.

---

## References

### Related Code
- Foundation (read-only): `scripts/read-pack.sh`, `scripts/parse-binding.sh`, `scripts/resolve-active-pack.sh`, `hooks/fetch-conventions.sh`.
- Sweep tests reconciled: the seven `*_test.sh` listed above.

### Documentation
- `explorations/features/r1-implementation-plan.md` (Wave 1 = C1–C7, DAG, sweeps, decisions).
- `explorations/features/r1-langpack-reconciliation.md` (C2 schema, §8.5), `…-interface.md`.

### Issues / PRs
- Roadmap R1 (Wave 2 of the v2.4→v3 roadmap). Foundation shipped v2.5.0 (PR #23); test-infra PRs #24/#25/#26.
