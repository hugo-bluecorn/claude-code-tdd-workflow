# Issue 013: Cycle output quality — capture the manual build's wins (scoped commits + code economy)

**Status:** deferred (vNext candidate) · **Found:** 2026-06-01 (R1-foundation manual-vs-cycle A/B dogfood)
**Evidence:** `docs/experimental-results/r1-foundation-manual-vs-cycle.md`

## Context

R1's foundation was built twice from the same base — manually (`feature/r1-foundation`, **A**) vs through the plugin's own cycle (`feature/r1-foundation-tdd`, **B**). B won decisively on completeness / robustness / test-depth / traceability — it even implemented a `dev:true` contract clause the human missed. But A won three things, **two recoverable** into the cycle.

## 1. Scoped commit messages — JOINT planner+implementer fix (recoverable, HIGH confidence; also a latent bug)

**Problem:** B emitted generic `test: add tests for read-pack.sh`; A emitted scoped `test(read-pack): …`.
**Root cause:** a planner↔implementer inconsistency. `agents/tdd-implementer.md` Git Workflow specifies the **scoped** form (`test(<scope>): …`, `<scope> = primary module/feature`), but `agents/tdd-planner.md`'s Commit Convention is **unscoped** (`test: add tests for <component>`). The implementer follows the plan it's handed, so the plan's unscoped convention undercuts the implementer's scoped instruction.
**Fix:** (a) planner adds an explicit `**Scope:**` field per slice (from the slice's primary module); (b) align the planner's commit convention to the scoped form. Testable (assert the plan emits a scope; assert the convention is scoped).
**Note:** this is a real inconsistency bug independent of the A/B, and it is **NOT gated on the packs** — it could land anytime as a quick win.

## 2. Code economy / elegance — Standards + Implementer (recoverable, MED-HIGH confidence; GATED on the packs)

**Problem:** B's `read-pack.sh` = 65 lines (~25 of doc-comment) vs A's 27; B used a case-statement where A used a clean one-liner.
**Root cause — a genuine gap, not a bug:** nothing in the cycle targets concision. The planner is WHAT-not-HOW by design; the implementer's "minimum code" means *scope* (no feature-creep), not *style*; and REFACTOR is (a) skipped on net-new and (b) its checklist (`duplicated code, naming clarity, unnecessary complexity`) omits doc-proportionality / idiom.
**Caveat:** most of B's extra *code* is justified robustness (the planner's edge-tests drove it — the win). A's concision was partly *doing less* (silent-degrade). The recoverable target is **gratuitous** verbosity (doc-bloat + non-idiomatic constructs), NOT the functional code. Robust-and-concise is reachable; B was over-verbose beyond its robustness.
**Fix (architecture-aligned):** language-specific *style* belongs in the **pack coding standards** the implementer reads (per R1) — add a style dimension (*"doc-comments proportionate to complexity; idiomatic constructs; a thin passthrough should look thin"*); the implementer applies it in GREEN + an extended REFACTOR checklist (verbosity/doc/idiom), nudging a light pass even on net-new.
**Why gated:** the fix's home — the pack standards — doesn't exist until the language packs are built. Correctly sequenced AFTER R1 + the packs.

## 3. Lower cost — NOT recoverable (structural)

A = one session; B = planner + 5×implementer + 5×verifier. The fan-out IS the price of the thoroughness that won.

## Validation — follow-up A/B (after the current release + language packs)

Once R1 + the language packs are done, re-run the foundation (or a comparable feature) through the **improved** cycle (Scope-field + scoped convention + the standards style-dimension) → compare to A (or B). **Prediction:** B′ yields scoped commits + leaner scripts (esp. doc headers) at the SAME robustness / completeness / coverage. The plugin should be **better positioned** by then: the packs exist (the style-dimension's home), the core is language-agnostic, and the cycle has been hardened through R1's own implementation.

## Scope note

This is **quality/polish** (better cycle *output*), not new capability. Prioritize against the rest of the roadmap (R4 verifier determinism, R4c tdd-review, R5 refactor mode, the R1 consumer fan-out). §2 (elegance) pairs naturally with the pack-build + R4c (also test/code-quality work); §1 (commits) is independent and can land anytime.
