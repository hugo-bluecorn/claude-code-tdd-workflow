# R1 Plugin-Side — Language-Pack Interface (TDD implementation plan)

> **Provenance:** PS's ratified R1 implementation plan (plan-mode output, G0-ratified), harvested verbatim from session before PS shutdown so the cross-wave sequencing isn't lost. The contract it implements is `r1-langpack-reconciliation.md` (v3 FINAL). **Wave 0 is already built** on `feature/r1-foundation-tdd` (B); this file's remaining value is **Waves 1–3** (the consumer fan-out). Each wave is re-`/tdd-plan`-able from the contract — keep this for its worked-out DAG, FFTs, and removal-sweeps.

## Context
R1 re-platforms the tdd-workflow plugin from a language-agnostic core + hardcoded language matrix into a core that reads per-language `pack.json` manifests. This plan implements only the **plugin side** — the dart/cpp packs are deferred (built elsewhere), so every consumer is tested against synthetic fixture `pack.json` files.

**Honored constraints:** ① planner-removal-sweep — each slice that removes a hardcoded site reconciles the existing tests asserting old behavior (mapped per slice). ② PRIME-safe degrade — warn-and-proceed; core `tdd-*` works pack-less; bashunit stays the built-in script default. ③ legacy-binding back-compat — old `{"conventions":[url|abspath]}` still resolves.

## Gate G0 — unified `pack.json` schema — RATIFIED
`commands.test` = the rich object `{granularity, setup[]?, run, variants[]?, passOn}` (so C++'s 3-step encodes; a flat string can't — the false-green root); `lint`/`format`/`coverage` siblings (string | `{setup?[],run,passOn}`); `testFilePattern`/`implToTestMap`/`versionFiles`/`projectFiles` top-level; `detect`+`standards` per §8.2.

## Test strategy (pack deferred)
- **Fixture packs:** tests create a temp dir with a synthetic `pack.json` (dart single-step + cpp 3-step/variants); shared `test/fixtures/`.
- **Dual-track for C1 (`load-conventions`):** its existing tests clone the real `tdd-workflow-conventions` repo and assert real content (Riverpod/GoogleTest/Unity/BARR-C) — detection tests use a fixture pack; **content-delivery tests keep cloning real.**
- **Floor:** 0 failed (765 local / 756+9skip CI). Removal-sweeps **rewrite** old-behavior tests, never just delete.
- **Env-propagation:** never depend on a live SessionStart export; `export TDD_ACTIVE_PACK=$fixture` as a test shortcut **+** a separate test proving the committed-binding fallback works with the env var unset.

## Waves & slices
Legend — FFT = first-failing-test · dep = hard prerequisite · sweep = old-behavior tests to reconcile.

### Wave 0 — Foundation (BUILT on B; here for completeness)
- **F1 `scripts/read-pack.sh`** — read a manifest field; missing → empty+exit 0 (blackbox-safe). dep: G0.
- **F2 `scripts/parse-binding.sh`** — parse `{packs:[{source,version,dev?}]}` + legacy `{conventions:[…]}`. dep: —. sweep: keep legacy assertions.
- **F3 evolve `hooks/fetch-conventions.sh`** → resolver: clone + `git checkout <version>`; legacy = HEAD. dep: F2. sweep: `fetch_conventions_test`, `external_conventions_repo_test`, `convention_loading_integration_test` (back-compat anchors stay green); must not add a 2nd `async:true` hook.
- **F4 `scripts/resolve-active-pack.sh`** — cwd markers × `pack.detect` → active pack dir(s); export `$TDD_ACTIVE_PACK`. dep: F1,F2.
- **F5 warn-and-proceed floor (C3)** — advisory marker→label map, warning-only, never command-bearing. dep: F4. (acknowledged advisory-only residual.)

### Wave 1 — Consumer fan-out (each depends on F1 + the resolve-active-pack pattern; otherwise mutually parallel)
- **C1 `load-conventions.sh`** — data-drive detection (replace 4 hardcoded dirnames with F4); keep content output + skill-DCI. dep: F1,F4. sweep: `load_conventions_test` + `load_conventions_config_test` (4 dirnames). Dual-track: content tests keep real clone.
- **C2 `auto-run-tests.sh`** — data-drive `.dart` (+ any pack ext) via `commands.test`; keep `.sh→bashunit` built-in; preserve informational `systemMessage`. dep: F1. sweep: `auto_run_tests_test` dart/sh paths.
- **C3 `auto-run-tests.sh` C++ false-green FIX** — run `commands.test.setup[]` then `ctest`, not `cmake --build`. dep: C2. sweep: flips `test_cpp_*_runs_cmake` (2 tests) → assert ctest.
- **C4 `validate-tdd-order.sh`** — read `testFilePattern`; `.sh` built-in; unknown ext + no pack → pass-through (degrade). dep: F1. sweep: `validate_tdd_order_test`.
- **C5 `tdd-verifier.md`** — resolve committed binding → `jq '.commands'` only (test/lint/coverage), commands-only blackbox guard; bashunit/shellcheck built-in. dep: F1,F4. sweep: TWO files — `tdd_verifier_bash_test` and `language_documentation_test`.
- **C6 `detect-project-context.sh`** — `test_runner` ← pack `commands.test` (net-new test); data-drive the `test_count` glob. dep: F1. sweep: `detect_project_context_test` test_count glob.
- **C7 `planner-bash-guard.sh`** — UNION built-in safe floor (git+read tools) with binaries from resolved `pack.commands`; never replace. dep: F1,F4. sweep: `planner_bash_guard_test` Test 5 (enumerated allowlist incl. flutter/dart/fvm must stay green via the floor).

### Wave 2 — Version-authority chain (ordered: the longest serial pole)
- **V1 `bump-version.sh`** — read `pack.versionFiles`+format; keep `plugin.json` self-host built-in. dep: F1. sweep: `bump_version_test` (6 ecosystems → pack-driven + plugin.json built-in).
- **V2 `tdd-releaser.md` quality chain (Steps 1-3)** → `pack.commands.{test,lint,format}`; keep an example (e.g. `dart format`) so Test 8 survives. dep: F1,V1. sweep: `tdd_releaser_test` chain assertions.
- **V3 C5 authority split + de-pollute `version-control.md`** — SemVer semantics → core; ecosystem cmds → pack; also fix line 165 "Squash and merge" → never-squash. dep: V2. sweep: `version-control.md`, `version_control_location_test`, `release_version_test`, `tdd_releaser_test` (Tests 10/12 ref the doc).
- **V4 de-hardcode `skills/tdd-release/SKILL.md` wrapper** (lines 26-34 duplicate the chain). dep: V2. sweep: `tdd_release_test`.

### Wave 3 — Cross-cutting tail + foundation hardening
**Opens with the R1-retro hardening fixes (issue 014), H1 first — H1 must precede langpack-dev. Each FFT asserts the ACTION, not the end-state — the #1 false-green lesson: a failed-and-cleaned-up clone reproduces the "no cache dir" success state, so end-state assertions are blind to it.**
- **H1 `fetch-conventions.sh` dev-pack tab-collapse fix (issue 014 #1, PRIORITY)** — `:110` naive `IFS=$'\t' read` collapses a dev pack's empty-version adjacent tabs → mis-fires `git clone --branch dev https://~/…` every SessionStart. Fix = share ONE binding-iteration helper with `active-pack.sh` (which already hand-rolls the split it warns about at `:83-97`). dep: F2,F3. sweep: `fetch_conventions_versioned_test` Test 4 — re-assert via a `git`-clone spy (clone NEVER invoked for a dev pack), NOT end-state `count==0` (which the bug passes).
- **H2 `auto-run-tests.sh` polyglot head-1 fix (issue 014 #2)** — `:47` `head -1` + single-ext check lets a non-matching first-declared pack fall through to the built-in C++ branch (cmake-only, no ctest) → resurrects the C3 false-green in polyglot repos. Fix = pick the resolved pack whose `detect.extensions` contains the edited ext (iterate all matches, don't truncate). dep: C2,C3. sweep: add a two-pack polyglot fixture asserting ctest fires for `.cpp` when a dart pack is declared first.
- **H3 `auto-run-tests.sh` derive_test_file `lib/` mangle fix (issue 014 #3)** — `:30` unanchored `s|lib/|test/|` rewrites `mylib/`→`mytest/`. Fix = anchor to a path segment `s|(^\|/)lib/|\1test/|`. dep: C2. sweep: `auto_run_tests_test` — add a nested `packages/<x>lib/lib/` case.
- **T1 `projectFiles` materialization (C4)** — resolver materializes `pack.projectFiles` into project root if absent, non-destructive; warn on drift. dep: F3.
- **T2 `CLAUDE.md` residual-language cleanup** — remove C content but keep the `### C Testing` header while dir-names absent. dep: C1,C5. sweep: `convention_loading_documentation_test` (both-sided fence), `bash_documentation_test`, `language_documentation_test`.

**Dropped:** `tdd-doc-finalizer` slice — verified already language-agnostic (Step 4 "run the project's test suite", no hardcoded command); when a pack IS bound, have it read `commands.test` via `resolve-active-pack` (light touch, not a slice).

## Dependency DAG & critical path
```
G0 (schema) ─► F1 ─┬─► F4 ─► F5
                   ├─► C1,C2,C4,C5,C6,C7   (fan-out — mutually parallel)
                   └─► V1 ─► V2 ─► V3 ─► V4   (serial: version authority)
F2 ─► F3 ─► T1        C2 ─► C3        F1,C1,C5 ─► T2
```
- Foundation depth = 2 (roots F1∥F2; then F3∥F4; then F5) — not a 5-chain.
- Consumer waves are a FAN-OUT from F1 (only intra-edge C2→C3).
- **Critical path = G0 → F1 → V1 → V2 → V3 → V4** (version-authority is the longest serial pole, gated only by F1). Start V1 right after F1.

## Key design decisions (agent-validated)
1. No consumer depends on `$TDD_ACTIVE_PACK` env→subagent propagation. In-session script (`auto-run-tests`) uses the env fast-path; subagent models resolve the committed binding themselves. Tests prove the fallback with the env var unset.
2. Verifier reads `jq '.commands'` ONLY — never `standards.index` — preserving its blackbox stance.
3. F5 + C7 carry intentional built-in floors (warn-list; planner safe-tools), advisory/PRIME-safe, asserted never command-bearing.
4. V1 before V2 (version-files seam): `bump-version.sh` becomes pack-aware internally; releaser keeps calling it positionally.

## PR / dogfood structure
Each wave = one `/tdd-plan → /tdd-implement → /tdd-release` cycle = one PR (no-squash, preserving `test:→feat:→refactor:`). Order: Wave 0 → (Wave 1 ∥ start Wave 2) → Wave 3. Wave 0 merges first. Sizes: W0 (5), W1 (7), W2 (4), W3 (5: H1,H2,H3 hardening + T1,T2). H1–H3 from the post-merge retro (issue 014).

## Verification
- Per slice: `./lib/bashunit test/<dir>/<file>_test.sh` RED→GREEN; then full suite `./lib/bashunit test/` — `0 failed`.
- shellcheck on every changed `.sh`.
- Degrade proof: a temp project with a marker + no binding → SessionStart warns, suite still runs.
- Back-compat proof: legacy binding → resolver still clones.
- C++ fix proof: cpp fixture → `auto-run-tests` emits a ctest invocation (not cmake-only).

## Risks / open
- T2 doc-fence is a tight needle (remove dir-names, keep `### C Testing` header) — resolve by updating the doc-test.
- Pack-side `pack.json` authoring is out of scope (deferred); fixtures stand in.
