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

2. **Quality gates:**
   - Run the full test suite. Detect the project type and use the appropriate runner:
     - Dart/Flutter: `flutter test` (or `fvm flutter test` if FVM detected)
     - C++: `ctest --test-dir build/ --output-on-failure`
     - Bash: `./lib/bashunit test/`
   - Run static analysis appropriate to the project:
     - Dart: `dart analyze` (or `fvm dart analyze`)
     - Bash: `shellcheck -S warning` on all `.sh` files
     - C++: `clang-tidy` if configured
   - Run the formatter (project-type aware):
     - Dart: `dart format .` (or `fvm dart format .`)
     - Bash/C++: skip or use appropriate tool if configured

3. **CHANGELOG update:**
   - Read slice names and descriptions from `.tdd-progress.md`
   - Generate CHANGELOG entries categorized as Added, Changed, or Fixed
   - Present the proposed entries to the user via AskUserQuestion for approval
   - Write approved entries to CHANGELOG.md via Bash (using sed or echo) -- do NOT use the Edit tool

4. **Commit and push:**
   - Stage and commit: `git add CHANGELOG.md && git commit -m "docs: update CHANGELOG for <feature>"`
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
