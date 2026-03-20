# Feature Notes: Project-Aware Convention Loading

**Created:** 2026-03-19
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Transform the TDD workflow plugin from language-specific to language-agnostic.
Currently, 3 agents hardcode all 4 language convention skills in their `skills:`
frontmatter, loading ~16,000 lines of irrelevant convention content per feature.
This change externalizes all language convention content to a separate GitHub repo
and replaces the 4 hardcoded skills with a single `project-conventions` meta-skill
that dynamically loads only relevant conventions at agent startup.

### Use Cases
- A Rust + ROS 2 project loads zero language conventions (no Dart/C++/C/Bash noise)
- A Flutter + C FFI project loads both Dart and C conventions automatically
- A team adds custom Python conventions by pointing to their own repo
- Adding Rust conventions to the ecosystem requires no plugin changes

### Context
- Issue: `issues/006-project-aware-convention-loading.md`
- Version: v2.0.0 (breaking change, no backward compatibility)
- Current state: v1.14.1, 683 tests, 4 convention skills bundled
- `` !`cmd` `` DCI confirmed working in `skills:` preloading (source code verified)
- `${CLAUDE_PLUGIN_DATA}` provides persistent cache across sessions

---

## Requirements Analysis

### Functional Requirements
1. External conventions repo `hugo-bluecorn/tdd-workflow-conventions` with 4 convention skills
2. `load-conventions.sh` detects project type and outputs relevant cached conventions
3. `project-conventions` skill uses DCI to invoke `load-conventions.sh`
4. `fetch-conventions.sh` SessionStart hook fetches/caches via `git clone`/`git pull`
5. Planner and implementer get `project-conventions`; context-updater gets nothing
6. `.claude/tdd-conventions.json` config format respected
7. All 4 convention skills removed from plugin

### Non-Functional Requirements
- All tests pass (shellcheck clean, bashunit green)
- Documentation updated (CLAUDE.md, README.md, user-guide.md, CHANGELOG.md)
- No convention content remains in plugin

### Integration Points
- SessionStart hook integrates with hooks.json
- `project-conventions` skill integrates with agent `skills:` frontmatter
- Config file integrates with consuming project's `.claude/` directory
- External repo integrates with git clone/pull

---

## Implementation Details

### Architectural Approach
```
SessionStart hook                    Agent startup
─────────────────                    ─────────────
Check ${CLAUDE_PLUGIN_DATA}/    →    skills: [project-conventions]
  conventions/ for cached repos           │
If missing: git clone                !`load-conventions.sh`
If stale: git pull                        │
Store locally                        Reads cached files, detects
                                     project type, outputs only
                                     relevant conventions
                                          │
                                     Agent receives project-specific
                                     convention content ✓
```

Convention sources can be URLs (cloned/cached by SessionStart hook) or local
paths (read directly by load-conventions.sh). Config via `.claude/tdd-conventions.json`.

### Design Patterns
- **Dependency Injection:** Convention content injected at runtime, not bundled
- **Dynamic Context Injection (DCI):** `` !`cmd` `` in skill body executes at load time
- **Cache-aside:** SessionStart hook manages cache; load script reads from it

### File Structure
```
scripts/
  load-conventions.sh          # Core: project detection + convention output
hooks/
  fetch-conventions.sh         # SessionStart: git clone/pull convention repos
skills/
  project-conventions/
    SKILL.md                   # Meta-skill with DCI invocation
```

### Naming Conventions
- Scripts: kebab-case (`load-conventions.sh`, `fetch-conventions.sh`)
- Tests: snake_case (`load_conventions_test.sh`)
- Skills: kebab-case directories, `SKILL.md` inside

---

## TDD Approach

### Slice Decomposition

The feature is broken into 10 independently testable slices (0-9), each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 0 | Create external conventions repo | None |
| 1 | load-conventions.sh core detection | 0 |
| 2 | tdd-conventions.json config reading | 0, 1 |
| 3 | project-conventions SKILL.md | 1 |
| 4 | Agent frontmatter migration | 3 |
| 5 | fetch-conventions.sh SessionStart hook | 0, 2 |
| 6 | Convention skill removal | 4 |
| 7 | Breaking test cleanup | 4, 6 |
| 8 | Planner body cleanup | 4 |
| 9 | Documentation updates | 4, 5, 6, 7, 8 |

---

## Dependencies

### External Packages
- `jq`: JSON parsing for `.claude/tdd-conventions.json`
- `git`: Cloning and pulling convention repos
- `gh`: Creating the external conventions repo (Slice 0 only)

### Internal Dependencies
- `hooks/hooks.json`: SessionStart hook registration
- `scripts/detect-project-context.sh`: Existing project detection (preserved)
- Agent frontmatter: `skills:` field modification

---

## Known Limitations / Trade-offs

### Limitations
- Convention content requires network access on first run (SessionStart clone)
- Cache staleness depends on session frequency (refreshed via git pull each session)
- No cross-plugin convention discovery (each plugin manages its own)

### Trade-offs Made
- **Real repo tests vs mocks:** Chose real repo for end-to-end validation at cost of network dependency in tests
- **git clone/pull vs tarball:** Chose git for simplicity; tarballs would be faster but add complexity
- **Context-updater excluded:** Scope redesign deferred; loses convention update capability temporarily
- **Breaking change (v2.0):** Clean slate over migration path; simpler implementation

---

## Implementation Notes

### Key Decisions
- **v2.0 breaking change:** No backward compatibility. Users must configure convention sources.
- **Context-updater gets nothing:** Scope redesign deferred. Convention skills simply removed.
- **git clone for fresh, git pull for stale:** Simple, reliable, no sparse checkout complexity.
- **Tests use real repo:** End-to-end validation against `hugo-bluecorn/tdd-workflow-conventions`.

### Future Improvements
- `/tdd-create-convention` scaffolding skill for new convention packages
- Context-updater redesign to work with external conventions
- Convention version pinning (specific git tags/commits)
- Convention caching with configurable TTL

### Potential Refactoring
- `load-conventions.sh` project detection logic could be shared with `detect-project-context.sh`
- Convention output format could be standardized across all convention packages

---

## References

### Related Code
- `agents/tdd-planner.md`, `agents/tdd-implementer.md`, `agents/context-updater.md`
- `skills/dart-flutter-conventions/`, `skills/cpp-testing-conventions/`, `skills/c-conventions/`, `skills/bash-testing-conventions/`
- `hooks/hooks.json`
- `scripts/detect-project-context.sh`

### Documentation
- `issues/006-project-aware-convention-loading.md` — full issue with research findings
- `docs/plugin-developer-context.md` — plugin architecture overview
- `docs/reference/index.md` — API reference index

### Issues / PRs
- Issue 006: Project-Aware Convention Loading
- Blocks: `/tdd-init-roles`, future convention skills
