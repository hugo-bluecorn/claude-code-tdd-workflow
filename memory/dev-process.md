---
name: dev-process
description: How changes are made to this plugin — TDD (dogfood or direct bashunit), CA/CP/CI roles, CHANGELOG/SemVer/Conventional Commits, design principles.
metadata:
  type: project
---

This plugin is built **via TDD, dogfooding itself**. To implement a roadmap item:
- **Preferred (dogfood):** `/tdd-plan "<item>"` → review/Approve → `/tdd-implement` (RED→GREEN→REFACTOR per slice, verifier validates) → `/tdd-release`. Plan state lives in `.tdd-progress.md` (root); archives in `planning/YYYYMMDD_HHMM_*.md`. Resume with `/tdd-implement`.
- **Direct (if the plugin isn't installed):** write the failing bashunit test first, then code, then make the suite green ([[test-suite]]).

**Dev roles (3-terminal, human-mediated; a solo session plays all three):** **CA** (architect) decides + authors `issues/NNN-*.md` + writes the `/tdd-plan` prompt + owns the root `MEMORY.md` (sole writer) + verifies output; **CP** (planner) runs `/tdd-plan`; **CI** (implementer) runs `/tdd-implement`+`/tdd-release` + merges after CA verification. Files: `.claude/skills/role-{ca,cp,ci}/SKILL.md`. (Roles are *optional* — see [[prime-directive]].)

**Conventions:**
- **Conventional Commits**: `test:`→`feat:`→`refactor:` is the TDD sequence (also `fix:`/`docs:`/`chore:`).
- **CHANGELOG** (Keep-a-Changelog): every change documented under `## Unreleased`. **SemVer** — authority is `skills/tdd-release/reference/version-control.md`; `scripts/bump-version.sh <ver>` propagates the version.
- Issues → `issues/`, planning archives → `planning/`, API reference → `docs/reference/`, developer/design notes → `docs/plugin-developer-context.md`, experimental evidence → `docs/experimental-results/`.

**Design principles (honor when editing):** context isolation per agent; **hook-enforced discipline** (exit 2 blocks; agents can't bypass); approval gates before plan writes; test-first non-negotiable; blackbox verification; resume safety via `.tdd-progress.md`; minimal per-agent permissions (`tools` allowlist OR `disallowedTools` denylist — never both); `${CLAUDE_PLUGIN_ROOT}` in all hook/MCP paths; **subagents can't spawn subagents** (so `/tdd-implement` runs in main context). Hooks are delivered via `hooks/hooks.json` (frontmatter hooks are ignored on marketplace installs). See [[prime-directive]] [[decisions]].
