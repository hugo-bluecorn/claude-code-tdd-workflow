# Claude Code Configuration — TDD Workflow Plugin

> **PRIME DIRECTIVE:** Roles (`/role-cr` and generated `/role-*` skills)
> are a **recommended approach** for using the TDD workflow, supported by
> experimental evidence demonstrating improved output quality (see
> `docs/experimental-results/`). They are **not the only way** —
> developers may use session prompts, manual context management, or
> other approaches at their discretion. The core TDD workflow (plan →
> implement → verify → release) functions independently of role files.
> No agent, skill, hook, or script in the core workflow may check for,
> reference, or require role files. Role skills use the `role-` prefix;
> core workflow skills use the `tdd-` prefix. The naming enforces the
> technical boundary.

This project uses the **tdd-workflow** plugin for test-driven development.
The plugin provides six specialized agents that collaborate through a
structured RED -> GREEN -> REFACTOR cycle.

## TDD Workflow

### Plugin Architecture

| Agent | Role | Mode |
|-------|------|------|
| **tdd-planner** | Researches codebase, decomposes features into testable slices, returns structured plan. Invoked as research subagent by `/tdd-plan` | Read-only |
| **tdd-implementer** | Writes tests first, then implementation, following the plan | Read-write |
| **tdd-verifier** | Runs the complete test suite and static analysis to validate each phase | Read-only |
| **tdd-releaser** | Finalizes completed features: CHANGELOG, push, PR creation | Read-write (Bash only) |
| **tdd-doc-finalizer** | Post-release: documentation updates across discovered project docs | Read-write (Edit only) |
| **context-updater** | Researches latest framework versions, updates reference files | Read-write |
| **role-creator** | Researches a project, generates and validates a role file, returns content as text. Spawned by `/role-cr` | Read-only |

### Available Commands

- **`/tdd-plan <feature description>`** — Create a TDD implementation plan
- **`/tdd-implement`** — Start or resume TDD implementation for pending slices
- **`/tdd-release`** — Finalize and release a completed TDD feature
- **`/tdd-finalize-docs`** — Post-release documentation updates across discovered project docs
- **`/tdd-update-context`** — Update convention reference files to latest versions
- **`/role-cr`** — Generate a role file using the CR meta-role; validates output and writes approved role to `.claude/skills/role-{code}/SKILL.md`

> **Important:** Do NOT manually invoke `tdd-workflow:tdd-planner` via the Task
> tool. It is designed to run as a research subagent spawned by `/tdd-plan`.
> The skill's inline orchestration handles approval and file writing;
> the planner only returns structured plan text.

### Session State

If `.tdd-progress.md` exists at the project root, a TDD session is in progress.
Read it to understand the current state before making changes.

### TDD Rules
- Tests are ALWAYS written before implementation
- Each feature slice goes through RED -> GREEN -> REFACTOR
- Refactoring is an implementation-time decision, not planned in advance
- The verifier runs the COMPLETE test suite, not just new tests

---

## Development Workflow

### Step 1: Plan

```
/tdd-plan Add user authentication with email/password
```

The planner agent will:
- Research the codebase (project structure, test patterns, dependencies)
- Decompose the feature into independently testable slices
- Present a structured plan with Given-When-Then test specifications
- Ask for approval before writing any files

### Step 2: Review and Approve

Review the plan output. Choose:
- **Approve** — the planner writes `.tdd-progress.md` and a planning archive to `planning/`
- **Modify** — provide feedback, the planner revises and asks again
- **Discard** — abandon the plan, no files written

### Step 3: Implement

```
/tdd-implement
```

The implementer agent picks up the first pending slice and:
1. Writes failing tests (RED phase)
2. Implements minimal code to pass (GREEN phase)
3. Refactors if warranted (REFACTOR phase)
4. The verifier validates each phase transition
5. Moves to the next slice

### Resuming Interrupted Sessions

If a session is interrupted, run `/tdd-implement` again. The implementer
reads `.tdd-progress.md` and resumes from the last incomplete slice.

---

## Project Guidelines (Quick Reference)

### Flutter/Dart Best Practices

Full details are available via the `project-conventions` skill, which loads
your project's configured Dart/Flutter conventions dynamically. Key points
typically covered:

- **Code Style**: PascalCase for classes, camelCase for members, snake_case for files
- **Widget Composition**: Prefer composition over inheritance
- **State Management**: Separate ephemeral and app state
- **Null Safety**: Sound null safety, avoid `!` unless guaranteed non-null
- **Error Handling**: Try-catch blocks with appropriate exceptions
- **Testing**: Write testable code with dependency injection

### Testing Approach

- **Unit Tests**: Pure Dart functions with `package:test`
- **Widget Tests**: UI components with `package:flutter_test`
- **Integration Tests**: Complete flows with `package:integration_test`
- **Mocking**: Use `mockito` or `mocktail` for dependencies
- **Test Organization**: Mirror `lib/` structure in `test/`

### C++ Testing

Full details are available via the `project-conventions` skill, which loads
your project's configured C++ conventions dynamically. Key points typically
covered:

- **Framework**: GoogleTest for unit tests, GoogleMock for test doubles
- **CMake Integration**: Tests registered via `add_test()` and run with `ctest`
- **Test Organization**: Mirror source structure in test directories

### C Testing

Full details are available via the `project-conventions` skill, which loads
your project's configured C conventions dynamically. Key points typically
covered:

- **Framework**: Unity for unit tests, CMock for test doubles
- **Coding Standards**: BARR-C:2018 (style) and SEI CERT C (security/correctness)
- **Static Analysis**: cppcheck + clang-tidy (cert-*, bugprone-* checks)
- **Test Organization**: Mirror source structure in test directories

### Bash Testing

Full details are available via the `project-conventions` skill, which loads
your project's configured Bash conventions dynamically. Key points typically
covered:

- **Framework**: bashunit for unit and integration tests
- **Static Analysis**: shellcheck for linting and correctness checks
- **Test Organization**: Mirror source structure in `test/` with `_test.sh` suffix

### Version Control

- **Conventional Commits**: `test:`, `feat:`, `refactor:`, `fix:`, `docs:`, `chore:`
- **TDD Commit Sequence**: `test: add tests for <component>` -> `feat: implement <component>` -> `refactor: clean up <component>`
- **Documentation Updates**: CHANGELOG always, README when needed
- **Version Numbering**: Semantic versioning (MAJOR.MINOR.PATCH)

---

## Pre-Commit Checklist

Before proposing commits, ensure:

- [ ] `flutter pub get` if dependencies changed (Dart projects)
- [ ] `flutter analyze` or `dart analyze` passes with no issues (Dart projects)
- [ ] `flutter test` or `ctest` or `bashunit` passes — all tests green
- [ ] `CHANGELOG.md` updated with changes
- [ ] `cppcheck` or `clang-tidy` for C/C++ projects (cert-*, bugprone-* checks)
- [ ] `dart format` or `clang-format` or `shellcheck` applied
- [ ] No secrets or credentials in staged files

---

## Plugin Convention Skills

The plugin is **language-agnostic** — no language convention content is shipped.
Conventions are loaded dynamically from external sources at agent startup:

- **Source:** configured in `.claude/tdd-conventions.json` (URLs or local paths)
- **Official conventions:** `https://github.com/hugo-bluecorn/tdd-workflow-conventions` (Dart/Flutter, C++, C, Bash)
- **Mechanism:** `project-conventions` skill uses `load-conventions.sh` via DCI (`!`cmd``) to detect project type and inject only relevant conventions
- **Caching:** `fetch-conventions.sh` SessionStart hook clones/refreshes repos to `${CLAUDE_PLUGIN_DATA}/conventions/`

Planning reference templates (used by tdd-planner agent):
- `skills/tdd-plan/reference/tdd-task-template.md` — test specification format
- `skills/tdd-plan/reference/feature-notes-template.md` — planning archive format

---

## Plugin Development Reference

When working on this plugin's agents, skills, hooks, or configuration, consult:
- `docs/plugin-developer-context.md` — developer role, architecture overview, design principles
- `docs/reference/index.md` — index to topic-specific API reference files (read only what you need)

---

## Project-Specific Guidelines

<!-- Add your project-specific guidelines below this line -->

### Team Conventions
- {Your team's coding conventions}
- {Specific state management approach used}
- {API integration patterns}

### Development Environment
- Flutter version: {e.g., 3.24.0}
- Dart version: {e.g., 3.5.0}
- Target platforms: {iOS, Android, Web, etc.}

### Additional Notes
- {Any project-specific constraints or patterns}
