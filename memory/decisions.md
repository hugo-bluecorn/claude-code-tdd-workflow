---
name: decisions
description: Ratified decisions (2026-05-30) governing the v2.4→v3 upgrade — convention delivery, vision, verifier model, /tdd-upgrade naming, dead-commands.
metadata:
  type: project
---

Ratified 2026-05-30 (Hugo). Implement the roadmap consistent with these.

- **R1 — Convention delivery (ratified, recommended option):** deliver language convention packs via **`userConfig`** (manifest prompts for the convention repo at enable-time; replaces hand-edited `.claude/tdd-conventions.json`, which stays as a back-compat fallback) **+ `skills-dir` convention plugins** (each language pack ships as its own `<name>@skills-dir` plugin, versioned independently; data-drive detection instead of the 4 hardcoded dirnames in `load-conventions.sh`). Ship `dart-flutter-conventions` as the first pack. **Core `tdd-*` agents must stay pack-optional** (degrade gracefully) — the `dependencies` variant was explicitly rejected for PD-safety. This dissolves issue #006 (its "no plugin-dependency mechanism exists" premise is now false). See [[prime-directive]].
- **Vision — Direction 1:** language-agnostic TDD framework **+ a convention-pack ecosystem** is the near-term direction. Direction 2 ("ride CC orchestration primitives" — dynamic workflows / agent-teams replacing the hand-rolled sequential loop) is **deferred/tracked-to-GA**, gated on those primitives going GA and on the verifier-reliability baseline (R4).
- **Verifier model — A/B during R4:** do NOT pre-pick haiku vs sonnet; run an **A/B on false-PASS detection** as a slice of R4 (the verifier deterministic re-run gate) and let the data settle it. Current verifier = haiku.
- **`/upgrade` naming:** ships as **`/tdd-upgrade`** — keep the `tdd-` prefix so it appears in `/tdd-*` command-completion (discoverability over purity). Still bound by [[prime-directive]] (must not require role files).
- **Dead commands (R11):** **`/tdd-update-context` → RETIRE** (its edit targets were externalized in v2.0.0; salvage the version-research engine into the convention-pack freshness story). **`/tdd-finalize-docs` → REBUILD in place** (plumbing is current/project-agnostic; add an accuracy-assessment step + an `AskUserQuestion` approval gate + gate the auto-push). See [[upgrade-roadmap]] R11.
