---
name: test-suite
description: How to run the bashunit suite (≈770 tests) and the ~48 known-non-defect failures — don't misread them as breakage.
metadata:
  type: project
---

Test framework: **bashunit 0.32.0**, vendored at `lib/bashunit` (committed; no Makefile/package.json/.bashunit.yml).

```bash
./lib/bashunit test/                              # full suite (~770 tests)
./lib/bashunit test/hooks/check_tdd_progress_test.sh   # single file
./lib/bashunit test/hooks/                        # single directory
```
Layout mirrors source: `test/{agents,hooks,integration,scripts,skills}/`. Test count is **~770** (the CHANGELOG's "691" is stale — counts stopped being maintained after v1.14.0). New work writes the failing test first ([[dev-process]]).

**⚠️ A clean run currently shows 727 passed / 43 failed / 770 total — all 43 are environmental/staleness, NOT defects.** Re-measured 2026-05-30 (this session). Two buckets remain (the old "shellcheck not installed" bucket is GONE — see below):
1. ~~**`shellcheck` not installed**~~ **RESOLVED** — `shellcheck` IS installed now (0.11.0, `/usr/bin/shellcheck`). This bucket no longer fails. (The bootstrap claim "~48 / missing shellcheck" was stale.)
2. **gitignored `.claude/settings.local.json` absent** (9 tests, all in `test/agents/tdd_verifier_bash_test.sh`). It's developer-created (`.gitignore`), not committed — create it locally to clear. **R14 scope note:** R14 must make these 9 tests **skip-when-absent** (the file is gitignored, so CI/fresh-clone never has it) — clearing the 34 README failures alone won't reach a green floor for Wave 2; the settings tests must skip gracefully when the file is missing.
3. **Stale README assertions** (~34 tests) — they assert exact README strings the v2.x rewrite removed. Spread across SIX files, not just `integration/`: `test/integration/{bash,release,convention_loading,c}_documentation_test.sh` + `test/skills/role_docs_test.sh` + `test/scripts/version_control_location_test.sh`. → roadmap **R14** reconciles them (update README to satisfy, or retire the stale assertions). **DELETE this whole caveat once R14 greens the suite.**

**Attribution gotcha:** bashunit prints each failure twice (inline + an end-of-run summary); the summary half all appears under whatever `Running test/...` header printed last, so naive `awk` attribution over-attributes to one file (it made `tdd_release_test.sh` look like it had 43 failures — it passes 8/8 alone). Trust per-file runs, not full-suite header attribution.

**Do not treat these 48 as core breakage.** Before trusting "green," install shellcheck + create the settings file, or scope your run to the dirs you changed. Note also: both dead commands have *structural* tests (frontmatter/shape) but **no tests verify output usefulness** — a green suite does not prove a command works. See [[upgrade-roadmap]] [[decisions]].
