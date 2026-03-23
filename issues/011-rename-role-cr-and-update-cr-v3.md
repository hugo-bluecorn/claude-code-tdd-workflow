# Issue 011: Rename /role-cr → /role-create + Update CR Definition to v3

## Problem

Two changes needed:

### 1. Naming Convention Violation

The skill `/role-cr` violates the established naming convention (§2.2 of
the validation report):
- Skills (actions): `prefix-verb` — e.g., `tdd-plan`, `tdd-implement`
- Agents (actors): `prefix-noun` — e.g., `tdd-planner`, `tdd-implementer`

`/role-cr` is an abbreviation of the role code, not a verb. The convention
predicts `role-create` (skill, verb) + `role-creator` (agent, noun).

### 2. CR Definition v2 → v3

The CR definition at `skills/role-init/reference/cr-role-creator.md` is v2
(hand-refined). Experiment A of the self-compilation study (§6 of
`docs/experimental-results/role-cr-self-compilation.md`) produced a
regenerated v3 that is measurably better on 6 of 9 criteria:

- "Optional" removed (semantic framing self-correction)
- Responsibilities reordered to match execution sequence
- New placeholder constraint with behavioral explanation
- Format Evolution dropped (meta-concern, not runtime)
- Startup reordered: rules before state
- Tech stack detection with specific file type examples

## Scope

### In Scope

1. **Rename `skills/role-cr/` → `skills/role-create/`**
   - Directory rename
   - SKILL.md `name:` field: `role-cr` → `role-create`
   - SKILL.md description updated
2. **Update `skills/role-init/reference/cr-role-creator.md`** to v3
   - Content from experiment branch `experiment/cr-v3-definition`
   - Strip skill frontmatter (this is a reference doc, not a skill)
   - Version bump: 2 → 3
3. **Update `agents/role-creator.md`** — any references to `/role-cr`
4. **Update `CLAUDE.md`** — command table
5. **Update `README.md`** — skill table and directory tree
6. **Update `scripts/validate-role-output.sh`** — if it references `/role-cr`
7. **Update all tests** referencing `role-cr` path or name
8. **Update `docs/user-guide.md`** — any `/role-cr` references
9. **Generated role files** — `generator: /role-cr` → `generator: /role-create`
   in the validator or skill instructions

### Out of Scope

- Regenerating the project's cohort roles (separate step after this ships)
- Format spec changes (stable)
- Experimental results documentation (historical, references are accurate
  for the time they were written)

## Acceptance Criteria

- [ ] `/role-create` is the invocable skill name (autocomplete shows it)
- [ ] `skills/role-cr/` directory no longer exists
- [ ] `skills/role-create/SKILL.md` has `name: role-create`
- [ ] `cr-role-creator.md` is v3 content (from experiment)
- [ ] Agent body references `/role-create` not `/role-cr`
- [ ] Generated roles have `generator: /role-create`
- [ ] CLAUDE.md, README.md, user-guide.md updated
- [ ] All existing tests pass (updated where needed)
- [ ] shellcheck clean
