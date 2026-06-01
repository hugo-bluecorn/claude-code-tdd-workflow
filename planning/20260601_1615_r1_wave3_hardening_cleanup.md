# Feature Notes: R1 Wave 3 — Foundation Hardening + Cross-cutting Tail (H1–H3, T1, T2)

**Created:** 2026-06-01T14:15:30Z
**Status:** Planning

> Read-only planning archive produced by the tdd-planner. Live status in `.tdd-progress.md`.

---

## Overview

### Purpose
Close R1 with two kinds of work in one cycle: (a) **hardening** the merged
foundation against three real breaks an adversarial retro found shipping green
under blind end-state tests (issue 014: dev-pack mis-parse, polyglot head-1
false-green, nested-`lib` path mangle); (b) the **cross-cutting tail** — pack
`projectFiles` materialization and removing the now-untested C-testing content
from `CLAUDE.md`. After Wave 3, R1 is complete.

### Use Cases
- A pack author dev-binds a local langpack → no bogus failed `git clone` every
  SessionStart (H1).
- A polyglot repo (Dart app + native C++) → editing a `.cpp` runs the cpp pack's
  `ctest`, not a silent cmake-only build, regardless of pack order (H2).
- A monorepo with `packages/mylib/lib/` → the auto-test derives the correct test
  path (H3).
- A bound pack ships tool-configs (e.g. `analysis_options.yaml`) → materialized
  into the project if absent, never overwriting a user's customized copy (T1).

### Context
Waves 0/1/2 shipped (v2.7.0). The retro (issue 014) classified findings as
block/break/edge: zero blocks, one break in normal use (H1, the dev-binding flow
R1 is built to enable), two edge breaks (H2/H3). The #1 lesson: those bugs passed
green because tests asserted the **end-state**, which a broken-but-cleaned-up path
reproduces. Wave 3's FFTs assert the **action** instead.

---

## Requirements Analysis

### Functional Requirements
1. One shared binding-iteration helper used by both `fetch-conventions.sh` and `active-pack.sh` (H1).
2. Auto-run-tests selects the pack matching the edited extension across all resolved packs (H2).
3. `derive_test_file` rewrites only a full `lib` path segment (H3).
4. The resolver materializes `projectFiles` non-destructively, warning on drift (T1).
5. `CLAUDE.md` keeps the `### C Testing` header but drops its C-specific body (T2).

### Non-Functional Requirements
- Floor 0 failed AND 0 risky; all changed `.sh` shellcheck-clean.
- No `role-*` reference; hooks stay `exit 0`/non-blocking; PRIME-safe degrade.
- Every FFT asserts the action (spy / exact string / file written), not the end-state.

### Integration Points
- `fetch-conventions.sh` (H1, T1) and `auto-run-tests.sh` (H2, H3) are the runtime hooks.
- The shared `iterate-binding.sh` becomes the single binding-iteration seam.
- Doc-fence sweeps (convention_loading/bash/language documentation tests) bound T2.

---

## Implementation Details

### Architectural Approach
H1 extracts the correct tab-preserving binding split (already hand-rolled in
`active-pack.sh`) into one shared helper, eliminating the divergence the retro
exploited. H2 replaces `head -1` with extension-membership selection over all
resolved packs. H3 anchors the `lib/` substitution to a path segment. T1 adds a
non-destructive materialization step to the SessionStart resolver. T2 is a tight
documentation edit guarded on both sides by the existing doc-tests. The unifying
discipline: each RED test spies on or asserts the exact action the fix performs.

### Design Patterns
- **Single seam, many consumers (H1):** one `iterate-binding.sh` — chosen to kill
  the parser divergence permanently rather than patch the same trap twice.
- **Action-assertion via PATH-shim stubs (H1/H2):** fake `git`/`ctest` recording
  argv — chosen because end-state assertions proved blind to failed-and-cleaned actions.
- **Non-destructive materialization (T1):** create-if-absent, warn-on-drift, never
  overwrite — chosen so a user's customized tool-config is never clobbered.

### File Structure
```
scripts/iterate-binding.sh                           [NEW, H1]
hooks/fetch-conventions.sh                           [H1, T1]
scripts/active-pack.sh                               [H1 — use shared helper]
hooks/auto-run-tests.sh                              [H2, H3]
CLAUDE.md                                            [T2]
test/fixtures/dart-fixture/pack.json                 [T1 — add projectFiles]
test/fixtures/dart-fixture/analysis_options.yaml     [NEW, T1 — content]
# tests: iterate_binding_test (new), fetch_conventions_versioned_test (H1 rewrite + T1),
#        auto_run_tests_test (H2/H3 + polyglot fixture), convention_loading_documentation_test (T2)
```

### Naming Conventions
PATH-shim stubs under a temp `bin/` recording to an `invocations.log`; `mktemp -d`
temp projects; tests mirror source with `_test.sh`; reuse `test/fixtures/`.

---

## TDD Approach

### Slice Decomposition
Each slice RED -> GREEN -> REFACTOR; full Given/When/Then (with explicit
action-assertion mechanisms) in `.tdd-progress.md`.

**Test Framework:** bashunit 0.36.0
**Test Command:** `scripts/run-fast-tests.sh` (per-slice) / `./lib/bashunit test/` (full; required for H1)

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| H1 | dev-pack tab-collapse fix (shared iterate-binding.sh) | F2, F3 |
| H2 | polyglot pack selection (no head-1) | C2, C3 |
| H3 | derive_test_file anchored lib/ | C2, H2 (same file) |
| T1 | projectFiles materialization | F3 |
| T2 | CLAUDE.md C-content cleanup | C1, C5 |

---

## Dependencies

### External Packages
- `jq`, `git` — already plugin dependencies.

### Internal Dependencies
- H1's shared helper is used by both runtime hooks' resolution. H2→H3 serialize (same file). T1/T2 independent.

---

## Known Limitations / Trade-offs

### Limitations
- Issue 014 #4–#10 (latent/cosmetic) are deferred to vNext / pack-author docs — not in this cycle.
- Real packs deferred; H2 polyglot + T1 materialization tested via synthetic fixtures.

### Trade-offs Made
- **Shared helper (H1) vs inline patch:** one more file + a refactor of two consumers,
  bought permanent elimination of the divergence — chosen over patching the trap twice.
- **Resolver owns materialization (T1):** couples the SessionStart hook to a project
  write, but it's the natural owner (C4) and strictly non-destructive.

---

## Implementation Notes

### Key Decisions
- **Assert the ACTION, not the end-state** — the overriding mandate from issue 014 #1.
- **H1 first** — it must precede langpack-dev (the dev-binding flow it fixes).
- **T1 owner = `fetch-conventions.sh`** (C4 resolver), non-destructive + warn-on-drift.

### Future Improvements
- After Wave 3, R1 is complete → roadmap R8 (`marketplace.json`) / R9 (`plugin validate --strict` in CI); CI reporting levers (`--log-gha`/`--output tap`) apply there.

### Potential Refactoring
- Keep H2's ext-match selection thin atop `active-pack.sh`/`resolve-active-pack.sh` output.

---

## References

### Related Code
- `hooks/fetch-conventions.sh`, `hooks/auto-run-tests.sh`, `scripts/active-pack.sh`, `scripts/resolve-active-pack.sh`, `scripts/read-pack.sh`
- Sweeps: `fetch_conventions_versioned_test`, `auto_run_tests_test`, `convention_loading_documentation_test`, `bash_documentation_test`, `language_documentation_test`

### Documentation
- `issues/014-r1-foundation-hardening-from-retro.md` (H1/H2/H3 root causes, fixes, the action-assertion lesson).
- `explorations/features/r1-implementation-plan.md` Wave 3 (reordered). `…-reconciliation.md` C4 (projectFiles), C2.

### Issues / PRs
- Roadmap R1 Wave 3 (final R1 wave). Foundation v2.5.0 (#23); Wave 1 v2.6.0 (#27); Wave 2 v2.7.0 (#28).
