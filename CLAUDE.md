# Claude Code Configuration — TDD Workflow Plugin

This project uses the **tdd-workflow** plugin for test-driven development.
The plugin provides five specialized agents that collaborate through a
structured RED -> GREEN -> REFACTOR cycle.

## TDD Workflow

### Plugin Architecture

| Agent | Role | Mode |
|-------|------|------|
| **tdd-planner** | Researches codebase, decomposes features into testable slices, produces structured plans | Read-only |
| **tdd-implementer** | Writes tests first, then implementation, following the plan | Read-write |
| **tdd-verifier** | Runs the complete test suite and static analysis to validate each phase | Read-only |
| **tdd-releaser** | Finalizes completed features: CHANGELOG, push, PR creation | Read-write (Bash only) |
| **context-updater** | Researches latest framework versions, updates reference files | Read-write |

### Available Commands

- **`/tdd-plan <feature description>`** — Create a TDD implementation plan
- **`/tdd-implement`** — Start or resume TDD implementation for pending slices
- **`/tdd-release`** — Finalize and release a completed TDD feature
- **`/tdd-update-context`** — Update convention reference files to latest versions

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

Full details are available in the plugin's `dart-flutter-conventions` skill
(auto-loaded when editing `.dart` files). Key points:

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

Full details are available in the plugin's `cpp-testing-conventions` skill
(auto-loaded when editing `.cpp` or `.h` files). Key points:

- **Framework**: GoogleTest for unit tests, GoogleMock for test doubles
- **CMake Integration**: Tests registered via `add_test()` and run with `ctest`
- **Test Organization**: Mirror source structure in test directories

### Bash Testing

Full details are available in the plugin's bash testing conventions skill
(auto-loaded when editing `.sh` files). Key points:

- **Framework**: bashunit for unit and integration tests
- **Static Analysis**: shellcheck for linting and correctness checks
- **Test Organization**: Mirror source structure in `test/` with `_test.sh` suffix

### Version Control

- **Conventional Commits**: `test:`, `feat:`, `refactor:`, `fix:`, `docs:`, `chore:`
- **TDD Commit Sequence**: `test: add tests for <component>` -> `feat: implement <component>` -> `refactor: clean up <component>`
- **Documentation Updates**: CHANGELOG always, README when needed
- **Version Numbering**: Semantic versioning (MAJOR.MINOR.PATCH)

### Project Structure

- **Feature-Based Organization**: Recommended for medium/large apps (MVVM hybrid)
- **Directory Naming**: snake_case, descriptive names
- **File Organization**: Under 300-400 lines per file
- **Import Organization**: Dart SDK, packages, local (alphabetical)

---

## Pre-Commit Checklist

Before proposing commits, ensure:

- [ ] `flutter pub get` if dependencies changed
- [ ] `flutter analyze` or `dart analyze` passes with no issues
- [ ] `flutter test` or `ctest` or `bashunit` passes — all tests green
- [ ] `CHANGELOG.md` updated with changes
- [ ] `dart format` or `clang-format` or `shellcheck` applied
- [ ] No secrets or credentials in staged files

---

## Plugin Convention Skills

The plugin auto-loads convention skills based on file type:

| Skill | Triggers On | Reference Docs |
|-------|------------|----------------|
| `dart-flutter-conventions` | `.dart` files | test-patterns, test-recipes, mocking-guide, widget-testing, project-conventions, riverpod-guide |
| `cpp-testing-conventions` | `.cpp`, `.h` files | googletest-patterns, cmake-integration, googlemock-guide, clang-tooling |
| `bash-testing-conventions` | `.sh` files | bashunit-patterns, shellcheck-guide |

Planning reference templates (used by tdd-planner agent):
- `skills/tdd-plan/reference/tdd-task-template.md` — test specification format
- `skills/tdd-plan/reference/feature-notes-template.md` — planning archive format

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
