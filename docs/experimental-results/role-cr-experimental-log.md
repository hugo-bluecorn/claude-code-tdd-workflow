# Appendix C: Chronological Experiment Log

> Supplementary material to the Role CR Validation Report.
> Detailed record of every experiment with setup, observations, and actions.

Chronological record of experiments, findings, and actions. Each entry
documents what was tested, what was observed, what was concluded, and
what action was taken.

---

## 2026-03-21 — CR Validation Session

### Experiment 0: CR format validation (pre-test)

**Setup:** Read cr-role-creator.md (v1, manually authored) against role-format.md (v2.0).

**Findings:**
- `stage: vN` incorrect — CR just created, should be `v1`
- Referenced non-existent files: `ca-template.md`, `ci-template.md`, `cp-template.md`
- Identity missing "for the {project} project" (inconsistent with format spec)
- CR had no composition table in §4 of format spec

**Action:** Fixed all four issues directly. Added CR composition table to §4.

---

### Experiment 1: Single-role generation (no source files)

**Setup:** Fresh `/tmp/solitaire` (flutter create + /init). Pasted CR role + format spec
into session. Prompt: "I want to create a role for this solitaire project." Provided
Flame GitHub URL + "Riverpod 3.x (no codegen)." No source roles given.

**CR behavior observed:**
1. Ran startup correctly — checked MEMORY.md, .tdd-progress.md, git, existing roles
2. Asked 5 targeted questions (role type, workflow, architecture, constraints, variant)
3. Spawned Explore agent to research Flame + Riverpod (verified deps: Flame 1.36.0,
   Riverpod 3.3.1, flame_riverpod 5.5.3)
4. Adapted intelligently — dropped Coordination (single developer), combined Issue+Prompt
   into "Feature Scoping", added architecture boundaries
5. Hit Approve/Modify/Reject gate
6. Generated 108-line role file at `context/roles/ca-architect.md`

**Output quality:**
- Architecture boundaries standout: Flame=rendering, Riverpod=state, Flutter=UI chrome,
  pure Dart=game logic (4-layer separation with flame_riverpod as bridge)
- Correctly dropped agent memory layer (none exists), Coordination (single developer)
- `generator: manual` (wrong — should be CR)
- Constraints 1-2 lack consequences
- Write-before-approve: wrote to disk then asked for approval

**CA functional test:**
Loaded generated CA role in same session. Told it: "propose the file structure for this project."
CA output:
- `models/` + `logic/` as pure Dart (zero Flutter/Flame imports)
- Provider for each domain concern (game, stock, score, move_validator, undo, settings, win)
- `game/components/` + `game/behaviors/` (Flame Behavior pattern)
- `test/` mirrors `lib/` with three-tier split (models, providers, game, integration)
- No `screens/` or `widgets/` — justified by single-screen game

**Conclusion:** CR generates useful roles from minimal input. Generated CA role guided
a session to produce architecturally sound output.

---

### Experiment 2: Three-role adaptation (source files provided)

**Setup:** Fresh `/tmp/solitaire`. Same prompt + provided paths to all three dev-roles
from the plugin project (ca-architect.md, cp-planner.md, ci-implementer.md).

**CR behavior observed:**
- Went straight to mapping and generating — minimal adaptation
- Near-verbatim copy with project name and stack substituted

**Findings (compared to Experiment 1):**
- "Do write" non-constraint carried verbatim from original
- Constraints lacked consequences
- Context sections thin (one-line architecture vs Experiment 1's rich boundaries)
- CP inherited `type: session` without questioning
- Coordination sections correct (proper handoff directions)
- Custom sections preserved (CP Quality Checklist, CI Error Handling)

**Root cause:** No explicit critique step between mapping existing content and generating.

**Action:** Added Critique phase (steps 5-6) to CR's workflow.

---

### Experiment 3: Critique phase validation

**Setup:** Fresh `/tmp/solitaire`. Same prompt as Experiment 2. CR now has Critique phase.

**Findings (what improved vs Experiment 2):**
1. "Do write" — dropped (CR flagged it as permission, not constraint)
2. Context richness — expanded (Flame/Riverpod/bridge described)
3. CP Quality Checklist — domain-specific ("empty deck, invalid moves, win condition")
4. Plugin-specific hook reference — removed
5. CI Error Handling — `flutter analyze` instead of `validate-tdd-order.sh`

**Still broken:** `generator: manual`, constraints lack consequences, CP type not questioned.

**Conclusion:** Critique phase improved 5 of 10 tracked issues.

---

### Experiment 4: Repeat with critique (non-determinism test)

**Setup:** Same as Experiment 3 — identical prompt, fresh project.

**Findings:**
- `generator: manual` regressed (was `/role-init` in one test, `manual` in this one)
- "Do write" regressed (dropped in Experiment 3, came back here)
- CP Quality Checklist lost domain-specific items

**Conclusion:** Prompt-level refinements have diminishing returns. Same prompt, different
quality. Non-deterministic behavior confirmed across runs. Persistent issues need
mechanical enforcement, not more words in the role file.

---

### Experiment 5: RTFM principle

**Setup:** Fresh `/tmp/solitaire`. Added step 4 to Research: "RTFM — do not rely on
internal knowledge. If information is not present in session context, memory, or project
docs, spawn research agents."

**Finding:** CR did NOT auto-trigger research despite explicit instruction. Had to be
prompted: "did you spawn research agents for the technology stacks?"

**After prompting:** CR spawned 3 research agents (~67k tokens total):
- Flame engine patterns
- Riverpod 3.x no-codegen
- Flame+Riverpod integration

**Research impact on role files (before → after):**

| Before (training data) | After (verified docs) |
|---|---|
| "Riverpod providers that Flame components watch" | flame_riverpod 5.5 — RiverpodAwareGameWidget + RiverpodGameMixin + RiverpodComponentMixin |
| "Riverpod 3.x" | NotifierProvider/AsyncNotifierProvider, no legacy StateProvider, ProviderContainer.test() |
| generic component pattern | addToGameWidgetBuild() BEFORE super.onMount(), ref.listen preferred over ref.watch |
| "GameWidget" | RiverpodAwareGameWidget with GlobalKey (plain GameWidget crashes) |
| "flutter test" | Three-tier: ProviderContainer.test(), testWithFlameGame, testWidgets |

**Research impact on downstream CA output:**
Loaded researched CA role, ran "propose the file structure." Output referenced real APIs:
- `app.dart` → "RiverpodAwareGameWidget setup with GlobalKey"
- `solitaire_game.dart` → "FlameGame + RiverpodGameMixin"
- `card_component.dart` → "PositionComponent + RiverpodComponentMixin + DragCallbacks"
- `state/rules/` as pure Dart functions (purer than any previous — not even Riverpod)
- Provider-per-domain split (tableau, foundation, stock, move, score, win)
- `win_provider` as derived provider watching foundations
- Explicit "what this doesn't include" section (scope discipline)

**Conclusion:** RTFM is the single highest-impact addition. The difference between
internal knowledge and researched docs is the difference between plausible architecture
and architecture that prevents real bugs.

---

## 2026-03-21 — Design Decisions

### Decision: Skill-only, no agent

**Arguments for:**
- Role creation is conversational — agents can't do multi-turn
- Developer's input is primary source material, session has perfect context
- Forked agent loses conversation history
- Mechanical enforcement small enough for validation script

**Decision:** Build `/role-cr` as inline skill only. Eliminate `/role-init` agent.

### Decision: Output convention `context/roles/`

**Arguments for:** Project-owned, version-controlled, outside `.claude/` namespace.
**Arguments against `.claude/roles/`:** Risk of user-level `.claude/` pollution.
Anthropic might adopt unrelated "roles" concept in `.claude/`.

---

## 2026-03-21 — v2.1.0 Shipped (Issue 007)

42 new tests, 691 total, 1010 assertions. `/role-cr` inline skill + `validate-role-output.sh`.

### E2E Test: v2.1.0 Plugin Install

**Setup:** Installed from local marketplace, fresh `/tmp/solitaire`, same prompt as
Experiment 5 (three-role adaptation with Flame/Riverpod).

**Observations:**
- DCI loaded references (CR had to search — DCI may have failed silently)
- CR researched Flame/Riverpod (spawned 3 agents)
- Critique caught "Do write" + missing consequences
- Validator caught 4 non-existent path references:
  - `memory/feature-plan.md` (example path in CA)
  - `issues/001-card-model.md` (example in CP)
  - `planning/` (directory reference)
  - `test/` (directory reference)
- CR fixed each one and re-validated
- Approval gate hit
- Files written to `context/roles/`

**CA functional test:**
Loaded generated CA, proposed file structure. Best output yet:
- `state/rules/` as pure Dart functions
- Provider-per-domain split
- `win_provider` as derived provider
- Explicit "what this doesn't include"

---

## 2026-03-22 — Bug Triage

### Bug 1: CLAUDE_PLUGIN_DATA not set

**Investigation:** `--plugin-dir` does not set `${CLAUDE_PLUGIN_DATA}`. Both
`fetch-conventions.sh` and `load-conventions.sh` fail to resolve URL-based cache paths.

**Conclusion:** Not a bug. Expected behavior for `--plugin-dir` local dev. URL cache
requires installed plugin. Use local paths in `tdd-conventions.json` during development.

### Bug 2: DCI permission mismatch

**Investigation:** `!`cmd`` in skills prompts for approval even with Bash permission
allowlist entries. Tested by running `/tdd-plan` on solitaire project with installed
plugin (not `--plugin-dir`).

**Finding:** No permission prompt occurred for `load-conventions.sh` when plugin was
installed from marketplace. Previous observations were during `--plugin-dir` development.

**Conclusion:** Not a bug. `--plugin-dir` dev-mode limitation. Installed plugins
execute DCI without prompting. Verified 2026-03-22.

**Action:** Both closed as "not bugs." Added documentation to user guide's
`--plugin-dir` section.

---

## 2026-03-22 — Output Path Research

### Research: `.claude/skills/` as output path

**Finding:** Anthropic's official guidance says `.claude/skills/` should be version
controlled. Project-scoped skills are auto-discovered by Claude Code.

**Anthropic's gitignore guidance:**
- `.claude/settings.json` → Track (team-wide config)
- `.claude/settings.local.json` → Ignore (personal)
- `.claude/skills/` → Track (project-scoped)
- `.claude/agents/` → Track (project-scoped)
- `.claude/agent-memory/` → Ignore (per-developer learning)
- `.claude/worktrees/` → Ignore (temp working copies)

### Research: Skill hot-reload

**Finding:** Skills in `.claude/skills/` are discovered at session startup. NOT
re-discovered on `/clear`. Community has filed feature requests for `/reload-skills`
(#20507) and `/restart-session` (#28685). The existence of these requests confirms
`/clear` does not re-discover skills.

**Implication:** After CR generates role skills, developer must start a new session
to invoke them via `/role-ca` etc.

### Decision: Change output path

Changed from `context/roles/{role-code}-{name}.md` to `.claude/skills/role-{code}/SKILL.md`.
Generated roles become auto-discoverable skills. Eliminates need for separate `/role-ca`,
`/role-cp`, `/role-ci` delivery skills.

---

## 2026-03-22 — v2.2.0 Shipped (Issue 008)

28 new tests (715 total, 1042 assertions). Output path change.

### E2E Test: v2.2.0 (bypass ON)

**Setup:** Installed v2.2.0, fresh solitaire, bypass permissions on.

**Observations:**
- `/role-cr` loaded cleanly (DCI worked with bypass)
- CR followed full procedure (critique, approval gate)
- Generated roles with correct skill frontmatter
- Wrote to `.claude/skills/role-{code}/SKILL.md`
- Validator caught and fixed path issues
- `/role-ca` appeared in autocomplete after session restart

**CA functional test:**
Loaded `/role-ca` in new session. CA ran startup, proposed file structure with
researched APIs (RiverpodAwareGameWidget, RiverpodGameMixin, etc.).

---

## 2026-03-22 — DCI Security Boundary Discovery

### Experiment: v2.2.0 (bypass OFF)

**Setup:** Same as above but with default permissions (no bypass).

**Error observed:**
```
Shell command permission check failed for pattern
"!.../.claude/plugins/cache/local-plugins/tdd-workflow/2.2.0/
scripts/load-role-references.sh": This command requires approval
```

**Finding:** DCI scripts from installed plugins DO prompt for approval when bypass
is off. Previous conclusion that "installed plugins execute DCI without prompting"
was wrong — we had always been using bypass.

**After approving:** CR recovered but skipped critique, approval gate, and validation.
Output had no skill frontmatter, Identity said "tdd-workflow plugin" instead of
"solitaire project." Same procedural corruption pattern.

**Root cause confirmed:** The DCI permission prompt interrupts the skill's preprocessing.
The skill body loads with missing content. The model's recovery is non-deterministic.

---

## 2026-03-22 — v2.2.1 Shipped (Issue 009)

Replaced `cat` DCI with `load-role-references.sh` script. 726 tests, 1058 assertions.

### Experiment: v2.2.1 (bypass OFF)

**Setup:** Installed v2.2.1, fresh solitaire, default permissions.

**Error observed:**
```
Shell command permission check failed for pattern
"!.../.claude/plugins/cache/local-plugins/tdd-workflow/2.2.1/
scripts/load-role-references.sh": This command requires approval
```

**Finding:** Same error. Replacing `cat` with a script didn't help — the DCI
execution path itself prompts for approval regardless of the command.

**After approving:** Same procedural corruption. CR skipped critique, approval,
validation. Wrote files without skill frontmatter.

**Conclusion:** The DCI mechanism itself is the problem, not the specific command.
Any `!`cmd`` in a skill will prompt for approval without bypass, and the interruption
corrupts the procedural chain.

---

## 2026-03-22 — Architecture Reversal

### Repeated bypass-off tests (3 runs)

All three bypass-off runs showed the same pattern:
1. DCI permission prompt interrupts skill loading
2. Developer approves
3. CR "recovers" but skips 2-4 procedural steps
4. Output quality degraded: no frontmatter, verbatim copying, no validation

All three bypass-on runs showed correct behavior:
1. DCI loads cleanly
2. Full procedure executes
3. Quality output with all checks

**Pattern is 100% reproducible.**

### Decision reversal: Skill-only → Skill+Agent

**Original decision (2026-03-21):** Skill-only, no agent.

**Reversed (2026-03-22):** Evidence forced the reversal. The skill+agent split
solves the problem because:
- The skill has NO DCI — nothing to interrupt
- The agent reads references via Bash `cat ${CLAUDE_PLUGIN_ROOT}/...`
- The agent runs in a forked context — fresh procedural chain, no recovery needed
- The skill handles conversation + approval gate + file writing

### Research: ${CLAUDE_PLUGIN_ROOT} in agents

**Finding:** `${CLAUDE_PLUGIN_ROOT}` does NOT resolve in agent body text. Agent
bodies are plain text system prompts — no preprocessing, no variable expansion.

**However:** When the agent instructs Claude to run a Bash command containing
`${CLAUDE_PLUGIN_ROOT}`, the variable resolves at Bash execution time.

**Correct pattern:** Agent body says "Run: `cat ${CLAUDE_PLUGIN_ROOT}/path/to/file`"
→ Claude uses Bash tool → Bash resolves the variable → file content returned.

**Wrong pattern:** Agent body says "Read ${CLAUDE_PLUGIN_ROOT}/path/to/file"
→ Claude uses Read tool with literal string → File not found.

**Evidence:** `tdd-planner.md` line 36 uses this same pattern for
`detect-project-context.sh` — confirmed working in production.

---

## 2026-03-23 — v2.3.0 Shipped (Issue 010)

New `role-creator` agent + rewritten `/role-cr` skill. 757 tests, 1109 assertions.

### E2E Test: v2.3.0 (bypass OFF — final validation)

**Setup:** Installed v2.3.0 from marketplace, fresh `/tmp/solitaire` (flutter create +
/init + git init), default permissions (no bypass).

**Observations:**
1. `/role-cr` loaded — NO DCI, NO permission prompt from the skill
2. Skill gathered input conversationally in main thread
3. Skill spawned 3 role-creator agents in parallel (CA, CP, CI)
4. Each agent independently:
   - Read cr-role-creator.md + role-format.md via Bash cat (not DCI)
   - Read target project (CLAUDE.md, pubspec.yaml, lib/, memory files)
   - Ran web searches for RTFM (Flame patterns, Riverpod 3.x, flame_riverpod)
   - Generated role file with skill frontmatter
   - Wrote draft to /tmp/ for validation
   - Ran validate-role-output.sh — caught path issues (lib/, test/ as directories)
   - Fixed issues (removed trailing slashes or created directories)
   - Re-validated — passed
   - Returned validated content as text
5. Skill presented summary of all three roles
6. Skill asked: Approve, Modify, or Reject
7. After Approve: skill wrote to `.claude/skills/role-{code}/SKILL.md`
8. After session restart: `/role-ca`, `/role-cp`, `/role-ci` appeared in autocomplete

**Permission prompts during test:**
- Bash heredoc for writing draft: prompted (normal tool approval, inside agent)
- validate-role-output.sh execution: prompted (normal tool approval, inside agent)
- Read of plugin scripts/ directory: prompted (normal tool approval, inside agent)
- None of these corrupted the procedural chain — each agent has its own clean context

**Output quality (CA role):**
- 130 lines, all constraints with consequences
- `generator: /role-cr`, `name: role-ca`, `description`, `disable-model-invocation: true`
- 3 concrete Workflow procedures (Issue Creation, Plan Review, Implementation Review)
- Architecture boundary with specific APIs (RiverpodComponentMixin, addToGameWidgetBuild)
- Responsibilities use action → output format
- Identity describes mode of operation ("you operate conversationally")
- No "Do write" non-constraint
- No verbatim copying from source

**CA functional test:**
Loaded `/role-ca` in new session. CA ran startup checklist, proposed file structure with:
- `state/rules/` as pure Dart functions
- Provider-per-domain split
- Specific Flame/Riverpod API references throughout
- Offered to draft first issue

**Verdict:** Full chain works without bypass. Skill+agent architecture eliminates the
DCI interruption problem. The approval gate is mechanical — agent cannot write files.
v2.3.0 is production-ready.
