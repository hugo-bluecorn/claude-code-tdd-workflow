---
name: conventions-and-methods
description: The convention-loading mechanism (current + the R1 re-platform target) and the upgrade methods (audit v2.0 / evolution v1.0 / /upgrade) + where the full artifacts live.
metadata:
  type: reference
---

## Convention loading (current → R1 target)
The plugin ships **zero language content** (language-agnostic since v2.0.0). Today: `.claude/tdd-conventions.json` → SessionStart `hooks/fetch-conventions.sh` git-clones sources into `${CLAUDE_PLUGIN_DATA}/conventions/` → `skills/project-conventions/SKILL.md` runs `scripts/load-conventions.sh` via DCI, which detects project type (**hardcoded** dirnames: `pubspec.yaml`→`dart-flutter-conventions`, etc.) and `cat`s the matching `SKILL.md` + `reference/*.md`. Official packs repo: `hugo-bluecorn/tdd-workflow-conventions`. Limits: `${CLAUDE_PLUGIN_DATA}` unset under `--plugin-dir`; hardcoded dirnames (your pack works only if named exactly `dart-flutter-conventions/`); no version pinning.
**R1 re-platform ([[decisions]]):** move to **`userConfig`** (config the repo at enable-time) + **`skills-dir`** convention plugins (data-drive detection, independent versioning); keep the JSON path as fallback; core stays pack-optional.

## The upgrade instruments (how this roadmap was produced; reuse to re-audit)
Full docs in `research/plugin-upgrade/` (knowledge-pack workspace); transplant into `docs/extensibility/` when implementing R-items that touch them. Versioned separately from each other:
- **Feature Inventory v4.0** (`audit-prompt-v4.0.md`) — the current catalog of CC extensibility features, categories **A–L** (A–F classic + G Orchestration/Workflows, H Scheduling/Routines, I Channels, J Worktrees, K Output-styles, L Agent-SDK). Has a **freshness date-gate**: if its Verified date is >~4 weeks old, refresh before auditing.
- **Audit Methodology v2.0** (`audit-methodology-vnext.md`) — *conformance* ("does the plugin use the platform fully/correctly?"). Phases: 0 freshness-gate → 1 relevance → 2 gap + **drift sweep** + **superseded-approach** + **landscape scan** → 3 prioritized recs + **efficiency** + **test-tie** → 4 specs → 5 exclusion table.
- **Evolution Review v1.1** (`evolution-review.md`) — *generative* ("what should it become?"). Dimensions **E1–E7** (capability gaps, component-effectiveness [empirical], integration/ecosystem, vision, health/debt, proposals, **E7 competitive/peer benchmark** = a vetted peer registry + a codified peer-research agent reusing R11a's salvaged engine).
- **`/upgrade` flow** (`upgrade-flow.md`) — merges audit + evolution into one roadmap; will ship as **`/tdd-upgrade`** ([[decisions]]).

Keep methodology version distinct from inventory version (a stale inventory ≠ a stale method). See [[upgrade-roadmap]] [[prime-directive]].
