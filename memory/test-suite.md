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

**⚠️ A clean run currently shows ~722 passed / ~48 failed — the 48 are environmental/staleness, NOT defects.** Three buckets:
1. **`shellcheck` not installed** (~5–6 tests, exit 127). Fix: `apt-get install shellcheck`.
2. **gitignored `.claude/settings.local.json` absent** (~9 tests). It's developer-created (`.gitignore`), not committed — create it locally.
3. **Stale `test/integration/*_documentation_test.sh`** (~30+ tests) — they assert exact README strings the v2.x rewrite removed (e.g. `grep -c "bashunit" README.md` = 0; per-file agent/skill tree replaced by prose tables). **These tests and the README are out of sync** → roadmap **R14/R15** reconciles them (update README to satisfy, or retire the stale assertions).

**Do not treat these 48 as core breakage.** Before trusting "green," install shellcheck + create the settings file, or scope your run to the dirs you changed. Note also: both dead commands have *structural* tests (frontmatter/shape) but **no tests verify output usefulness** — a green suite does not prove a command works. See [[upgrade-roadmap]] [[decisions]].
