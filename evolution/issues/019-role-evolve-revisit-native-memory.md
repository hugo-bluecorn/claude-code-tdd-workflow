# Issue 019: Revisit `/role-evolve` for native memory — promote emergent properties into a committed `emergence/` layer

**Status:** open (design-only; **first issue under the `evolution/` convention** — see `evolution/README.md`) · **Found:** 2026-06-10 (Hugo: `/role-evolve` was designed as an md-files-as-memory control loopback *because Claude Code had no native memory then*; native memory now exists)
**Type:** design revisit → `role-` feature (**MINOR** when built) · **Relates to:** `evolution/explorations/features/roles/emergence-memory-architecture.md` (the full design), `explorations/features/roles/synthesis.md` §8.3/§8.1 (original vision + deferral), issue 018 / R21 (`/tdd-sync-memory`), `docs/experimental-results/role-cr-self-compilation.md` (the quality-plateau finding that *named* role-evolve)

## Background — the original vision (and its now-dead premise)

`/role-evolve` was the roles system's designated "primary follow-up feature":
**synthesize agent-memory + `MEMORY.md` into role-context updates**, bidirectional
(updates *down* into role files; context suggestions *up* to CA), via a separate
`role-evolver` agent — "Edit-focused, diff-driven, preservation-aware." It was deferred
"until real `/role-init` usage provides design input," and **never built**.

Crucially, at design time **Claude Code had no native memory**. The *only* memory
substrate was local md files (`.claude/agent-memory/*/MEMORY.md`, `MEMORY.md`). `/role-evolve`
was the **control loop** that fed those md "memories" back into the role files.

## What changed

Claude Code now has **native, project-scoped memory** (a recall layer). This **invalidates
role-evolve's founding premise** — md files are no longer the only memory substrate — and it
introduces a second decision (see issue 018): native memory is *local, uncommitted, siloed*.

## The reframe — three knowledge layers

Native memory and role files are different epistemic categories, and a third — committed
`emergence/` — sits between them:

```
   native memory     →     emergence/          →     roles
   (private, local,        (committed, shared,        (loadable, curated
    fast recall)            human-readable)            session IDENTITY)
            \____________ role-evolve promotes ____________/
```

| | Native memory | `emergence/` | Role file |
|---|---|---|---|
| Retrieval | probabilistic recall | read live from repo | deterministic load at session start |
| Commit | local, uncommitted | **committed, portable** | committed |
| Audience | the model | team + any clone | the session it activates |
| Role | private inbox | **published record** | applied identity |

So native memory does **not obviate** role-evolve — it *feeds* it. Role-evolve's job becomes
**materialization + promotion**: surface emergent properties into the committed `emergence/`
layer, then promote the durable, validated subset into the role files.

(Full architecture: `evolution/explorations/features/roles/emergence-memory-architecture.md`.)

## Proposed direction

1. **Source the loop from native memory** (typed, relevance-ranked) rather than scraping
   `agent-memory/*.md`.
2. **Materialize into `emergence/` first.** role-evolve writes durable emergent properties as
   committed, human-readable docs under `emergence/` — the shared layer that travels via git.
3. **Promote `emergence/` → roles.** Propose a diff that lifts the validated subset into the
   approve-gated role files; never re-recall raw md scraps.
4. **The up-channel collapses.** The original awkward "suggestions up to CA who hand-edits
   `MEMORY.md`" becomes "write native memory / `emergence/`," which agents do directly.
5. **The approval gate is the damping term.** Roles shape sessions → sessions write memory →
   memory feeds roles is a *positive* feedback loop that would amplify errors. The diff-driven,
   preservation-aware, **user-approved** write keeps the loop *negative* (corrective). Native
   memory makes this damping *more* necessary, not less.

## `emergence/` as a cross-project product artifact

`emergence/` is not just this repo's — the plugin **establishes and writes it in any consumer
project** (decision 2026-06-10: only `emergence/` of the `origins/emergence/evolution` triad
crosses over). There it documents *that project's* emergent properties. Written by **core**
(PD-safe, sourced from agent/native memory, works with zero roles); **role-evolve enriches it
optionally**.

## Convergence with R21 (issue 018)

`/role-evolve` (native-memory → `emergence/` → roles) and R21 `/tdd-sync-memory` (native-memory
across silos) are two edges of one graph: **materialize emergent knowledge into durable
artifacts**. With `emergence/` committed, 018's cross-silo transfer becomes "commit to
`emergence/`, let git carry it." They share diff/promotion machinery — **co-design**.

## Design questions / scope decisions

- **Model C ratification** — relocate role *content* into `emergence/roles/` with a thin loader
  skill (roles = skill handles that DCI `emergence/` content, mirroring `project-conventions`),
  or keep role content in `.claude/skills/` for now? (Pending — see the design doc §4.2.)
- **`emergence/` structure** — mirror native memory's index + per-fact-file shape? Sub-dirs?
- **Feedback source** — native memory only, or native + residual md?
- **Agent** — a dedicated `role-evolver` vs. `role-creator` with a mode flag?
- **Diff/preservation** — detect generated-vs-human-edited sections so manual edits survive.
- **Gating** — USER-gated like plan/release (↔ issue 017 / R23 autonomy toggle).
- **PRIME DIRECTIVE** — writes `role-` files only; `emergence/` stays role-optional; core
  `tdd-*` never depends on roles.

## Relationship to the quality plateau

The self-compilation experiment found CR's improvements plateauing and named `/role-evolve` as
the source of the "fundamentally new input" needed to break past it. Native memory now accrues
that input automatically — so role-evolve is *more* feasible and valuable than at deferral time.

## Prior art — NOT greenfield (study before building)

ECC's **`continuous-learning-v2`** (Homunculus-inspired) is a **shipped** instance of this thesis:
hooks capture every Pre/PostToolUse → atomic **instincts** with **confidence scores** + evidence →
an **evolution pipeline** that clusters them into **skills, commands, and agents** (`/evolve`,
`/instinct-export`, `/prune`); v2.1 adds **project-scoped** instincts to avoid cross-project
contamination. Before building, **study it** and either adopt its mechanics or differentiate sharply.
Our only honest distinguishing angle is the **committed-to-git, human-curated, approve-gated**
`emergence/` (vs their local, auto-evolving store) — conservative & reviewable vs automatic & local.
Exhaustive teardown: `evolution/explorations/assessments/ecc-teardown-2026-06.md` §3b — note ECC's
store is **outside `~/.claude`**, its observer **defaults OFF**, and it promotes into **generic**
skills/commands/agents (we target **role identities**). Adopt its **confidence-scoring +
project-scoping**; differentiate on **commit + curate + gate**.

## Acceptance (future build cycle — each test asserts the ACTION)

- role-evolve reads a fixture native-memory set + an existing role and **writes the right
  emergent-property docs into `emergence/`** (assert the files/paths written).
- It **PROPOSES a role diff** promoting the durable subset; writes role files **only after
  approval**.
- **Preservation:** a human-edited role section is left byte-identical across a re-evolve
  (assert the preserved bytes); no role section overwritten without appearing in the diff.
- **PD guard:** `emergence/` is written with zero roles present (core path); no `role-*`
  reference is introduced into any core `tdd-*` component.

## Note

This is a **design revisit, not a build commitment.** It supersedes the md-scraping framing in
`synthesis.md` §8.3 and re-tags the `/role-evolve` lifecycle reference (currently read as
stale/never-built) to **planned / under-revisit**.
