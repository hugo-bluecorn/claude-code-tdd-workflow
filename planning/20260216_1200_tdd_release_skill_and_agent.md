# Feature Notes: /tdd-release Skill and tdd-releaser Agent (N6)

**Created:** 2026-02-16
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Complete the four-phase TDD architecture by adding a release workflow. Currently
the workflow is: plan -> (implement -> verify) x N -> ???. The releaser fills
the gap: plan -> (implement -> verify) x N -> **release**. This automates the
end-of-feature checklist from `docs/version-control.md`: test suite, static
analysis, formatting, CHANGELOG, commit, push, and PR creation.

### Use Cases
- User completes all TDD slices and wants to finalize the feature branch
- User needs CHANGELOG entries generated from slice descriptions
- User wants a PR created with auto-generated summary from the TDD plan

### Context
The design was documented in `docs/version-control-integration.md` (Layer 3)
and tracked as N6 in `docs/tdd-workflow-extensibility-audit.md`. Layers 1
(auto-commits) and 2 (branch creation) were implemented in v1.5.0. The releaser
is the final piece.

Existing agent patterns: tdd-planner (read-only, opus, plan mode), tdd-implementer
(read-write, opus, full tools), tdd-verifier (read-only, haiku, plan mode). The
releaser follows a new pattern: read-only for code, write-only for CHANGELOG via
Bash, sonnet model.

---

## Requirements Analysis

### Functional Requirements
1. Stop hook validates branch is pushed to remote before agent exits
2. Agent has tool restrictions: no Write/Edit (CHANGELOG via Bash only)
3. Skill delegates to releaser agent in forked context
4. hooks.json integration with SubagentStop (timeout: 15s)
5. Project-type aware: formatter, test runner, static analysis detection
6. Approval gates via AskUserQuestion for CHANGELOG, PR, cleanup
7. Graceful degradation when `gh` CLI unavailable

### Non-Functional Requirements
- All new scripts pass shellcheck
- Follows existing plugin conventions (hook patterns, agent frontmatter, skill format)
- Version bumped to 1.6.0

### Integration Points
- Reads `.tdd-progress.md` for slice descriptions (CHANGELOG source)
- Reads `planning/` archive for feature context (PR summary source)
- Modifies `CHANGELOG.md` via Bash (sed/echo)
- Interacts with git (commit, push) and gh (PR creation)
- hooks.json gains SubagentStop entry for tdd-releaser

---

## Implementation Details

### Architectural Approach
The releaser follows the same agent-per-role pattern as the existing three agents.
It runs in a forked context (like the planner) to keep noisy release output
separate from the main conversation. The key constraint is tool restriction:
Write/Edit are disallowed so the agent cannot modify arbitrary files. CHANGELOG
updates use Bash (sed/echo) — a deliberate trade-off of convenience for safety.

### Design Patterns
- **Agent isolation:** Forked context prevents release noise from polluting main conversation
- **Tool restriction:** disallowedTools enforces CHANGELOG-only writes
- **Stop hook validation:** Deterministic check that branch is pushed (matching verifier pattern)
- **Approval gates:** AskUserQuestion for user control over CHANGELOG entries, PR description, cleanup

### File Structure
```
tdd-workflow/
├── agents/
│   └── tdd-releaser.md                      (NEW)
├── skills/
│   └── tdd-release/
│       └── SKILL.md                         (NEW)
├── hooks/
│   ├── hooks.json                           (MODIFIED)
│   └── check-release-complete.sh            (NEW)
├── test/
│   ├── hooks/
│   │   ├── check_release_complete_test.sh   (NEW)
│   │   └── hooks_json_releaser_test.sh      (NEW)
│   ├── agents/
│   │   └── tdd_releaser_test.sh             (NEW)
│   ├── skills/
│   │   └── tdd_release_test.sh              (NEW)
│   └── integration/
│       ├── release_documentation_test.sh    (NEW)
│       └── release_version_test.sh          (NEW)
└── docs/
    ├── user-guide.md                        (MODIFIED)
    ├── tdd-workflow-extensibility-audit.md  (MODIFIED)
    └── version-control-integration.md       (MODIFIED)
```

### Naming Conventions
- Hook scripts: `kebab-case.sh` (e.g., `check-release-complete.sh`)
- Test files: `snake_case_test.sh` (e.g., `check_release_complete_test.sh`)
- Agent files: `kebab-case.md` (e.g., `tdd-releaser.md`)
- Skill directories: `kebab-case/` (e.g., `tdd-release/`)

---

## TDD Approach

### Slice Decomposition

The feature is broken into independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | check-release-complete.sh stop hook | None |
| 2 | tdd-releaser agent definition | None |
| 3 | /tdd-release skill definition | Slice 2 |
| 4 | hooks.json integration | Slice 1, Slice 2 |
| 5 | Documentation updates | Slice 3, Slice 4 |
| 6 | CHANGELOG and version bump | Slice 5 |

---

## Dependencies

### External Packages
- None required (all tools already available)

### Internal Dependencies
- `hooks/check-tdd-progress.sh` — pattern reference for stop hook
- `agents/tdd-verifier.md` — pattern reference for agent frontmatter
- `skills/tdd-plan/SKILL.md` — pattern reference for skill format
- `hooks/hooks.json` — existing configuration to extend
- `.tdd-progress.md` — runtime input for slice descriptions
- `planning/` archive — runtime input for feature context

---

## Known Limitations / Trade-offs

### Limitations
- **No version bump:** Version numbering differs across Dart (pubspec.yaml),
  C++ (CMakeLists.txt), and Bash (no standard). The releaser doesn't attempt
  automated version bumps.
- **CHANGELOG via Bash only:** Using sed/echo for CHANGELOG modifications is
  less precise than Edit, but enforces the constraint that the agent cannot
  modify arbitrary files.
- **gh CLI required for PR creation:** If gh is not installed, the agent outputs
  the gh command for copy-paste rather than failing.

### Trade-offs Made
- **Safety over convenience:** Edit excluded from tools to prevent arbitrary file
  modifications, at the cost of less elegant CHANGELOG editing.
- **Sonnet over Opus:** Procedural workflow doesn't need opus reasoning, saving
  cost and latency.
- **Stop hook simplicity:** Only checks "branch pushed" — CHANGELOG and PR are
  user-skippable via approval gates, not enforced by the hook.

---

## Implementation Notes

### Key Decisions
- **SubagentStop timeout: 15s:** Release operations (git push, gh pr create) take
  longer than plan validation. 15s vs the planner's 10s.
- **CHANGELOG entries from slices:** Reading `.tdd-progress.md` produces cleaner
  entries than parsing git log (which has implementation-level commits).
- **Formatter detection:** Check for pubspec.yaml (Dart), CMakeLists.txt (C++),
  or .sh files (Bash) to determine which formatter to run.

### Future Improvements
- **Version bump integration:** Could add per-ecosystem version bump as an
  optional step once patterns stabilize.
- **Release notes generation:** Could generate richer release notes from the
  planning archive, not just CHANGELOG entries.

---

## References

### Related Code
- `hooks/check-tdd-progress.sh` — stop hook pattern
- `agents/tdd-verifier.md` — agent with stop hook pattern
- `skills/tdd-plan/SKILL.md` — skill with context: fork pattern
- `hooks/hooks.json` — existing hook configuration
- `docs/version-control-integration.md` — Layer 3 design spec

### Documentation
- `docs/version-control.md` — CHANGELOG format, PR guidelines
- `docs/tdd-workflow-extensibility-audit.md` — N6 tracking
- `docs/user-guide.md` — user-facing workflow documentation
