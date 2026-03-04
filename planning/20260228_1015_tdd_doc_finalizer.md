# Feature Notes: tdd-doc-finalizer Agent and /tdd-finalize-docs Skill

**Created:** 2026-02-28
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
Add a post-release documentation finalization agent that runs after `/tdd-release` to handle version bumps, documentation updates, and release integration test maintenance — tasks the releaser deliberately excludes from its scope.

### Use Cases
- After `/tdd-release` creates a PR, run `/tdd-finalize-docs` to bump plugin.json version, update docs, update release tests, and push so the PR auto-updates
- Eliminate manual version bump drift (e.g., plugin.json stuck at old version)
- Ensure documentation tables, file structure trees, and workflow diagrams reflect new components

### Context
The tdd-releaser (v1.6.0) handles CHANGELOG, push, and PR creation. It deliberately avoids editing documentation or bumping versions because those are separate concerns. The doc-finalizer completes the release pipeline by handling everything the releaser does not.

---

## Requirements Analysis

### Functional Requirements
1. Agent definition with 7-step process: version detection, version bump, doc impact assessment, doc updates, test updates, verification, commit/push
2. Skill definition as orchestrating entry point with `context: fork` and `agent: tdd-doc-finalizer`
3. hooks.json SubagentStop entry reusing check-release-complete.sh for push validation
4. Strict constraints: no CHANGELOG modification, no source code changes, no framework version updates

### Non-Functional Requirements
- All existing tests pass (no regressions)
- shellcheck passes on all .sh files
- hooks.json remains valid JSON
- Tests follow existing naming conventions

### Integration Points
- Reads CHANGELOG.md (source of truth for release version)
- Reads .tdd-progress.md (source of truth for feature scope)
- Modifies plugin.json, docs/user-guide.md (version bumps)
- Modifies README.md, CLAUDE.md, docs/user-guide.md, docs/version-control-integration.md, docs/tdd-workflow-extensibility-audit.md (documentation)
- Modifies test/integration/release_version_test.sh, test/integration/release_documentation_test.sh (test assertions)
- Reuses hooks/check-release-complete.sh (push validation)

---

## Implementation Details

### Architectural Approach
Follows the established agent+skill pattern from tdd-releaser:
- Agent definition in `agents/` with YAML frontmatter (name, tools, model, hooks) + markdown body (system prompt)
- Skill in `skills/<name>/SKILL.md` with frontmatter (name, agent, context, disable-model-invocation) + markdown body (process description)
- SubagentStop hook in hooks.json for push validation

### Design Patterns
- **Agent+Skill Pattern**: Same as tdd-releaser — agent defines capabilities/constraints, skill defines orchestration entry point
- **Hook Reuse**: check-release-complete.sh already validates that a branch is pushed; no new hook needed
- **Tool Selection**: Edit tool (not sed via Bash) for documentation edits — targeted edits are more precise for markdown files

### File Structure
```
tdd-workflow/
├── agents/
│   └── tdd-doc-finalizer.md          (NEW)
├── skills/
│   └── tdd-finalize-docs/
│       └── SKILL.md                   (NEW)
├── hooks/
│   └── hooks.json                     (MODIFIED - add SubagentStop entry)
└── test/
    ├── agents/
    │   └── tdd_doc_finalizer_test.sh  (NEW)
    ├── skills/
    │   └── tdd_finalize_docs_test.sh  (NEW)
    └── hooks/
        └── hooks_json_doc_finalizer_test.sh (NEW)
```

### Naming Conventions
- Agent file: `tdd-doc-finalizer.md` (kebab-case, matches existing agent naming)
- Skill directory: `tdd-finalize-docs/` (kebab-case, matches existing skill naming)
- Test files: `tdd_doc_finalizer_test.sh`, `tdd_finalize_docs_test.sh`, `hooks_json_doc_finalizer_test.sh` (snake_case with `_test.sh` suffix)

---

## TDD Approach

### Slice Decomposition

The feature is broken into independently testable slices, each following the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full slice list with live status tracking.

**Test Framework:** bashunit
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | Agent Definition (`agents/tdd-doc-finalizer.md`) | None |
| 2 | Skill Definition (`skills/tdd-finalize-docs/SKILL.md`) | Slice 1 |
| 3 | hooks.json Registration + Full Regression | Slice 1, 2 |

---

## Dependencies

### External Packages
- None (all tooling already in project: bashunit, shellcheck, jq)

### Internal Dependencies
- `hooks/check-release-complete.sh` — reused as SubagentStop hook (no modification needed)
- `hooks/hooks.json` — modified to add new SubagentStop entry

---

## Known Limitations / Trade-offs

### Limitations
- Agent prompt is static — cannot dynamically discover new documentation files added after the prompt was written. If new doc files are added to the project, the prompt would need manual updates.
- No approval gates — fully automated, so if the agent makes incorrect edits, they'll be committed. Mitigated by running integration tests before commit.

### Trade-offs Made
- **Edit tool vs. Bash sed**: Chose Edit tool for doc modifications (more precise for markdown) vs. releaser's Bash-only approach (used because it only edits CHANGELOG). Trade-off: slightly broader tool access but much more reliable edits.
- **No AskUserQuestion**: Chose fully automated flow (no approval gates) vs. interactive flow (like releaser). Rationale: this runs after release PR is already created; user has already approved the release.
- **Reusing check-release-complete.sh**: Chose hook reuse over a dedicated hook. If doc-finalizer needs different stop validation in the future, a new hook would be needed.

---

## Implementation Notes

### Key Decisions
- **Model: sonnet**: Documentation updates don't require opus-level reasoning; matches releaser pattern
- **maxTurns: 30**: Same as releaser; sufficient for the read-edit-test-push cycle (~25 operations expected)
- **Prompt source**: Full agent prompt from `/home/hugo-bluecorn/.claude/projects/-home-hugo-bluecorn-bluecorn-CSR-git-zenoh-old/memory/doc-finalizer-prompt.md`

### Future Improvements
- Add dynamic file discovery so the agent can find new documentation files without prompt updates
- Consider adding a lightweight approval gate for the commit message before pushing
- Integration with `/tdd-release` so doc finalization can be triggered automatically after release

### Potential Refactoring
- The check-release-complete.sh hook could be generalized to support multiple agent matchers from a config rather than hardcoded entries — left for implementer to decide

---

## References

### Related Code
- `agents/tdd-releaser.md` — pattern reference for agent definition
- `skills/tdd-release/SKILL.md` — pattern reference for skill definition
- `test/agents/tdd_releaser_test.sh` — pattern reference for agent tests
- `test/skills/tdd_release_test.sh` — pattern reference for skill tests
- `test/hooks/hooks_json_releaser_test.sh` — pattern reference for hooks.json tests
- `hooks/check-release-complete.sh` — reused stop hook

### Documentation
- Doc-finalizer prompt specification: `/home/hugo-bluecorn/.claude/projects/-home-hugo-bluecorn-bluecorn-CSR-git-zenoh-old/memory/doc-finalizer-prompt.md`

### Issues / PRs
- None — new feature
