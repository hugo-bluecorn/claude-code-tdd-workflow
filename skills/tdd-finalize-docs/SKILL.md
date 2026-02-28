---
name: tdd-finalize-docs
description: >
  Finalize post-release documentation updates. Bumps version in plugin.json
  and docs, updates README.md, CLAUDE.md, and user-guide.md, maintains release
  integration tests, and pushes to the branch. Triggers on: "finalize docs",
  "update documentation", "finalize documentation".
context: fork
agent: tdd-doc-finalizer
disable-model-invocation: true
---

# Post-Release Documentation Finalization

Finalize documentation and version consistency after a release: $ARGUMENTS

## Process

1. **Determine the release version:**
   - Read `CHANGELOG.md` to extract the latest version header.
   - Read `.claude-plugin/plugin.json` to find the current version.
   - If they already match, skip the version bump step.

2. **Bump version in plugin.json and docs:**
   - Update the `"version"` field in `.claude-plugin/plugin.json`.
   - Update the version example in `docs/user-guide.md`.
   - Do NOT modify CHANGELOG.md (that is the tdd-releaser's responsibility).

3. **Assess documentation impact:**
   - Read `.tdd-progress.md` and the CHANGELOG entry to understand what changed.
   - Categorize changes: new agent, new skill, new hook, behavior change, bug fix.

4. **Update documentation files:**
   - **README.md** -- agents table, skills table, hooks table, file structure.
   - **CLAUDE.md** -- plugin architecture table, available commands section.
   - **docs/user-guide.md** -- workflow sections, configuration sections.
   - Only update sections directly affected by the changes.

5. **Update release integration test files:**
   - Check `test/integration/release_version_test.sh` for hardcoded version assertions.
   - Check `test/integration/release_documentation_test.sh` for feature-specific assertions.
   - Add assertions for new components if this release added agents, skills, or hooks.

6. **Verify consistency:**
   - Run release integration tests with `./lib/bashunit test/integration/release_version_test.sh`
     and `./lib/bashunit test/integration/release_documentation_test.sh`.
   - Run the full test suite with `./lib/bashunit test/` to check for regressions.
   - If tests fail, diagnose and fix. Iterate until all pass.

7. **Commit, push, and report:**
   - Stage all changes and create a single commit.
   - Run `git push` to update the existing branch and PR.
   - Report a summary of all changes made.

## Constraints

- Do NOT modify CHANGELOG.md -- that is the tdd-releaser's responsibility
- Do NOT modify source code, hook scripts, agent definitions, or skill definitions
- Do NOT invent documentation for features that do not exist
- Do NOT update framework versions in convention reference files
- Prefer minimal, targeted edits over full file rewrites
- Always read a file before editing it
