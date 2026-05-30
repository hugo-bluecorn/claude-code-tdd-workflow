# Bootstrap Memory — tdd-workflow upgrade

Seed memories for a Claude session here to **implement the v2.4 → v3 upgrade**. Read these, then seed your own project memory from them. One line per memory.

- [prime-directive](prime-directive.md) — the hard constraint: `tdd-*` core must work without `role-*`; skills=verbs, agents=nouns. Never violate.
- [decisions](decisions.md) — the ratified upgrade decisions (R1 convention delivery, Direction 1, verifier A/B, `/tdd-upgrade`, dead-commands).
- [upgrade-roadmap](upgrade-roadmap.md) — the 22-item, 4-wave roadmap; what to implement and in what order.
- [dev-process](dev-process.md) — how changes are made here: TDD (dogfood the plugin or direct bashunit), CA/CP/CI, CHANGELOG/SemVer/Conventional Commits.
- [test-suite](test-suite.md) — how to run the suite + the ~48 known-non-defect failures (don't misread them).
- [conventions-and-methods](conventions-and-methods.md) — the convention-loading mechanism + the upgrade methods (audit/evolution/`/upgrade`) and where the full artifacts live.
- [tdd-review](tdd-review.md) — the planned `tdd-review-*` component (R4c): a recallable test-quality reviewer guarding the planner→implementer seam; the falsifiability rubric.
- [vgv-critique](vgv-critique.md) — how this plugin compares to the VGV system: the moat to keep, the #1 gap (no design review), what to learn.
