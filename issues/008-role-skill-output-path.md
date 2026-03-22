# Issue 008: Role Output Path — context/roles/ → .claude/skills/

## Problem

CR currently writes generated role files to `context/roles/`. This is a
custom convention we invented. Anthropic's intended path for project-scoped,
version-controlled, team-shareable skills is `.claude/skills/`.

By writing to `.claude/skills/role-{code}/SKILL.md`, generated roles become
immediately discoverable as invocable skills — the developer types `/role-ca`
and the role loads. No DCI, no separate delivery skills, no manual pasting.

## Context

- Anthropic docs: "Project skills: Commit `.claude/skills/` to version control"
- `.claude/skills/` is NOT gitignored by default (only `settings.local.json`,
  `agent-memory/`, and `worktrees/` are)
- Skills in `.claude/skills/` are discovered at session startup (not mid-session)
- The role file body IS the skill body — one file serves both purposes
- `disable-model-invocation: true` prevents accidental auto-loading
- This eliminates the need for separate `/role-ca`, `/role-cp`, `/role-ci`
  delivery skills — the generated role files ARE the delivery skills

## Scope

### In Scope

1. **CR role file** — update Constraints and Workflow to reference
   `.claude/skills/role-{code}/SKILL.md` instead of `context/roles/`
2. **Role File Format spec** — update output convention from `context/roles/`
   to `.claude/skills/role-{code}/SKILL.md`
3. **validate-role-output.sh** — update any path assumptions if present
4. **SKILL.md for /role-cr** — update Step 6 (write to disk) path
5. **Skill frontmatter injection** — CR must add skill frontmatter (`name`,
   `description`, `disable-model-invocation: true`) to generated role files
6. **Tests** — update existing tests that reference `context/roles/`

### Out of Scope

- `/role-ca`, `/role-cp`, `/role-ci` delivery skills — eliminated by this change
- Mid-session skill discovery — platform limitation, documented not fixed
- `/role-evolve` — separate future feature

## Acceptance Criteria

- [ ] CR writes role files to `.claude/skills/role-{code}/SKILL.md`
- [ ] Generated role files have valid skill frontmatter (`name: role-{code}`,
      `description`, `disable-model-invocation: true`)
- [ ] `validate-role-output.sh` validates skill frontmatter fields
- [ ] Format spec documents `.claude/skills/` as the output convention
- [ ] `/role-cr` SKILL.md references the correct output path
- [ ] All existing tests pass (updated where needed)
- [ ] Generated role files are auto-discoverable by Claude Code on next session
