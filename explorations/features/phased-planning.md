# Phased Planning — Integration into tdd-workflow

> **Date:** 2026-03-15
> **Status:** Concept exploration — needs further refinement
> **Evidence:** zenoh-counter-flutter `docs/plan/phase-{1..6}.md`
> (14 slices across 6 phases, organized by MVVM architectural layer)

---

## 1. The Problem

Large features produce plans that exceed comfortable context boundaries at
every stage:

| Stage | Context Pressure | Example |
|-------|-----------------|---------|
| **Planning** | Planner researches 15-20 turns, then writes 14 slices with Given/When/Then, code signatures, test patterns. Exceeds planner's 30-turn budget. | zenoh-counter-flutter: 14 slices, 6 phases |
| **Implementation** | `/tdd-implement` spawns implementer + verifier for each slice. 14 slices = 28 agent invocations in one skill run. Earlier slices autocompact away. | Phase details from slice 2 lost by slice 10 |
| **Review** | CA reviews a 14-slice plan in one go. Overwhelming. Quality drops for later slices. | Hard to catch issues in slice 12 when 11 slices precede it |
| **Progress** | `.tdd-progress.md` with 14 slices is unwieldy. No natural milestones. | "7 of 14 done" — which ones? What's the next coherent deliverable? |

## 2. The User's Current Solution (Manual Phases)

The user asks CA to decompose the feature into phases before planning.
Each phase is a coherent group of 2-4 slices organized by feature or
architectural layer.

### Observed Pattern (zenoh-counter-flutter)

```
Phase 1: Foundation       (Slices 1-2)  — Models + ZenohService (GATE)
Phase 2: Data Layer       (Slices 3-4)  — Repositories
Phase 3: Wiring           (Slices 5-6)  — Providers + App Shell
Phase 4: ViewModels       (Slices 7-9)  — Connection + Counter ViewModels
Phase 5: Screens          (Slices 10-12) — UI Screens
Phase 6: Navigation       (Slices 13-14) — Router + Dev Script
```

### Observed Workflow

```
CA + human: Define overall feature scope
CA: Decompose into phases (manual)
CA: Write phase-1-foundation.md (scope, constraints, context)

CC: /tdd-plan <phase 1 scope>
CA: Review, approve
CI: /tdd-implement (2 slices)
CA: Verify

CA: Write phase-2-data-layer.md (adds "What Exists After Phase 1")

CC: /tdd-plan <phase 2 scope>
... repeat for each phase ...
```

### What a Phase Document Contains

Examining `phase-1-foundation.md` and `phase-4-viewmodels.md`:

**Fixed structure (same in every phase):**
- Phase header: name, slice numbers, depends-on, exit criteria
- Project context: purpose, architecture, key constraints
- Import organization rules
- Design spec reference

**Phase-specific content:**
- "What Exists After Phases 1-N" (Phase 4+ only) — cumulative build context
- Slice specifications: Given/When/Then, code signatures, test patterns
- Phase-specific dependencies and blocking relationships
- "What Happens Next" — link to the following phase

**Key observation:** Each phase document repeats the full project context
(constraints, import rules, design spec reference) because each `/tdd-plan`
invocation starts with a fresh context window. The repetition is intentional
— it's the only way to get the planner oriented.

**Second observation:** The phase documents ARE the plan output, not just
scope descriptions. They contain complete Given/When/Then specs, code
signatures, and test patterns. The `/tdd-plan` invocation either uses
these as input (if CA pre-wrote them) or produces them as output (if the
planner generates them from a scope description).

## 3. What Needs to Change in the Plugin?

### 3.1 What Already Works

The existing plugin components handle phases without modification:

| Component | Phase Compatibility |
|-----------|-------------------|
| `tdd-planner` agent | Works — plans whatever scope it's given |
| `/tdd-plan` skill | Works — accepts any feature description, including phase-scoped ones |
| `tdd-implementer` agent | Works — implements whatever slices are in `.tdd-progress.md` |
| `/tdd-implement` skill | Works — processes pending slices regardless of phase structure |
| `tdd-verifier` agent | Works — verifies whatever slice it's given |
| `tdd-releaser` agent | Works — releases whatever is on the branch |
| Hooks | Work — validate TDD order, auto-run tests, check progress |

The planner doesn't need to know about phases — it plans a scope. The
implementer doesn't need to know about phases — it implements slices.
Phases are an **orchestration concept**, not a component concept.

### 3.2 What's Missing

Three things that are currently manual:

| Gap | Current | Desired |
|-----|---------|---------|
| **Phase decomposition** | CA manually breaks features into phases | Assisted or automated decomposition |
| **Cross-phase context** | CA manually writes "What Exists After Phase N" | Automatically gathered from git/code |
| **Phase progress tracking** | CA manually tracks which phases are done | Structured tracking with milestones |

## 4. Approaches

### Approach A: Phase Decomposition Skill (`/tdd-decompose`)

A lightweight skill that takes a full feature description and produces a
phase breakdown — NOT full slice specs, just phase scope and ordering.

```
/tdd-decompose MVVM Flutter subscriber app with connection, counter, and settings screens
```

Output: A phase plan document listing 4-8 phases with:
- Phase name and scope (2-3 sentences)
- Architectural layer or feature grouping
- Phase dependencies
- Exit criteria
- Estimated slice count (rough)

This is CA's decomposition work, automated. The skill doesn't replace CA's
judgment — it proposes a decomposition that CA reviews and modifies.

**Effort:** New skill + lightweight agent (read-only research, no file writes
beyond the phase plan). ~60 lines SKILL.md, ~40 lines agent.

**Integration:** Runs before `/tdd-plan`. Output is a reference document
that CA uses to scope individual `/tdd-plan` invocations.

### Approach B: Phase-Aware `/tdd-plan`

Modify `/tdd-plan` to accept a phase reference:

```
/tdd-plan --phase "Phase 2: Data Layer" --phase-plan docs/plan/phases.md
```

The skill reads the phase plan, identifies which phase to plan, and
automatically gathers cross-phase context by:
1. Reading prior `.tdd-progress.md` entries (completed slices)
2. Reading git log for what was built in prior phases
3. Globbing for source/test files created in prior phases

This eliminates the need for CA to manually write "What Exists After
Phase N" sections.

**Effort:** Modify `/tdd-plan` SKILL.md (~30 lines), modify tdd-planner
agent prompt (~20 lines for cross-phase context instructions).

**Risk:** Adds complexity to `/tdd-plan` which is already working well
for single-phase use.

### Approach C: Phase Progress File (`.tdd-phases.md`)

A master progress file that tracks phases:

```markdown
# Feature: Flutter Counter App

## Phase 1: Foundation (Slices 1-2) — DONE
- Exit criteria: Models pass, ZenohService GATE passes
- Completed: 2026-03-10
- Slices: 2/2 done

## Phase 2: Data Layer (Slices 3-4) — DONE
- Exit criteria: Repositories pass with fakes
- Completed: 2026-03-10
- Slices: 2/2 done

## Phase 3: Wiring (Slices 5-6) — IN PROGRESS
- Exit criteria: Providers resolve, app shell renders
- Slices: 1/2 done

## Phase 4: ViewModels (Slices 7-9) — NOT STARTED
...
```

This provides a single-glance view of feature progress. Currently, progress
is tracked implicitly (CA knows, git log shows, but there's no structured
view).

**Effort:** Convention only (no code). Or a small hook/skill to generate
from git log + `.tdd-progress.md` history.

**Question:** Does `.tdd-phases.md` replace `.tdd-progress.md`, extend it,
or sit alongside it?

### Approach D: Hierarchical Planning (Decompose + Plan)

Combine A and B into a two-stage workflow:

```
Stage 1: /tdd-decompose <feature>
  → Produces phase breakdown (docs/plan/phases.md)
  → CA reviews, approves

Stage 2: /tdd-plan <phase scope> (repeated per phase)
  → Planner reads phase breakdown for context
  → Planner auto-gathers "what exists" from prior phases
  → Produces .tdd-progress.md for current phase
  → CA reviews, approves
  → CI implements
  → Repeat for next phase
```

This is the most complete solution but also the most complex.

### Approach E: Convention Only (Document the Pattern)

Don't add any new components. Instead:
1. Document the phased planning pattern in CLAUDE.md and the user guide
2. Provide a phase plan template in `skills/tdd-plan/reference/`
3. Let CA continue to decompose manually, using the template

**Effort:** Minimal (~20 lines of documentation).
**Value:** Low. Documents what the user already does without reducing effort.

## 5. Analysis: Where Phases Actually Help

### 5.1 The Decomposition Step

This is the highest-value gap. Currently CA manually breaks features into
phases, which requires:
- Understanding the full feature scope
- Knowing the project's architectural layers
- Deciding grouping criteria (by layer? by feature? by risk?)
- Ordering phases by dependency
- Estimating slice counts per phase

A `/tdd-decompose` skill would automate the research (project structure,
existing architecture, dependency graph) and propose a decomposition. CA
still reviews and approves — the skill reduces effort, not judgment.

### 5.2 Cross-Phase Context

This is the second-highest-value gap. When planning Phase 4, the planner
needs to know what Phases 1-3 produced:
- What files exist (source paths, test paths)
- What classes/functions are available (API surface)
- What patterns were established (test utilities, fakes, fixtures)

Currently CA manually writes this as "What Exists After Phases 1-3". This
is tedious and error-prone (CA might miss a file or get a path wrong).

Auto-gathering this from the actual codebase is reliable and eliminates
manual work. The planner already researches the codebase — it just needs
to be told "focus on what was built since the feature branch was created."

**Implementation:** The planner's prompt could include:
```
Files created on this branch (not on main):
$(git diff --name-only main...HEAD)
```

This gives the planner a precise list of what prior phases produced, without
CA having to write it manually.

### 5.3 Phase Progress Tracking

This is lower value. CA already knows which phases are done (they just
finished implementing them). A `.tdd-phases.md` file is nice for visibility
but doesn't unblock any workflow step.

It would be most valuable for:
- Resuming after interruption (which phase am I on?)
- Handoff between developers (status at a glance)
- `/tdd-status` integration (report phase-level progress)

## 6. Interaction with `.tdd-progress.md`

The current `.tdd-progress.md` tracks slices for a single `/tdd-plan`
invocation. With phased planning, the lifecycle becomes:

### Option 1: One progress file per phase

```
Phase 1: /tdd-plan → .tdd-progress.md → /tdd-implement → complete
          (archive to planning/)
Phase 2: /tdd-plan → .tdd-progress.md → /tdd-implement → complete
          (archive to planning/)
...
```

The progress file is ephemeral — it exists during implementation and gets
archived when the phase completes. This is the **current behavior**: the
planner writes `.tdd-progress.md`, the implementer works through it, the
releaser archives it.

**Advantage:** No changes to existing components.
**Disadvantage:** No master view of all phases. Between phases,
`.tdd-progress.md` doesn't exist.

### Option 2: Cumulative progress file

```
Phase 1: /tdd-plan → slices added to .tdd-progress.md
Phase 2: /tdd-plan → more slices added to .tdd-progress.md
...
```

The progress file grows across phases, accumulating all slices.

**Advantage:** Single file with full history.
**Disadvantage:** File gets large. Planner would need to append rather
than write. Breaks current "fresh file per plan" behavior.

### Option 3: Master file + per-phase files

```
.tdd-phases.md              ← master (phase status, links)
.tdd-progress.md            ← current phase's slices (ephemeral)
planning/phase-1-*.md       ← archived phase 1 plan
planning/phase-2-*.md       ← archived phase 2 plan
```

**Advantage:** Clean separation. Master provides overview, progress file
provides working detail, archives provide history.
**Disadvantage:** More files to manage.

### Recommendation: REVISED — Phase tracking is CRITICAL, not optional

**The status quo is broken for phased planning.** The current lifecycle:

```
/tdd-plan → .tdd-progress.md (all slices) → /tdd-implement → /tdd-release (archives)
```

Has two blockers for phases:

1. **`/tdd-plan` refuses to run if `.tdd-progress.md` exists with pending
   slices.** After Phase 1 completes, the file has completed slices but
   still exists. Running `/tdd-plan Phase 2` is blocked unless the file
   is deleted or archived.

2. **`/tdd-implement` processes ALL pending slices.** If the file contains
   14 slices from a single large plan, CI implements all 14 — defeating
   the purpose of phases.

3. **`/tdd-release` archives the file** — but releasing after each phase
   doesn't make sense. The feature ships after ALL phases, not after each one.

**The phase transition is undefined.** Between phases, `.tdd-progress.md`
is stuck: completed but not releasable, blocking the next plan.

**Required solution:** A phase-aware lifecycle:

```
/tdd-decompose → .tdd-phases.md (master plan, all phases)
/tdd-plan Phase 1 → .tdd-progress.md (Phase 1 slices only)
  → /tdd-implement → Phase 1 slices done
  → PHASE TRANSITION: archive .tdd-progress.md, update .tdd-phases.md
/tdd-plan Phase 2 → .tdd-progress.md (Phase 2 slices only)
  → /tdd-implement → Phase 2 slices done
  → PHASE TRANSITION: archive, update
...
/tdd-release → ships the feature (all phases complete)
```

The phase transition step must:
1. Archive current `.tdd-progress.md` to `planning/phase-N-*.md`
2. Update `.tdd-phases.md` to mark Phase N as done
3. Clear the way for `/tdd-plan` to create a new `.tdd-progress.md`

This could be:
- A new skill: `/tdd-advance-phase` or `/tdd-next-phase`
- A modification to `/tdd-implement`: when all slices are done, ask
  "Archive this phase and plan the next one?"
- A modification to `/tdd-plan`: if `.tdd-progress.md` exists but all
  slices are terminal AND `.tdd-phases.md` shows more phases pending,
  auto-archive and proceed

The third option is the most seamless — `/tdd-plan` already checks for
`.tdd-progress.md`. It just needs a phase-aware branch:

```
if .tdd-progress.md exists:
  if has pending slices → "Run /tdd-implement first" (current behavior)
  if all terminal AND .tdd-phases.md has more phases:
    → archive to planning/
    → update .tdd-phases.md
    → proceed with next phase planning
  if all terminal AND no .tdd-phases.md → "Run /tdd-release" (current behavior)
```

## 7. Interaction with Other Proposals

### `/tdd-init-roles` (from prior exploration)

Phase decomposition could trigger role refinement. After planning Phase 1,
the planner has discovered concrete file paths and patterns that should
be in CI's role file. This aligns with the iterative lifecycle concept:

```
/tdd-decompose → phase breakdown
/tdd-plan Phase 1 → concrete slices
/tdd-init-roles [v2] → refined roles with Phase 1 knowledge
/tdd-implement Phase 1 → code exists
/tdd-init-roles [v3] → roles with actual code examples
```

### `/tdd-status`

Phase-aware status reporting:

```
## TDD Session Status

**Feature:** Flutter Counter App
**Phase:** 3 of 6 (Wiring)
**Phase Progress:** 1/2 slices complete
**Overall:** 5/14 slices complete
**Next slice:** Slice 6 (App Shell)
```

### `/tdd-verify-feature`

Verification at phase boundaries, not just at release:

```
/tdd-verify-feature --phase 3
→ Runs tests for Phase 3 slices specifically
→ Also runs full regression (all prior phases)
```

## 8. Grouping Criteria for Phases

The user mentioned phases can be organized "by feature or architectural
layer." From the evidence:

### By Architectural Layer (zenoh-counter-flutter)

```
Phase 1: Models (data layer foundation)
Phase 2: Repositories (data layer logic)
Phase 3: Providers (dependency injection)
Phase 4: ViewModels (presentation logic)
Phase 5: Screens (UI)
Phase 6: Navigation (routing + glue)
```

This works for greenfield MVVM apps. Each layer depends on the one below.

### By Feature (alternative for feature-rich apps)

```
Phase 1: Authentication (model + repo + VM + screen)
Phase 2: Dashboard (model + repo + VM + screen)
Phase 3: Settings (model + repo + VM + screen)
```

Each feature is a vertical slice through all layers. Works better for
adding features to existing apps.

### By Risk (alternative for uncertain projects)

```
Phase 1: GATE — prove the riskiest integration works
Phase 2: Core — build the main flow
Phase 3: Polish — edge cases, error handling, UX
```

The zenoh-counter-flutter project uses this implicitly — Phase 1's
ZenohService slice is marked as a "GATE" test. If native libs don't load,
everything stops.

### Implication for `/tdd-decompose`

The decomposition skill should ask the user which grouping strategy to use,
or detect it from the project structure:
- MVVM/layered architecture → suggest by-layer
- Feature-based organization → suggest by-feature
- New technology integration → suggest gate-first

## 9. Recommended Implementation Path

### Minimum Viable Phase Support (v1)

**New skill, phase tracking file, and modified `/tdd-plan` behavior:**

1. **`/tdd-decompose` skill** — Researches project, proposes phase breakdown,
   CA reviews and approves. Writes `.tdd-phases.md` at project root.
   Lightweight agent (read-only research + AskUserQuestion).

2. **`.tdd-phases.md` master file** — CRITICAL. Tracks phase status,
   enables phase transitions. Created by `/tdd-decompose`, read by
   `/tdd-plan` and `/tdd-status`. Format:

   ```markdown
   # Feature: <name>
   **Created:** <ISO 8601>
   **Branch:** feature/<name>

   ## Phase 1: Foundation (Slices 1-2) — done
   **Scope:** Models + ZenohService
   **Exit criteria:** Models pass, ZenohService GATE passes
   **Archive:** planning/phase-1-foundation-*.md

   ## Phase 2: Data Layer (Slices 3-4) — in-progress
   **Scope:** Counter + Settings repositories
   **Exit criteria:** Repositories pass with fakes
   ...
   ```

3. **Phase-aware `/tdd-plan`** — Modified behavior when `.tdd-phases.md`
   exists:

   ```
   if .tdd-progress.md exists:
     if has pending slices:
       → "Run /tdd-implement first" (current behavior)
     if all slices terminal AND .tdd-phases.md has more phases:
       → Archive .tdd-progress.md to planning/
       → Update .tdd-phases.md (mark phase done)
       → Identify next phase from .tdd-phases.md
       → Ask CA to confirm proceeding to next phase
       → Plan next phase (fresh .tdd-progress.md)
     if all slices terminal AND no more phases:
       → "All phases complete. Run /tdd-release"
   if .tdd-progress.md does not exist AND .tdd-phases.md exists:
     → Identify first unplanned phase
     → Plan that phase
   if neither file exists:
     → Current behavior (plan the whole feature)
   ```

4. **Cross-phase context** — When planning Phase N, the planner
   automatically gathers:
   - Files created on the branch: `git diff --name-only main...HEAD`
   - Completed phase summaries from `.tdd-phases.md`
   - Planner memory from `memory: project` (accumulates naturally)

### Enhanced Phase Support (v2)

5. **Phase-aware `/tdd-status`** — Reports phase-level progress alongside
   slice-level progress.

6. **Phase-aware `/tdd-verify-feature`** — Verification at phase boundaries.

### What NOT to Build

- **Phase-aware implementer** — The implementer doesn't need to know about
  phases. It processes pending slices. `.tdd-progress.md` contains only
  the current phase's slices, so the implementer naturally stays scoped.

- **Phase-aware verifier** — Same reasoning. The verifier checks whatever
  slice it's given.

- **Cumulative `.tdd-progress.md`** — Keep the existing ephemeral model.
  Each phase gets its own fresh progress file. History lives in
  `planning/` archives and `.tdd-phases.md` status.

## 10. Open Questions

### 10.1 Where does the phase plan live?

Options:
- `.tdd-phases.md` at project root (parallel to `.tdd-progress.md`)
- `docs/plan/phases.md` (in the docs directory)
- `planning/phases.md` (in the planning archive)

The user currently puts phase docs in `docs/plan/`. The master file
could live there too, or at the root for visibility.

### 10.2 Does `/tdd-decompose` produce phase DOCUMENTS or just a phase LIST?

The user's current phase documents (like `phase-1-foundation.md`) include
full project context, constraints, and even code signatures. These are
essentially complete planning inputs.

Should `/tdd-decompose` produce:
- **Just a list:** Phase names, scope, ordering, exit criteria (~1 page)
- **Full phase documents:** Complete planning inputs per phase (~5 pages each)

The list is simpler and lets the planner do its job. The full documents
front-load more CA work into the decomposition step.

**Suggestion:** Start with a list. If the planner consistently needs more
context, evolve toward fuller phase documents.

### 10.3 When should `/tdd-decompose` be used vs. direct `/tdd-plan`?

Not every feature needs phases. Small features (3-5 slices) work fine
with a single `/tdd-plan` invocation. The decomposition step adds
overhead that isn't worth it for small features.

**Heuristic:** If CA expects more than ~6 slices, use `/tdd-decompose`
first. Otherwise, go straight to `/tdd-plan`.

The skill could detect this: research the feature scope, estimate slice
count, and recommend whether phasing is needed.

### 10.4 Should the planner auto-detect that it's planning a phase?

If `.tdd-phases.md` exists, the planner could automatically:
1. Read the phase plan
2. Identify which phase is being planned
3. Gather cross-phase context from git
4. Scope its output to that phase

This would work without modifying `/tdd-plan` — the planner agent already
reads the project state. It just needs instructions to look for
`.tdd-phases.md`.

### 10.5 How do phases interact with git branches?

Current model: one feature branch per feature, created by `/tdd-implement`.
With phases, options include:
- **One branch for all phases** (current) — simplest, one PR at the end
- **One branch per phase** — multiple PRs, more granular review
- **Phase branches from feature branch** — sub-branches merged into feature

**Suggestion:** Keep one branch. Phases are planning units, not release
units. The feature ships as one PR.

### 10.6 How does this interact with `/tdd-init-roles`?

The iterative lifecycle from the prior exploration maps cleanly:

```
/tdd-decompose             → phase breakdown (CA reviews)
/tdd-init-roles [v1]       → initial roles from spec + skeleton
/tdd-plan Phase 1          → first phase planned
/tdd-init-roles [v2]       → roles refined with Phase 1 knowledge
/tdd-implement Phase 1     → code exists
/tdd-plan Phase 2          → second phase planned (planner has context)
/tdd-implement Phase 2     → more code
...
/tdd-init-roles [vN]       → mature roles after all phases
/tdd-release               → feature ships
```

## 11. Summary

| Question | Answer |
|----------|--------|
| Is phased planning needed? | **Yes** — context pressure is real for features with 6+ slices |
| What's the highest-value gap? | **Phase transition lifecycle** — `.tdd-progress.md` blocks `/tdd-plan` between phases |
| Second-highest gap? | **Phase decomposition** (currently manual CA work) |
| Third gap? | **Cross-phase context** (currently manual "What Exists" sections) |
| What changes in existing components? | **`/tdd-plan` skill** needs phase-aware branching logic |
| What's new? | `/tdd-decompose` skill, `.tdd-phases.md` master file |
| How do phases interact with `.tdd-progress.md`? | One progress file per phase (archived on phase transition) |
| Where does the phase plan live? | `.tdd-phases.md` at project root |
| Grouping criteria? | By-layer (MVVM), by-feature, or by-risk — skill asks user |
| Git model? | One branch per feature (phases are planning units, not release units) |
| Estimated effort (v1)? | `/tdd-decompose` skill + agent + `/tdd-plan` modification: ~200 lines |

---

*Concept exploration complete 2026-03-15. Needs refinement in future sessions.
Integration with `/tdd-init-roles` lifecycle documented in section 10.6.*
