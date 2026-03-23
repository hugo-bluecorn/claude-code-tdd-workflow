# Role Creator (CR) Validation Report

**Authors:** Hugo (developer), Claude Opus 4.6 (CA session)
**Date:** 2026-03-21 to 2026-03-23
**Plugin:** tdd-workflow v2.0.0 → v2.3.0
**Target project:** Klondike solitaire (Flutter/Dart, Flame, Riverpod 3.x)

---

## Abstract

This report documents the iterative design, implementation, and validation
of the Role Creator (CR) feature for the tdd-workflow Claude Code plugin.
Over three days and 10+ experiments, we evolved CR from a pasted prompt
through an inline skill to a skill+agent architecture. Key findings:
(1) prompt-level procedural instructions are non-deterministically followed
by LLMs, (2) DCI shell commands in Claude Code skills create permission
interruptions that corrupt procedural chains, (3) forked agents with
restricted tool access provide mechanical enforcement that inline skills
cannot, (4) requiring LLMs to research external documentation (RTFM)
rather than relying on training data produces dramatically higher-quality
output with verified API references. The final v2.3.0 architecture
generates validated, auto-discoverable role skill files without requiring
permission bypass.

---

## 1. Introduction

### 1.1 Problem Statement

Developers using the tdd-workflow plugin across multiple projects need
project-specific role files that encode workflow patterns, knowledge
references, and behavioral constraints into reusable session documents.
The three-session model (CA/CP/CI) requires each session to know its
identity, responsibilities, constraints, and coordination protocols.
Without role files, developers manually repeat these instructions at the
start of every session.

### 1.2 What Roles Are

A role encodes the repeated workflow patterns, knowledge references, and
behavioral constraints that a developer would otherwise manually provide
at the start of every session. Roles answer three questions:

1. **Who is this session?** — identity, responsibilities, constraints
2. **What does this session know?** — project context, architecture notes
3. **How does this session work?** — startup procedures, review checklists

### 1.3 What CR Does

The Role Creator (CR) is a meta-role — it generates role files for other
projects. It researches a target project's codebase, asks the developer
about their workflow, and produces structured role files conforming to
the Role File Format specification.

### 1.4 Research Questions

1. Can CR generate role files that are functionally useful — i.e., that
   guide a session to produce architecturally sound output?
2. What delivery mechanism (prompt, skill, skill+agent) produces reliable,
   deterministic output quality?
3. What workflow refinements (critique phase, RTFM, mechanical validation)
   have the highest impact on output quality?

---

## 2. Background

### 2.1 Prior Work

The Role File Format v2.0 was authored 2026-03-20. It defined YAML
frontmatter, section types (FIXED/HYBRID/DYNAMIC), composition tables
for CA/CI/CP/CR roles, and validation rules. The CR meta-role file was
manually authored as the first format-conforming instance.

Prior explorations documented in `explorations/features/roles/synthesis.md`
established the prime directive (roles are optional, core TDD workflow
never depends on them), the three-session coordination model, and the
planned skill architecture.

### 2.2 Claude Code Plugin Architecture

The tdd-workflow plugin provides six agents and multiple skills. The
established pattern for complex operations is inline skill + forked agent
(e.g., `/tdd-plan` + `tdd-planner`). Skills handle user interaction;
agents handle mechanical execution in isolated contexts.

### 2.3 Relevant Platform Behaviors

- **DCI (Dynamic Context Injection):** `!`cmd`` syntax in skill files
  executes shell commands at skill preprocessing time, injecting output
  into the skill body before Claude sees it.
- **Permission bypass:** Claude Code's `shift+tab` cycles through
  permission modes including bypass, which auto-approves all tool calls.
- **Skill discovery:** `.claude/skills/<name>/SKILL.md` files are
  auto-discovered at session startup (not mid-session).
- **`${CLAUDE_PLUGIN_ROOT}`:** Environment variable resolved by Bash at
  execution time, not in agent body text or Read tool paths.

---

## 3. Methodology

### 3.1 Test Environment

- **Target project:** `/tmp/solitaire` — a fresh `flutter create` project
  recreated from scratch before each experiment
- **Stack:** Dart SDK ^3.11.1, Flutter, Flame 1.36+, Riverpod 3.x (no
  codegen), flame_riverpod 5.5+
- **Plugin source:** `claude-code-tdd-workflow` (this repository)
- **Plugin delivery:** Local marketplace install (`local-plugins`)

### 3.2 Measurement Criteria

Each generated CA role was evaluated against 12 criteria:

| # | Criterion | Description |
|---|---|---|
| 1 | Frontmatter completeness | Required fields present (role, name, type) |
| 2 | Skill frontmatter | name: role-{code}, description, disable-model-invocation |
| 3 | Generator field | Set to `/role-cr` (not `manual`) |
| 4 | "Do write" absence | No permissions disguised as constraints |
| 5 | Constraints with consequences | Every constraint explains what breaks |
| 6 | Architecture boundaries | Specific API names, not generic descriptions |
| 7 | Workflow procedures | Concrete step-by-step checklists |
| 8 | RTFM research | Web search for unfamiliar tech, not training data |
| 9 | Validation execution | `validate-role-output.sh` ran and passed |
| 10 | Approval gate | Approve/Modify/Reject before writing to disk |
| 11 | Skill discoverability | Auto-discoverable via `/role-{code}` |
| 12 | Bypass independence | Works without permission bypass |

### 3.3 Functional Validation

After generating roles, we loaded the CA role into a session and prompted:
"Become CA now and then propose the file structure for this project." The
file structure proposal was evaluated for:

- Correct separation of concerns (Flame/Riverpod boundary)
- Use of specific API references (not generic framework names)
- Test strategy alignment with the architecture
- Scope discipline (not over-engineering)

### 3.4 Standardized Prompts

Five standardized prompts were used across experiments. Full text is
documented in Appendix C (Chronological Experiment Log, "Prompts Used"
section). Summary:

| Prompt | Purpose | Used in |
|---|---|---|
| A | Load CR via pasted files | Tests 1-5 (pre-skill) |
| B | Single-role request | Test 1 |
| C | Three-role adaptation (with source files) | Tests 2-5, E2E v2.1.0-v2.2.1 |
| D | Three-role from scratch (no source files) | E2E v2.3.0 |
| E | CA functional test ("propose file structure") | Tests 1, 5, all E2E |

Prompts C and D differ only in whether source role file paths are provided.
This isolates the effect of source material on CR's output quality.

### 3.5 Source Input Matrix

A key experimental variable was the source input provided to CR for role
generation. Two conditions were tested:

| Condition | Description | Prompt | Experiments |
|---|---|---|---|
| **A priori** | Generate from scratch — CR researches the target project and developer's workflow description, no prior role files provided | D (also B for single-role) | Test 1, E2E v2.3.0 |
| **Adapted** | Adapt from existing roles — CR receives paths to hand-authored role files from another project and maps them to the target | C | Tests 2-5, E2E v2.1.0-v2.2.1 |

This matrix was not designed in advance. Test 1 used a priori generation
naturally (the developer didn't mention source files). Test 2 introduced
source files to test adaptation. The quality difference between conditions
was an emergent finding that informed later experiments.

**Observed difference:** A priori generation (Test 1) produced richer
architecture boundaries, more creative section composition, and
project-specific adaptations. Adapted generation (Tests 2-4) was
deferential to source material — near-verbatim copying with minimal
project-specific enrichment. The final v2.3.0 test deliberately used
a priori generation (Prompt D) informed by this finding.

### 3.6 Experimental Controls

- Each experiment used a freshly recreated `/tmp/solitaire` project
- The same base prompt was used across comparable experiments
- Only one variable changed between sequential experiments
- All experiments were conducted by the same CA session (this session)

### 3.7 Auto-Memory Contamination (Discovered Variable)

Claude Code persists auto-memory at `~/.claude/projects/<path>/memory/`,
derived from the project's absolute path. Deleting the project directory
(`rm -rf /tmp/solitaire`) does NOT clear the memory — it persists in
`~/.claude/`.

**Tests 1-5 (prompt-based):** Clean. No auto-memory existed because these
were the first sessions at that path. No autocompaction occurred. The
developer never asked Claude to create memories. CR was pasted, not a
plugin — no hooks created memory.

**E2E tests v2.1.0 onward:** Contaminated. The v2.1.0 session created
memory files (`user_workflow.md`, `project_stack.md`). Subsequent `/init`
runs read these and injected Flame/Riverpod stack info into CLAUDE.md
without developer input — an uncontrolled variable not present in Tests 1-5.

**Corrective action for v2.3.0 Prompt C test:** Auto-memory explicitly
cleared before the experiment (`rm -rf ~/.claude/projects/-tmp-solitaire/memory/`),
restoring clean-slate conditions matching Tests 1-5.

See Appendix C "Note on Auto-Memory Contamination" for the full analysis.

---

## 4. Experiments and Results

### Phase 1: Format Spec Redesign (2026-03-21)

#### 4.1.1 Pre-test: CR Format Validation

Validated the manually-authored CR role file against the format spec v2.0.

**Defects found:** 4 (incorrect stage field, non-existent template file
paths, missing Identity consistency, no CR composition table in §4).

**Action:** Fixed all defects directly.

#### 4.1.2 Format Spec Simplification

Through thought experiments examining use cases (single-developer with
one role, developer formalizing an existing prompt, developer importing
roles between projects), we identified fundamental problems with the
format spec:

1. §4 composition tables hardcoded CA/CI/CP roles — contradicted the
   goal of CR being role-agnostic
2. FIXED/HYBRID/DYNAMIC section types assumed templates that didn't exist
3. "FIXED sections are copied verbatim from templates" — no templates
   existed to copy from
4. Required sections (Memory, Coordination) weren't needed for all roles

**Action:** Removed §4 composition tables (archived). Replaced
FIXED/HYBRID/DYNAMIC with Core/Optional/Custom section menu. Made only
Identity required. Added Custom sections as first-class citizens. Bumped
format spec to v2.1. Made CR role-agnostic (removed all CA/CI/CP references).

**Decision:** Output convention set to `context/roles/` (later changed to
`.claude/skills/` in Phase 2).

### Phase 2: Prompt-Based Testing (2026-03-21)

All tests in this phase used CR as a pasted prompt (not a skill or agent).
The target was a fresh Flutter solitaire project with Flame + Riverpod.

#### 4.2.1 Experiment 1: Single-Role Generation

**Variable:** No source roles provided. Brief prompt + Flame GitHub URL.

**Results (12 criteria):**

| Criterion | Result |
|---|---|
| Frontmatter | PASS (role fields only) |
| Skill frontmatter | N/A (predates skill output) |
| Generator field | FAIL (`manual`) |
| "Do write" absence | PASS |
| Constraints with consequences | FAIL (2 of 4 lack consequences) |
| Architecture boundaries | PASS (rich 4-layer separation) |
| Workflow procedures | FAIL (none) |
| RTFM research | PASS (spawned research agents) |
| Validation execution | FAIL (not invoked) |
| Approval gate | FAIL (wrote before approval) |
| Skill discoverability | N/A |
| Bypass independence | N/A |

**Functional test:** CA proposed file structure with pure Dart separation,
per-domain providers, Flame Behavior pattern, three-tier test structure.
Architecture boundaries from the role correctly influenced the output.

**Key finding:** Giving CR creative freedom (no source files to copy)
produced richer output than providing source files.

#### 4.2.2 Experiment 2: Three-Role Adaptation

**Variable:** Provided three existing dev-role files from the plugin project.

**Results:** CR was too deferential to source material. Near-verbatim copy
with project name substitution. "Do write" non-constraint carried through.
Context sections thin (one line vs Experiment 1's rich boundaries).
Constraints lacked consequences. Coordination sections correct.

**Root cause identified:** No critique step between mapping and generating.

**Action:** Added Critique phase (steps 5-6) to CR's workflow.

#### 4.2.3 Experiment 3: Critique Phase Validation

**Variable:** CR workflow now includes Critique phase.

**Results:** 5 of 10 tracked issues improved. "Do write" dropped. Context
expanded. CP Quality Checklist became domain-specific. Plugin-specific
references removed. `flutter analyze` replaced plugin hook reference.

**Still failing:** `generator: manual`, constraints lack consequences,
CP type not questioned.

#### 4.2.4 Experiment 4: Non-Determinism Test

**Variable:** None — identical prompt and setup to Experiment 3.

**Results:** Regressions. `generator: manual` returned. "Do write" returned.
CP Quality Checklist lost domain-specific items. Improvements from
Experiment 3 were non-deterministic.

**Conclusion:** Prompt-level refinements have diminishing returns. The same
prompt produces different quality across runs. Persistent issues require
mechanical enforcement, not more prompt engineering.

#### 4.2.5 Experiment 5: RTFM Principle

**Variable:** Added RTFM instruction: "do not rely on internal knowledge,
spawn research agents for unfamiliar tech."

**Finding:** CR did NOT auto-trigger research despite the explicit
instruction. Required manual prompting. After prompting, CR spawned 3
research agents (~67k tokens):

| Internal Knowledge | Researched Documentation |
|---|---|
| "Riverpod providers that Flame components watch" | flame_riverpod 5.5 — RiverpodAwareGameWidget + RiverpodGameMixin + RiverpodComponentMixin |
| "Riverpod 3.x" | NotifierProvider/AsyncNotifierProvider, no legacy StateProvider, ProviderContainer.test() |
| generic component pattern | addToGameWidgetBuild() BEFORE super.onMount(), ref.listen over ref.watch |
| "GameWidget" | RiverpodAwareGameWidget with GlobalKey (plain GameWidget crashes) |
| "flutter test" | Three-tier: ProviderContainer.test(), testWithFlameGame, testWidgets |

**Functional test:** CA proposed file structure referencing real APIs
throughout — `RiverpodAwareGameWidget setup with GlobalKey`,
`FlameGame + RiverpodGameMixin`, `PositionComponent + RiverpodComponentMixin +
DragCallbacks`, `state/rules/` as pure Dart functions (not even Riverpod).

**Conclusion:** RTFM is the single highest-impact workflow addition. The
difference between internal knowledge and researched docs is the difference
between plausible architecture and architecture that prevents real bugs.

### Phase 3: Skill Implementation (2026-03-21 to 2026-03-22)

#### 4.3.1 Architecture Decision: Skill-Only

Based on Phase 2 results, we decided to implement `/role-cr` as an inline
skill (no agent). Arguments:

- Role creation is conversational — agents can't do multi-turn
- Developer's input is primary source material
- Forked agent loses conversation history
- Mechanical enforcement achievable via validation script

**Issue 007** implemented: `/role-cr` inline skill + `validate-role-output.sh`.
42 new tests. v2.1.0 shipped (PR #12).

#### 4.3.2 E2E Test: v2.1.0 (bypass ON)

Installed from marketplace. Fresh solitaire project.

**Results:** DCI loaded references (with some searching). CR researched
Flame/Riverpod. Critique caught "Do write" + missing consequences.
Validator caught 4 non-existent path references and CR fixed them.
Approval gate hit. Files written to `context/roles/`.

**Validator findings:** `memory/feature-plan.md` (example path),
`issues/001-card-model.md` (example), `planning/` (directory),
`test/` (directory) — all flagged as non-existent. CR rewrote to
remove specific path references.

**Observation:** Validator may be too aggressive on illustrative paths
in "e.g." contexts. Noted as future refinement.

### Phase 4: Output Path Migration (2026-03-22)

#### 4.4.1 Research: Anthropic's `.claude/` Guidance

Investigated official Claude Code documentation for gitignore policy.

**Findings:**

| Path | Track? | Source |
|---|---|---|
| `.claude/settings.json` | Yes | Official docs |
| `.claude/settings.local.json` | No | Auto-gitignored by Claude Code |
| `.claude/skills/` | Yes | Official docs: "Commit to version control" |
| `.claude/agents/` | Yes | Official docs |
| `.claude/agent-memory/` | No | Siloed by design |

#### 4.4.2 Research: Skill Discovery and Hot-Reload

**Finding:** Skills in `.claude/skills/` are discovered at session startup
only. `/clear` does NOT re-discover skills. Community feature requests
confirm: GitHub #20507 (`/reload-skills`), #28685 (`/restart-session`).

**Implication:** After CR generates role skills, developer must restart the
session to invoke them.

#### 4.4.3 Identity Conflict Discovery

Explored `/role-load` as a generic delivery mechanism. Traced the workflow
of loading multiple roles in the same session:

**Finding:** With 1M context, nothing gets compacted. Loading CA then CI
in the same session creates conflicting identity instructions. CA says
"never write code," CI says "write code." The most recent role wins by
recency bias, but the earlier role creates noise.

**Conclusion:** Role switching requires `/clear` + reload. The three-session
model is about context purity, not context size. This remains true at 1M tokens.

#### 4.4.4 Decision: Role Files as Skills

Generated role files written to `.claude/skills/role-{code}/SKILL.md`
serve dual purpose — both role definition and auto-discoverable skill.
Eliminates need for separate `/role-ca`, `/role-cp`, `/role-ci` delivery skills.

**Issue 008** implemented: output path change. 28 new tests. v2.2.0 shipped (PR #13).

### Phase 5: DCI Security Discovery (2026-03-22)

#### 4.5.1 Experiment: v2.2.0 (bypass OFF)

First test without permission bypass.

**Error observed:**
```
Shell command permission check failed for pattern
"!.../scripts/load-role-references.sh": This command requires approval
```

**Finding:** DCI scripts from installed plugins prompt for approval when
bypass is off. Our previous conclusion that "installed plugins execute DCI
without prompting" was incorrect — we had always been testing with bypass on.

**After approving:** CR recovered but skipped critique, approval gate, and
validation. Output had no skill frontmatter, Identity said "tdd-workflow
plugin" instead of "solitaire project."

#### 4.5.2 Hypothesis: `cat` is the problem

Replaced `cat` DCI commands with a `load-role-references.sh` script.

**Issue 009** implemented. v2.2.1 shipped (PR #14).

#### 4.5.3 Experiment: v2.2.1 (bypass OFF)

**Same error.** The DCI execution path itself prompts regardless of the
command. Replacing `cat` with a script made no difference.

**After approving:** Same procedural corruption. CR skipped critique,
approval, validation. Wrote files without skill frontmatter.

**Conclusion:** The DCI mechanism is the root cause, not the specific
command. Any `!`cmd`` in a skill prompts without bypass, and the
interruption corrupts the procedural chain.

#### 4.5.4 Procedural Corruption Analysis

Developer observed: "Skills based on context only have issues when trying
to follow a mechanical procedure and the procedure is interrupted. The
interruption may and can lead to non-deterministic 'recovery' of the
mechanical procedure with empty gaps or new gaps introduced to compensate
for the interruption procedural gap."

**Bypass-off results (3 runs, 100% reproducible):**
1. DCI permission prompt interrupts skill loading
2. Developer approves
3. CR "recovers" but skips 2-4 procedural steps
4. Output quality degraded: no frontmatter, verbatim copying, no validation

**Bypass-on results (3 runs, 100% reproducible):**
1. DCI loads cleanly
2. Full procedure executes
3. Quality output with all checks

### Phase 6: Architecture Reversal (2026-03-22 to 2026-03-23)

#### 4.6.1 Decision Reversal: Skill-Only → Skill+Agent

**Original decision (2026-03-21):** Skill-only, no agent.

**Evidence forcing reversal:** 6+ E2E tests showing 100% reproducible
procedural corruption without bypass.

**New architecture:**
- Skill (inline): NO DCI. Self-contained instructions. Handles conversation,
  spawns agent, presents output, approval gate, writes to disk.
- Agent (forked, read-only): Reads references via Bash `cat ${CLAUDE_PLUGIN_ROOT}/...`.
  Researches, critiques, generates, validates. Returns text. Cannot write files.

**Critical insight:** Remove DCI entirely from the skill. The agent reads
references itself. No DCI = no permission prompt = no interruption.

#### 4.6.2 Research: `${CLAUDE_PLUGIN_ROOT}` Resolution

**Finding:** `${CLAUDE_PLUGIN_ROOT}` does NOT resolve in agent body text.
Agent bodies are plain text system prompts with no preprocessing.

**Correct pattern:** Agent instructs Claude to run
`cat ${CLAUDE_PLUGIN_ROOT}/path/file` via Bash tool. Bash resolves the
variable at execution time.

**Wrong pattern:** Agent instructs Claude to `Read ${CLAUDE_PLUGIN_ROOT}/path/file`.
Read tool receives the literal string. File not found.

**Evidence:** `tdd-planner.md` line 36 uses the Bash pattern for
`detect-project-context.sh` — confirmed working in production.

#### 4.6.3 Issue 010 Implementation

New `role-creator` agent + rewritten `/role-cr` skill. 757 tests, 1109
assertions. v2.3.0 shipped (PR #15).

### Phase 7: Final Validation (2026-03-23)

#### 4.7.1 Experiment: v2.3.0 (bypass OFF)

**Setup:** v2.3.0 installed from marketplace. Fresh `/tmp/solitaire`
(flutter create + /init + git init). Default permissions — no bypass.

**Procedure observed:**

1. `/role-cr` loaded — NO DCI, NO permission prompt from the skill
2. Skill gathered input conversationally in main thread
3. Skill spawned 3 role-creator agents in parallel (CA, CP, CI)
4. Each agent independently:
   - Read cr-role-creator.md + role-format.md via `Bash cat`
   - Read target project (CLAUDE.md, pubspec.yaml, lib/, memory files)
   - Ran web searches for RTFM (Flame, Riverpod, flame_riverpod)
   - Generated role file with skill frontmatter
   - Wrote draft to `/tmp/` for validation
   - Ran `validate-role-output.sh` — caught path issues
   - Fixed issues and re-validated
   - Returned validated content as text
5. Skill presented summary of all three roles
6. Skill asked: **Approve, Modify, or Reject**
7. After Approve: skill wrote to `.claude/skills/role-{code}/SKILL.md`
8. After session restart: `/role-ca`, `/role-cp`, `/role-ci` in autocomplete

**Permission prompts during test:** Bash heredoc, validate-role-output.sh,
plugin scripts/ Read — all normal tool approvals inside agent contexts.
None corrupted the procedural chain.

**Results (12 criteria):**

| Criterion | Result |
|---|---|
| Frontmatter | PASS |
| Skill frontmatter | PASS (name: role-ca, description, disable-model-invocation) |
| Generator field | PASS (/role-cr) |
| "Do write" absence | PASS |
| Constraints with consequences | PASS (all four) |
| Architecture boundaries | PASS (specific APIs: RiverpodComponentMixin, addToGameWidgetBuild) |
| Workflow procedures | PASS (3 concrete checklists) |
| RTFM research | PASS (web search in each agent) |
| Validation execution | PASS (validator ran, caught issues, fixed, re-validated) |
| Approval gate | PASS (Approve/Modify/Reject before write) |
| Skill discoverability | PASS (auto-discovered after restart) |
| Bypass independence | PASS (no bypass needed) |

**Functional test:** CA loaded via `/role-ca`, ran startup checklist,
proposed file structure with `state/rules/` as pure Dart functions,
provider-per-domain split, specific Flame/Riverpod API references throughout.

---

## 5. Discussion

### 5.1 Prompt-Level Instructions Are Non-Deterministic

Experiments 2-4 demonstrated that identical prompts produce different
output quality across runs. The critique phase improved 5/10 issues in
one run and regressed in the next. The RTFM instruction was ignored until
the developer explicitly asked "did you spawn research agents?"

**Implication:** Procedural steps that must execute reliably cannot be
expressed as prompt instructions. They require mechanical enforcement —
either tool restrictions, validation scripts, or agent architecture
that makes skipping steps impossible.

### 5.2 DCI Permission Interruptions Corrupt Procedural Chains

The DCI mechanism (`!`cmd``) executes at skill preprocessing time. When
permission is required, the interruption leaves the skill body incomplete.
The LLM's recovery from this incomplete state is non-deterministic —
it infers where it left off and typically skips steps that depend on the
missing content.

This is not a bug in Claude Code. It is a fundamental property of how
LLMs handle context gaps. The model cannot distinguish between "this
content was supposed to be here but failed to load" and "this content
was intentionally omitted."

**Implication:** Skills that require DCI for procedural content should
either (a) use bypass mode, or (b) avoid DCI entirely and delegate
content loading to a forked agent.

### 5.3 Forked Agents Provide Mechanical Enforcement

The role-creator agent starts with a clean context on every invocation.
There is no prior interruption to recover from. Its tool allowlist
(Read, Bash, Glob, Grep, WebSearch, WebFetch — no Write/Edit) makes
the approval gate mechanical: the agent literally cannot write files.

Permission prompts inside the agent (Bash commands, Read tool) do not
corrupt its procedural chain because each prompt is handled within the
agent's own clean context. The agent resumes from the exact point it
left off, not from an inferred recovery point.

### 5.4 RTFM Produces Dramatically Better Output

The difference between training-data knowledge and researched documentation:

- Training data: "Flame handles rendering, Riverpod handles state"
- Researched docs: "FlameGame subclass with RiverpodGameMixin, components
  use RiverpodComponentMixin, call addToGameWidgetBuild() BEFORE
  super.onMount(), use ref.listen not ref.watch, widget tree uses
  RiverpodAwareGameWidget not GameWidget (plain GameWidget crashes)"

The downstream impact is significant. When CA uses a researched role to
propose file structure, it names real classes, real patterns, and real
testing utilities. The developer can implement from this output directly.
With training-data roles, the developer must research the frameworks
separately — the role provides direction but not actionable specifics.

### 5.5 A Priori vs Adapted Generation

The source input matrix (§3.5) revealed a consistent pattern across
experiments:

**A priori generation** (no source roles provided):
- Test 1: 4-layer architecture boundary (Flame/Riverpod/Flutter/pure Dart),
  creative section composition (combined Issue+Prompt into "Feature Scoping"),
  dropped Coordination for single-developer, domain-specific constraints
- E2E v2.3.0: 3 concrete workflow procedures, specific API names in
  implementation review checks, action → output format in responsibilities

**Adapted generation** (source role files provided):
- Test 2: Near-verbatim copy with project name substitution, thin Context
  section (one-line architecture), "Do write" carried verbatim, constraints
  lacked consequences
- Tests 3-4: Improved with Critique phase but non-deterministic — some
  improvements regressed between identical runs
- E2E v2.1.0-v2.2.1: Better than Tests 2-4 (validator enforced structural
  quality) but still anchored to source material structure

**Direct comparison on the same criterion — Architecture boundaries:**

| Condition | Context Section Content |
|---|---|
| A priori (Test 1) | "Flame = rendering, Riverpod = state, Flutter = UI chrome, pure Dart = game logic. flame_riverpod bridges via RiverpodAwareGameWidget and RiverpodComponentMixin" |
| Adapted (Test 2) | "Flame components for rendering + Riverpod providers for game state" |
| Adapted + Critique (Test 3) | "Flame handles rendering + Riverpod manages game state. flame_riverpod bridges." |
| A priori + Agent (v2.3.0) | "Three-layer separation — Flame (rendering only), Riverpod (game state only), flame_riverpod (bridge via RiverpodAwareGameWidget and RiverpodComponentMixin). addToGameWidgetBuild before onMount." |

**Initial interpretation (before v2.3.0 Prompt C test):** When CR has
source roles to adapt, it anchors to the source text and makes minimal
changes. The adapted condition triggers "copy and substitute"; the a priori
condition triggers "research and compose."

**Revised interpretation (after v2.3.0 Prompt C test):** The deferential
copying was a property of the inline skill delivery, not of adaptation
itself. When the same Prompt C (adapted from source files) was tested with
the v2.3.0 agent architecture on a clean-slate project (auto-memory
explicitly cleared per §3.7), the results were:

| Condition | Context Section Content |
|---|---|
| Adapted + Inline Skill (Test 2) | "Flame components for rendering + Riverpod providers for game state" (one line) |
| Adapted + Agent (v2.3.0 Prompt C) | **Four-layer architecture:** Flame (rendering, sprites, drag-and-drop), Riverpod (deck, tableau, foundation, stock/waste, move history, win detection), Flutter (app shell, menus, HUD), Domain (cards with suit/rank, piles, moves, validity rules). 160 lines total — richest CA output across all experiments. |

The agent-adapted version produced **richer** output than both the
agent-from-scratch version (v2.3.0 Prompt D, three layers) and all
previous adapted versions (Tests 2-5, one or two layers). New content
not in any previous version:

- **Four layers** — added Domain model as an explicit separation layer
  (cards, piles, moves, validity rules live in the domain, not UI code)
- **CP "Domain-Aware Review"** — entirely new section ensuring game logic
  slices are separated from rendering, providers scoped narrowly, card
  interaction specs define both logic effect and visual feedback separately
- **CP Quality Checklist** with solitaire-specific edge cases: "empty stock,
  invalid moves, win condition, undo at stack boundary"
- **CA cross-check logic preserved** (lines 100-102) — crash-recovery
  heuristic from the hand-authored source that was lost in all previous
  generated versions
- **Verification Summary** includes `flutter analyze` status

**Conclusion:** With the agent architecture, adapted generation produces
richer output than a priori generation because the source roles provide
structural scaffolding that the agent enriches with project-specific
content rather than copying verbatim. The deferential copying observed
in Tests 2-4 was a prompt-level inline skill problem — the agent's
mechanical critique phase fixes it.

**Implication for `/role-evolve`:** This finding provides a hypothetical
premise for the planned role evolution feature. If adapted generation
(source role + agent enrichment) produces richer output than from-scratch
generation, then evolve follows the same pattern: take the existing role
(v1) as structural scaffolding, enrich it with accumulated agent memory
and MEMORY.md insights, and produce a higher-quality v2. The "scaffold +
enrich" mechanism validated here is the same mechanism that `/role-evolve`
would use — the difference is that evolve's enrichment source is machine-
learned operational wisdom rather than developer-provided source roles.

### 5.6 Architecture Decision Timeline

| Date | Decision | Basis |
|---|---|---|
| 2026-03-21 | Skill-only, no agent | Role creation is conversational; agents can't do multi-turn |
| 2026-03-21 | Output to `context/roles/` | Outside `.claude/` namespace |
| 2026-03-22 | Output to `.claude/skills/` | Anthropic's intended path for project skills; auto-discoverable |
| 2026-03-22 | DCI via script (not `cat`) | Security boundary blocks `cat` across directories |
| 2026-03-22 | Reverse: skill+agent | DCI interruption corrupts procedural chain (100% reproducible) |
| 2026-03-23 | Remove DCI entirely | Agent reads refs via Bash; no DCI = no interruption |

Each decision was made based on experimental evidence, not assumption.
Reversals were driven by findings that contradicted the prior basis.

### 5.7 Limitations

1. All experiments used a single target project (Flutter solitaire with
   Flame + Riverpod). Results may differ for other stacks.
2. The "procedural corruption" finding applies to Claude Opus 4.6. Other
   models may handle context gaps differently.
3. RTFM research quality depends on web search availability and the
   framework's documentation quality.
4. The validator catches structural issues (missing frontmatter, non-existent
   paths) but cannot validate semantic quality (are the constraints
   actually useful?). Semantic quality was assessed manually.
5. Generated roles lack operational wisdom that accumulates through usage
   (crash-recovery heuristics, verification templates). This is expected
   for v1 roles and is the motivation for the planned `/role-evolve` feature.

---

## 6. Conclusion

### 6.1 Answers to Research Questions

**RQ1: Can CR generate functionally useful roles?**
Yes. Generated CA roles consistently guided sessions to produce
architecturally sound file structure proposals that respected encoded
boundaries and referenced correct APIs. The v2.3.0 output is the most
complete, with 3 concrete workflow procedures, specific API checks in
implementation review, and action → output format in responsibilities.

**RQ2: What delivery mechanism produces reliable output?**
Skill + forked agent (v2.3.0). Prompt-only (Tests 1-5) is non-deterministic.
Inline skill with DCI (v2.1.0-v2.2.1) is reliable only with permission
bypass. Skill + agent with no DCI (v2.3.0) is reliable without bypass.

**RQ3: What workflow refinements have the highest impact?**
Ranked by measured impact:
1. **RTFM research** — transforms generic descriptions into verified
   API-specific content. Highest-impact single addition.
2. **Mechanical validation** — catches issues that prompt-level CR
   consistently misses (non-existent paths, permissions-as-constraints).
3. **Critique phase** — improved 5/10 issues when it executes, but
   execution is non-deterministic in inline skills.
4. **Approve/Modify/Reject gate** — critical for preventing write-before-approve,
   but only reliable when mechanically enforced (agent can't write).

### 6.2 Final Architecture

```
/role-cr (inline skill, no DCI)
  → Gather developer input conversationally
  → Spawn role-creator agent(s) with serialized input
  → Agent: read refs via Bash, research, RTFM, critique, generate, validate
  → Skill: present output, Approve/Modify/Reject, write on Approve
  → Output: .claude/skills/role-{code}/SKILL.md (auto-discoverable)
```

### 6.3 Shipped Versions

| Version | PR | Tests | Key Change |
|---|---|---|---|
| v2.1.0 | #12 | 691 / 1010 | `/role-cr` inline skill + `validate-role-output.sh` |
| v2.2.0 | #13 | 715 / 1042 | Output path → `.claude/skills/role-{code}/SKILL.md` |
| v2.2.1 | #14 | 726 / 1058 | DCI `cat` → `load-role-references.sh` script |
| v2.3.0 | #15 | 757 / 1109 | Skill+agent split, DCI eliminated |

### 6.4 Future Work

- **`/role-evolve`** — memory-driven role refinement. After usage
  accumulates operational wisdom in agent memory and MEMORY.md, evolve
  synthesizes it back into role files. Separate future feature.
- **Validator refinement** — skip illustrative paths in "e.g." contexts.
- **Agent memory** — add `memory: project` to role-creator agent when
  `/role-evolve` is implemented, enabling cross-session learning.

---

## References

| Ref | File |
|---|---|
| Format spec | `skills/role-init/reference/role-format.md` (v2.1) |
| CR role definition | `skills/role-init/reference/cr-role-creator.md` (v2) |
| Validator | `scripts/validate-role-output.sh` |
| Role-creator agent | `agents/role-creator.md` |
| /role-cr skill | `skills/role-cr/SKILL.md` |
| Issue 007 | `issues/007-role-creator-skill.md` |
| Issue 008 | `issues/008-role-skill-output-path.md` |
| Issue 009 | `issues/009-role-cr-dci-security-boundary.md` |
| Issue 010 | `issues/010-role-cr-skill-agent-split.md` |
| Synthesis doc | `explorations/features/roles/synthesis.md` |
| Plugin CA role | `docs/dev-roles/ca-architect.md` |

---

## Appendix A: Output Quality Comparison

See `role-cr-test-comparison.md` in this directory.

## Appendix B: Design Decisions Log

See `role-format-redesign.md` in this directory.

## Appendix C: Chronological Experiment Log

See `role-cr-experimental-log.md` in this directory.
