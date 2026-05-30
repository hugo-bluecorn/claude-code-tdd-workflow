---
name: upgrade-roadmap
description: The v2.4→v3 upgrade roadmap — 22 items in 4 dependency waves; each is a TDD slice with a named bashunit done-test.
metadata:
  type: project
---

A modernized audit + an evolution review of plugin v2.4.0 produced one prioritized roadmap. Implement items **as TDD slices** (RED→GREEN→REFACTOR), in wave order. Each item has a bashunit "done-test" (the first failing test). Full roadmap + per-item specs: `research/plugin-upgrade/upgrade-roadmap.md` (knowledge-pack workspace) — summarized here.

**Wave 1 — foundation & quick correctness (no blockers):** R2 fix `Task`→`Agent` drift in `context-updater` denylist · R3 modernize the bare `plugin.json` (add `author`/`repository`/`license`/`$schema`) · R6 pin `effort` on all 7 agents (none have it — verifier=low, planner/implementer=high, rest=medium) · R7 make the SessionStart convention fetch `async: true` · R14 update stale `audit`/issue statuses **+ reconcile the stale `test/integration/*_documentation_test.sh` vs the v2 README** (see [[test-suite]]) · R15 C/C++ `auto-run-tests` runs `ctest` (not just build) + remove legacy `load-role-references.sh` · R16 drop inert agent-frontmatter `hooks`.

**Wave 2 — distribution & convention re-platform (needs R3):** **R1** (highest leverage) re-platform conventions → `userConfig` + `skills-dir` packs, data-drive detection, ship `dart-flutter-conventions` pack ([[decisions]]) · R8 publish `.claude-plugin/marketplace.json` · R9 `plugin validate --strict` in CI.

**Wave 3 — quality & job-coverage:** **R4** verifier deterministic re-run **command** gate (replace prompt self-report; today's false-PASS risk) **+ the verifier A/B** ([[decisions]]) → **R4c** codified recallable **test-quality reviewer** (`/tdd-review-tests` + `tdd-test-reviewer`; guards the planner→implementer seam the blackbox verifier can't; reads test+code+spec; rubric [[tdd-review]]; first use = self-audit the plugin's own ~770 tests) → R10 verifier `isolation: worktree` · R5 `/tdd-refactor` (characterize→restructure-under-green; the #1 capability gap) · **R11a retire `/tdd-update-context`** + **R11b rebuild `/tdd-finalize-docs`** (add accuracy-assessment + approval gate) · R12 `/tdd-fix` · R13 `/tdd-green` autopilot.

**Wave 4 — polish & forward bets:** R17 test-first output style · R18 Notification hook · R19 SessionStart TDD reminder · R20 `statusMessage` · R21 `/tdd-sync-memory` · R22 headless SDK recipe · then evaluate the **deferred** Direction-2 bets (dynamic workflows / agent-teams / channels / routines).

Honor [[prime-directive]] on every item; commit per [[dev-process]]; mind the [[test-suite]] caveat before trusting a green run.
