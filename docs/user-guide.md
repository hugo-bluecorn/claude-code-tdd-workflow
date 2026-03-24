# User Guide

This guide walks through using the tdd-workflow plugin from start to finish.

---

## Prerequisites

- Claude Code installed with plugin support
- A project with test infrastructure already set up (any language)
- Language conventions configured in `.claude/tdd-conventions.json`, or an
  external conventions repo accessible at session start (see
  `skills/project-conventions/SKILL.md` for setup)

---

## Installing the Plugin

```bash
claude plugin install <path-to-tdd-workflow>
```

After installation, verify it loaded:

```bash
claude --debug
```

Look for `loading plugin: tdd-workflow` in the output. The `/tdd-plan`, `/tdd-implement`, `/tdd-release`, `/tdd-finalize-docs`, `/tdd-update-context`, and `/role-create` commands should appear in your skill list.

---

## Configuring Convention Sources

The plugin is language-agnostic — it ships no language convention content. Conventions are loaded dynamically from external sources configured per project.

### Setup

Create `.claude/tdd-conventions.json` in your project root:

```json
{
  "conventions": [
    "https://github.com/hugo-bluecorn/tdd-workflow-conventions"
  ]
}
```

The official repo includes conventions for Dart/Flutter, C++, C, and Bash. You can also point to local directories or your own convention repos:

```json
{
  "conventions": [
    "https://github.com/hugo-bluecorn/tdd-workflow-conventions",
    "/home/user/my-rust-conventions"
  ]
}
```

### How it works

1. **SessionStart hook** (`fetch-conventions.sh`) clones or refreshes URL sources to `${CLAUDE_PLUGIN_DATA}/conventions/` on each session start
2. **Agent startup** — when a TDD agent spawns, the `project-conventions` skill runs `load-conventions.sh` via Dynamic Context Injection
3. **Project detection** — the script detects your project type (pubspec.yaml → Dart, CMakeLists.txt + .cpp → C++, .c files → C, _test.sh → Bash) and outputs only relevant conventions
4. **Multi-language** — projects using multiple languages get all relevant conventions loaded

### Without configuration

If no `.claude/tdd-conventions.json` exists, agents run without language convention context. They still work — they just don't have language-specific testing patterns preloaded.

### Local development with --plugin-dir

When using `--plugin-dir` for local plugin development, two differences apply:

1. **`${CLAUDE_PLUGIN_DATA}` is not set.** URL convention sources won't be cached. Use local paths in your `.claude/tdd-conventions.json` instead.
2. **DCI shell commands prompt for approval.** Skills that use `!`cmd`` (like `project-conventions` and `/role-create`) will ask for permission on first run. Installed plugins execute these without prompting.

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
  "version": "2.4.0"
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

The `/tdd-plan` skill runs **inline** in your main conversation and:

1. Spawns the **tdd-planner** agent (read-only) to research your codebase
2. The planner auto-detects your test runner and frameworks, reads your project structure, existing tests, and architecture, and returns a structured plan
3. The skill presents the plan and asks you to **approve**, **revise**, or **discard** it
4. After approval, the skill writes the plan to two locations:
   - `.tdd-progress.md` at your project root (the live tracking file)
   - `planning/YYYYMMDD_HHMM_feature_name.md` (read-only archive)

### 3. Review the plan

The skill presents the full plan and asks you to **Approve**, **Modify**, or **Discard** it.

- **Approve**: proceed to implementation
- **Modify**: tell the skill what to change; the planner is re-invoked with your feedback
- **Discard**: abandon the plan entirely

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
2. Runs static analysis (e.g., `shellcheck`, `dart analyze`, `clang-tidy` — depends on project type)
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
| `validate-plan-output.sh` | standalone utility | `/tdd-plan` skill | Validates plan file structure (required sections, no refactoring leak); called after approval, not a hook |
| `check-tdd-progress.sh` | Stop | main thread | Prevents session end with pending slices |
| `check-release-complete.sh` | Stop + SubagentStop | releaser | Validates branch is pushed to remote before release completes |

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

See `skills/tdd-release/reference/version-control.md` for the full commit message format and branching strategy.

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
5. Propagates the new version into all version-bearing files via `scripts/bump-version.sh`
6. Pushes the branch to the remote
7. Creates a PR via `gh pr create` with an auto-generated summary
8. Optionally cleans up `.tdd-progress.md`

### Approval gates

The releaser asks for your approval before each destructive or external action:

- **CHANGELOG entries** — approve, edit, or skip
- **PR description** — approve, edit, or skip

If `gh` is not installed or not authenticated, the releaser skips PR creation gracefully and prints manual instructions instead.

### Stop hook

The `check-release-complete.sh` hook validates that the branch has been pushed to the remote before allowing the releaser to finish. This ensures no work is lost locally.

---

## Finalizing Documentation

After `/tdd-release` creates the PR, run:

```
/tdd-finalize-docs
```

This forks a fresh context and launches the **tdd-doc-finalizer** agent, which:

1. Runs `detect-doc-context.sh` to discover which documentation files exist in the project
2. Reads `CHANGELOG.md` to understand what changed in the release
3. Updates affected documentation files (README, CLAUDE.md, docs/) with targeted edits
4. Runs the test suite to verify consistency
5. Commits and pushes to the same branch — the existing PR auto-updates

The doc-finalizer is fully automated with no approval gates. It only modifies documentation — it never touches CHANGELOG, source code, agent definitions, skill definitions, or version files (version bumping is the releaser's responsibility).

> **Not recommended for use.** The doc-finalizer mechanically propagates CHANGELOG entries to documentation files but does not assess whether the documentation is actually accurate or complete. A redesign is planned but not yet scheduled. For now, review and update documentation manually after release.

The same `check-release-complete.sh` hook validates that the push succeeded before the agent finishes.

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
tools: Read, Glob, Grep, Bash, WebFetch, WebSearch
```

### Adjusting permissionMode

The planner runs in `permissionMode: plan` by default. The planner is read-only and does not write files, so this is a safe default. If Bash read commands are unexpectedly blocked in your environment, remove `permissionMode: plan` from `agents/tdd-planner.md`.

### Changing state management or architecture

The planner follows whatever conventions are loaded by the `project-conventions`
skill from your external convention files (configured in `.claude/tdd-conventions.json`).
To switch from one approach to another (e.g., Riverpod to Bloc, or Provider to Redux):

1. Edit the relevant convention file in your external conventions repo
2. Update the **State Management** section with your preferred solution and code examples
3. Update example code to match
4. Update the **Official References** table

The plugin itself has no opinion about state management — it reads the conventions
and follows them. You never need to edit SKILL.md or agent files to change
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

2. **`agents/tdd-planner.md`** — The planner agent's body contains the full
   format specification. Update three places:
   - The inline example structure — change the `### Test N` block
   - The self-check section — update the Given/When/Then checklist item to
     describe your format
   - The enforcement line after the code block — adjust the description of
     what's acceptable

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

The auto-detection in `/tdd-plan` checks for `pubspec.yaml` (Dart), `CMakeLists.txt` (C/C++), or `*.sh` files (Bash). If your project uses a non-standard setup, the planner will still research your codebase — the auto-detection just provides initial hints.

### Verifier reports FAIL but tests look correct

The verifier runs the **complete** test suite, not just the new tests. A FAIL may come from a pre-existing broken test or a regression in another part of the codebase. Check the verifier's report for the specific failure paths.

### Session won't end

The Stop hook prevents Claude from ending the session while `.tdd-progress.md` has PENDING or IN_PROGRESS slices. To end early:

- Update the remaining slices to a terminal status manually
- Or delete `.tdd-progress.md` from the project root

---

## Updating Convention References

> **Not recommended for use.** Since v2.0.0, language conventions live in an external repo, not in this plugin. The context-updater agent's target files no longer exist here, making `/tdd-update-context` effectively non-functional against the plugin. A scope redesign is planned but not yet scheduled. Update convention reference files directly in your external conventions repo.

---

## Reference

- `README.md` — Architecture overview and component listing
- `skills/tdd-release/reference/version-control.md` — Git workflow and commit conventions
- `skills/project-conventions/` — Dynamic convention loading based on project configuration

---

## Addendum: Agent Memory and Knowledge Promotion

> **Status:** Developing concept. This guidance reflects current understanding
> of how the plugin's agents learn and how that knowledge can be leveraged
> across sessions.

### How the agents learn

Four of the plugin's agents have persistent memory (`memory: project`):

| Agent | Memory location | What it learns |
|---|---|---|
| tdd-planner | `.claude/agent-memory/tdd-planner/` | Architecture patterns, naming conventions, test framework preferences |
| tdd-implementer | `.claude/agent-memory/tdd-implementer/` | Assertion styles, test fixtures, edge case patterns, common pitfalls |
| tdd-verifier | `.claude/agent-memory/tdd-verifier/` | Test runner commands, failure patterns, flaky tests, static analysis quirks |
| context-updater | `.claude/agent-memory/context-updater/` | Framework version findings, URL validity, update history |

Each agent accumulates domain-specific knowledge across invocations. This
happens automatically — the agent writes what it learns, and reloads it on
the next run.

### The promotion gap

Agent memories are **siloed by design**. The planner doesn't see what the
implementer learned, and neither feeds into your project's shared memory
(MEMORY.md or CLAUDE.md) automatically. Valuable insights — a test pattern
that works well, an architectural constraint discovered during implementation,
a framework quirk — stay locked in the agent that found them.

### Recommended practice

After a feature completes (all slices implemented, tests green), review
the work agents' per-agent memory for insights worth promoting to your
project's shared context:

1. **Read agent memories** — check `.claude/agent-memory/tdd-planner/MEMORY.md`
   and `.claude/agent-memory/tdd-implementer/MEMORY.md` for new entries
2. **Identify project-wide insights** — patterns, conventions, or constraints
   that would benefit future planning and implementation, not just the agent
   that discovered them
3. **Promote to shared context** — add relevant insights to your project's
   CLAUDE.md, auto-memory, or convention documentation where all sessions
   and agents can access them
4. **Prune stale agent memory** — remove entries that were specific to a
   completed feature and no longer apply

This is a manual step today. The agents learn well within their own scope;
closing the loop across agents requires human judgment about what deserves
promotion. Consider making this part of your post-implementation review
routine.

### Future: automated promotion (not currently planned)

If the manual approach proves insufficient, several automation paths exist:

- **`/tdd-sync-memory` skill** — a dedicated skill that reads all agent
  memories, identifies cross-cutting insights, and proposes promotions to
  shared context for your review
- **Cross-reading agent memories** — configuring agents to read each
  other's per-agent memory directories (e.g., the planner reads the
  implementer's memory for test pattern knowledge)
- **SubagentStop hooks** — hooks that fire when an agent finishes and
  extract key learnings from the agent's output for surfacing to the user

None of these are currently planned. The manual approach is lightweight
and gives you full control over what enters shared context. If you
experiment with any of these patterns, we'd welcome feedback on what
works.
