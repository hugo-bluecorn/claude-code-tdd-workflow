# Feature Notes: C Language Conventions

**Created:** 2026-03-02
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose

The TDD workflow plugin has zero support for plain C projects. No convention
skill loads on `.c` files, no reference docs exist for any C test framework,
`detect-project-context.sh` doesn't count `*_test.c` files, and agents have
no C-specific guidance. This feature adds first-class C language support,
making agents write correct, standardized C code and tests regardless of
build system.

### Use Cases
- Developer runs `/tdd-plan` on a C project and the planner loads C conventions, detects Unity/CMock, and produces C-appropriate test specifications
- Developer runs `/tdd-implement` on a C project and the implementer writes Unity tests following BARR-C naming and SEI CERT C safety rules
- Developer runs `/tdd-update-context` and the context-updater scans C convention reference files for staleness

### Context

The anchor project is `zenoh_dart` — a Dart FFI plugin with a pure C shim layer.
Exploration revealed: CMake + Ninja + clang build, no formal test framework
(raw assert.h), snake_case with prefix namespacing, no static analysis configured.
C projects differ fundamentally from C++ in test framework (Unity vs GoogleTest),
mocking (CMock vs GMock), coding standards (BARR-C vs Google C++), and idioms.
The existing C++ conventions are build-system-coupled (cmake-integration.md,
hardcoded ctest commands); C conventions follow the correct build-system-agnostic
philosophy and become the model for future C++ alignment.

---

## Requirements Analysis

### Functional Requirements
1. `skills/c-conventions/SKILL.md` auto-loads on `.c` files with `user-invocable: false`
2. Three reference documents covering testing patterns, coding standards, and static analysis
3. `detect-project-context.sh` counts `*_test.c` files in test file count
4. Agents tdd-planner, tdd-implementer, context-updater include `c-conventions` in skills list
5. tdd-planner body includes C project detection and convention loading instructions
6. tdd-verifier mentions C explicitly in verification checklist
7. CLAUDE.md and README.md document the new skill

### Non-Functional Requirements
- All existing 501 tests still pass
- shellcheck clean on all modified scripts
- No unfilled template placeholders in new files
- C-specific docs do not bleed Dart or C++ content

### Integration Points
- `detect-project-context.sh` — test file counting (minimal change)
- Agent frontmatter skills lists — preload mechanism
- Planner body — project detection and convention loading
- Verifier checklist — test runner and static analysis entries
- CLAUDE.md auto-load table — skill trigger documentation
- README.md — skills table, file structure, overview

---

## Implementation Details

### Architectural Approach

Follow the bash-testing-conventions pattern exactly. The bash skill was the
most recently added via TDD and has the most thorough test coverage. The C
conventions skill mirrors its structure: SKILL.md frontmatter pattern,
reference doc organization, test file patterns, and integration tests.

Convention docs describe what good C code and tests look like. They reference
CMake examples where concrete syntax is needed (Unity FetchContent,
compile_commands.json) but frame these as "common setup" not "required setup."
The plugin does not own the build system.

### Design Patterns
- **Convention skill pattern**: SKILL.md with frontmatter + reference docs directory, matching existing dart-flutter-conventions, cpp-testing-conventions, and bash-testing-conventions
- **Build-system-agnostic content**: Prescriptive about code/test quality, descriptive about build integration
- **Dual coding standard**: BARR-C:2018 (style + bug prevention) + SEI CERT C (security + correctness) — together they cover style + correctness + security without commercial tools

### File Structure
```
skills/c-conventions/
  SKILL.md                              (NEW)
  reference/
    c-testing-patterns.md               (NEW)
    c-coding-standards.md               (NEW)
    c-static-analysis.md                (NEW)
scripts/
  detect-project-context.sh             (MODIFIED)
agents/
  tdd-planner.md                        (MODIFIED)
  tdd-implementer.md                    (MODIFIED)
  context-updater.md                    (MODIFIED)
  tdd-verifier.md                       (MODIFIED)
CLAUDE.md                               (MODIFIED)
README.md                               (MODIFIED)
test/scripts/
  detect_project_context_test.sh        (NEW)
test/skills/
  c_conventions_test.sh                 (NEW)
  c_testing_patterns_test.sh            (NEW)
  c_coding_standards_test.sh            (NEW)
  c_static_analysis_test.sh            (NEW)
test/integration/
  c_agent_skills_test.sh                (NEW)
  c_documentation_test.sh               (NEW)
```

### Naming Conventions
- Test files: `snake_case` with `_test.sh` suffix
- Skill directory: `kebab-case` (`c-conventions`)
- Reference files: `kebab-case` with `.md` extension
- Following all existing project conventions

---

## TDD Approach

### Slice Decomposition

The feature is broken into 7 independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | detect-project-context.sh Counts C Test Files | None |
| 2 | C Conventions SKILL.md Structure | None |
| 3 | c-testing-patterns.md Reference Document | Slice 2 |
| 4 | c-coding-standards.md Reference Document | Slice 2 |
| 5 | c-static-analysis.md Reference Document | Slice 2 |
| 6 | Agent Skill Preloads | Slice 2 |
| 7 | Verifier + CLAUDE.md + README.md Documentation | Slices 1-6 |

---

## Dependencies

### External Packages
- None required (all tools already available)

### Internal Dependencies
- bashunit (already in `./lib/bashunit`)
- shellcheck (already installed)
- Existing convention skills as structural templates

---

## Known Limitations / Trade-offs

### Limitations
- **No monorepo support**: Detection doesn't handle mixed C+Dart projects (deferred to future issue)
- **No multi-runner logic**: Verifier assumes single test suite per project (deferred)
- **CMake-centric examples**: Build examples use CMake syntax; Make/Meson users must adapt

### Trade-offs Made
- **Unity/CMock over GoogleTest**: GMock can't mock C functions, making GoogleTest inadequate for C TDD. Unity is pure C with native mocking via CMock. Trade-off: less familiar to C++ developers, but correct for C.
- **BARR-C + CERT C over MISRA**: MISRA C:2025 is paywalled and requires commercial tooling. BARR-C + CERT C are free, enforceable with open-source tools, and together cover the same ground. Trade-off: no MISRA compliance claim.
- **3 reference files (not 4)**: Dropped c-build-systems.md. The plugin doesn't own the build system, and the planner can read project files directly. Trade-off: no build system guidance, but that's the correct scope boundary.

---

## Implementation Notes

### Key Decisions
- **Separate C and C++ skills**: Different frameworks, standards, idioms — merging would dilute both
- **Build-system-agnostic**: Convention docs prescribe code/test quality, not build setup
- **Minimal detect script change**: Only add `*_test.c` to find pattern; planner reads project files for everything else
- **Planner body gets C detection**: Three additions — convention loading, `*_test.c` in find, C framework identification

### Future Improvements
- **C++ convention alignment**: C becomes the model for build-system-agnostic conventions; C++ should be refactored to match
- **Project scaffolding plugin**: Separate plugin to fill the gap that `flutter create` fills for Dart — `/scaffold-c-project --std=c23 --test=unity`
- **Monorepo detection**: Handle mixed-language projects with multiple test runners

### Potential Refactoring
- C++ conventions could be refactored to follow C's build-system-agnostic pattern (separate issue)
- detect-project-context.sh could gain richer C detection in a future pass

---

## References

### Related Code
- `skills/bash-testing-conventions/` — structural template for skill organization
- `skills/cpp-testing-conventions/` — existing C++ conventions (build-system-coupled)
- `skills/dart-flutter-conventions/` — most comprehensive convention skill
- `test/skills/bash_testing_conventions_test.sh` — test pattern template
- `test/integration/bash_agent_skills_test.sh` — integration test template
- `test/integration/bash_documentation_test.sh` — documentation test template
- `scripts/detect-project-context.sh` — detection script to modify

### Documentation
- `issues/003-c-language-conventions.md` — full issue specification with source-of-truth URLs
- `memory/c-conventions-plan.md` — exploration context from zenoh_dart audit
- `memory/c-conventions-dry-run.md` — dry run findings (3 in scope, 3 deferred)

### Issues / PRs
- Issue 002 (PR #7, merged) — prerequisite (v1.12.0 baseline)
- Issue 003 — this feature
