# User Guide

This guide walks through using the tdd-workflow plugin from start to finish.

---

## Prerequisites

- Claude Code installed with plugin support
- A Dart/Flutter or C++ project with test infrastructure already set up
  - Dart: `flutter_test` or `package:test` in `pubspec.yaml`
  - C++: GoogleTest available via CMake, with a `build/` directory configured

---

## Installing the Plugin

```bash
claude plugin install <path-to-tdd-workflow>
```

After installation, verify it loaded:

```bash
claude --debug
```

Look for `loading plugin: tdd-workflow` in the output. The `/tdd-plan` command should appear in your skill list.

---

## Starting a TDD Session

### 1. Invoke the planner

Type the `/tdd-plan` command followed by a description of what you want to build:

```
/tdd-plan Implement a LocationService that wraps the geolocator package
```

You can also use natural language that includes phrases like "implement with TDD", "TDD plan", or "test-driven" and Claude may invoke the skill automatically.

### 2. What happens next

The plugin forks a **fresh context** (separate from your main conversation) and launches the **tdd-planner** agent. This agent:

1. Auto-detects your test runner and frameworks
2. Reads your project structure, existing tests, and architecture
3. May ask you clarifying questions about scope or design decisions
4. Decomposes the feature into ordered **slices** — each one a self-contained test-implement-refactor cycle
5. Writes the plan to two locations:
   - `.tdd-progress.md` at your project root (the live tracking file)
   - `planning/YYYYMMDD_HHMM_feature_name.md` (read-only archive)

### 3. Review the plan

The planner presents the full plan and asks you to **approve**, **revise**, or **reject** it.

- **Approve**: proceed to implementation
- **Revise**: tell the planner what to change (scope, ordering, missing cases)
- **Reject**: discard the plan entirely

Take time here. A good plan prevents wasted implementation cycles. Each slice should have:

- **Test Specification**: what behavior to assert, test file path, edge cases
- **Implementation Scope**: files to create/modify, public API surface
- **Verification Criteria**: expected test output, analysis requirements

---

## The Implementation Loop

After plan approval, each slice goes through a three-phase cycle. Claude orchestrates this by invoking two agents per slice.

### Phase 1: RED — The implementer writes a failing test

The **tdd-implementer** agent receives the slice specification and:

1. Writes the test file at the specified path
2. Runs the test
3. Confirms it **fails** (this is the "red" in red-green-refactor)

If the test passes without any implementation, the test is wrong and the implementer rewrites it.

**What the hooks do during RED:**
- `validate-tdd-order.sh` allows writes to test files freely
- `auto-run-tests.sh` runs the matching test after every file save, giving immediate feedback

### Phase 2: GREEN — The implementer writes minimal code

The implementer then writes the **minimum** code needed to make the test pass:

1. Creates or modifies the implementation file
2. Runs the test
3. Confirms it **passes**

**What the hooks do during GREEN:**
- `validate-tdd-order.sh` checks that test files were modified before allowing implementation file writes. If you see `BLOCKED: No test files have been written yet`, it means the implementer tried to write code before writing a test — the hook caught it.
- `auto-run-tests.sh` runs the test after each file change

### Phase 3: REFACTOR — The implementer cleans up

The implementer looks for opportunities to improve code quality:

1. Removes duplication, improves naming, simplifies logic
2. Runs the test again to confirm it still passes
3. Skips this phase if the code is already clean

### Phase 4: VERIFY — The verifier checks everything

After the implementer finishes, the **tdd-verifier** agent runs. It has no knowledge of what was just implemented — it only sees the code on disk. It:

1. Runs the **complete** test suite (not just new tests)
2. Runs static analysis (`dart analyze`, `flutter analyze`, or clang-tidy)
3. Checks coverage if tooling is available
4. Verifies each criterion from the plan slice
5. Reports a structured **PASS** or **FAIL** verdict

If the verifier reports **PASS**, the workflow moves to the next slice. If **FAIL**, the implementer is invoked again to fix the issues.

---

## Understanding `.tdd-progress.md`

This file is the central state tracker. It lives at your project root and is updated throughout the session.

Typical structure:

```markdown
# TDD Progress: LocationService

## Slice 1: Basic position retrieval
- Status: PASS
- Test: test/services/location_service_test.dart
- Implementation: lib/services/location_service.dart

## Slice 2: Permission handling
- Status: IN_PROGRESS
- Test: test/services/location_service_permission_test.dart

## Slice 3: Error scenarios
- Status: PENDING
```

The **Stop hook** checks this file before allowing your Claude session to end. If slices are still PENDING or IN_PROGRESS, it will prompt Claude to continue working.

---

## What the Hooks Do

The plugin installs five hooks that enforce TDD discipline automatically.

### Command Hooks (deterministic, on the implementer)

| Hook | When | What it does |
|------|------|--------------|
| `validate-tdd-order.sh` | Before every Write/Edit | Blocks implementation file writes if no test files have been modified yet. Ensures test-first ordering. |
| `auto-run-tests.sh` | After every Write/Edit | Runs the relevant test file and returns output as a system message. Dart files map `lib/foo.dart` to `test/foo_test.dart`. C++ files trigger `cmake --build`. |

### Prompt Hooks (LLM-evaluated)

| Hook | When | What it does |
|------|------|--------------|
| SubagentStop (implementer) | When implementer finishes | Checks that all three R-G-R phases completed with test output. Blocks if incomplete. |
| SubagentStop (verifier) | When verifier finishes | Checks that full test suite, static analysis, and structured report were produced. Blocks if incomplete. |
| Stop (session) | When Claude tries to stop | Checks `.tdd-progress.md` for remaining slices. Blocks session end if work remains. |

### When a hook blocks

If you see a hook block message:

- **"No test files have been written yet"** — The implementer tried to skip to implementation. It should write a test first.
- **"Incomplete R-G-R cycle"** — The implementer tried to finish without completing all three phases.
- **"Verification incomplete"** — The verifier tried to report results without running all checks.
- **"TDD session has remaining slices"** — Claude tried to end the session with unfinished work.

These are guardrails, not errors. The agent will self-correct and continue.

---

## Committing Your Work

Each TDD slice maps to a natural commit pattern:

```
test: add tests for LocationService          # RED phase
feat: implement LocationService              # GREEN phase
refactor: clean up LocationService           # REFACTOR phase (if applicable)
```

See `docs/version-control.md` for the full commit message format and branching strategy.

---

## Resuming an Interrupted Session

If your session ends mid-workflow (timeout, crash, manual exit):

1. Start a new Claude session in the same project
2. Claude reads `CLAUDE.md` which tells it to check for `.tdd-progress.md`
3. If the file exists, Claude will see which slices are done and which remain
4. You can say "continue the TDD session" or "resume from slice 3"

The `planning/` archive provides the original plan for reference if `.tdd-progress.md` gets corrupted.

---

## Configuration

### Switching the planner to Opus

For complex features where plan quality is critical, edit `agents/tdd-planner.md` and change:

```yaml
model: sonnet
```

to:

```yaml
model: opus
```

The tradeoff is slower planning but more thorough codebase analysis.

### Enabling web access for the planner

To let the planner look up API docs on pub.dev or reference documentation, edit `agents/tdd-planner.md` and add `WebFetch, WebSearch` to the tools list:

```yaml
tools: Read, Glob, Grep, Bash, AskUserQuestion, WebFetch, WebSearch
```

### Adjusting permissionMode

The planner runs in `permissionMode: plan` by default, which may block some Bash writes. If the planner cannot write `.tdd-progress.md`, you have two options:

1. Remove `permissionMode: plan` from `agents/tdd-planner.md` (the `disallowedTools` list still prevents code writes)
2. Approve the write when prompted

### Increasing agent turn limits

If a complex slice needs more iterations, edit the `maxTurns` value in the relevant agent file:

- `agents/tdd-implementer.md` — default 50
- `agents/tdd-verifier.md` — default 20
- `agents/tdd-planner.md` — default 30

---

## Troubleshooting

### "No matching test file found"

The `auto-run-tests.sh` hook maps Dart source files from `lib/` to `test/` by convention (e.g., `lib/services/foo.dart` becomes `test/services/foo_test.dart`). If your project uses a different structure, the auto-run won't find the test. The implementer will still run tests manually.

### Hook not firing

Check that the hook scripts are executable:

```bash
ls -la <plugin-path>/hooks/*.sh
```

Both files should have the `x` permission bit. If not:

```bash
chmod +x <plugin-path>/hooks/*.sh
```

### Planner can't detect test framework

The auto-detection in `/tdd-plan` checks for `pubspec.yaml` (Dart) or `CMakeLists.txt` (C++). If your project uses a non-standard setup, the planner will still research your codebase — the auto-detection just provides initial hints.

### Verifier reports FAIL but tests look correct

The verifier runs the **complete** test suite, not just the new tests. A FAIL may come from a pre-existing broken test or a regression in another part of the codebase. Check the verifier's report for the specific failure paths.

### Session won't end

The Stop hook prevents Claude from ending the session while `.tdd-progress.md` has PENDING or IN_PROGRESS slices. To end early:

- Update the remaining slices to a terminal status manually
- Or delete `.tdd-progress.md` from the project root

---

## Reference

- `README.md` — Architecture overview and component listing
- `docs/version-control.md` — Git workflow and commit conventions
- `skills/dart-flutter-conventions/` — Dart/Flutter testing patterns and project conventions
- `skills/cpp-testing-conventions/` — C++ GoogleTest patterns and CMake integration
