# User Guide

This guide walks through using the tdd-workflow plugin from start to finish.

---

## Prerequisites

- Claude Code installed with plugin support
- A Dart/Flutter, C++, or Bash/Shell project with test infrastructure already set up
  - Dart: `flutter_test` or `package:test` in `pubspec.yaml`
  - C++: GoogleTest available via CMake, with a `build/` directory configured
  - Bash: bashunit installed, shellcheck available

---

## Installing the Plugin

```bash
claude plugin install <path-to-tdd-workflow>
```

After installation, verify it loaded:

```bash
claude --debug
```

Look for `loading plugin: tdd-workflow` in the output. The `/tdd-plan`, `/tdd-implement`, and `/tdd-release` commands should appear in your skill list.

---

## Updating the Plugin

How you update depends on how the plugin was installed.

### Marketplace-managed plugin

If the plugin was installed via a local or remote marketplace (check `~/.claude/settings.json` for an entry like `tdd-workflow@<marketplace-name>`):

```bash
claude plugin marketplace update <marketplace-name>
```

For example, with a local marketplace called `local-plugins`:

```bash
claude plugin marketplace update local-plugins
```

This refreshes the marketplace index, picks up the new version from `plugin.json`, and updates the cached copy.

### Directly installed plugin

If the plugin was installed directly (not through a marketplace):

```bash
claude plugin update tdd-workflow
```

You can target a specific scope with `-s user`, `-s project`, or `-s local`.

### Local development

If you're loading the plugin with `--plugin-dir`:

```bash
claude --plugin-dir ./path/to/tdd-workflow
```

No update step is needed — changes are picked up immediately since there's no caching.

### Version bumps matter

The plugin system uses the `version` field in `.claude-plugin/plugin.json` to detect updates. Always bump the version before updating:

```json
{
  "version": "1.8.2"
}
```

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

### 4. Start implementation

After the planner writes `.tdd-progress.md`, run:

```
/tdd-implement
```

This reads the progress file, finds pending slices, and runs each through the red-green-refactor cycle with automated verification.

---

## The Implementation Loop

`/tdd-implement` orchestrates the implementation. For each pending slice, it invokes two agents in sequence.

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

The **Stop hook** (`check-tdd-progress.sh`) reads this file before allowing your Claude session to end. It counts slices by `## Slice` headers and checks their status lines. If any slices are not in a terminal state (PASS, DONE, COMPLETE, FAIL, SKIP), it blocks the stop and tells Claude how many slices remain.

---

## What the Hooks Do

The plugin uses hooks to enforce TDD discipline automatically.

### Command Hooks (deterministic)

| Hook | Event | Agent | What it does |
|------|-------|-------|--------------|
| `validate-tdd-order.sh` | PreToolUse (Write/Edit) | implementer | Blocks implementation file writes if no test files have been modified yet |
| `auto-run-tests.sh` | PostToolUse (Write/Edit) | implementer | Runs tests after every file change, returns output as system message |
| `planner-bash-guard.sh` | PreToolUse (Bash) | planner | Allowlists read-only commands; blocks writes and destructive operations |
| `validate-plan-output.sh` | Stop + SubagentStop | planner | Enforces plan approval via AskUserQuestion with retry counter; validates required sections and no refactoring leak |
| `check-tdd-progress.sh` | Stop | main thread | Prevents session end with pending slices |
| `check-release-complete.sh` | Stop + SubagentStop | releaser | Validates branch is pushed to remote before release completes |
| SubagentStart | SubagentStart | planner | Injects git branch, last commit, dirty file count as additional context |

### Prompt Hooks (LLM-evaluated)

| Hook | When | What it does |
|------|------|--------------|
| SubagentStop (implementer) | When implementer finishes | Checks that all three R-G-R phases completed with test output. Blocks if incomplete. |

### When a hook blocks

If you see a hook block message:

- **"No test files have been written yet"** — The implementer tried to skip to implementation. It should write a test first.
- **"Incomplete R-G-R cycle"** — The implementer tried to finish without completing all three phases.
- **"Verification incomplete"** — The verifier tried to report results without running all checks.
- **"TDD session has remaining slices"** — Claude tried to end the session with unfinished work.

These are guardrails, not errors. The agent will self-correct and continue.

---

## Committing Your Work

The implementer auto-commits after each confirmed phase transition:

```
test(<scope>): add tests for <slice name>      # RED phase
feat(<scope>): implement <slice name>          # GREEN phase
refactor(<scope>): clean up <slice name>       # REFACTOR phase (if applicable)
```

The `/tdd-implement` skill also auto-creates a `feature/<name>` branch before the first slice if you're on `main` or `master`.

See `docs/version-control.md` for the full commit message format and branching strategy.

---

## Releasing Your Feature

After all slices are complete, run:

```
/tdd-release
```

This forks a fresh context and launches the **tdd-releaser** agent, which:

1. Verifies all slices in `.tdd-progress.md` are in a terminal state (pass/done)
2. Runs the full test suite one final time
3. Runs static analysis and code formatting
4. Updates `CHANGELOG.md` with entries generated from slice descriptions
5. Pushes the branch to the remote
6. Creates a PR via `gh pr create` with an auto-generated summary
7. Optionally cleans up `.tdd-progress.md`

### Approval gates

The releaser asks for your approval before each destructive or external action:

- **CHANGELOG entries** — approve, edit, or skip
- **PR description** — approve, edit, or skip

If `gh` is not installed or not authenticated, the releaser skips PR creation gracefully and prints manual instructions instead.

### Stop hook

The `check-release-complete.sh` hook validates that the branch has been pushed to the remote before allowing the releaser to finish. This ensures no work is lost locally.

---

## Resuming an Interrupted Session

If your session ends mid-workflow (timeout, crash, manual exit):

1. Start a new Claude session in the same project
2. Run `/tdd-implement` — it reads `.tdd-progress.md`, skips completed slices, and resumes from the first pending one

The `planning/` archive provides the original plan for reference if `.tdd-progress.md` gets corrupted.

---

## Configuration

### Switching the planner to Sonnet

The planner defaults to `model: opus` for thorough codebase analysis. For faster planning on simpler features, edit `agents/tdd-planner.md` and change:

```yaml
model: opus
```

to:

```yaml
model: sonnet
```

The tradeoff is faster planning but less thorough analysis.

### Enabling web access for the planner

To let the planner look up API docs on pub.dev or reference documentation, edit `agents/tdd-planner.md` and add `WebFetch, WebSearch` to the tools list:

```yaml
tools: Read, Glob, Grep, Bash, AskUserQuestion, WebFetch, WebSearch
```

### Adjusting permissionMode

The planner runs in `permissionMode: plan` by default, which may block some Bash writes. If the planner cannot write `.tdd-progress.md`, you have two options:

1. Remove `permissionMode: plan` from `agents/tdd-planner.md` (the `disallowedTools` list still prevents code writes)
2. Approve the write when prompted

### Changing state management or architecture

The planner follows whatever conventions are defined in
`skills/dart-flutter-conventions/reference/project-conventions.md`. To switch
from Riverpod to Bloc, Provider, or any other approach:

1. Edit `project-conventions.md`
2. Update the **State Management** section with your preferred solution and code examples
3. Update the **ViewModel Example** and **View Example** to match
4. Update the **Official References** table

The plugin itself has no opinion about state management — it reads the conventions
doc and follows it. You never need to edit SKILL.md or agent files to change
architecture choices.

### Changing the test specification format

The planner outputs test specs in a compact Given/When/Then format:

```
### Test 1: Shows app name and version
Given: Settings screen rendered
When: Scrolling to the bottom of the screen
Then: Shows "Oogstbord" and a version string (e.g., "0.1.0")
```

To change this format (e.g., table rows, single-line, or multi-line blocks),
edit these three files:

1. **`skills/tdd-plan/reference/tdd-task-template.md`** — The template the
   planner reads for output structure. Change the test examples in the
   "Test Specifications" section to your preferred format.

2. **`skills/tdd-plan/SKILL.md`** — The planner's instructions. Update three
   places:
   - **Step 6** (inline example structure) — change the `### Test N` block
   - **Step 7** (self-check) — update the Given/When/Then checklist item to
     describe your format
   - The enforcement line after the code block in step 6 — adjust the
     description of what's acceptable

3. **`agents/tdd-planner.md`** — The agent's Output section references the
   format briefly. Update the description to match.

The implementer and verifier do not parse Given/When/Then — they read the
test file paths and slice status from `.tdd-progress.md`. So changing the
format only affects the planner's output and has no downstream impact.

### Increasing agent turn limits

If a complex slice needs more iterations, edit the `maxTurns` value in the relevant agent file:

- `agents/tdd-implementer.md` — default 50
- `agents/tdd-verifier.md` — default 20
- `agents/tdd-planner.md` — no limit (maxTurns commented out)
- `agents/tdd-releaser.md` — default 30

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

## Updating Convention References

Run `/tdd-update-context` to update the plugin's convention reference files to the latest framework versions. This is useful when a new major version of GoogleTest, Flutter, or another framework is released and the plugin's documentation becomes stale.

The context-updater agent will:

1. Read all current reference files and note documented versions
2. Research latest stable versions from canonical sources (GitHub repos, official sites)
3. Analyze breaking changes between documented and latest versions
4. Perform a gap analysis (stale patterns, missing docs, incorrect examples)
5. Present a structured proposal with priority ratings
6. Ask for approval before editing any files
7. Apply approved changes and commit

This workflow only modifies reference content files and SKILL.md quick references — it never touches agent definitions, hook scripts, or workflow logic.

---

## Reference

- `README.md` — Architecture overview and component listing
- `docs/version-control.md` — Git workflow and commit conventions
- `skills/dart-flutter-conventions/` — Dart/Flutter testing patterns, project conventions, Riverpod guide, and test recipes
- `skills/cpp-testing-conventions/` — C++ GoogleTest patterns, CMake integration, and Clang tooling
- `skills/bash-testing-conventions/` — Bash testing with bashunit and shellcheck
