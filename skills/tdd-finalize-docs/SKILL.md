---
name: tdd-finalize-docs
description: >
  Finalize post-release documentation updates. Discovers documentation files,
  reads CHANGELOG to understand what changed, updates README.md, CLAUDE.md,
  and docs/ as needed, and pushes to the branch. Triggers on: "finalize docs",
  "update documentation", "finalize documentation".
context: fork
agent: tdd-doc-finalizer
disable-model-invocation: true
---

# Post-Release Documentation Finalization

Finalize documentation consistency after a release: $ARGUMENTS

## Process

1. **Discover documentation files:**
   - Run `detect-doc-context.sh` to discover which documentation files exist.
   - Use the output to determine which files may need updating.

2. **Read CHANGELOG to understand what changed:**
   - Read `CHANGELOG.md` to extract the latest version and changes.
   - Read `.tdd-progress.md` (if it exists) for additional context.
   - Categorize changes: new agent, new skill, new hook, behavior change, bug fix.

3. **Update discovered documentation files:**
   - **README.md** -- component tables, file structure, workflow diagrams.
   - **CLAUDE.md** -- architecture tables, available commands sections.
   - **docs/** -- any documentation files affected by the changes.
   - Only update sections directly affected by the changes.

4. **Verify consistency:**
   - Run the project test suite to confirm documentation is consistent.
   - If tests fail, diagnose and fix. Iterate until all pass.

5. **Commit, push, and report:**
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
