# R1 Langpack × tdd-workflow — Reconciliation (canonical merge) — v3 FINAL

> **Merges:** advisor trace (`/tmp/r1-synergy-trace-advisor.md`) + plugin trace A (`/tmp/r1-langpack-trace-A.md`); compare (`/tmp/r1-trace-compare-advisor.md`); PS review (`/tmp/r1-trace-reconciliation-PS-review.md`).
> **Status:** **FINAL** — PS CONCUR + A1/A2/A3 folded; Hugo ACCEPTED; **C3 RULED = warn-and-proceed**. Next: apply §D to §8/§9 (both copies) + memory; both sessions plan R1.
> **On acceptance:** §D deltas fold into §8/§9 of both exploration-doc copies; then slice R1.

---

## A. Settled findings — converged, zero contradictions (LOCKED)
1. The language matrix is **hardcoded across 8 sites** (+1 dup, +content) — see §B.1. R1's thesis = collapse them into `pack.json` as the single source.
2. **The verifier + releaser + doc-finalizer consume no pack** — they hardcode the entire test/lint/format chain; §8 gives a *model* no channel to receive it.
3. **§8.2 lacks `lint`/`format` commands** (only `test`).
4. **Standards arrive via the `project-conventions` skill-DCI** (agent frontmatter `skills:` → `!load-conventions.sh`), *not* `SessionStart additionalContext`. SubagentStart carries git-status only.
5. `fetch-conventions.sh` is a bare fetcher — **no detect, no version-pin**; binding is abspath/URL-flat (no version).
6. **No-pack degrade is a behavior change, not a no-op:** the hardcoded chains *are* the fallback; stripping them drops an unconfigured Dart/C++ project to bashunit-only.
7. C++ `auto-run-tests` runs `cmake --build` only — **never executes tests** (false-green); `auto-run-tests` is **informational** (`systemMessage`), not blocking.
8. Worktree-isolation propagation — **resolved by design (C1/A2):** subagent models resolve the *committed* `.claude/tdd-conventions.json` (present in every checkout incl. worktrees, per §10's portability requirement) → abspath cache → `pack.json`; no reliance on session env-export reaching subagents. *(Closes G9.)*

## B. Merged superset (union of both traces)
### B.1 Hardcoded-language sites — 8 (+1 dup, +content)
1. `scripts/load-conventions.sh` — 4 project types + skill-dir names + content layout
2. `scripts/detect-project-context.sh` — `test_runner` (by `command -v`)
3. `hooks/auto-run-tests.sh` — ext→cmd; **C++ build-only**; impl→test map; informational
4. `hooks/validate-tdd-order.sh` — test-file vs source patterns (RED gate)
5. `agents/tdd-verifier.md` — test + analyze + coverage (in prompt)
6. `agents/tdd-releaser.md` — test + analyze + **format** + version (in prompt)
7. `hooks/planner-bash-guard.sh` — `flutter dart fvm` allowlist **blocks C++ research tooling** *(PS A-catch)*
8. `scripts/bump-version.sh` — version-bearing files + formats for **6 ecosystems** *(PS A1; mildest, degrades gracefully; the concrete embodiment of C5's version-files)*
   *(+dup)* `skills/tdd-release` SKILL wrapper re-hardcodes test/lint/format *(PS catch)*
   *(+content)* `CLAUDE.md` residual language sections — content-sites, in R1's doc-content scope.

### B.2 Orphaned command-consumers (models, no channel today)
`tdd-verifier` · `tdd-releaser` · `tdd-doc-finalizer`.

### B.3 Gap register (deduped, prioritized)
- **P0:** site consolidation (B.1) · verifier/releaser/doc-finalizer orphans · §8.2 missing lint/format · `fetch-conventions` resolver+version-pin · binding portability (§8.6).
- **P1:** C++ build-only correctness bug · degrade-floor behavior change (ratify, C3) · impl→test map move-to-pack · skill-DCI vs additionalContext channel (→ C1, resolved).
- **P2:** `planner-bash-guard` Dart-only · `validate-tdd-order` hardcoded patterns · `bump-version.sh` 6-ecosystem · `projectFiles` no materialization owner · versioning authority (C5).
- **P3/future:** R4 `tdd-review` test-lint schema field · doc-finalizer test channel (R11) · standards-freshness ownership (R11 salvage).

---

## C. The six decisions — recommended resolutions (RATIFY)

### C1. Channel architecture — **KEYSTONE** — split-by-half synthesis *(amended per A2; PS pressure-test PASSED)*
**Resolution:** split delivery by *half*, not by *hook*.
- **Standards (model-half):** KEEP skill-DCI — `load-conventions.sh` reads `pack.json` (data-driven). Do **not** build the `additionalContext`/`reloadSkills` standards path.
- **Commands (script-half):** two consumer kinds, two robust paths:
  - **In-session script** (`auto-run-tests`, PostToolUse hook) → `$TDD_ACTIVE_PACK` env fast-path (SessionStart hook resolves binding + version-pin + exports it).
  - **Subagent models** (verifier/releaser/doc-finalizer) → resolve the **committed `.claude/tdd-conventions.json`** → abspath cache → `pack.json`; read **`jq '.commands'` ONLY**, never `standards.index`.
  - **No consumer depends on unverified env→subagent propagation** — all can fall back to the committed-binding resolution. (Mirrors today's proven skill-DCI reading `$CLAUDE_PLUGIN_DATA` inside subagents.)
**Why:** delivers commands to the orphaned models without over-contexting the blackbox (the `commands{}`-only guard); the committed-binding path **closes G9 (worktree) for free** and drops the keystone's dependency on the one unproven mechanism; recharacterizes PS's "linchpin" (G1) from *additionalContext-unbuilt* → *resolver-unbuilt* (smaller); keeps working skill-DCI. **Correctness bonus:** pack-sourced commands eliminate the 3-way drift (`cmake --build` vs `ctest` vs `ctest --test-dir build/`) — same root cause as the C++ false-green bug. *Resolves advisor-G5 ⇄ PS-G1.*
**Pressure-test — ANSWERED (PS):** Q1 verifier reads `pack.json` under `plan`+`disallowedTools` → **YES** (`disallowedTools` blocks *write* tools only; the verifier already runs the suite via Bash — reading JSON is strictly less invasive). Q2 blackbox dilution → **NO**, scoped to `commands{}`.

### C2. §8.2 schema — **G0 RATIFIED (Hugo)**
`commands.test` is the **rich object** (so C++'s 3-step encodes — a flat string can't, which is the false-green root); `lint`/`format`/`coverage` are **siblings** (string | `{setup?[],run,passOn}`); `testFilePattern` (feeds `validate-tdd-order`), `implToTestMap` (feeds `auto-run-tests`), `versionFiles[]`, `projectFiles[]` top-level; `detect`+`standards` per §8.2. Canonical `pack.json`:
```jsonc
{ "schemaVersion": 1, "name": "…", "version": "…", "language": "…",
  "detect": { "extensions": ["…"], "markers": ["…"] },
  "commands": {
    "test":  { "granularity": "file|suite", "setup": ["…"], "run": "…{file}…", "variants": ["…"], "passOn": "exitZero" },
    "lint": "…", "format": "…", "coverage": "…" },
  "testFilePattern": "…", "implToTestMap": "…",
  "versionFiles": ["…"], "projectFiles": ["…"],
  "standards": { "index": "SKILL.md", "dir": "standards/" } }
```
(`setup`/`variants` optional; future `review`/`testLint` for R4.)

### C3. No-pack degrade floor — **RULED (Hugo): warn-and-proceed**
When no pack resolves for a detected **non-bash** language: the plugin **warns** — *"no convention pack for &lt;lang&gt;; TDD will proceed on training data + session context only"* — and **proceeds**. No hard stop, no hardcoded fallback chain. *PRIME-safe* (core works pack-less), *honest* (degradation surfaced), *zero drift* (no fallback to maintain). **Nuance:** the *model* agents (planner/implementer/verifier/releaser) carry the loop on training knowledge; the *script* hooks that can't use training data (`auto-run-tests`) no-op for that language (bashunit stays the only built-in script default). The warning fires from the **SessionStart resolver** when a language marker is detected but no pack resolves.

### C4. `projectFiles` materialization owner — the resolver
At pack-resolution, **materialize `pack.projectFiles` into the project root if absent, non-destructively** (never overwrite an existing file).

### C5. Versioning/commit authority — SCOPE-SPLIT *(refined per A3)*
- **Core owns** the *universal* logic: **SemVer semantics** (the MAJOR/MINOR/PATCH decision — don't fragment it across packs) + the TDD *commit cadence* (`test:`→`feat:`→`refactor:` + RGR gates).
- **Pack owns** the *ecosystem-specific* policy: **version-bearing files + format** (→ `bump-version.sh` becomes pack-driven, site #8), commit-message format, changelog format. The releaser reads the **pack** for files/format, **core** for the MAJOR/MINOR/PATCH call.

### C6. `project-conventions` skill disposition — KEEP as dispatcher
Plugin's `project-conventions` skill stays the **language-agnostic dispatcher** (DCI → `load-conventions.sh` → `pack.json`). The pack's `SKILL.md` is **index content the dispatcher injects**, not a competing frontmatter-loaded skill → **no collision**. Agents keep `skills: project-conventions`.

---

## D. Resulting §8/§9 deltas (apply on acceptance)
- **§8.2** → `commands{test,lint,format,coverage}` + `testFilePattern` + `implToTestMap` (+future `testLint`). [C2]
- **§8.4** → REWRITE: SessionStart hook = *resolve binding (version-pin) + export `$TDD_ACTIVE_PACK`* (in-session fast-path); standards stay via skill-DCI; **subagent models resolve the committed binding themselves** (A2); **drop** additionalContext/reloadSkills standards path. [C1]
- **§8.5** → dispatcher (`auto-run-tests`, in-session) reads `pack.commands.test` via `$TDD_ACTIVE_PACK`; **preserve informational `systemMessage`** (remove `decision:block`); subagent models resolve committed binding → `pack.json`, `jq '.commands'` only. [C1, finding 7]
- **§8.6** → binding `{source, version}`; resolver clones + **checks out the tag**; binding **must be committed** (A2/§10). [P0]
- **§9** → widen "data-drive detection" to **all 8 sites** (add `planner-bash-guard`, `validate-tdd-order`, `detect-project-context`, **`bump-version.sh`**); add verifier/releaser/doc-finalizer pack-wiring (committed-binding resolution, A2); add `projectFiles` owner [C4]; degrade = **warn-and-proceed** [C3 ruled]; versioning authority — **SemVer→core, version-files→pack** [C5/A3]; skill disposition [C6]; add the **SessionStart no-pack warning**.

---

## E. Sign-off
- ✅ **PS:** CONCUR + A1/A2/A3 (folded above) — `/tmp/r1-trace-reconciliation-PS-review.md`.
- ✅ **Advisor:** authored + folded A1–A3; concur.
- ✅ **Hugo:** ACCEPTED as final; **C3 RULED = warn-and-proceed**. → next: apply §D deltas to §8/§9 (both copies) + memory; both sessions enter plan mode for R1.
