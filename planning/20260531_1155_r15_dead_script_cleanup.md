# Feature Notes: R15 — remove dead load-role-references.sh

**Created:** 2026-05-31T09:55:26Z
**Status:** Planning

> Read-only planning archive. Live status in `.tdd-progress.md`.

---

## Overview

### Purpose
R15 (de-scoped): remove the dead `scripts/load-role-references.sh`. Its original C/C++
`ctest` half is DROPPED per ratified Decision #6 — C/C++ test-running belongs in the
`claude-cpp-template` convention pack (delivered via R1), not in core. What remains is a
pure dead-code cleanup.

### Context
`load-role-references.sh` was introduced (v2.2.1, issue #009) to replace two `cat` DCI
invocations in the `/role-cr` skill. The v2.3 skill→agent split (issue #010) moved
reference loading into the `role-creator` agent, leaving the script unused — explicitly
noted as "no longer used by the skill" and deferred as separate cleanup. This slice is
that cleanup.

---

## Requirements Analysis

### Functional Requirements
1. Remove `scripts/load-role-references.sh`.
2. Remove its orphaned test `test/scripts/load_role_references_test.sh`.
3. Remove the now-stale live doc line `docs/plugin-developer-context.md:88`.
4. Add a permanent absence-guard test so the dead script can't silently return.

### Non-Functional Requirements
- Full-suite FAILURE count holds at 34 (no regressions).
- New guard test shellcheck-clean.
- PRIME-neutral; no core→role dependency introduced.

### Integration Points
- None at runtime — the script has zero callers (verified sweep).

---

## Implementation Details

### Architectural Approach
Pure removal with an absence-guard test (the R5-gap pattern: a removal has no natural RED,
so a guard test asserting absence supplies one — RED while the file exists, GREEN once
removed — and stays as a regression guard).

### Sweep findings (provenance)
`grep -rl load-role-references` across the repo:
- **Zero** runtime callers in `skills/ agents/ hooks/ scripts/`.
- Historical/immutable: `CHANGELOG.md`, `planning/*`, `docs/experimental-results/*`,
  `issues/*` — record what happened; NOT edited.
- Orphaned test: `test/scripts/load_role_references_test.sh` — removed with the script.
- Live stale doc: `docs/plugin-developer-context.md:88` — removed (no test guards it;
  verified zero `plugin-developer-context` refs under `test/`).
- `test/skills/role_create_test.sh` Test 6 — asserts the SKILL body does NOT reference the
  script; remains TRUE after removal; KEEP untouched.

### Design Patterns
- **Absence-guard test** — precedent: `test/skills/convention_skills_removed_test.sh`
  (uses `$(pwd)`-relative paths + absence asserts). House style.

### File Structure
```
test/scripts/load_role_references_removed_test.sh   # NEW guard (permanent)
scripts/load-role-references.sh                     # REMOVED
test/scripts/load_role_references_test.sh           # REMOVED (orphaned)
docs/plugin-developer-context.md                    # line 88 removed
```

---

## TDD Approach

### Slice Decomposition
Single slice (RED→GREEN). See `.tdd-progress.md`.

**Test Framework:** bashunit. **Command:** `./lib/bashunit test/scripts/load_role_references_removed_test.sh`, then `./lib/bashunit test/`.

### Slice Overview
| # | Slice | PRIME | Dependencies |
|---|-------|-------|-------------|
| 1 | Remove dead load-role-references.sh | neutral | None |

---

## Dependencies
- None.

---

## Known Limitations / Trade-offs

### Trade-offs Made
- Including the `docs/plugin-developer-context.md` line removal is mild scope creep beyond
  "remove the script," accepted because leaving a live doc describing a deleted script just
  swaps dead code for fresh doc-drift — against the upgrade's purpose. It's unguarded by any
  test, so no reconciliation needed.
- Keeping a one-assert guard test file is intentional (cheap, prevents regression), matching
  the existing `*_removed_test.sh` precedent.

---

## Implementation Notes

### Key Decisions
- **Guard-test RED→GREEN** instead of a bare removal — gives a real failing-first step and a
  durable regression guard.
- **Remove the orphaned test with the script** (R16 removal lesson — a test of a removed
  artifact would otherwise newly fail and break the floor).

### Commit sequence
1. Test commit (`test` type): add absence guard for removed load-role-references.sh (RED — script present)
2. Removal commit (`refactor` type — dead-code removal, no behavior change): delete the script,
   its orphaned test, and the stale doc line (GREEN — floor holds at 34)

### Potential Refactoring
- None.

---

## References

### Related Code
- `scripts/load-role-references.sh`, `test/scripts/load_role_references_test.sh`
- `test/skills/convention_skills_removed_test.sh` (guard precedent)
- `test/skills/role_create_test.sh` Test 6 (kept)
- `docs/plugin-developer-context.md:88` (removed line)

### Documentation
- Roadmap R15 (Wave 1); Decision #6 (C/C++ → convention pack).
- issues/009 (script introduced), issues/010 + docs/experimental-results/role-format-redesign.md ("no longer used").

### Issues / PRs
- Roadmap R15 (de-scoped). Release 2.4.4.
