---
name: tdd-review
description: The planned tdd-review-* component (roadmap R4c) — a recallable test-quality reviewer that guards the planner→implementer seam; grounded in the plugin's own TDD references.
metadata:
  type: project
---

**R4c — `/tdd-review-tests` skill + `tdd-test-reviewer` agent** (on-demand → cheap; Wave 3). The missing guardian of the **planner→implementer seam**: the planner *specs* tests (Given/When/Then), the implementer *creates* them but is **free to "fix coding problems"** → tests may drift/weaken/mirror the code, and the **blackbox `tdd-verifier`** (pass/fail only) can't see it. `tdd-review` checks the *actual* tests are honest.

**It is a test review that is, by consequence, a CODE review** — you can't judge a test in isolation, so it reads the slice's **tests + code-under-test + the planned spec**. (Contrast the `tdd-verifier`, which is deliberately **context-starved/blackbox** → objective pass/fail. The two are the halves of verification: *does it work?* vs *do the tests honestly prove it works, as specified?*)

**Rubric (6 criteria), grounded in the plugin's OWN references:**
- **Falsifiability (keystone):** *would this test fail if the behavior broke?* (from implementer's "if a test passes without implementation it's wrong"). Catches tautological / mock-only / shape-only / "is-declawed" tests.
- **Behavioral fidelity:** asserts the OUTCOME from the caller's perspective, not an internal detail (planner's "WHAT not HOW").
- **Spec fidelity:** actual tests still cover the planner's G/W/T + edge cases — the implementer-drift guard.
- **Edge-coverage · Integrity (one-behavior, assertions present, async awaited, not bent-to-pass) · Convention-compliance** (per-language, from the pack).

**Two tiers:** Tier-1 deterministic static lint (test files only; ~free; may run per-slice; ships per-language in the convention pack) + Tier-2 single semantic agent (test+code+spec; on-demand). **First invocation = self-audit the plugin's own ~770 bashunit tests** (falsifiability dominant; folds in R14 + the "all tests structural" finding). Full rubric: `research/plugin-upgrade/tdd-review-criteria.md` (knowledge-pack workspace — transplant when building R4c). See [[upgrade-roadmap]] [[prime-directive]] [[dev-process]].
