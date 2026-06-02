# Issue 015: C3 "no convention pack" warning false-negative for dev-bound packs

**Status:** scheduled (r1-hardening-2, slice 1) · **Found:** 2026-06-01 (advisor, dart pack's first real-data validation — dev-bound project at `/home/hugo/bluecorn/claude/test/temp_convert`)
**Severity:** ⬜ cosmetic (false-negative *output*; right behavior) · **Confidence:** high (data-flow traced; the T1 block two sections below already does it the correct way)
**Advisor ref:** `research/plugin-upgrade/bug-fix-log.md` → BF-001 · ships as **PATCH** (v2.8.1)

## Symptom

A project with a dev-bound pack —

```json
{ "packs": [ { "source": "…", "dev": true } ] }
```

— prints at SessionStart:

```
fetch-conventions: no convention pack for Dart; TDD will proceed on training data + session context only
```

…even though the pack **is** bound and fully resolving: standards are delivered, `flutter test` is driven, the drift advisory fires. The warning tells a pack author their pack is dead while it is demonstrably alive.

## Root cause — two resolvers in one script disagree

`hooks/fetch-conventions.sh` resolves the C3 coverage check ("is this marker covered by an active pack?") by scanning the **fetch cache** (`$CLAUDE_PLUGIN_DATA/conventions`): it `find`s `pack.json` files into `resolved_packs[]`, then feeds those to `resolve-active-pack.sh`. A **dev pack never populates that cache** (it is local, never fetched — see `resolve_binding_tuple` Case 1) → `resolved_packs` is empty → `active_packs=""` → `c3_marker_covered` short-circuits to "not covered" → the warning fires.

The **T1 / projectFiles block immediately below** (same file) resolves active packs via `bash active-pack.sh "."` — the unified committed-binding resolver — and **does** find the dev pack. The script contains two resolvers that disagree on what is active.

**Class:** Wave-1 *incomplete-rewiring*. When `active-pack.sh` became the unified resolver, the other consumers were switched to it but the C3 coverage check was missed. Same "synthetic-fixture-passes / real-dev-bind-breaks" family as H1 (issue 014 #1).

## Fix

Compute the C3 coverage `active_packs` via `bash active-pack.sh "."` (mirror the T1 block), replacing the cache-scan. This is also *more correct*: it asks "what packs are active for THIS project," not "what packs exist anywhere in the cache."

## Action-asserting test (must fail against today's code — real RED)

The falsifier the synthetic fixtures lacked:

- **(a)** dev-bound Dart project → assert the `no convention pack for Dart` line is **ABSENT** from stderr. *(RED today — the cache-scan can't see the dev pack.)*
- **(b)** Dart project with **no** binding → assert the warning **FIRES**. *(guards we didn't silence the floor.)*

Assert the **action** (the advisory line emitted / not emitted), never an end-state a broken path could reproduce — the lesson from H1's false-green (`memory/assert-action-not-end-state.md`).
