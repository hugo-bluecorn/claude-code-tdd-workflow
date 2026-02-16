# Version Control Integration — Design Notes

Notes on integrating the git/GitHub workflow described in `version-control.md`
into the TDD workflow plugin as automated behavior rather than advisory documentation.

---

## The Gap (partially closed)

`version-control.md` describes branching, per-phase commits, PRs, releases, and
changelogs. Layers 1 and 2 are now implemented (v1.5.0). Layer 3 (`/tdd-release`)
remains unimplemented.

The TDD commit pattern maps directly onto the existing R-G-R cycle:

| TDD Phase | Commit Type | Trigger Point |
|-----------|-------------|---------------|
| RED       | `test:`     | After implementer confirms RED |
| GREEN     | `feat:`     | After implementer confirms GREEN |
| REFACTOR  | `refactor:` | After implementer confirms REFACTOR (optional) |

---

## Proposed Integration: Three Layers

### Layer 1 — Per-Phase Auto-Commits (implementer agent) — IMPLEMENTED v1.5.0

**Where:** `agents/tdd-implementer.md` — "Git Workflow" section added to the
mandatory workflow.

After each phase is confirmed, the implementer commits automatically:

- RED confirmed → `git add <test files>` → `git commit -m "test(<scope>): add tests for <slice>"`
- GREEN confirmed → `git add <impl files>` → `git commit -m "feat(<scope>): implement <slice>"`
- REFACTOR confirmed → `git add <changed files>` → `git commit -m "refactor(<scope>): clean up <slice>"`

Every commit is atomic — tests pass at each point. This produces the fine-grained
history that `version-control.md` recommends.

**Effort:** Small — ~15 lines added to implementer system prompt. Done.

### Layer 2 — Branch Creation (implement skill) — IMPLEMENTED v1.5.0

**Where:** `skills/tdd-implement/SKILL.md` — Step 0 added before the implementation loop.

```
0. If not already on a feature branch, create one:
   git checkout -b feature/<feature-name-from-progress-file>
```

The planner does NOT create the branch because:
- It runs in `permissionMode: plan` with write tools disallowed
- It runs in a forked context — branch state wouldn't carry over
- Branching is repo management, not planning

The `/tdd-implement` orchestrator runs in the main context with full permissions,
making it the natural place for this.

**Effort:** Small — ~5 lines added to implement skill. Done.

### Layer 3 — `/tdd-release` Skill + Agent — NOT YET IMPLEMENTED

A new command for the end-of-feature workflow: validate, document, and publish.

**`/tdd-release`** would:
1. Verify all slices in `.tdd-progress.md` are terminal (pass/done)
2. Run the full test suite one final time
3. Run static analysis (`dart analyze` / `flutter analyze`)
4. Run code formatting (`dart format .`)
5. Update `CHANGELOG.md` — generate entries from slice descriptions
6. Commit the changelog: `docs: update CHANGELOG for <feature>`
7. Push the branch: `git push -u origin <branch>`
8. Create a PR via `gh pr create` with auto-generated summary
9. Optionally clean up `.tdd-progress.md`

---

## Why `/tdd-release` Should Be a Dedicated Agent

### It's a distinct role with distinct constraints

| Agent       | Can write code? | Can write config/docs? | Blackbox? |
|-------------|-----------------|------------------------|-----------|
| planner     | No              | Yes (plan files only)  | N/A       |
| implementer | Yes             | No                     | No        |
| verifier    | No              | No                     | Yes       |
| **releaser**| **No**          | **Yes (CHANGELOG only)**| **No**   |

The releaser must NOT touch source code or tests. This constraint needs enforcement
through `disallowedTools` or a PreToolUse hook — something only an agent definition
provides. Bare skill instructions in the main context have no mechanism to prevent
Claude from "helpfully" fixing a lint issue before committing.

### It completes a four-phase architecture

Current workflow:
```
plan → (implement → verify) × N → ???
```

With releaser:
```
plan → (implement → verify) × N → release
```

Each phase has a dedicated agent with a single responsibility. Same design
principle that justified separating verifier from implementer.

### It needs a Stop hook

The verifier has a Stop hook: "did you run the full suite and produce PASS/FAIL?"
The releaser needs an equivalent: "did you run tests, update CHANGELOG, and
create the PR?" Without an agent definition, hooks can't be attached.

### Everything it needs is on disk

The releaser reads `.tdd-progress.md` for slice summaries, the planning archive
for feature context, and `CHANGELOG.md` for style. It doesn't need conversation
history. A forked context works and keeps noisy output (test results, git output)
out of the main conversation.

### User interaction works through AskUserQuestion

The planner already proves this pattern. The releaser would use it for:
- "Approve these CHANGELOG entries?" (Approve / Edit / Skip)
- "Approve this PR description?" (Create / Edit / Skip)
- "Version bump type?" (Patch / Minor / Major)

### Proposed agent configuration

```
agents/tdd-releaser.md:
  tools: Read, Edit, Bash, Glob, Grep, AskUserQuestion
  disallowedTools: Write, MultiEdit, NotebookEdit
  model: sonnet
  permissionMode: (none — needs Bash for git/gh)
  memory: none (each release is independent)
  hooks:
    Stop: verify tests ran, CHANGELOG updated, PR created
```

Invoked by `skills/tdd-release/SKILL.md` with `agent: tdd-releaser`.

---

## What NOT to Do

- **Don't add git operations to the verifier** — it's a blackbox validator with
  no side effects.
- **Don't commit in hooks** — hooks enforce constraints, they don't perform
  workflow actions. A PostToolUse commit hook would create partial commits mid-phase.
- **Don't auto-push after every slice** — too noisy. Push is a deliberate action
  in `/tdd-release` or done manually.
- **Don't have the planner create branches** — wrong role, wrong context, wrong
  permission mode.

---

## Summary of All Changes

| What | Where | Effort | Status |
|------|-------|--------|--------|
| Per-phase auto-commits | `agents/tdd-implementer.md` | Small | Done (v1.5.0) |
| Branch creation at start | `skills/tdd-implement/SKILL.md` | Small | Done (v1.5.0) |
| `/tdd-release` skill | New: `skills/tdd-release/SKILL.md` | Medium | Not started |
| `tdd-releaser` agent | New: `agents/tdd-releaser.md` | Medium | Not started |
| Permission updates | `.claude/settings.local.json` | Small | Not started |
| Releaser Stop hook | New: `hooks/check-release-complete.sh` | Small | Not started |

---

## References

- `docs/version-control.md` — source guidelines this integration automates
- `agents/tdd-implementer.md` — agent that will gain commit behavior
- `skills/tdd-implement/SKILL.md` — skill that will gain branch creation
- `skills/tdd-plan/SKILL.md` — pattern for skill-to-agent delegation
