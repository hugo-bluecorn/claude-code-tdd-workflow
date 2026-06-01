# Issue 014: R1 foundation hardening — adversarial-retro findings (dev-pack fetch, polyglot ctest, lib/ mangle)

**Status:** scheduled (Wave 3 opening slices, #1 first) · **Found:** 2026-06-01 (advisor adversarial retro of merged R1 PRs #23 foundation + #27 Wave 1)
**Method:** code-vs-contract read of every runtime-bearing R1 script, hunting *not* "do tests pass" (they do) but "does this survive a **real** pack/project + honor the reconciled contract." Synthetic fixtures + green tests hid these.

## Operational classification (block / break / edge)

Recast of the retro in the terms that decide urgency:
- **Block** = hard-stops the workflow (exit 2 / crash / abort). **NONE found** — PRIME-safe degrade held everywhere; every hook `exit 0`s.
- **Break** = proceeds but does the *wrong* thing.
- **Edge** = only under a rare trigger, or cosmetic.

| # | Finding | Block | Break | Edge | Bites when |
|---|---------|:-----:|:-----:|:----:|-----------|
| **1** | dev-pack tab-collapse (`fetch-conventions.sh`) | no | **YES** | **no** | **Any `dev:true` binding — every session the moment a langpack is dev'd** |
| 2 | head-1 defeats C++ ctest (`auto-run-tests.sh`) | no | yes | yes | Polyglot repo, ≥2 packs bound, non-matching pack declared first |
| 3 | `lib/` sed mangle (`auto-run-tests.sh derive_test_file`) | no | yes | yes | A path segment ends in "lib" (`mylib/`, monorepo) |
| 4–10 | latent / cosmetic (below) | no | no | yes | Future packs/consumers, or never |

**Headline:** zero block; exactly one breaks in normal use (**#1**, tied to the pack-author workflow R1 enables); two break only under an edge trigger (#2, #3); the rest are latent traps or cosmetic.

---

## H1 (#1) — `fetch-conventions.sh` mis-parses every `dev:true` pack → bogus `git clone` each SessionStart  ·  PRIORITY

**Severity:** medium · **Confidence:** high (data-flow traced + the codebase's own comment confirms the trap + the test is proven blind).

**Root cause — an internal inconsistency the repo already knows about.** `scripts/active-pack.sh:83-97` *documents* that a dev pack emits two adjacent tabs (empty `version`) and that `IFS=$'\t' read` collapses them (TAB is IFS-whitespace), so it hand-rolls a manual split to preserve the empty field. **`hooks/fetch-conventions.sh:110` then uses the exact naive `while IFS=$'\t' read -r source version dev` it warns against.**

Trace for a dev binding `{"packs":[{"source":"~/pack","dev":true}]}`:
- `parse-binding` emits `~/pack\t\tdev` (source, **empty version**, dev).
- naive read collapses the adjacent tabs → `source=~/pack`, `version="dev"`, `dev=""`.
- dev-skip (`:114` `[ "$dev" = "dev" ]`) is **missed**; `[ "$version" = "legacy" ]` false; `[ -n "$version" ]` **true** → `fetch_versioned "~/pack" "dev"`.
- `fetch_versioned`: local path isn't a fetchable URL → normalized to `https://~/pack` → `git clone --quiet --branch dev https://~/pack …` → **fails** (bogus host), logs `failed to clone … at version dev`, `rm -rf` the partial.

**Impact:** does NOT block (hook `exit 0`s) and standards still deliver (load-conventions uses `active-pack.sh`, the *correct* parser). But every session start does a failed clone + confusing stderr + latency (fails fast on DNS, not a hang) — for *exactly* the dev-binding pack-author flow R1 is built to enable. Also a partial fulfilment-gap against the plan's **design decision #1** ("tests prove the committed-binding fallback with the env var unset"): the dev path IS that fallback, and it's broken.

**Why it shipped green — confirmed, not assumed.** `test/hooks/fetch_conventions_versioned_test.sh` Test 4 `test_dev_source_is_not_fetched` binds `{"packs":[{"source":"$repo","dev":true}]}` and asserts the **end-state** `count==0` cache dirs (`:167-170`). The buggy path attempts the clone, *fails, and `rm -rf`s the partial* → still `count==0` → **passes**. The assertion cannot distinguish "skipped" from "tried-and-failed-and-cleaned-up." (It even passes partly by luck — the fixture has no `dev` tag; a fixture with one would have *created* `…@dev` and flipped the test red.)

**Fix (DRY + architectural):** factor the binding-iteration out of `active-pack.sh` into one shared helper that both consumers call — kills the divergence permanently rather than patching the same trap twice. Independent of Wave 2/3; landable anytime.

**Test-design lesson (apply to ALL three fixes):** when a failure mode reproduces the success end-state, **assert the ACTION, not the end-state.** Here: spy that `git clone` is never invoked for a dev pack (PATH-shim a fake `git` that records its args, or assert no `failed to clone` on stderr), not just "no cache dir after."

---

## H2 (#2) — `auto-run-tests.sh` head-1 quietly resurrects the C++ false-green in polyglot repos

**Severity:** medium-low (edge-triggered) · **Confidence:** high (code-traced).

`:47` `PACK_DIR=$(active-pack … | head -1)`, then `:51-53` checks only *that* pack's `detect.extensions`. In a repo with both a dart and a cpp pack bound, dart declared first: editing a `.cpp` → `.cpp ∉ dart.extensions` → falls through to the **built-in** C++ branch (`:107-112` `cmake --build` only, **no ctest**) — i.e. the precise false-green that Wave-1 commit `4a8a973` was written to kill comes back. The plan's "C++ fix proof" (impl-plan §Verification) only exercises the cpp fixture **in isolation** (single pack), so the head-1 gap was never proven against.

**Fix:** select the resolved pack whose `detect.extensions` contains the edited file's ext, not `head -1`. (`active-pack`/`resolve-active-pack` already emit *all* matches in order — iterate, don't truncate.)

---

## H3 (#3) — `derive_test_file` `s|lib/|test/|` mangles any path with a component ending in "lib"

**Severity:** low-medium · **Confidence:** high (code-traced).

`hooks/auto-run-tests.sh:30` unanchored sed: `packages/mylib/lib/foo.dart` → the *first* `lib/` is inside `my**lib/**` → `packages/mytest/lib/foo_test.dart` (wrong dir) → "No matching test file found" → the auto-test feedback is silently unhelpful. Hits monorepos / nested packages.

**Fix:** anchor to a path segment — `s|(^\|/)lib/|\1test/|`.

---

## Deferred — latent / cosmetic (#4–#10), vNext or pack-author docs

Not live breaks; several are really "things to tell pack authors," not code bugs.

- **#4 `resolve-active-pack.sh` extension detection is `maxdepth 1`** (`:75`) — *shallower* than the legacy `load-conventions has_files` (`:55`, recursive) it replaces. A pack with **no markers** relying on `detect.extensions` won't resolve for nested source (the normal `lib/`/`src/` layout). Markers carry the common cases → latent. **Doc:** "markers do detection; extensions barely fire."
- **#5 `read-pack.sh` `// empty` eats falsey scalars** (`:61` — a boolean-`false`/`null` field reads as absent; none live), and **array-of-objects fields print raw JSON** (`versionFiles` object-form, `implToTestMap`) though the header (`:10`) lists them as supported. V1 already routes around object-form via `jq` directly. **Doc:** read-pack is scalars + scalar-arrays only.
- **#6 `eval` of pack command + unsanitized `{file}`** (`auto-run-tests.sh:59,61`) — injection via a crafted filename (`a; rm -rf ~.dart`). Pack semi-trusted; filename from tool_input. Low odds, real vector.
- **#7 suite-granularity re-runs `setup[]` (cmake *configure*) on every save** (`:81-85`) — no "configure once" guard, unlike the built-in branch's own `[ -d build ]` (`:108`). Perf, not correctness; slows real C++ TDD.
- **#8 marker→language knowledge triplicated** — resolve-active (data) / fetch-conventions C3 map (`:142`) / load-conventions legacy (`:146`). Drift surface.
- **#9 `read-pack` builds its jq program by string-interpolating `field_path`** (`:61`) — internal callers only; `getpath(split("."))` is the robust idiom.
- **#10 doc-disproportion** (read-pack 26 doc / 39 code) — the issue-013 §2 pattern; cosmetic.

## What held up (worth recording)
`active-pack.sh` (the tab trap, dev-`~` expansion, PRIME-safe degrade) and `planner-bash-guard.sh` (union-floor that only ever *adds* binaries) are well done. Degrade contracts are consistent. RED-first `test:`→`feat:` trails clean on both PRs. The A/B's feared B-style bloat did **not** materialize — the foundation is lean.

## Sequencing (ratified 2026-06-01)
Fold into **Wave 3 as its opening slices**: **H1 → H2 → H3, then T1 (projectFiles) / T2 (CLAUDE.md cleanup).** H1 first because it must precede langpack-dev. One cycle, no extra wave — R1 still closes in three waves. Each fix's FFT asserts the **action**, per the lesson above. #4–#10 → vNext / pack-author docs. See `explorations/features/r1-implementation-plan.md` Wave 3.
