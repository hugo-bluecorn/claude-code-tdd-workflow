# Issue 016: `bump-version.sh` drops a Flutter `+build` suffix when given a bare semver

**Status:** scheduled (r1-hardening-2, slice 2) · **Found:** 2026-06-01 (advisor, `temp_convert` `/tdd-release`; predicted in advance, confirmed by direct isolation test)
**Severity:** 🟨 latent/edge (outcome was correct on the live run, via the releaser's intelligence — not codified) · **Confidence:** high (reproduced directly)
**Advisor ref:** `research/plugin-upgrade/bug-fix-log.md` → BF-003 · ships as **PATCH** (v2.8.1)

## Symptom

The bare-path `.yaml` heuristic rewrites the **whole** version line, dropping any `+build`:

```
version: 0.1.0+1      # before
$ bump-version.sh 0.2.0
version: 0.2.0        # after — the +1 is gone
```

Confirmed by isolation test on a Flutter `pubspec.yaml`.

## Why no live harm (this run)

`temp_convert` still landed at `0.2.0+2` because the **releaser** computed the full version-with-build (`0.2.0+2`, incrementing `+1→+2`) and passed THAT string in; `bump-version` faithfully wrote it. The outcome was correct — but only because the model noticed the `+build` and re-supplied it. The behavior is **not codified**.

## Root cause

`bump-version.sh` is a faithful full-line writer (`s/^version: .*/version: <V>/`) — it writes exactly the string given, with no Flutter-build-aware path. Correctness depended on the caller (releaser) re-supplying the build number.

**Risk:** a less-careful releaser run (passes bare `0.2.0` → build lost), or ANY direct `bump-version.sh <semver>` against a Flutter `pubspec.yaml`.

## Fix — option (a): preserve an existing `+build` when the supplied version omits one

- `version: 0.1.0+1` + bump `0.2.0` → `version: 0.2.0+1` (existing build preserved).
- `version: 0.1.0+1` + bump `0.2.0+5` → `version: 0.2.0+5` (an **explicit** build in the argument still wins).
- `version: 0.1.0` (no build) + bump `0.2.0` → `version: 0.2.0` (unchanged behavior).

The caller-owns-the-build contract still holds when a build is supplied; we only stop *destroying* a build the caller omitted.

## Action-asserting test (must fail against today's code — real RED)

- `version: 0.1.0+1` + bump `0.2.0` → assert the resulting line is `version: 0.2.0+1` (the `+1` is **preserved**). *(RED today — the current sed drops it.)*
- `version: 0.1.0+1` + bump `0.2.0+5` → assert `version: 0.2.0+5` (explicit build wins).
- `version: 0.1.0` + bump `0.2.0` → assert `version: 0.2.0` (no spurious build added).

Assert the **written line**, the action the fix changes.
