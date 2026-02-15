# Feature Notes: Bash Testing Support (bashunit + shellcheck)

**Created:** 2026-02-14
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
The TDD workflow plugin currently supports two languages: Dart/Flutter and C++. Adding bash/shell script as a third supported language enables the plugin to TDD its own hook scripts, making it truly language-agnostic and self-dogfooding. This closes the gap where the plugin enforces test-first development for user code but cannot apply the same discipline to its own shell-based infrastructure.

### Use Cases
- TDD'ing new hook scripts (validate-tdd-order.sh, auto-run-tests.sh) with bashunit before writing implementation
- Running shellcheck as static analysis on all `.sh` files during verification, catching common bash pitfalls
- Using the same planner/implementer/verifier workflow for bash scripts as for Dart and C++ code

### Context
The plugin's hook system (`hooks/validate-tdd-order.sh`, `hooks/auto-run-tests.sh`) is written in bash but has no test coverage. The existing convention skills (`dart-flutter-conventions`, `cpp-testing-conventions`) follow an identical pattern: SKILL.md with YAML frontmatter, a `reference/` directory with framework-specific guides, and integration with the planner/implementer/verifier agents. The bash skill must follow this exact pattern to be loadable by the same infrastructure.

---

## Requirements Analysis

### Functional Requirements
1. New `skills/bash-testing-conventions/` directory with SKILL.md (matching existing skill YAML frontmatter pattern) and reference docs for bashunit patterns and shellcheck usage
2. `validate-tdd-order.sh` hook extended to recognize `*_test.sh` as test files and `.sh` as source files requiring test-first enforcement
3. `auto-run-tests.sh` hook extended to detect `.sh` file changes and run bashunit on the matching `_test.sh` file, with graceful degradation when bashunit is not installed
4. Verifier agent (`agents/tdd-verifier.md`) updated to run bashunit for test suite execution and shellcheck for static analysis on bash projects
5. `settings.local.json` updated with `Bash(shellcheck *)` and `Bash(bashunit *)` permissions (space syntax, not deprecated colon syntax)
6. Agent frontmatter (`tdd-planner.md`, `tdd-implementer.md`) updated to list `bash-testing-conventions` as a loadable skill
7. `tdd-plan/SKILL.md` updated with bash project detection and bashunit framework identification
8. Documentation (CLAUDE.md, README.md, CHANGELOG.md) updated to reference bash as a third language, including installation instructions and permission setup notes

### Non-Functional Requirements
- All existing hook scripts must pass shellcheck after changes
- Documentation depth for bash skill must match existing Dart and C++ skills
- No changes to existing Dart/Flutter or C++ behavior — bash is additive only

### Integration Points
- **Hook system:** Both `validate-tdd-order.sh` (PreToolUse) and `auto-run-tests.sh` (PostToolUse) receive JSON from Claude Code on stdin and must parse `tool_input.file_path`
- **Agent system:** Planner and implementer agents load convention skills via frontmatter `skills` lists
- **Settings:** `settings.local.json` is gitignored (development-environment only) — users must configure permissions themselves, documented in README.md
- **External tools:** bashunit (test runner) and shellcheck (static analyzer) must be installed separately

---

## Implementation Details

### Architectural Approach
Follow the existing plugin architecture exactly. Each supported language has:
1. A convention skill directory (`skills/{lang}-conventions/`) with SKILL.md and `reference/` docs
2. Hook detection logic in `validate-tdd-order.sh` (test file regex, source file regex)
3. Hook test runner logic in `auto-run-tests.sh` (language-specific elif branch)
4. Verifier instructions in `agents/tdd-verifier.md`
5. Skill references in agent frontmatter

Bash support follows this same pattern with no architectural changes.

### Design Patterns
- **Convention-over-configuration:** Test files use `_test.sh` suffix, mirroring `_test.dart` and `_test.cpp`
- **Graceful degradation:** Hooks check for bashunit/shellcheck availability and produce informative messages when missing, rather than crashing
- **Additive changes only:** All regex patterns are extended with `|sh` rather than restructured

### File Structure
```
New files:
  skills/bash-testing-conventions/
    SKILL.md
    reference/
      bashunit-patterns.md
      shellcheck-guide.md
  test/
    skills/
      bash_testing_conventions_test.sh
      bashunit_patterns_test.sh
      shellcheck_guide_test.sh
    hooks/
      validate_tdd_order_test.sh
      auto_run_tests_test.sh
    agents/
      tdd_verifier_bash_test.sh
    integration/
      bash_agent_skills_test.sh
      bash_documentation_test.sh

Modified files:
  hooks/validate-tdd-order.sh
  hooks/auto-run-tests.sh
  agents/tdd-verifier.md
  .claude/settings.local.json
  CLAUDE.md
  README.md
  agents/tdd-planner.md
  agents/tdd-implementer.md
  skills/tdd-plan/SKILL.md
  CHANGELOG.md
```

### Naming Conventions
- Files: snake_case (`bash_testing_conventions_test.sh`)
- Test functions: `test_` prefix (`test_allows_test_sh_files`)
- Variables: snake_case (`FILE_PATH`, `TEST_FILE`)
- Skills: kebab-case (`bash-testing-conventions`)

---

## TDD Approach

### Slice Decomposition

The feature is broken into 8 independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit
**Static Analysis:** shellcheck
**Test Command:** `bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | bash-testing-conventions Skill Structure | None |
| 2 | bashunit-patterns.md Reference Document | Slice 1 |
| 3 | shellcheck-guide.md Reference Document | Slice 1 |
| 4 | validate-tdd-order.sh Recognizes Bash Test Files | None |
| 5 | auto-run-tests.sh Runs bashunit for Shell Files | None |
| 6 | Verifier Agent and Settings Update | Slices 1-5 |
| 7a | Agent Frontmatter + tdd-plan SKILL.md | Slices 1-6 |
| 7b | Documentation (CLAUDE.md, README.md, CHANGELOG.md) | Slices 1-7a |

---

## Dependencies

### External Packages
- **bashunit:** Bash testing framework. Install via `curl -s https://bashunit.typeddevs.com/install.sh | bash`. No version constraint — use latest.
- **shellcheck:** Shell script static analyzer. Install via package manager (`apt install shellcheck`, `brew install shellcheck`). Already available on many systems at `/usr/bin/shellcheck`.

### Internal Dependencies
- **Hook JSON parsing:** Both hooks use `jq` to parse `tool_input.file_path` from stdin — jq must be available.
- **Git:** `validate-tdd-order.sh` uses `git diff --name-only HEAD` to check for recent test file modifications.

---

## Known Limitations / Trade-offs

### Limitations
- **Bash-only scope:** The `_test.sh` convention and bashunit assume bash scripts. Other shell dialects (zsh, fish, dash) are out of scope. Could be extended later if needed.
- **No build system integration:** Unlike C++ with CMake, bash has no build system. The auto-run-tests hook runs bashunit directly on test files rather than through a build pipeline.
- **settings.local.json is gitignored:** Permission configuration for shellcheck/bashunit cannot be distributed to users automatically. They must manually add entries to their own settings.

### Trade-offs Made
- **Space syntax for new permissions vs. updating existing colon syntax:** New permissions use the current `Bash(command *)` syntax while existing entries keep the deprecated `Bash(command:*)` syntax. This avoids unnecessary churn on unrelated entries while following best practices for new code.
- **Sequential slice ordering vs. parallel:** Slices 1-5 could theoretically run in parallel, but the TDD implementer processes them sequentially. The dependency graph ensures correct ordering if parallelism is added later.

---

## Implementation Notes

### Key Decisions
- **`_test.sh` suffix convention:** Mirrors `_test.dart` and `_test.cpp` for consistency. Keeps the regex pattern extension minimal (`|sh`).
- **Source-to-test path mapping:** `hooks/foo.sh` maps to `test/hooks/foo_test.sh` (prepend `test/`, insert `_test` before `.sh`). Same "mirror in test/" principle as Dart's `lib/` -> `test/` mapping.
- **PreToolUse JSON format:** Tests use the real Claude Code format (`{"tool_name": "Write", "tool_input": {"file_path": "..."}}`) rather than simplified structures.
- **Graceful degradation:** Hooks produce informative JSON messages when bashunit is not installed, rather than failing silently or crashing.

### Future Improvements
- **Dogfooding:** Once bash support works, the plugin's own hooks can be TDD'd using bashunit, validating the entire workflow end-to-end.
- **Config-driven language detection:** The growing regex in validate-tdd-order.sh could be externalized to a configuration file listing supported extensions.
- **Auto-install:** Hooks could offer to install bashunit automatically when it's missing, similar to how some tools handle missing dependencies.

### Potential Refactoring
- The three `elif` branches in auto-run-tests.sh (dart, cpp, bash) could be refactored into a function dispatch table — left for implementer to decide at implementation time.

---

## References

### Related Code
- `hooks/validate-tdd-order.sh` — PreToolUse hook, currently handles dart/cpp
- `hooks/auto-run-tests.sh` — PostToolUse hook, currently handles dart/cpp
- `agents/tdd-verifier.md` — Verifier agent instructions
- `skills/dart-flutter-conventions/SKILL.md` — Reference pattern for convention skills
- `skills/cpp-testing-conventions/SKILL.md` — Reference pattern for convention skills
- `.claude/settings.local.json` — Development permissions (gitignored)

### Documentation
- bashunit documentation: https://bashunit.typeddevs.com/
- shellcheck wiki: https://github.com/koalaman/shellcheck/wiki
- Claude Code hooks documentation: https://docs.anthropic.com/en/docs/claude-code/hooks
- Claude Code permissions format: space-based syntax `Bash(command *)` (colon syntax deprecated)

### Issues / PRs
- No related issues — this is a new feature request
