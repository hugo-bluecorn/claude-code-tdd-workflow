# Emergence & Memory Architecture — `origins / emergence / evolution` + the two memory captures

> **Status:** design (forward-looking — lives under `evolution/` per the tree convention).
> `evolution/` exists today; `origins/` and `emergence/` are described here as design —
> their creation/migration is a follow-up, and `emergence/` as a *built* feature is issue 019's scope.
> **Date:** 2026-06-10 · **Authors:** Hugo + Claude (Opus 4.8)
> **Relates to:** `evolution/issues/019` (role-evolve revisit), issue 018 / R21 (`/tdd-sync-memory`),
> `explorations/features/roles/synthesis.md` §8.3 (original role-evolve vision), the `project-conventions`
> thin-skill loader pattern, the PRIME DIRECTIVE.

## 1. The temporal triad

The project organizes its knowledge along a **designed → discovered → designed** axis:

| Root | Tense | Holds | Authored by |
|---|---|---|---|
| `origins/` | what **was** | the record it descended from — planning archives, experimental results, closed issues, superseded explorations | design (deliberate) |
| `emergence/` | what **is** | documented **emergent properties** — patterns, gotchas, operational wisdom that arose *through use* | discovery (emergent) |
| `evolution/` | what **will be** | forward design — proposals, draft issues, specs | design (deliberate) |

Deliberate authorship at the ends; emergent discovery in the middle. All three are process-nouns from
complexity/evolutionary theory — one lexicon, one mental model. The live plugin **code** is unaffected:
it stays at the repo root as the working artifact; `emergence/` *documents* what has emerged about it
(it is additive, like `evolution/`, never a relocation of code).

### 1.1 Only `emergence/` crosses over (decision, 2026-06-10)

`origins/` and `evolution/` are **this repo's** development doc-organization — how the plugin records its
own past and future. They do **not** appear in consumer projects.

`emergence/` is different in kind: a **product artifact**. The plugin *establishes and writes* `emergence/`
in any project that uses it — there it documents *that project's* emergent properties. In this repo,
`emergence/` documents the plugin's own. **Same intent, two deployments.**

The asymmetry is intentional: `emergence/` is part of what the plugin **delivers**; `origins/` + `evolution/`
are part of how the plugin is **developed**.

## 2. Two kinds of memory capture

Two distinct stores of accumulated knowledge, with different intents. Keeping them straight is the core of
this design.

| | **Native memory** | **`emergence/`** |
|---|---|---|
| **Intent** | private **working recall** | published **shared knowledge** |
| **Audience** | the Claude session (machine recall) | the team + any future session in any clone |
| **Location** | `~/.claude/projects/<p>/memory/` — **local, uncommitted, siloed** | `emergence/` in the repo — **committed, portable, versioned** |
| **Optimized for** | the model: terse, relevance-ranked, pointer-layer | humans: readable prose, organized, curated |
| **Lifecycle** | continuous private accretion, **no gate** | deliberate **promotion + review**, graduated |
| **Captures** | anything that aids *this* agent's recall (incl. half-formed) | durable, validated emergent properties worth sharing |
| **Analogy** | personal working notes / episodic memory | the team wiki / institutional memory |

### 2.1 The relationship

Native memory is the **private inbox**; `emergence/` is the **published record**. Promotion (native →
`emergence/`) is deliberate and curated. Committing `emergence/` to git is exactly what makes it valuable
*beyond* native memory: it **dissolves native memory's siloing** (issue 018) — the shared layer travels
with the repo, read live by any clone, teammate, or future session.

**Non-duplication rule:** native memory **points to** `emergence/`, it never duplicates it. Once a fact is
promoted, the native note collapses to a one-line pointer — the same pointer-discipline native memory
already follows toward the repo's md dirs.

### 2.2 Who writes `emergence/`

In a consumer project, `emergence/` is written by **core** (PD-safe — sourced from agent/native memory,
functions with zero roles), with **role-evolve as an optional enricher**. `emergence/` must never *require*
roles; it is available to every plugin user.

## 3. The three-layer knowledge model

```
   native memory     →     emergence/          →     roles
   (private, local,        (committed, shared,        (loadable, curated
    fast recall)            human-readable)            session IDENTITY)
            \____________ role-evolve promotes ____________/
```

- **Native memory** — private, local, fast recall. Per-agent, per-machine.
- **`emergence/`** — committed, shared, human-readable emergent knowledge. Per-repo.
- **Roles** — loadable, curated session identity; a *structured application* of emergent knowledge.

`role-evolve` is the **promoter** across these layers: materialize emergent properties into `emergence/`,
then promote the durable, validated subset into role files — diff-driven, preservation-aware,
**approve-gated** (the gate is the loop's damping term; see issue 019).

## 4. Where roles fit

### 4.1 `/role-create` output is one layer *downstream* of `emergence/`

A role is not raw emergent knowledge — it is a curated, activatable **identity** (Identity /
Responsibilities / Constraints / Coordination). `/role-create` *reads* knowledge (project research today;
`emergence/` + native memory later) to *produce* a role. So role output sits **after** `emergence/`, not
inside it. `role-evolve` is the loop that re-promotes accumulated `emergence/` into role updates.

### 4.2 Roles are skill *handles* that load content from `emergence/` — Model C (proposed/target, pending ratification)

Two facts constrain the design:

1. Roles must stay **activatable** — the `.claude/skills/role-*/SKILL.md` handle is what provides `/role-ca`
   + the `disable-model-invocation` human-gate.
2. Content under `emergence/` is **not** a registered skill — Claude Code discovers `SKILL.md` only under
   `.claude/skills/` (the same constraint that prevents language-pack skills from registering via the
   conventions cache). So "pure load from `emergence/`" *loses* slash-activation.

So the answer to **"are roles skills, or loaded from `emergence/`?"** is **both**:

> A thin `role-*` **skill handle** under `.claude/skills/` provides activation + the human-gate; the role's
> **substance** lives in / is sourced from `emergence/` (e.g. `emergence/roles/ca.md`), loaded via DCI.

This mirrors `project-conventions` exactly — a thin skill that DCIs external convention content (R1's
externalization pattern, applied to roles). Bonus: it dissolves the historical **double-frontmatter**
friction — skill-frontmatter on the handle, clean role-format md in `emergence/`.

**Ratification status:** Model C is the **target**, staged as part of issue 019 — *not* a prerequisite.
Until ratified, role content stays physically in `.claude/skills/role-*/SKILL.md` (today's layout) and
`emergence/` is treated as knowledge-only.

## 5. PRIME-DIRECTIVE safety

- `emergence/` is a directory convention, **role-optional**: core `tdd-*` may read or populate it from
  agent memory; it never requires a role file.
- `role-evolve` writes `role-` files (role-prefixed, opt-in); reading `emergence/` / native memory to update
  roles is fine.
- Core `tdd-*` must never depend on roles or on the existence of any `emergence/roles/` content.

## 6. Convergence: issues 018 & 019 are two faces of one mechanism

- **Issue 018 / R21** (`/tdd-sync-memory`) — move knowledge across project silos.
- **Issue 019** (role-evolve) — promote knowledge into role identity.

Both are **materialization of emergent knowledge into durable artifacts**. With `emergence/` as the
committed shared layer, 018's cross-silo transfer becomes "commit to `emergence/`, let git carry it," and
019's role refinement becomes "promote `emergence/` → roles." They share the diff/promotion machinery.
**Co-design.**

## 7. Open questions / next steps

- **Ratify Model C?** (relocate role content into `emergence/roles/` + thin loader skill) — or keep
  `.claude/skills/` content for now.
- **`emergence/` internal structure** — mirror native memory's shape (index + per-fact files with
  frontmatter)? Sub-dirs (`emergence/roles/`, `emergence/patterns/`, …)?
- **Promotion trigger** — manual (`/role-evolve` or a sync command), or also automatic at milestones?
- **Distinction from `planning/` + agent memory** — `planning/` = intended decompositions (designed);
  agent memory = per-agent local learnings; `emergence/` = discovered, committed, shared. Keep distinct.
- Fold the decided parts into issue 019's build scope.
