# Issue 007: Role Creator Skill (`/role-cr`)

## Problem

Developers using the tdd-workflow plugin across multiple projects need
project-specific role files to encode their workflow patterns, constraints,
and context into reusable session documents. Currently, role creation
requires manually pasting the CR role file and format spec into a session
— there's no first-class entry point.

### What's Missing

- No `/role-cr` skill to load the CR role into a session
- No mechanical enforcement of format spec validation rules
- No programmatic approval gate (write-before-approve observed in all tests)
- No automatic `generator` field assignment
- Research (RTFM) is a suggestion, not enforced

### Validated Design

CR was tested across 5 iterations on a Flutter/Flame/Riverpod project:
- Test 1: Single-role generation (creative, rich architecture boundaries)
- Test 2: Three-role adaptation (too deferential, verbatim copying)
- Test 3: Added Critique phase (5/10 issues fixed)
- Test 4: Non-deterministic regression confirmed diminishing returns
- Test 5: RTFM research (highest-impact — real APIs vs plausible guesses)

Full test results: `memory/role-format-redesign.md`

## Scope

### In Scope

1. **`/role-cr` inline skill** — loads CR role content + format spec via DCI
2. **`validate-role-output.sh`** — hard-fail validation script:
   - Constraints must be "Never X" / "Do not X" with consequences (reject permissions like "Do write")
   - No placeholders (`{...}`, `TODO`, `TBD`)
   - All referenced file paths exist on disk
   - YAML frontmatter has required fields (`role`, `name`, `type`)
   - Identity section present
   - Under 400 lines
3. **Skill-level mechanical enforcement:**
   - Set `generator: /role-cr` before writing (not left to CR)
   - Run `validate-role-output.sh` before presenting to developer
   - Approve/Modify/Reject gate — only write to disk on Approve
   - Create `context/roles/` directory if it doesn't exist

### Out of Scope

- `/role-init` agent — eliminated. `/role-cr` absorbs its purpose.
- `/role-evolve` — separate future feature (memory-driven updates)
- `/role-ca`, `/role-cp`, `/role-ci` delivery skills — separate issue
- Convention loading within role sessions — existing `project-conventions` handles this
- Role file format spec changes — v2.1 is validated and stable

## Architecture

```
/role-cr (inline skill, user-invocable, disable-model-invocation: true)
  → DCI: loads cr-role-creator.md + role-format.md into session
  → Developer has conversation with CR (questions, existing prompts, iteration)
  → Developer says "generate" or "approve"
  → Skill runs validate-role-output.sh on generated content
  → Skill sets generator field
  → Skill presents with Approve/Modify/Reject
  → On Approve: mkdir -p context/roles/ && write file
  → On Modify: developer gives feedback, CR revises, re-validate
  → On Reject: nothing written
```

### Key Files

| File | Purpose |
|---|---|
| `skills/role-cr/SKILL.md` | Inline skill definition |
| `scripts/validate-role-output.sh` | Validation script (hard-fail) |
| `skills/role-init/reference/cr-role-creator.md` | CR role content (already exists, v2) |
| `skills/role-init/reference/role-format.md` | Format spec (already exists, v2.1) |

### Design Decisions

- **Inline skill, not agent.** Role creation is conversational — agents can't
  do multi-turn dialogue. The session has perfect context from the conversation.
- **`disable-model-invocation: true`.** Role loading is deliberate, never
  auto-invoked by context matching.
- **Validation is a script, not prompt instructions.** Tests showed CR treats
  format rules as suggestions. A bash script that greps for violations and
  exits non-zero is not optional.
- **RTFM enforcement.** The validation script can check IF research was done
  (does Context reference specific API classes or just framework names?). If
  the check fails, the skill can spawn a research subagent before re-presenting.

## Acceptance Criteria

- [ ] `/role-cr` loads CR role + format spec into session via DCI
- [ ] `validate-role-output.sh` catches: permissions-as-constraints, missing
      consequences, placeholders, non-existent paths, missing frontmatter fields,
      missing Identity, over 400 lines
- [ ] Generated role files have `generator: /role-cr` (set by skill, not CR)
- [ ] Files only written to disk after explicit Approve
- [ ] `context/roles/` created automatically if absent
- [ ] Works on a fresh project with only CLAUDE.md from `/init`
- [ ] All existing tests continue to pass

## Constraints

- CR role file (`cr-role-creator.md`) and format spec (`role-format.md`) are
  stable — do not modify them in this issue unless a bug is found during
  implementation
- The skill must work without the tdd-workflow plugin being installed in the
  target project (CR operates on any project)
- Prime directive: `/role-cr` must not create dependencies in the core TDD
  workflow
