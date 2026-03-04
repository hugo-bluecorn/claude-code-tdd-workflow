# Feature Notes: Generalize tdd-doc-finalizer and Fix Version Responsibility Split

**Created:** 2026-03-02
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
The tdd-doc-finalizer agent and `/tdd-finalize-docs` skill are hardcoded for the tdd-workflow plugin's own documentation structure. When invoked on an external project, the agent refuses to run because plugin-specific files don't exist. Additionally, the releaser agent has zero guidance on version selection (no semver reference), while the doc-finalizer is the only agent that bumps versions — creating a responsibility gap.

This feature reorganizes version responsibilities (releaser owns version selection + propagation, doc-finalizer owns documentation only) and generalizes both agents to work on any project type.

### Use Cases
- Running `/tdd-finalize-docs` on a Dart project (pubspec.yaml, README.md, docs/) after `/tdd-release`
- Running `/tdd-finalize-docs` on a Rust project (Cargo.toml, README.md) after `/tdd-release`
- Running `/tdd-release` with proper semver guidance from version-control.md reference
- Version propagation across all version-bearing files at release time (not post-release)

### Context
The plugin's current architecture has three issues:
1. `docs/version-control.md` is outside the context-updater's scan path (`skills/*/reference/*.md`)
2. The releaser has no reference to semver rules — it picks versions without guidance
3. The doc-finalizer hardcodes plugin-specific paths (plugin.json, user-guide.md, release integration tests)

Discovered during real-world testing of v1.11.0 on the zenoh-dart project (see `issues/002-generalize-doc-finalizer.md`).

---

## Requirements Analysis

### Functional Requirements
1. `docs/version-control.md` moves to `skills/tdd-release/reference/version-control.md`; all references updated
2. `scripts/bump-version.sh` propagates a version string into discovered version-bearing files (pubspec.yaml, package.json, Cargo.toml, pyproject.toml, plugin.json, CMakeLists.txt)
3. Releaser agent gains a directive to read version-control.md for semver rules and a step to call bump-version.sh
4. `scripts/detect-doc-context.sh` discovers project documentation files (README.md, CLAUDE.md, CHANGELOG.md, docs/)
5. Doc-finalizer agent becomes documentation-only — no version bumping, no hardcoded paths
6. Both agent and skill description frontmatter become project-agnostic

### Non-Functional Requirements
- All 434+ existing tests continue to pass
- shellcheck passes on all new and modified scripts
- New scripts follow the detect-project-context.sh pattern (key=value output)

### Integration Points
- `bump-version.sh` integrates with the releaser workflow (called after CHANGELOG commit)
- `detect-doc-context.sh` integrates with the doc-finalizer workflow (called at start for discovery)
- `version-control.md` at new location is picked up by context-updater's `skills/*/reference/*.md` scan
- Existing hooks (check-release-complete.sh) remain unchanged

---

## Implementation Details

### Architectural Approach

**Discovery over hardcoding:** Both new scripts follow the `detect-project-context.sh` pattern: scan the current directory for known files, output key=value pairs, exit 0. This makes agent prompts project-agnostic because they delegate file discovery to scripts.

**Version responsibility split:** The releaser owns version selection (guided by version-control.md semver rules) and version propagation (via bump-version.sh). The doc-finalizer owns only documentation updates. This eliminates the gap where the releaser has zero semver guidance and the doc-finalizer is the only agent that bumps versions.

**Reference file co-location:** `skills/tdd-release/reference/version-control.md` puts the file in the context-updater's scan path and co-locates it with its primary consumer (the releaser skill).

### Design Patterns
- **Discovery script pattern**: Shell scripts that scan for known files and output key=value pairs — same pattern as `detect-project-context.sh`
- **Reference delegation**: Agent prompts reference a document for rules rather than inlining them — the releaser reads version-control.md instead of having semver rules in its body
- **Tool constraint preservation**: The releaser uses bump-version.sh via Bash (already permitted) rather than needing Edit tool access

### File Structure
```
scripts/
  bump-version.sh                    (NEW - version propagation)
  detect-doc-context.sh              (NEW - doc discovery)
skills/tdd-release/
  reference/
    version-control.md               (MOVED from docs/)
agents/
  tdd-releaser.md                    (MODIFIED - semver ref + bump step)
  tdd-doc-finalizer.md               (MODIFIED - generalized)
skills/tdd-release/SKILL.md          (MODIFIED)
skills/tdd-finalize-docs/SKILL.md    (MODIFIED)
CLAUDE.md                            (MODIFIED)
README.md                            (MODIFIED)
test/scripts/
  bump_version_test.sh               (NEW)
  detect_doc_context_test.sh         (NEW)
  version_control_location_test.sh   (NEW)
```

### Naming Conventions
- Scripts: `kebab-case.sh` in `scripts/` directory
- Tests: `snake_case_test.sh` in `test/` mirroring source structure
- Reference docs: `kebab-case.md` in `skills/*/reference/` directories

---

## TDD Approach

### Slice Decomposition

The feature is broken into 6 independently testable slices, each following the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | Move version-control.md to reference location | None |
| 2 | bump-version.sh script | None |
| 3 | Releaser gains version-control reference and bump-version step | Slice 1, 2 |
| 4 | detect-doc-context.sh script | None |
| 5 | Generalize doc-finalizer agent and skill | Slice 1, 4 |
| 6 | CLAUDE.md and README.md consistency updates | Slice 1, 2, 3, 4, 5 |

---

## Dependencies

### External Packages
- None — all scripts use coreutils (sed, grep, find) only

### Internal Dependencies
- `detect-project-context.sh`: Pattern reference for new scripts
- `check-release-complete.sh`: Unchanged, already generic
- `version-control.md`: Moved but content unchanged — authority for semver rules

---

## Known Limitations / Trade-offs

### Limitations
- `bump-version.sh` has zero semver intelligence — it takes a string and propagates it. The releaser agent must make the semver decision based on version-control.md guidance.
- `detect-doc-context.sh` uses a fixed list of known documentation patterns (README.md, CLAUDE.md, docs/). Unusual documentation layouts require agent judgment.

### Trade-offs Made
- **Discovery scripts vs. inline logic**: Scripts add files but make agent prompts project-agnostic and testable. Chose scripts over embedding discovery logic in markdown prompts.
- **Reference delegation vs. inline rules**: The releaser reads version-control.md at runtime instead of having rules in its body. This avoids duplication but requires the file to exist. Acceptable because the file is part of the plugin.
- **Planning archives untouched**: Old planning archives reference `docs/version-control.md`. These are historical and won't be updated — avoids churn in read-only archives.

---

## Implementation Notes

### Key Decisions
- **Slice 6 depends on Slice 3**: The README agents table describes the releaser, and Slice 3 changes the releaser's behavior. Slice 6 must reflect these changes.
- **Negative assertion coverage in Slice 1**: Three-layer approach (blanket sweep Test 7 + file-specific Tests 3, 4) ensures no stale references survive the move.
- **No Edit tool for releaser**: bump-version.sh runs via Bash, preserving the existing tool constraint.

### Future Improvements
- Plugin-internal mode: detect when running in the tdd-workflow plugin's own repo and apply plugin-specific logic (release integration tests, etc.) as a special case
- Version file auto-detection could be extracted into a shared `detect-version-files.sh` if other agents need it

### Potential Refactoring
- The doc-finalizer's hardcoded test runner commands could be generalized using `detect-project-context.sh` output — left for implementer to decide at implementation time

---

## References

### Related Code
- `scripts/detect-project-context.sh` — pattern for new detection scripts
- `agents/tdd-releaser.md` — current releaser agent body
- `agents/tdd-doc-finalizer.md` — current doc-finalizer agent body
- `docs/version-control.md` — file being moved
- `hooks/check-release-complete.sh` — already generic, unchanged

### Documentation
- `issues/002-generalize-doc-finalizer.md` — original issue
- `docs/version-control-integration.md` — VCS integration docs (references to update)
- `docs/user-guide.md` — user guide (references to update)

### Issues / PRs
- Issue 002: Generalize tdd-doc-finalizer for Any Project
