# Issue 018: Cross-session memory transfer — `/tdd-export-memory` + `/tdd-sync-memory` (R21)

**Status:** open (logged, build deferred) · **Found:** 2026-06-02 (Hugo: the advisor/CC session building the Flutter + C/C++ langpacks generates knowledge that must eventually land in THIS project's memory; current method is ad-hoc)
**Type:** new capability → **MINOR** · **Roadmap:** R21 (Wave 4) · **Relates to:** `docs/user-guide.md` (manual memory-promotion model), `explorations/assessments/multi-session-paradigm-survey.md` (§8.4 human-as-message-bus, §8.5 HANDOFF.md), the roles `MEMORY.md` single-writer model, `explorations/features/r1-langpack-interface.md` (an existing "handoff snapshot")

## Problem

Two Claude Code sessions run in DIFFERENT project dirs — the plugin repo
(`…/claude-code-tdd-workflow`) and the langpack/advisor workspace
(`…/claude_flutter/`). Claude Code **native memory is project-scoped** (keyed by
git repo, stored at `~/.claude/projects/<project>/memory/`), so the two memory
stores are **siloed**. Knowledge the advisor session produces (langpack design,
dogfound bugs, decisions) must be promoted into the plugin project's memory.

**Hugo's current ad-hoc method:** tell one session to dump its "memory core +
relevant context" into a directory the other session can read, then **restart**
the other session so it reads the dump and integrates it.

## Why Claude Code can't do this natively (docs-verified, 2026-06-02)

- No native bridge between two projects' memory stores; no live cross-session
  sync; **no official MCP memory server**; session resume/`--continue` is
  directory-tied (can't pull session B into session A's dir).
- Supported primitives that partially help: `@import` in CLAUDE.md (abs paths,
  ≤4 hops); user-level `~/.claude/CLAUDE.md` (loads in all projects);
  **SessionStart hook → `additionalContext`** (auto-inject a shared inbox on
  (re)start); `.claude/rules/` (symlinkable shared instructions). The best
  native-only automation is "shared file + SessionStart-hook ingest" — which
  automates the paste but **keeps the restart**.

## Key insight — the restart is unnecessary

The restart in Hugo's method exists ONLY because native memory is read at
**session start**. But a **skill reads live** (re-reads disk at invocation time —
same mechanism as the convention DCI). So a skill that reads a handoff file →
writes it into native memory → surfaces highlights **needs no restart**. (This is
exactly the manual loop the main thread already performs: read dump → Write
memory files → report.) Turning it into a command is the upgrade.

## Proposed design — a producer/consumer command pair

### `/tdd-export-memory <dest>` (producing side, e.g. the advisor session)
- Dumps the session's **memory core + relevant context** to `<dest>` in a
  **standard handoff-dump format** (below). Reads the project's native
  `MEMORY.md` index + linked files; optionally accepts a scope filter
  (e.g. only `project`/`reference` types, or a topic).
- Writes a single `MEMORY-CORE-DUMP.md` (or a `handoff/<timestamp>/` dir for
  larger transfers) at `<dest>`.

### `/tdd-sync-memory <src>` (receiving side, this project)
- Reads `<src>` **live** (no restart), identifies **cross-cutting insights**,
  and **proposes promotions** into THIS project's native memory — each as a
  proposed `MEMORY.md` pointer + memory file — **for user approval** (gated;
  mirrors the planner/releaser approval-gate pattern; note issue 012 — the
  approval gate must run on the main thread, not a subagent).
- On approval: writes the native memory files, then **archives** the consumed
  dump (move to `handoff/consumed/`), so re-runs don't re-import.
- De-dup: skip insights whose `name:` slug already exists; update-in-place when
  the dump supersedes an existing memory.

### Standard handoff-dump format
Reuse the native `MEMORY.md` shape (one-line index + per-fact files with
frontmatter `type: user|feedback|project|reference`). A dump = an index section
+ inlined fact blocks + a "relevant context" appendix (paths, contracts, open
decisions). Align with the survey's §8.5 HANDOFF.md fields (Goal / Completed /
Not-yet-done / Decisions).

## Scope decisions to make at build time

- **Direction:** ship BOTH commands, or just `/tdd-sync-memory` (consumer) and
  let any session hand-author a dump? (Lean: both — symmetry makes it routine.)
- **One-way vs round-trip:** the need is one-way (advisor → plugin). Don't build
  bidirectional live-sync (over-engineering; Claude Code can't support it).
- **PRIME DIRECTIVE:** core `tdd-*` plumbing, no role coupling. (NB the roles
  system already models a `MEMORY.md` single-writer; these commands are the
  core-side, role-optional realization.)
- **Gating:** `/tdd-sync-memory` writes memory → should be USER-gated like
  plan/release (↔ issue 017 R23 autonomy toggle — once R23 lands, gating becomes
  per-step configurable).
- **Alternative/inferior automation to document and reject:** a SessionStart
  hook that auto-ingests an inbox (still needs restart); a custom MCP memory
  server (unofficial); `.swarm/memory.db`-style SQLite shared memory (survey
  §8.1 — continuous, but over-engineered for periodic one-way promotion).

## Acceptance (future build cycle — each test asserts the ACTION)

- `/tdd-sync-memory` reads a fixture dump and PROPOSES the right set of
  promotions (assert the proposed file list/pointers), writes them only after
  approval, and archives the dump (assert the move).
- De-dup: a dump whose insights already exist proposes 0 new writes (or
  in-place updates), not duplicates.
- `/tdd-export-memory` produces a dump that `/tdd-sync-memory` round-trips
  (export → import → same memory set).
- No `role-*` reference (PD guard).

## Note

`docs/user-guide.md` currently says these automation paths are "not currently
planned." If R21 is built, update that section to point at the shipped commands.
