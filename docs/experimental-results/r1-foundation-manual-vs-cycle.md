# R1 Foundation Layer — Manual TDD vs the Plugin's TDD Cycle (A/B)

> **What:** the same R1 "foundation layer" feature, built twice from the same base commit — once by a careful developer doing manual test-first TDD, once through the plugin's own `/tdd-plan → /tdd-implement → /tdd-verify` cycle — then compared.
> **Why:** to measure what the cycle adds *over a disciplined human already doing test-first* — the plugin's value proposition under its own scrutiny.
> **When:** 2026-06-01 · **Branches:** A = `feature/r1-foundation` (manual) · B = `feature/r1-foundation-tdd` (cycle) · base `e14d4bb` · neither merged.

## Method
- **Shared base:** both cut from `e14d4bb`; suite floor 0 (765 local).
- **Shared input:** the reconciled R1 contract (`explorations/features/r1-langpack-reconciliation.md`, v3 FINAL) + the plugin's bootstrap `memory/`. The cycle session got **no scope list, no TDD constraints, no extra guidance** — only the contract — so its planning, scoping, and test quality reflect the cycle *unaided*.
- **Integrity:** the cycle session never read Branch A.
- **Comparison:** branch diffs + direct read of source and tests; test-function counts via `grep`.

## Scope — the cycle drew the cleaner line
| | A (manual) | B (cycle) |
|---|---|---|
| Slices | F1–F5 **+ V1** (`bump-version` pulled into the foundation for scheduling) | F1–F5 (pure read-side primitives) |
| Deferred | — | `bump-version` (a consumer) + `projectFiles` (a side-effect) → consumer cycle |

B scoped the foundation to *pure read-side primitives* and pushed consumers/side-effects out — the more principled boundary — and held a scope fence (its `resolve_active_pack_test.sh` includes an absence-guard verifying `load-conventions.sh` stays un-rewired).

## Findings (with file evidence)

### 1. Robustness — B surfaces errors; A swallows them
`scripts/read-pack.sh`:
- **A (27 lines):** `jq -r "(.${field})? // empty"` — missing manifest, malformed JSON, *and* absent field all → silent empty + exit 0. Elegant, but a **corrupt `pack.json` fails silently**; arrays are left for the caller to index.
- **B (65 lines):** validates JSON up front, projects arrays one-per-line, special-cases `commands.test.variants → .name`, and **distinguishes "absent optional → empty+0" from "missing/malformed → exit 1 + stderr."**

### 2. Completeness — B implemented a contract clause A omitted
`scripts/parse-binding.sh`: the §8.6 binding schema declares a `dev:true` local-path escape hatch.
- **B** emits `source⇥version⇥dev` (+ a `"legacy"` sentinel for legacy entries).
- **A** emits only `source⇥version` — **`dev` is absent from the parser.**

The cycle's per-clause Given/When/Then planning surfaced a requirement the disciplined human glossed.

### 3. Test depth — B wrote ~2× the tests
Test-function counts (A → B): `read-pack` 6→9 · `parse-binding` 7→9 · `resolve-active-pack` **5→10**. B split fetch-conventions into two focused files (`*_versioned` 8, `*_no_pack_warn` 6) vs A's one consolidated file. The extra tests are real edge coverage — a custom-marker *data-driven* proof, error-class distinctions, a real tag-pin check — not padding. Totals: B ~1,460 added lines vs A ~641; B final suite **807/0**.

### 4. Traceability — B leaves a paper trail
B produced `.tdd-progress.md`, a `planning/20260601_*` archive, per-slice `tdd-verifier` blackbox sign-offs, and a memory note — and was transparent about its one judgment call (the C3 marker→language map) and a cosmetic bug (a detached-HEAD stderr leak, fix deferred). A is commits only.

### 5. Where the manual build won
- **Elegance:** A's 27-line reader is genuinely tighter than B's 65-line case-statement.
- **Commit messages:** A used scoped Conventional Commits (`test(read-pack):`); B used generic (`test:`).
- **Cost:** A = one developer session; B = planner + 5×implementer + 5×verifier.
- Both held the 0-floor with clean `test:→feat:` trails.

## Verdict
The cycle's value over disciplined manual TDD is **concrete, not merely enforcement-for-the-undisciplined**: cleaner scope, more defensive primitives, ~2× edge tests, full traceability, and it **caught a spec detail (`dev:true`) the human missed.** The price: verbosity (heavy doc-comments inflate the line delta), compute (the agent fan-out), and a little elegance.

**Caveat — not a clean sweep:** B's "hard-fail on missing/malformed" vs A's "always degrade" is a genuine design *divergence*, not strictly a B-win (A's uniform-degrade is simpler for consumers); and much of B's 2.3× size is documentation, not function.

## Actionables
- **A is missing `dev:true`** — a real gap if A is the branch kept.
- **B is the stronger foundation to keep** (more complete + traceable); `bump-version`/V1 follows in the consumer cycle, where B's plan placed it.
- **Cosmetic:** B's resolver `git clone --branch <tag>` leaks a detached-HEAD advisory to stderr at SessionStart — one-line fix (`git -c advice.detachedHead=false …`) next time the resolver is touched.
