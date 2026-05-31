---
name: test-suite
description: How to run the bashunit suite and read its results. As of R14 the suite is a genuine 0-failure floor (local AND CI).
metadata:
  type: project
---

Test framework: **bashunit 0.32.0**, vendored at `lib/bashunit` (committed; no Makefile/package.json/.bashunit.yml).

```bash
./lib/bashunit test/                              # full suite
./lib/bashunit test/hooks/check_tdd_progress_test.sh   # single file
./lib/bashunit test/hooks/                        # single directory
```
Layout mirrors source: `test/{agents,hooks,integration,scripts,skills}/`. New work writes the failing test first ([[dev-process]]).

**✅ As of R14 (2026-05-31, v2.4.5) the suite is a genuine 0-failure floor:**
- **Locally** (developer machine, `.claude/settings.local.json` present): **765 passed / 0 failed**.
- **Fresh clone / CI** (gitignored settings file absent): **756 passed / 9 skipped / 0 failed** — the 9 settings tests in `test/agents/tdd_verifier_bash_test.sh` now SKIP when the file is absent (bashunit `bashunit::skip`, see [[bashunit-skip-idiom]]), instead of failing.

**What R14 fixed (the old ~34/43 "floor" is GONE):**
- `shellcheck` is installed (0.11.0) — the old "not installed" bucket was already moot.
- The 9 settings tests are now skip-when-absent (CI-safe).
- The ~34 stale-README assertions (which pinned the pre-v2 README structure the rewrite removed) were RETIRED or de-brittled (FIX-GREP) across 6 files; `c_documentation_test.sh` was renamed to `language_documentation_test.sh`.

**Attribution gotcha (still true):** bashunit prints each failure twice (inline + an end-of-run summary under the last-seen `Running test/...` header), so naive `awk` attribution over-attributes to one file. **Trust the `Tests: N passed, M failed, T total` SUMMARY LINE**, not per-file header scraping.

**A green suite still isn't proof of usefulness:** the two dead commands have structural (frontmatter/shape) tests but no output-usefulness tests — a green run does not prove a command works. See [[upgrade-roadmap]] [[decisions]].
