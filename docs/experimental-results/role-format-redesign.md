---
name: Role format v2.1 redesign decisions
description: Key design decisions from 2026-03-21 CR validation session — templates eliminated, format spec simplified, CR made role-agnostic
type: project
---

## Decisions (2026-03-21)

### Templates eliminated
Role composition tables (§4) and per-role templates (ca-template.md, ci-template.md,
cp-template.md) are NOT needed. The format spec is a section menu, not a checklist.
CR generates role content from format rules + project research, not from templates.

**Why:** Templates were "compressed templates in disguise" — the §4 Content Focus column
tried to do what templates would do but was too thin to generate from. Without templates,
FIXED/HYBRID/DYNAMIC distinction lost its meaning (nothing to copy verbatim from).

**Archived:** Old §4 composition tables saved in `memory/removed-role-compositions.md`.

### FIXED/HYBRID/DYNAMIC → Core/Optional/Custom
Format spec v2.1 replaces the three section types with:
- **Core** (Identity, Responsibilities, Constraints) — almost always needed
- **Optional** (Memory, Startup, Workflow, Context, Coordination) — include when relevant
- **Custom** — developer-defined sections, first-class citizens, same quality rules

**Why:** A single-role developer doesn't need Coordination. A simple role doesn't need Memory.
The format should be a toolkit CR selects from, not a mandatory checklist.

### Only Identity is required
All other sections are optional. Validation no longer checks "all core sections present."

### Custom sections are first-class
Developers can add sections the format spec doesn't define (e.g., `## Level Design Patterns`,
`## Pipeline Topology`). They go after optional sections, before Coordination (if present),
and follow the same quality rules.

### CR is role-agnostic
CR doesn't know about CA, CI, or CP. It generates whatever roles the developer needs based
on their workflow description or existing prompts. This was validated against three use cases:
1. "I need roles for my three-session workflow" → generates multiple roles
2. "I only use tdd-planner and write tests manually" → generates one role
3. "I have an existing prompt, formalize it" → maps existing content to format sections

### CR has an Approve/Modify/Reject gate
Same pattern as `/tdd-plan`. CR presents the generated role, developer approves, modifies,
or rejects before anything is written to disk.

### Output convention: `context/roles/`
Role files live at `context/roles/{role-code}-{short-name}.md` — project-owned, versioned,
outside `.claude/` to avoid namespace collisions with Claude Code internals. Developer can
use a different path if they prefer (e.g., `ai/roles/`).

### Role import workflow
Developer copies role file from project A to project B, tells CR to adapt it. CR researches
project B, diffs intent vs reality, updates project-specific content, presents for approval.
No new tooling needed — file copy + CR adaptation.

## Flutter Test Results (2026-03-21)

Tested CR on `/tmp/solitaire` — a fresh `flutter create` project with only CLAUDE.md from `/init`.

### CR behavior (acting as pasted prompt, not skill)
1. Ran startup correctly — checked MEMORY.md, .tdd-progress.md, git, existing roles
2. Asked targeted questions before generating (workflow, variant, state mgmt, constraints)
3. Verified external deps (Flame 1.36.0, Riverpod 3.3.1, flame_riverpod 5.5.3)
4. Adapted original CA role intelligently — dropped Coordination, combined sections, added Context
5. Hit Approve/Modify/Reject gate
6. Generated 108-line role file at `context/roles/ca-architect.md`

### Generated CA role quality
- Format compliant (all validation rules pass except minor constraint wording)
- Architecture boundaries section was the standout — Flame/Riverpod/Flutter/pure-Dart separation
- Correctly dropped agent memory layer (none exists), Coordination (single developer)
- Minor issues: `generator: manual` (should be CR), constraints 1-2 lack consequences

### CA role functional test
Loaded the generated CA role in the same session. CA:
- Ran its startup checklist correctly
- Proposed detailed project file structure that followed the architecture boundaries from Context
- Kept pure Dart separation (models/ + logic/ have zero Flutter/Flame imports)
- Stayed within constraints (didn't write code, asked rather than guessing game rules)
- Test structure mirrors lib/ as expected

**Verdict:** CR generates useful roles. The generated CA role guided a session to produce
architecturally sound output that respected the encoded boundaries and constraints.

### Write-before-approve "bug"
CR wrote the file to disk before the developer approved. This is NOT a bug in CR's role file
or the format spec — it's an artifact of testing CR as a pasted prompt. When implemented as
a proper skill + agent (like `/tdd-plan` + `tdd-planner`), the skill handles the approval gate
mechanically: agent returns text → skill presents → developer approves → skill writes.
No fix needed to CR or format spec.

## Test 2: Three-role generation (2026-03-21)

Fresh `/tmp/solitaire`, same stack (Flame + Riverpod 3.x). Provided all three existing
dev-roles (CA, CP, CI) and asked CR to adapt them.

### Findings
- CR was too deferential to source material — near-verbatim copy with project name substitution
- Test 1 (single role, briefer prompt) produced richer, more creative output
- "Do write" non-constraint carried verbatim from original — CR didn't flag it
- Constraints lacked consequences — CR didn't enforce format spec rules
- Context sections were thin (one-line architecture) vs Test 1's rich boundaries
- CP inherited `type: session` without questioning whether `type: context` fits better
- Coordination sections were correct — proper handoff directions for all three roles
- Custom sections preserved (CP Quality Checklist, CI Error Handling)

### Root cause
CR's workflow had no explicit critique step between mapping existing content and generating.
It mapped → generated → validated, but validation was too late to improve content quality.

### Fix applied
Added **Critique** phase (steps 5-6) to CR's workflow between Research and Generate:
- Check constraints against format rules (absolute? consequences? no permissions?)
- Question inherited role type assumptions
- Evaluate Context richness — add architecture boundaries when research supports it
- Flag verbatim copying when adaptation is warranted
- Report critique to developer before generating

CR bumped to include steps 1-4 (Research), 5-6 (Critique), 7-9 (Generate), 10-11 (Approve).

## Tests 3-4: Critique phase validation (2026-03-21)

Test 3 showed critique phase improved 5 of 10 issues (dropped "Do write", richer Context,
domain-specific CP checklist, removed plugin-specific hook references, correct `flutter analyze`).
Test 4 showed non-deterministic regression — `generator: manual` and "Do write" came back.

**Conclusion:** Prompt-level refinements have diminishing returns. Persistent issues
(`generator` field, constraint consequences, "Do write") need mechanical enforcement
in skill/agent implementation, not more words in the role file.

## Test 5: RTFM principle (2026-03-21)

Added step 4 to Research: "RTFM — do not rely on internal knowledge. If information is not
present in session context, memory, or project docs, spawn research agents."

### Key finding
CR didn't auto-trigger research — had to be prompted ("did you spawn research agents?").
Once prompted, CR spawned 3 agents (Flame patterns, Riverpod 3.x no-codegen, Flame+Riverpod
integration) totaling ~67k tokens of research.

### Research impact on role files
Research replaced vague internal-knowledge descriptions with verified API-specific content:

| Before (training data) | After (verified docs) |
|---|---|
| "Riverpod providers that Flame components watch" | flame_riverpod 5.5 — RiverpodAwareGameWidget + RiverpodGameMixin + RiverpodComponentMixin |
| "Riverpod 3.x" | NotifierProvider/AsyncNotifierProvider, no legacy StateProvider, ProviderContainer.test() |
| generic component pattern | addToGameWidgetBuild() BEFORE super.onMount(), ref.listen preferred over ref.watch |
| "GameWidget" | RiverpodAwareGameWidget with GlobalKey (plain GameWidget crashes) |
| "flutter test" | Three-tier: ProviderContainer.test(), testWithFlameGame, testWidgets |

### Research impact on downstream CA output
When CA used the researched role to propose file structure, every file referenced real APIs:
- `app.dart` → "RiverpodAwareGameWidget setup with GlobalKey"
- `solitaire_game.dart` → "FlameGame + RiverpodGameMixin"
- `card_component.dart` → "PositionComponent + RiverpodComponentMixin + DragCallbacks"
- Test tiers mapped to actual test utilities
- `drag_stack.dart` separated as Flame rendering concern (shows real component model understanding)

**Verdict:** RTFM is the single highest-impact addition to CR's workflow. The difference
between internal knowledge and researched docs is the difference between plausible architecture
and architecture that prevents real bugs (e.g., plain GameWidget crashes, ref.watch vs ref.listen).

### Remaining non-deterministic issues (need mechanical enforcement)
- `generator: manual` vs `/role-init` — varies across runs
- "Do write" non-constraint — sometimes caught, sometimes not
- Constraints without consequences — consistently missed
- Research not auto-triggered — CR needed prompting despite explicit RTFM instruction

These are skill/agent implementation concerns, not role file refinements.

## CR Validation Complete (2026-03-21)

5 tests across 3 workflow revisions. CR + format spec v2.1 validated. Design is sound.
Remaining gaps are implementation concerns for the skill/agent layer.

## Architecture Decision: Skill-only, no agent (2026-03-21)

`/role-cr` is an inline skill (like `/tdd-implement`), NOT a skill + forked agent.

**Why no agent:**
- Role creation is conversational — agents are fire-and-forget, can't do multi-turn
- The developer's input (workflow description, existing prompts, answers to questions)
  is the primary source material, and the session already has perfect context
- A forked agent would lose conversation history or need it serialized
- The `/tdd-plan` analogy breaks down: planner has well-defined input/output,
  role creation has variable input and variable output
- The mechanical enforcement we need is small enough for a validation script

**Skill-only architecture:**
```
/role-cr (inline skill)
  → Loads CR role content into session via DCI
  → Developer has conversation with CR
  → When developer says "generate":
    → CR generates role file content in the session
    → Skill runs validate-role-output.sh (hard fail on:
      missing consequences, placeholders, non-existent paths, permissions-as-constraints)
    → Skill sets generator field
    → Skill presents with Approve/Modify/Reject
    → Skill writes to context/roles/ on Approve
```

**One exception:** RTFM research. A validation script can check IF research was done
(does Context reference specific API classes or just framework names?) but can't DO
research. The skill may spawn a research subagent specifically for stack investigation —
not a role-generation agent, just a research helper.

**`/role-init` is eliminated.** `/role-cr` absorbs its purpose. The role-initializer
agent from the synthesis doc is not needed.

**Next steps:**
1. Build `/role-cr` inline skill with `validate-role-output.sh`
2. Create implementation issue for roles feature
3. `/role-evolve` remains a separate future feature (memory-driven, different problem)

## E2E Test: Plugin Install (2026-03-21)

v2.1.0 installed from marketplace, tested on fresh Flutter project (`/tmp/solitaire`).

### Full chain validated
`/role-cr` skill → DCI loaded references → CR researched Flame/Riverpod (spawned 3 agents) →
critique caught "Do write" + missing consequences → validator caught non-existent example paths
(memory/feature-plan.md, issues/001-card-model.md, planning/, test/) → CR fixed and re-validated
→ approval gate → files written to `context/roles/`.

### Validator earned its keep
Caught 4 non-existent path references that prompt-level CR never caught. CR iterated to fix
each one before files passed. This is the mechanical enforcement working as designed.

### CA functional test (best output yet)
Loaded generated CA role, proposed file structure with:
- `state/rules/` as pure Dart functions (not even Riverpod — purer than any previous test)
- Provider-per-domain split (tableau, foundation, stock, move, score, win)
- `win_provider` as derived provider watching foundations
- Explicit "what this doesn't include" section (scope discipline)
- All Flame/Riverpod API references correct (RiverpodGameMixin, RiverpodComponentMixin, etc.)

### Observation
Validator may be too aggressive on illustrative example paths (e.g., `issues/001-card-model.md`
in an "e.g." context). CR had to strip useful context to pass. Future refinement: consider
skipping paths preceded by "e.g." or inside parenthetical examples. Being too strict is better
than too loose, so not urgent.

## Architecture Reversal: Skill-only → Skill+Agent (2026-03-22)

Original decision (2026-03-21): skill-only, no agent. CR handles everything inline.

**Reversed after E2E testing (2026-03-22):** DCI permission prompts interrupt the skill's
procedural chain. Recovery is non-deterministic — CR skips critique, validation, approval.
6+ E2E tests confirmed: bypass-on = correct output, bypass-off = degraded output every time.

**New architecture:** `/tdd-plan` + `tdd-planner` pattern.
- Skill (inline): conversation, gather input, spawn agent, present, approve, write to disk
- Agent (forked, read-only): reads references via Read tool, researches, critiques, generates,
  validates, returns text. No Write/Edit tools — approval gate is mechanical.

**Critical insight:** Remove DCI entirely from the skill. The agent reads cr-role-creator.md
and role-format.md itself via Read tool. No DCI = no permission prompt = no interruption.
`load-role-references.sh` (Issue 009) is no longer used by the skill.

**Agent has no memory for v1.** Generated role files are the durable output. Memory becomes
valuable when `/role-evolve` exists — add it then based on real usage evidence.

**Issue:** `issues/010-role-cr-skill-agent-split.md`

## Files shipped in v2.1.0
- `skills/role-cr/SKILL.md` — inline skill with DCI, validation, approval gate
- `scripts/validate-role-output.sh` — hard-fail validation (188 lines)
- `skills/role-init/reference/role-format.md` — v2.1, section menu model
- `skills/role-init/reference/cr-role-creator.md` — v2, critique phase, RTFM, role-agnostic
- 42 new tests (691 total, 1010 assertions)
