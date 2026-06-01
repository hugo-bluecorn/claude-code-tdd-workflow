---
name: tdd-release
description: >
  Finalize a completed TDD feature for release. Validates all slices are
  terminal, runs tests and static analysis, updates CHANGELOG, pushes branch,
  and creates a PR. Triggers on: "release TDD", "finalize feature", "publish TDD".
context: fork
agent: tdd-releaser
disable-model-invocation: true
---

# TDD Release Workflow

Finalize the current TDD feature for release: $ARGUMENTS

## Process

1. **Pre-flight checks:**
   - Read `.tdd-progress.md` and verify all slices are terminal (pass/done/complete/fail/skip).
     Refuse to proceed if any slice is still pending or in-progress.
   - Check the current branch. Refuse to release if on main or master.
     You must be on a feature branch.

2. **Quality gates (pack-driven):**
   The releaser runs the test suite, static analysis, and formatter using the
   **active convention pack's commands** — not a hardcoded per-language matrix.
   The pack is resolved from the committed binding `.claude/tdd-conventions.json`
   (via `scripts/active-pack.sh`); the test/lint/format commands come from
   `pack.commands` (`pack.commands.test`, `pack.commands.lint`,
   `pack.commands.format`). See `agents/tdd-releaser.md` for the resolution
   detail — it is the authoritative source for the quality-chain commands.
   - **Test suite:** `pack.commands.test`. Illustrative: a `ctest` invocation
     for C++, `flutter test` for Dart.
   - **Static analysis:** `pack.commands.lint`. Illustrative: `clang-tidy` for
     C++, `analyze` for Dart.
   - **Formatter:** `pack.commands.format` (skipped when the pack defines none).
   - **Built-in bash floor (no pack):** Bash projects need no pack — the
     releaser falls back to `bashunit` for the test suite and `shellcheck` for
     static analysis.

3. **CHANGELOG update:**
   - Read `skills/tdd-release/reference/version-control.md` for semantic versioning rules
   - Use those rules to determine the appropriate version (MAJOR, MINOR, or PATCH)
   - Read slice names and descriptions from `.tdd-progress.md`
   - Generate CHANGELOG entries categorized as Added, Changed, or Fixed
   - Present the proposed entries to the user via AskUserQuestion for approval
   - Write approved entries to CHANGELOG.md via Bash (using sed or echo) -- do NOT use the Edit tool

4. **Commit CHANGELOG and propagate version:**
   - Stage and commit: `git add CHANGELOG.md && git commit -m "docs: update CHANGELOG for <feature>"`
   - Run `bump-version.sh <version>` to propagate the chosen version into all version-bearing files
   - Stage and commit version file changes: `git add -A && git commit -m "chore: bump version to <version>"`
   - Push the branch: `git push -u origin <branch>`

5. **PR creation:**
   - Generate a PR title and body from the feature description and slice summaries
   - Present the PR draft to the user via AskUserQuestion for approval
   - If `gh` CLI is available, create the PR via `gh pr create`
   - If `gh` is not available or not installed, output the full command for the user to copy-paste manually

6. **Optional cleanup:**
   - Ask the user if they want to clean up `.tdd-progress.md`
   - If yes, remove or archive the file
   - If no, leave it in place for reference

## Constraints

- Do NOT modify source code or test files -- this workflow is release-only
- All file modifications (CHANGELOG) must go through Bash, not Edit or Write tools
- Always get user approval before committing, pushing, or creating a PR
- If any quality gate fails, stop and report the failure to the user
