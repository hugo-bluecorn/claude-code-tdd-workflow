# Feature Notes: R1 Foundation Layer (conventions-as-packs)

**Created:** 2026-06-01T03:23:44Z
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
R1 is the highest-leverage item on the v2.4→v3 upgrade roadmap: re-platform
language conventions away from hardcoded language matrices into per-language
**convention packs**. A pack is a standalone git repo declaring, symmetrically
across languages, three things — **detect** (extensions + markers), a
**test-command** (richer than a string), and **standards** (markdown docs) — in
a `pack.json` manifest. The plugin becomes a language-agnostic core that reads
`pack.json` instead of branching on hardcoded language names across 8 sites.

This planning cycle scopes **only the foundation layer**: the script-half data
primitives every later consumer reads. It deliberately does NOT rewire any
consumer — that is the next ("consumer fan-out") cycle.

### Use Cases
- A Dart/Flutter project binds the `dart-flutter-conventions` pack by git-URL +
  version; the plugin resolves it to a per-machine cache and reads its `pack.json`.
- A multi-language project (Flutter app + native C++) activates both packs; the
  detection primitive returns both pack dirs.
- A project with a non-bash language but no bound pack: the plugin warns honestly
  and proceeds on training data rather than hard-stopping or silently degrading.

### Context
The language matrix is hardcoded across 8 sites (`load-conventions.sh`,
`detect-project-context.sh`, `auto-run-tests.sh`, `validate-tdd-order.sh`,
`tdd-verifier.md`, `tdd-releaser.md`, `planner-bash-guard.sh`, `bump-version.sh`)
plus residual doc-content in `CLAUDE.md`. R1's thesis collapses them onto a single
`pack.json` source of truth. The existing `fetch-conventions.sh` SessionStart hook
(made async by R7) is a bare fetcher with no detection and no version-pin; the
binding `.claude/tdd-conventions.json` currently uses absolute paths (author-only).
The foundation layer builds the primitives that close those gaps.

---

## Requirements Analysis

### Functional Requirements
1. A pack manifest reader exposing every ratified C2 schema field path.
2. A binding parser accepting the new git-URL+version schema and the legacy
   absolute-path schema, emitting normalized `(source, version)` tuples.
3. A resolver that caches a bound `source@version` under a `<repo>@<version>`
   key with the tag checked out, preserving the legacy unversioned path.
4. Data-driven active-pack detection from each pack's declared `detect` data.
5. A no-pack warn-and-proceed floor for detected non-bash languages (decision C3).

### Non-Functional Requirements
- Full suite stays at 0 failures after every slice (the floor is the guard).
- Every new script is shellcheck-clean and executable.
- Honesty of degradation: a missing pack surfaces a warning, never a silent drop.

### Integration Points
- Reads `.claude/tdd-conventions.json` (the committed, portable project binding).
- Reads/writes the per-machine cache under `${CLAUDE_PLUGIN_DATA}/conventions/`.
- The primitives are consumed (next cycle) by `auto-run-tests.sh`,
  `load-conventions.sh`, and the verifier/releaser/doc-finalizer agents.
- No dependency on any role file (PRIME DIRECTIVE).

---

## Implementation Details

### Architectural Approach
The contract (interface §8) splits delivery by half: **standards** reach the
model via the existing skill-DCI, **commands** reach the script-half via the
resolver and a committed-binding fallback. This foundation cycle builds the
script-half data layer only. The reader and parser are pure, jq-based,
side-effect-free accessors; the resolver evolves the existing hook additively so
every legacy behavior is preserved (the pre-existing test file is the guard); the
detection primitive is standalone and explicitly does not touch its future
consumer. The warn-and-proceed floor wires decision C3 into the resolve→detect path.

### Design Patterns
- **Single accessor (read-pack):** every consumer reads pack fields through one
  script, so the schema knowledge lives in one place — chosen to prevent the 8-site
  drift R1 exists to eliminate.
- **Additive evolution (resolver):** extend `fetch-conventions.sh` without altering
  its legacy branch — chosen because back-compat is non-negotiable and the existing
  suite pins the old behavior.
- **Absence-guard (detection):** a test asserts the consumer (`load-conventions.sh`)
  stays un-rewired this cycle — chosen to enforce the scope fence mechanically.

### File Structure
```
scripts/read-pack.sh                                 [NEW]
scripts/parse-binding.sh                             [NEW]
scripts/resolve-active-pack.sh                       [NEW]
hooks/fetch-conventions.sh                           [EVOLVED — additive]
test/scripts/read_pack_test.sh                       [NEW]
test/scripts/parse_binding_test.sh                   [NEW]
test/scripts/resolve_active_pack_test.sh             [NEW]
test/hooks/fetch_conventions_versioned_test.sh       [NEW]
test/hooks/fetch_conventions_no_pack_warn_test.sh    [NEW]
test/hooks/fetch_conventions_test.sh                 [UNCHANGED — back-compat guard]
test/hooks/fetch_conventions_async_test.sh           [UNCHANGED — back-compat guard]
```

### Naming Conventions
New scripts in `scripts/`, the evolved hook stays in `hooks/`. Tests mirror the
source path with the `_test.sh` suffix. Fixtures are synthetic, created under
`mktemp -d` and torn down with `rm -rf`. The bashunit skip idiom is
`bashunit::skip "reason" && return` inline in the test function.

---

## TDD Approach

### Slice Decomposition

The feature is broken into independently testable slices, each following the
RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full slice list
with live status tracking and the per-slice Given/When/Then specifications.

**Test Framework:** bashunit
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | Pack manifest reader (`read-pack.sh`) | None |
| 2 | Binding parser (`parse-binding.sh`) | None |
| 3 | Resolver + versioned cache (evolve `fetch-conventions.sh`) | Slice 2 |
| 4 | Active-pack detection (`resolve-active-pack.sh`) | Slice 1 |
| 5 | No-pack warn-and-proceed floor (resolver path) | Slices 3, 4 |

Recommended sequence: 1 → 2 → 3 → 4 → 5.

---

## Dependencies

### External Packages
- `jq`: already a plugin dependency, used by existing scripts to read JSON.
- `git`: used by the resolver to clone/fetch and check out the pinned tag.

### Internal Dependencies
- Slice 4 reads pack fields via Slice 1 (`read-pack.sh`).
- Slice 3 consumes Slice 2's binding tuples (including the dev flag).
- Slice 5 sits at the junction of Slices 3 (resolve) and 4 (detect).

---

## Known Limitations / Trade-offs

### Limitations
- **C4 (`projectFiles` materialization) deferred:** materializing tool-configs into
  the consuming project mutates project state, which couples the read-only resolver
  to side-effects. It is deferred to the consumer cycle; it does not fall out of the
  pure data layer cleanly.
- **Synthetic fixtures only:** the real dart/cpp packs are deferred deliverables, so
  every test exercises synthetic fixture manifests and a locally-created tagged git
  repo rather than a real pack.

### Trade-offs Made
- **Additive resolver vs. rewrite:** evolving the hook additively keeps the legacy
  path bit-for-bit but leaves two code paths until the legacy form is retired — chosen
  because back-compat outweighs momentary tidiness.
- **Foundation-first vs. vertical slice:** building data primitives before any
  consumer means the primitives have no in-product caller yet this cycle — chosen
  because the consumer fan-out (7+ sites) all depend on a stable data layer; building
  them against a moving foundation would churn.

---

## Implementation Notes

### Key Decisions
- **Rich `commands.test` object (C2):** models optional `setup[]`, `run`, per-file
  vs suite `granularity`, named `variants`, and `passOn` — a flat ext→string map
  could not encode the C++ 3-step and was the root of the C++ false-green bug.
- **Versioned cache key (§8.4):** `<repo>@<version>` lets pinned versions coexist and
  makes the pin real by checking out the tag, not HEAD.
- **Warn-and-proceed (C3, ruled by Hugo):** PRIME-safe (core works pack-less), honest
  (degradation surfaced), zero-drift (no fallback chain to maintain). The warning fires
  from the SessionStart resolver when a non-bash marker is detected but no pack resolves.

### Future Improvements
- Consumer fan-out cycle: pack-drive `auto-run-tests.sh`, data-drive
  `load-conventions.sh`, pack-wire verifier/releaser/doc-finalizer, and the remaining
  hardcoded-language sites; remove the now-untested C doc-content.
- C4 `projectFiles` non-destructive materialization, attached to the resolver in the
  consumer cycle.

### Potential Refactoring
- A shared jq-field helper between the reader and the binding parser, if duplication
  emerges once tests pass — left for the implementer to decide at implementation time.

---

## References

### Related Code
- `hooks/fetch-conventions.sh` (+ `test/hooks/fetch_conventions_test.sh`,
  `test/hooks/fetch_conventions_async_test.sh`) — the hook being evolved + its guards.
- `scripts/load-conventions.sh` — the consumer the detection primitive will replace
  next cycle (kept un-rewired this cycle).
- `test/scripts/detect_project_context_test.sh` — bashunit test-idiom reference.

### Documentation
- `explorations/features/r1-langpack-interface.md` — §8 contract (schema §8.2/§8.3,
  SessionStart §8.4, dispatcher §8.5, binding §8.6), §9 worklist, §10 distribution.
- `explorations/features/r1-langpack-reconciliation.md` — decisions C1–C6, the merged
  8-site inventory (§B.1), and the §8/§9 deltas.
- `memory/decisions.md` (Decision #6 governs R1), `memory/prime-directive.md`.

### Issues / PRs
- Roadmap item R1 (Wave 2). Dissolves issue #006. Related: issue #012
  (gated skills + AskUserQuestion).
