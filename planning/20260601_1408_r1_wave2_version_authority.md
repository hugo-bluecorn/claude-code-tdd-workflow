# Feature Notes: R1 Wave 2 — Version Authority (V1–V4)

**Created:** 2026-06-01T12:08:39Z
**Status:** Planning

> Read-only planning archive produced by the tdd-planner. Live status in `.tdd-progress.md`.

---

## Overview

### Purpose
Complete the version-authority half of R1: make the release/versioning chain
pack-driven so version-bearing files and ecosystem command formats come from the
active convention pack, while SemVer semantics stay owned by core. This removes the
last hardcoded-language sites in the release path (`bump-version.sh`'s 6 ecosystems,
the releaser's Step 1–3 chain, and the `/tdd-release` SKILL wrapper's duplicate
chain), and corrects the `version-control.md` merge guidance to the project's
never-squash preference.

### Use Cases
- A bound pack declares `versionFiles` → `bump-version.sh` bumps exactly those
  files; the plugin always self-hosts its own `plugin.json`.
- The releaser (a subagent) resolves the committed binding and runs the pack's
  test/lint/format commands; pack-less projects fall back to bashunit/shellcheck.
- Contributors get correct merge guidance (merge commit, no squash) preserving the
  TDD commit trail.

### Context
Foundation (v2.5.0) + Wave 1 consumer fan-out (v2.6.0) already shipped. The shared
`scripts/active-pack.sh` resolver and `test/fixtures/{dart,cpp}-fixture` exist. The
releaser doc mirrors the verifier's "Resolving the active convention pack" pattern
introduced in Wave 1 (C5).

---

## Requirements Analysis

### Functional Requirements
1. `bump-version.sh` reads `versionFiles[]` from the active pack; keeps `plugin.json` self-host; CLI positional interface unchanged.
2. The releaser reads `pack.commands.{test,lint,format}` for its quality chain.
3. `version-control.md` states the SemVer-core / version-files-pack split and prescribes never-squash.
4. The `/tdd-release` SKILL wrapper defers to the pack-driven releaser (no duplicate per-language matrix).

### Non-Functional Requirements
- Floor 0 failed AND 0 risky (fail-on-risky enforced).
- All changed `.sh` shellcheck-clean.
- No `role-*` reference (PRIME DIRECTIVE); pack-optional degrade everywhere.

### Integration Points
- `bump-version.sh` is called positionally by the releaser (decision #4).
- Resolution via `active-pack.sh` (committed-binding, env-unset safe).
- Doc-anchor sweeps (releaser, SKILL, version-control location) assert content presence.

---

## Implementation Details

### Architectural Approach
`bump-version.sh` becomes pack-aware internally: resolve the active pack, read
`versionFiles[]`, bump each (bare-path heuristic or `{path,pattern}` object via jq),
always self-host `plugin.json`. The releaser and SKILL wrapper become
instruction-level pack consumers (like the Wave-1 verifier) — they describe
resolving the committed binding and reading `pack.commands`, keeping illustrative
examples so doc-anchor sweeps stay green. `version-control.md` is edited to encode
the C5 authority split and the never-squash correction, both asserted by tests.

### Design Patterns
- **Pack-aware-internally, positional-externally (decision #4):** the CLI seam is
  stable; pack-awareness is an implementation detail — chosen so the releaser need
  not change how it invokes the bumper.
- **Mirror the verifier's resolution prose (V2):** reuse the proven Wave-1 pattern
  for committed-binding, env-unset-safe resolution.
- **One authoritative source, references elsewhere (V4):** the SKILL wrapper points
  at the releaser rather than duplicating the chain — removes the drift V2 fixed.

### File Structure
```
scripts/bump-version.sh                              [V1 — rewrite internals]
test/fixtures/dart-fixture/pack.json                 [V1 — add versionFiles]
agents/tdd-releaser.md                               [V2]
skills/tdd-release/reference/version-control.md      [V3]
skills/tdd-release/SKILL.md                          [V4]
# rewritten sweeps: bump_version_test, tdd_releaser_test,
# version_control_location_test, release_version_test, tdd_release_test
```

### Naming Conventions
`versionFiles` per C2 (top-level array; bare path or `{path,pattern}`). Tests mirror
source with `_test.sh`; `mktemp -d` temp projects; reuse `test/fixtures/`.

---

## TDD Approach

### Slice Decomposition
Each slice RED -> GREEN -> REFACTOR. Full Given/When/Then in `.tdd-progress.md`.

**Test Framework:** bashunit 0.36.0
**Test Command:** `scripts/run-fast-tests.sh` (per-slice) / `./lib/bashunit test/` (full)

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| V1 | bump-version.sh pack-driven | F1, C0 |
| V2 | tdd-releaser.md pack commands | V1 |
| V3 | version-control.md authority split + never-squash | V2 |
| V4 | tdd-release SKILL wrapper de-hardcode | V2 |

---

## Dependencies

### External Packages
- `jq`, `git` — already plugin dependencies.

### Internal Dependencies
- V1 consumes `active-pack.sh` + `read-pack.sh`. V2/V3/V4 depend on V1/V2 as in the DAG.

---

## Known Limitations / Trade-offs

### Limitations
- Real packs deferred; tested against synthetic fixtures (the dart fixture gains `versionFiles`).
- V2/V4 are doc/instruction slices — behavior asserted via doc-anchor tests, not executable code.

### Trade-offs Made
- **Two `versionFiles` forms (bare path + object):** the heuristic covers common
  ecosystems concisely; the object form handles irregular cases (CMake) — chosen over
  a single rigid schema to keep the common case terse.
- **SKILL wrapper defers rather than re-implements (V4):** one source of truth at the
  cost of the wrapper no longer being self-contained.

---

## Implementation Notes

### Key Decisions
- **#4:** bump-version pack-aware internally; releaser calls it positionally.
- **C5:** SemVer → core; version files + ecosystem format → pack.
- **never-squash:** corrects the standing contradiction in `version-control.md` line 165.

### Future Improvements
- Wave 3 (T1 `projectFiles` materialization, T2 `CLAUDE.md` residual-language cleanup) follows in its own cycle.

### Potential Refactoring
- Shared "defer to pack.commands" prose between releaser and SKILL — keep the releaser authoritative.

---

## References

### Related Code
- `scripts/bump-version.sh`, `scripts/active-pack.sh`, `scripts/read-pack.sh`
- `agents/tdd-releaser.md`, `agents/tdd-verifier.md` (pattern to mirror)
- `skills/tdd-release/SKILL.md`, `skills/tdd-release/reference/version-control.md`
- Sweeps: `bump_version_test`, `tdd_releaser_test`, `version_control_location_test`, `release_version_test`, `tdd_release_test`

### Documentation
- `explorations/features/r1-implementation-plan.md` (Wave 2 = V1–V4, decision #4).
- `explorations/features/r1-langpack-reconciliation.md` (C5 authority split, C2 `versionFiles`).

### Issues / PRs
- Roadmap R1 Wave 2. Foundation v2.5.0 (PR #23); Wave 1 v2.6.0 (PR #27).
