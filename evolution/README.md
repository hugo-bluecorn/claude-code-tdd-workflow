# `evolution/` — "what will be"

This tree holds **forward-looking documents** — design proposals, draft issues,
exploratory specs — that describe **what the project WILL be**. It is kept
deliberately separate from the committed record of **what the project is/was**.

## Convention

- **Mirror the project structure.** A proposed issue → `evolution/issues/NNN-…`,
  a design doc → `evolution/explorations/features/…`, a draft skill →
  `evolution/skills/…`, and so on. Paths under `evolution/` echo the real tree.
- **The repo-root trees are frozen as history.** `issues/`, `explorations/`,
  `planning/`, `docs/` at the repo root remain the "what is/was" record. New
  forward-looking docs go **here** instead of being appended there.
- **Effective 2026-06-10, for newly produced docs only.** Existing documents are
  **not** migrated.
- **Numbering continues the global sequence** — so `evolution/issues/019` can
  graduate to `issues/019` without renumbering.

## Promotion

When a proposal is accepted and built, its doc **graduates** out of `evolution/`
into the corresponding real tree, and the implementation lands via the normal
TDD cycle. `evolution/` should trend toward empty as items ship.

## Not in scope

Native Claude Code memories live separately (`~/.claude/projects/<project>/memory/`)
and are not part of this tree.
