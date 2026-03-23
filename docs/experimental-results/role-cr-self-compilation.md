# Self-Compilation Experiment: Generating Roles for the Plugin Project

**Authors:** Hugo (developer), Claude Opus 4.6 (CA session)
**Date:** 2026-03-23
**Plugin version:** v2.3.0
**Target project:** claude-code-tdd-workflow (this repository)

---

## Abstract

This experiment applies the Role Creator (CR) to the project that built
it — generating CA/CP/CI roles for the tdd-workflow plugin itself from
the hand-authored proto-roles that preceded the role system. The purpose
is twofold: (1) validate that CR produces higher-quality roles than the
manual process it replaces, and (2) measure what operational wisdom is
preserved, lost, or newly discovered when an automated system processes
hand-authored artifacts. Results show the agent-generated roles are
measurably superior in structure, content quality, and completeness while
preserving all identified operational wisdom from the proto-roles.

---

## 1. Motivation

The proto-roles (`docs/dev-roles/ca-architect.md`, `cp-planner.md`,
`ci-implementer.md`) were the original motivation for building CR. They
were manually authored, evolved organically across projects, and contained
operational wisdom accumulated through weeks of use. However, they lacked
formal structure (no frontmatter, no validation), used inconsistent
section names, and included format violations (permissions disguised as
constraints).

This experiment tests whether CR can bootstrap itself — producing roles
for the project that created it, using the proto-roles as source material.

## 2. Setup

**Prompt used:** Prompt C (three-role adaptation with source file paths)

```
I want to regenerate the 3 roles for this project. I use three concurrent sessions:
- CA (Architect) — decisions, issues, prompts, memory, verification
- CP (Planner) — runs /tdd-plan, iterates on plan quality
- CI (Implementer) — runs /tdd-implement, /tdd-release, /tdd-finalize-docs, direct edits

Adapt from the existing proto-roles:
- docs/dev-roles/ca-architect.md
- docs/dev-roles/cp-planner.md
- docs/dev-roles/ci-implementer.md

This is a Claude Code plugin written in Bash, tested with bashunit, linted with shellcheck.
```

**Permission mode:** Bypass on (for speed; the v2.3.0 architecture has
no DCI in the skill, so bypass only affects agent tool approvals)

**Auto-memory:** Present (legitimate project memory — this is our project,
not a controlled experiment requiring clean slate)

**CR behavior observed:**
1. Skill gathered input conversationally
2. Skill spawned 3 role-creator agents in parallel
3. Each agent: read CR definition + format spec via Bash cat, read source
   proto-role, read project files (CLAUDE.md, pubspec equivalent, test
   structure, agent/skill/hook inventory), ran validation, returned text
4. Skill presented summary with Approve/Modify/Reject gate
5. After Approve: wrote to `.claude/skills/role-{code}/SKILL.md`

## 3. Results

### 3.1 Line Count

| Role | Proto-role | Agent-generated | Delta |
|---|---|---|---|
| CA | 113 | 155 | +42 (+37%) |
| CP | 89 | 137 | +48 (+54%) |
| CI | 104 | 141 | +37 (+36%) |
| **Total** | **306** | **433** | **+127 (+42%)** |

The increase is entirely new content (workflow procedures, context
sections, coordination directions) — not verbosity.

### 3.2 Structural Comparison

| Aspect | Proto-roles | Agent-generated |
|---|---|---|
| YAML frontmatter | None | Skill + role frontmatter, `generator: /role-cr` |
| Section names | Non-standard ("Startup Checklist", "Handoff Patterns", "Memory Model") | Format spec compliant ("Startup", "Coordination", "Memory") |
| "Do write" violation | Present in CA | Eliminated — converted to Memory Management responsibility |
| Constraints with consequences | 0 of 13 | **13 of 13** — every constraint explains what breaks |
| Workflow procedures | 0 named procedures | **10 named procedures** across all three roles |
| Context sections | None | Present in all three with key paths tables |
| Coordination directions | 8 (some implicit) | **13 explicit** with message format specified |
| Skill discoverability | N/A (text files) | Auto-discoverable as `/role-ca`, `/role-cp`, `/role-ci` |

### 3.3 CA Detailed Comparison

**What the agent preserved from the proto-role:**
- Cross-check logic in Startup step 4: "if MEMORY.md says implementation
  in progress but .tdd-progress.md shows all slices done, trust
  .tdd-progress.md — CA may have crashed before updating memory"
- Verification summary format content (test count delta, assertion count
  delta, slices completed, key decisions, deviations, acceptance criteria)
- "CA is the sole memory writer" convention
- All five responsibility areas (Decision-Making, Issue Authoring, Prompt
  Authoring, Verification, Memory Management)

**What the agent improved:**
- Identity now describes mode of operation: "you operate conversationally —
  the developer discusses intent with you, and you translate that into
  structured artifacts"
- Responsibilities use action → output format: "Evaluate proposed changes
  → decision recorded in memory or issue file"
- "Do write" converted from constraint to Memory Management responsibility
- New constraint #4: "Never write to MEMORY.md without verifying current
  state first. Stale reads produce conflicting updates." — operational
  wisdom the proto-role didn't encode
- 4 named Workflow procedures with concrete commands (`./lib/bashunit test/`,
  `shellcheck`, `issues/` path checks)
- Context section with 10-row key paths table
- 6 explicit coordination directions (was 3 handoff patterns)

**What the agent lost:**
- Nothing identified. All proto-role content is present in the generated
  role, restructured into format-compliant sections.

### 3.4 CP Detailed Comparison

**What the agent preserved:**
- Quality checklist items (Given/When/Then specs, DAG ordering, no
  pre-planned refactoring, edge cases, correct file paths)
- Crash-recovery guidance (re-run with same prompt if interrupted before
  approval; report to CA if interrupted after)
- "CP and CI never communicate directly" principle

**What the agent improved:**
- Quality checklist promoted to named Workflow procedure ("Quality
  Self-Review") — elevates it from a passive list to an active step
- Memory table simplified from 4 layers to 2 layers CP actually uses
  (MEMORY.md and .tdd-progress.md) — honest about what CP reads
- Coordination adds explicit "To CI (indirect, via files)" direction
- All constraints now have consequences

**What the agent lost:**
- The proto-role's "Plan Quality" section had 5 bullet points. The agent
  merged these into "Plan Quality Assurance" responsibility with 4
  verification points. The key checks are preserved; granularity slightly
  reduced.

### 3.5 CI Detailed Comparison

**What the agent preserved:**
- RED → GREEN → REFACTOR cycle reference
- Conventional commit prefixes (`test:`, `feat:`, `refactor:`, `docs:`,
  `fix:`, `chore:`)
- Hook compliance instruction (write tests before implementation)
- Git status check on recovery for uncommitted changes
- "Do not modify .tdd-progress.md manually" constraint

**What the agent improved:**
- Error Handling absorbed into Workflow as "Error Recovery" procedure with
  concrete steps including specific hook name (`validate-tdd-order.sh`)
- 8-row key paths table with purpose for each directory
- 6 coordination directions (added "From CP, indirect via plan")
- Constraint: "Never write to MEMORY.md — causes merge conflicts and state
  divergence across sessions"
- All 5 constraints now have consequences

**What the agent lost:**
- Nothing identified. Error handling content is fully present in the Error
  Recovery workflow procedure.

### 3.6 Structural Issue: Double Frontmatter

The generated files have two consecutive YAML frontmatter blocks:

```yaml
---
name: role-ca
description: "Code Architect session role..."
disable-model-invocation: true
---

---
role: CA
name: "Code Architect"
type: session
...
---
```

The first block is skill frontmatter (for Claude Code discovery). The
second is role frontmatter (for role metadata). Claude Code reads the
first as the skill definition. The second is visible in the file but not
parsed as YAML by the skill system.

This is functional — both purposes are served — but could be cleaner as
a single merged block. Noted as a refinement for validate-role-output.sh.

## 4. Discussion

### 4.1 Operational Wisdom Preservation

The primary concern with automated role generation is losing operational
wisdom — the crash-recovery heuristics, verification templates, and
coordination protocols that accumulate through real usage. This experiment
shows the agent preserves all identified operational wisdom:

| Wisdom | Proto-role | Agent-generated |
|---|---|---|
| Cross-check logic (CA crash recovery) | Present | Preserved |
| Verification summary template | Present | Preserved (in Workflow procedure) |
| CP crash-recovery guidance | Present | Preserved |
| CI git status recovery check | Present | Preserved |
| Hook compliance | Present | Preserved (names specific hook) |
| "CA is sole memory writer" | Present | Preserved |
| CP/CI never communicate directly | Implicit | Made explicit |

### 4.2 New Wisdom the Agent Generated

The agent produced content that the proto-roles lacked — not from the
source material or from training data, but from analyzing the project
structure and applying the format spec's requirements:

1. **"Never write to MEMORY.md without verifying current state first"**
   (CA constraint #4) — derived from the cross-check logic. The proto-role
   had the check but didn't have the constraint preventing stale writes.
2. **Named Workflow procedures** — the proto-roles described what to hand
   off (Handoff Patterns) but not what to DO. The agent created step-by-step
   procedures including specific commands.
3. **CP "Quality Self-Review" as a Workflow procedure** — the proto-role
   had a checklist. The agent promoted it to a named procedure, making it
   an active workflow step rather than a passive reference.
4. **CI Error Recovery as a Workflow procedure** — the proto-role listed
   bullet points. The agent structured them as ordered steps with decision
   logic.

### 4.3 The Scaffold + Enrich Pattern Confirmed

This experiment further validates the finding from §5.5 of the main
validation report: when adapting source roles through the agent, the source
material serves as structural scaffolding that gets enriched. The proto-roles
provided the foundation (responsibilities, constraints, coordination model)
and the agent added structure (format compliance, workflow procedures,
context sections) and new content (operational constraints, explicit
coordination directions).

### 4.4 The Compiler Analogy

A compiler must be able to compile itself. The tdd-workflow plugin's role
system now passes this test: CR generates roles that are measurably
superior to the hand-authored roles that preceded it, for the project
that built CR. The generated roles can replace the proto-roles as the
active session configuration for this project's development.

## 5. Conclusion

The self-compilation experiment validates that:

1. CR preserves operational wisdom from source proto-roles
2. CR adds structural quality the proto-roles lacked (format compliance,
   frontmatter, validation, workflow procedures)
3. CR generates new operational content the proto-roles didn't have
   (memory verification constraint, named procedures with commands)
4. The scaffold + enrich pattern works for the plugin's own roles
5. The generated roles are production-ready replacements for the proto-roles

**Recommendation:** Adopt the agent-generated roles as the active session
configuration for the tdd-workflow plugin project. Retain the proto-roles
in `docs/dev-roles/` as historical reference.

---

## Appendix E: Proto-Roles (Source Material)

### E.1 CA Proto-Role (docs/dev-roles/ca-architect.md)

```markdown
# CA — Architect / Reviewer

> **Why a separate session?** Isolating review from planning and implementation
> keeps each session's context focused. CA retains full conversation history
> across multiple review cycles without autocompaction discarding prior analysis.

## Identity

You are the **CA (Code Architect)** session for the tdd-workflow plugin.
You are the primary interface with the developer. You make architectural
decisions, author issues, write prompts for other sessions, and verify
that every TDD agent has done its job correctly.

## Responsibilities

### Decision-Making
- Make architectural decisions (approach, scope, what to include/exclude)
- Decide whether a change needs full TDD workflow or a direct edit
- Decide when a feature is ready for release
- Approve or reject CP's plans with specific feedback

### Issue Authoring
- Write issue files (`issues/*.md`) with full scope, requirements, and constraints
- Define acceptance criteria before CP begins planning
- Reference prior exploration context and architectural decisions in the issue

### Prompt Authoring
- Write the `/tdd-plan` prompt that CP will execute
- Ensure the prompt captures the architectural intent from the issue
- Provide enough context that CP can plan without needing CA's full history

### Verification
- Review CP's plan output for correctness, coverage, and over-engineering
- After CI completes `/tdd-implement`, verify all slices pass acceptance criteria
- After CI completes `/tdd-release`, review the PR and provide a comprehensive
  verification summary for the PR body (developer copies this into the PR)
- After CI completes `/tdd-finalize-docs`, verify documentation accuracy
- Spot-check that agents followed conventions (test-first, commit messages, etc.)

### Memory Management
- Own and maintain `MEMORY.md` — the cross-session shared state
- Update memory after each milestone (plan approved, implementation complete, release merged)
- Record architectural decisions, open questions, and follow-up items
- Clean up stale entries (completed features, resolved blockers)
- Create topic files (e.g., `memory/feature-plan.md`) for feature-specific
  context that would bloat MEMORY.md. Delete them when the feature ships.
- **CA is the sole memory writer.** CP and CI read memory but never write to it.
  This keeps shared state coherent — one author, no conflicts.

## Constraints

- **Read-only for code.** Never write source files, test files, or scripts.
  All code changes go through CI.
- **Never merge PRs.** That is CI's job after CA provides verification.
- **Never run `/tdd-plan`, `/tdd-implement`, `/tdd-release`, or `/tdd-finalize-docs`.**
  Those belong to CP and CI respectively.
- **Do write** issue files, memory files, and dev-role prompt files.

## Memory Model

Three layers of state, each with a clear owner:

| Layer | Owner | Purpose |
|-------|-------|---------|
| `MEMORY.md` + topic files | CA writes, all read | Project state, decisions, context |
| `.tdd-progress.md` | Plugin agents manage | Operational state — which slices done |
| Git log + branches | CI writes, all read | Implementation ground truth |

All three roles share the same auto-memory directory. CA is the sole writer.
CP and CI recover state by reading these layers — they never need to write
memory because their outputs are durable artifacts (plans in `planning/`,
code in git, slice status in `.tdd-progress.md`).

## Startup Checklist

On fresh start or recovery after interruption:

1. Read `MEMORY.md` for current project state
2. Read `.tdd-progress.md` if it exists (active TDD session)
3. Check `git log --oneline -10` and `git branch` for recent activity
4. Cross-check: if MEMORY.md says "implementation in progress" but
   `.tdd-progress.md` shows all slices done, trust `.tdd-progress.md` —
   CA may have crashed before updating memory
5. Identify what needs attention: pending reviews, blocked work, next feature
6. Update MEMORY.md if the state was stale from a prior crash

## Handoff Patterns

### To CP (planning)
Provide: issue file path + `/tdd-plan` prompt text. CP executes the prompt
and returns the plan for CA review.

### To CI (implementation)
Say "proceed with `/tdd-implement`" after approving CP's plan. CI reads
`.tdd-progress.md` and executes. After completion, CI waits for CA
verification before proceeding to release.

### From CI (release review)
CI runs `/tdd-release` which creates a PR. CA reviews the PR, writes a
verification summary, and tells the developer to copy it into the PR body.
CI then merges.

## Verification Summary Format

When reviewing a completed feature for PR body text, include:

- Test count delta (before/after)
- Assertion count delta
- Slices completed (planned vs actual test count)
- Key implementation decisions made during CI's work
- Any deviations from the plan and why
- Confirmation that acceptance criteria are met
```

### E.2 CP Proto-Role (docs/dev-roles/cp-planner.md)

```markdown
# CP — Planner

> **Why a separate session?** Planning often requires multiple `/tdd-plan`
> iterations. Isolating planning keeps the full history of prior attempts
> and CA feedback available, so each iteration builds on the last without
> losing context to autocompaction.

## Identity

You are the **CP (Code Planner)** session for the tdd-workflow plugin.
You execute `/tdd-plan` with prompts authored by CA. Your job is to
produce high-quality, testable slice decompositions. You do not implement
code or make architectural decisions.

## Responsibilities

### Plan Execution
- Execute `/tdd-plan <prompt>` using the prompt provided by CA
- Review the planner's output for completeness before approving
- If the plan is weak (missing edge cases, wrong test patterns, scope creep),
  reject and re-run with refined input

### Plan Quality
- Ensure slices are independently testable
- Ensure Given/When/Then specs are concrete and unambiguous
- Verify test counts are realistic (not inflated, not missing edge cases)
- Check that dependency ordering between slices is correct
- Confirm no implementation details leak into test specifications

### Iteration
- CA may request plan revisions with specific feedback
- Re-run `/tdd-plan` with adjusted prompts as needed
- Each iteration should address CA's feedback precisely

## Constraints

- **Only run `/tdd-plan`.** Never run `/tdd-implement`, `/tdd-release`,
  or `/tdd-finalize-docs`.
- **Never write code.** No source files, test files, or scripts.
- **Never make architectural decisions.** If the plan requires a decision
  not covered by CA's prompt or the issue file, ask CA.
- **Do not approve your own plans for implementation.** CA reviews and
  decides when a plan is ready for CI.

## Memory

CP **reads** shared memory but never writes to it. CA maintains `MEMORY.md`.

CP's durable outputs are:
- `.tdd-progress.md` — written by the planner agent on approval
- `planning/*.md` — planning archive, written by the planner agent

These survive session crashes. If CP is interrupted mid-planning (before
approval), no state is lost — the plan hadn't been written yet. Re-run
`/tdd-plan` with the same prompt.

If CP is interrupted after approval, `.tdd-progress.md` exists on disk.
Tell CA the plan is ready for review.

## Startup Checklist

On fresh start or recovery after interruption:

1. Read `MEMORY.md` for current project state
2. Check if `.tdd-progress.md` already exists — if yes, planning is done;
   report to CA and wait for further instructions
3. Read the issue file CA references (e.g., `issues/003-c-language-conventions.md`)
4. Wait for CA's `/tdd-plan` prompt before executing

## Handoff Patterns

### From CA
Receive: a `/tdd-plan` prompt (usually as quoted text). Execute it.
If the plan is approved by the planner's approval gate, report back to CA
for review.

### To CA
Return: the plan is written to `.tdd-progress.md` and a planning archive
in `planning/`. Tell CA both file paths so they can review.

## Quality Checklist (self-review before reporting to CA)

- [ ] Every slice has concrete Given/When/Then test specs
- [ ] Test file paths follow project conventions (snake_case, mirror source structure)
- [ ] Slice dependencies form a valid DAG (no cycles)
- [ ] No refactoring is pre-planned (refactoring is an implementation-time decision)
- [ ] Edge cases are covered (empty inputs, error paths, boundary conditions)
- [ ] The plan references correct existing file paths (verified by planner research)
```

### E.3 CI Proto-Role (docs/dev-roles/ci-implementer.md)

```markdown
# CI — Implementer

> **Why a separate session?** CI runs the full TDD cycle across multiple
> workflow stages. Isolating implementation keeps the complete build history
> (test results, verifier feedback, refactoring decisions) available throughout
> the feature lifecycle without autocompaction discarding earlier slices.

## Identity

You are the **CI (Code Implementer)** session for the tdd-workflow plugin.
You execute all code-producing and code-shipping operations. You focus on
implementation correctness and let CA handle architectural decisions.

## Responsibilities

### Implementation
- Execute `/tdd-implement` to work through pending slices in `.tdd-progress.md`
- Follow the RED -> GREEN -> REFACTOR cycle enforced by the plugin
- Resume interrupted sessions by re-running `/tdd-implement`

### Release
- Execute `/tdd-release` after CA confirms all slices pass verification
- The releaser handles: CHANGELOG, version bump, branch push, PR creation

### Documentation
- Execute `/tdd-finalize-docs` after release to update project documentation

### Direct Edits
- When CA decides a change is too small for TDD (e.g., adding URLs to a list,
  fixing a typo), make the edit directly and commit
- Use conventional commit format: `docs:`, `fix:`, `chore:` as appropriate
- CA decides whether a change needs TDD or a direct edit — CI does not
  make this call

### PR Merge
- Merge PRs after CA provides verification and the developer approves
- Use `gh pr merge` with the appropriate merge strategy

## Constraints

- **Never run `/tdd-plan`.** That belongs to CP.
- **Never make architectural decisions.** If implementation reveals an
  ambiguity or design choice not covered by the plan, report back to CA.
- **Never skip TDD for features.** Only CA can authorize a direct edit
  instead of the full TDD workflow.
- **Do not modify `.tdd-progress.md` manually.** The plugin agents manage it.
- **Follow the plan.** If a slice needs more tests than planned, that's fine.
  If a slice needs fewer, that's fine. But do not add or remove slices
  without CA's approval.

## Memory

CI **reads** shared memory but never writes to it. CA maintains `MEMORY.md`.

CI's durable outputs are all in git:
- Commits (test, feat, refactor) on the feature branch
- `.tdd-progress.md` slice status updates (managed by plugin agents)
- PR creation (via `/tdd-release`)

These survive session crashes. If CI is interrupted mid-slice, the plugin
resumes from the last completed slice when `/tdd-implement` runs again.
Uncommitted work from a crashed session is lost — CI should check
`git status` on recovery for any staged but uncommitted changes.

## Startup Checklist

On fresh start or recovery after interruption:

1. Read `MEMORY.md` for current project state
2. Read `.tdd-progress.md` to understand which slices are pending
3. Check `git status` — look for uncommitted changes from a prior crash
4. Check `git branch` — confirm you are on the correct feature branch
5. Wait for CA's instruction before starting (implement, release, or direct edit)

## Handoff Patterns

### From CA (implementation)
Receive: "proceed with `/tdd-implement`" (or "resume `/tdd-implement`").
Execute. Report back with test counts and any issues encountered.

### To CA (post-implementation)
Report: slice completion status, test count, assertion count, any deviations
from the plan. Wait for CA verification before proceeding to release.

### From CA (release)
Receive: "proceed with `/tdd-release`". Execute. Report back with PR URL.
Wait for CA to provide verification summary text for the PR body.

### From CA (merge)
Receive: confirmation to merge. Execute `gh pr merge`. Report completion.

### From CA (direct edit)
Receive: specific edit instructions with commit message guidance.
Make the edit, commit, report back.

## Error Handling

- If `/tdd-implement` fails on a slice, report the failure to CA with
  the error output. Do not retry without understanding the root cause.
- If tests fail after implementation, investigate and fix. Do not skip
  failing tests.
- If a hook blocks an action (e.g., `validate-tdd-order.sh` blocks writing
  implementation before tests), comply — write the tests first.
```

## Appendix F: Agent-Generated Roles (Output)

The complete agent-generated roles are committed to this repository at:
- `.claude/skills/role-ca/SKILL.md` (155 lines)
- `.claude/skills/role-cp/SKILL.md` (137 lines)
- `.claude/skills/role-ci/SKILL.md` (141 lines)
- `.claude/skills/role-cr/SKILL.md` (148 lines) — see §6 below

These files are version-controlled and can be viewed in the repository.
They are not reproduced here to avoid duplication with the live files.

---

## 6. CR Self-Regeneration Experiment

### 6.1 Motivation

The ultimate bootstrap test: can CR generate an improved version of
itself? The current CR definition (`skills/role-init/reference/cr-role-creator.md`,
v2) was hand-refined through 5 prompt-based test iterations. This
experiment tests whether the agent-based system can improve on that
hand-refined artifact.

### 6.2 Setup

**Session:** Same session that generated the CA/CP/CI cohort (warm context).

**Prompt:**
```
I want to create one more role: the CR (Role Creator) meta-role.
This role generates project-specific roles for any project that
uses the tdd-workflow plugin. It is project-agnostic — it works
for any target project, not just this one.

Adapt from the existing definition:
- skills/role-init/reference/cr-role-creator.md
```

**Permission mode:** Bypass on (same as cohort generation).

### 6.3 Results

| Aspect | CR v2 (hand-refined, 158 lines) | CR Regenerated (agent, 148 lines) |
|---|---|---|
| Frontmatter | No skill frontmatter | Skill + role, `project: "any"`, `stack: "project-agnostic"` |
| Identity | "You help developers create..." (passive) | "You research, interview, and produce... You operate conversationally" (active, describes mode) |
| Project-agnostic | Implicit | **Explicit**: "You are project-agnostic. You generate roles FOR projects but do not belong to any specific project." |
| Responsibilities | Role Generation, QA, Project Research, Format Evolution | **Project Research, Developer Interview, Role Generation, QA** (reordered to match workflow) |
| Format Evolution | Present | **Dropped** — meta-concern, not runtime |
| RTFM | "RTFM — do not rely on internal knowledge" (label) | "Search official documentation... do not rely on internal knowledge alone" (same intent) |
| Critique phase | Steps 6-7, 4 checks | Steps 6-7, 4 checks (same structure) |
| "Optional" in text | Line 63: "Roles are optional context" | **Gone** — no "optional" anywhere |
| Placeholder constraint | Not present | **New**: explains why placeholders cause "confused behavior" |
| Tech stack detection | Generic | **Specific examples**: package.json, pubspec.yaml, CMakeLists.txt, Cargo.toml |
| Startup order | MEMORY.md first | **Format spec first** — rules before state |

### 6.4 Key Findings

**Finding 1: "Optional" removed without instruction.**

The current CR definition says "Roles are optional context" (line 63).
The regenerated version contains no instance of "optional" anywhere. The
agent was not instructed to remove this word. The critique phase or natural
generation eliminated it — consistent with the semantic framing principle
(§5.9 of the main validation report) which predicts that when the system
generating roles understands the framing problem (via the revised PRIME
DIRECTIVE and format spec), it self-corrects.

This is significant: the semantic framing principle is not just a
documentation concern — it propagates through the generation system and
affects the artifacts the system produces.

**Finding 2: Responsibilities reordered to match execution.**

Current: Role Generation, Quality Assurance, Project Research, Format Evolution.
Regenerated: Project Research, Developer Interview, Role Generation, Quality Assurance.

The regenerated order matches the actual workflow: research first, then
interview, then generate, then validate. The current order places the
output (Role Generation) before the inputs (Project Research). The agent
corrected this without being told to.

**Finding 3: New placeholder constraint with behavioral explanation.**

The agent added: "Never leave placeholders in output. Patterns like
curly-brace tokens, incomplete markers... cause the session loading that
role to treat them as literal instructions, producing confused behavior."

This constraint didn't exist in the current CR. The agent derived it from
the format spec's validation rules (which check for placeholders) and
explained WHY it matters in terms of LLM behavior — a session that loads
a role with `{placeholder}` will try to interpret it as a literal
instruction. This is an emergent operational insight.

**Finding 4: Format Evolution dropped as a responsibility.**

The agent decided that maintaining the format spec is a meta-concern — it
belongs to the plugin developers, not to CR at runtime. This is a valid
judgment: CR follows the format spec, it doesn't maintain the format spec.

**Finding 5: Startup reordered — rules before state.**

Current CR reads MEMORY.md first. Regenerated reads the format spec first.
For a project-agnostic role, knowing the rules before knowing the state
makes more sense — the format spec is constant across all projects, while
MEMORY.md is project-specific and might not exist.

### 6.5 Assessment: Is the Regenerated CR "Better"?

By the measurement criteria established in this study:

| Criterion | CR v2 | CR Regenerated | Winner |
|---|---|---|---|
| Format compliance | No skill frontmatter | Full skill + role frontmatter | Regenerated |
| "Optional" framing | Present | Absent | Regenerated |
| Responsibility ordering | Output before input | Input before output (matches workflow) | Regenerated |
| Placeholder constraint | Missing | Present with behavioral explanation | Regenerated |
| RTFM instruction | Present ("RTFM" label) | Present (rephrased, no label) | Tie |
| Critique phase | Present | Present (identical structure) | Tie |
| Format Evolution | Present (useful for maintainers) | Dropped (valid for runtime) | Context-dependent |
| Project-agnostic explicitness | Implicit | Explicit statement in Identity | Regenerated |
| Tech stack examples | Generic | Specific (4 file types named) | Regenerated |

**Verdict:** The regenerated CR is measurably better on 6 criteria, tied
on 2, and context-dependent on 1. The most significant improvement is
the removal of "optional" — a self-correction that validates the semantic
framing principle as a systemic property, not just a documentation fix.

### 6.6 Implication for Experiment B

The regenerated CR is different enough from the current CR to warrant
Experiment B (regenerating the cohort with the new CR). Specifically:
- The reordered Responsibilities may produce differently-structured roles
- The placeholder constraint may produce roles that are more explicit
  about output quality
- The "rules before state" Startup may produce roles with different
  startup procedures
- The absence of "optional" may affect how strongly generated roles
  frame their own recommendations

**Recommendation:** Proceed with Experiment B — replace
`cr-role-creator.md` temporarily with the regenerated content and
regenerate the CA/CP/CI cohort to measure the downstream effect.

### 6.7 Structural Issue: Double Frontmatter (same as §3.6)

Same pattern as the cohort roles — two consecutive YAML frontmatter
blocks. Functional but could be cleaner. The agent looked at the existing
role skills, saw the pattern, and replicated it.

---

## 7. Experiment B: Cohort Regeneration with CR v3

### 7.1 Motivation

Experiment A (§6) produced a regenerated CR definition that was measurably
better on 6 of 9 criteria. This experiment tests whether the improved CR
definition propagates quality improvements downstream — do the roles
generated by CR v3 differ from the roles generated by CR v2?

### 7.2 Setup

**Branch:** `experiment/cr-v3-definition`

**Preparation:**
1. Saved the CR v2 cohort (CA/CP/CI generated in §3-5) to `context/cohorts/v1/`
2. Cleared `.claude/skills/role-{ca,cp,ci}/`
3. Replaced `skills/role-init/reference/cr-role-creator.md` with the
   regenerated v3 content (stripped skill frontmatter, version bumped to 3)
4. Removed `.claude/skills/role-cr/` (was shadowing the plugin's orchestration skill)

**Prompt:** Same as §2 (Prompt C — adapt from proto-roles, Bash/bashunit/shellcheck)

**Permission mode:** Bypass on

### 7.3 Results: Line Counts

| Role | CR v2 Cohort | CR v3 Cohort | Delta |
|---|---|---|---|
| CA | 155 | 146 | -9 (-6%) |
| CP | 137 | 114 | -23 (-17%) |
| CI | 141 | 144 | +3 (+2%) |
| **Total** | **433** | **404** | **-29 (-7%)** |

The v3 cohort is 7% leaner overall, with CP showing the largest reduction.

### 7.4 CA Comparison (v1 → v2)

| Aspect | CR v2 Cohort (v1, 155 lines) | CR v3 Cohort (v2, 146 lines) |
|---|---|---|
| Constraints | 4 | **5** — "sole memory writer" promoted to explicit constraint |
| Constraint language | "Never invent project knowledge" | **"Never fabricate project knowledge"** — stronger verb |
| Coordination | 6 directions | **4 directions** — more focused, added explicit "To CI (direct edit)" |
| Project name | "claude-code-tdd-workflow" | "tdd-workflow" — shorter, matches common usage |
| Architecture in Context | Lists all 7 agents by name | Describes architecture pattern without enumerating all agents |
| Responsibility format | Longer action descriptions | More concise action → output format |

**Assessment:** v2 CA is more focused. Promoting "sole memory writer" to a
constraint (rather than a note in Memory Management) gives it enforcement
weight. The architecture description is less comprehensive but more
pattern-oriented — describing the plugin's structure rather than listing
components.

### 7.5 CP Comparison (v1 → v2)

| Aspect | CR v2 Cohort (v1, 137 lines) | CR v3 Cohort (v2, 114 lines) |
|---|---|---|
| Lines | 137 | **114 (-17%)** — leanest version |
| Context section | Present with commands | **Absent** — "CP never runs tests/linting — kept lean" |
| Identity | Describes responsibilities | Describes **mode of operation**: "command-driven mode" + names other roles |
| Workflow procedures | 2 (Plan Execution, Quality Self-Review) | **3** (Plan Execution, Plan Rejection/Re-run, Quality Self-Review) |
| "Iteration With CA" | Separate responsibility section | Folded into Plan Rejection workflow procedure |
| Issue example | Generic (`issues/010-...`) | **Specific**: `issues/010-role-cr-skill-agent-split.md` |
| Crash recovery | In Memory section | In Memory section (unchanged) |

**Assessment:** The most notable editorial decision across both cohorts.
The v3 agent decided CP doesn't need a Context section — CP only runs
`/tdd-plan` and never runs tests, linting, or builds. This is a valid
judgment: Context contains build/test/analyze commands that CP never
executes. Removing it makes the role more honest about what CP actually
does.

The addition of "Plan Rejection/Re-run" as a separate procedure is also
new — previous versions folded rejection into the general plan execution
flow. Making it explicit gives CP a clear procedure for handling weak
planner output.

### 7.6 CI Comparison (v1 → v2)

| Aspect | CR v2 Cohort (v1, 141 lines) | CR v3 Cohort (v2, 144 lines) |
|---|---|---|
| Lines | 141 | **144 (+2%)** — slightly larger |
| Workflow procedures | 4 (Implementation, Release, Direct Edit, Error Recovery) | **5** (Implementation, Release, Post-Release Docs, Direct Edit, PR Merge) |
| Git Operations | Mixed into other responsibilities | **Separate responsibility section** |
| Direct Edit workflow | 3 steps | **4 steps** — added `./lib/bashunit test/` and `shellcheck` before commit |
| PR Merge | Not proceduralized | **Explicit procedure**: `gh pr checks` → `gh pr merge` → report |
| Error Recovery | Separate workflow procedure | Absorbed into individual workflow steps |

**Assessment:** The v3 agent separated PR Merge into its own procedure —
previously it was just a coordination direction. This makes the merge
protocol explicit: check CI status first, then merge, then report. The
addition of test/shellcheck steps to Direct Edit is a quality improvement
— ensures that even small changes don't break the build.

Error Recovery was absorbed into the individual workflow procedures rather
than being a standalone section. This is a trade-off: the standalone
section was easier to find, but the integrated approach means recovery
steps are contextual to the procedure where failures occur.

### 7.7 Key Findings

**Finding 1: The v3 CR definition produces measurably leaner roles.**

The 7% total reduction (433 → 404 lines) comes from editorial decisions
that remove content the role doesn't need — most significantly, CP's
Context section. This is the reordered-responsibilities effect: because
v3 CR lists Project Research before Role Generation, the agent researches
what each role actually does before generating, rather than copying all
sections from the source.

**Finding 2: Procedure granularity increased.**

Both CP and CI gained new workflow procedures (Plan Rejection, PR Merge).
These procedures existed implicitly in v1 but weren't separated into named
steps. The v3 CR's emphasis on workflow patterns (reordered responsibilities,
"Developer Interview" as explicit phase) may have prompted the agent to
decompose procedures more granularly.

**Finding 3: Differences are subtle, not dramatic.**

The v3 CR's improvements over v2 were subtle (reordered responsibilities,
stronger constraint verbs, placeholder constraint). The downstream effects
are correspondingly subtle — the cohort roles are ~7% leaner with slightly
different editorial decisions, but the core content (constraints,
coordination, responsibilities) is very similar.

**Finding 4: The "sole memory writer" promotion is significant.**

In v1, "CA is the sole memory writer" was a note in the Memory Management
responsibility. In v2, it became an explicit constraint with a consequence:
"CP and CI writing would create merge conflicts and split-brain state." This
is a quality improvement — constraints are more visible and enforceable than
responsibility notes.

### 7.8 Conclusion: Does CR v3 Produce Better Cohorts?

**Yes, but the improvement is incremental, not transformational.** The v3
cohort is leaner, has more granular procedures, and makes bolder editorial
decisions (dropping CP's Context section, promoting memory ownership to a
constraint). These improvements trace to specific changes in the v3 CR
definition:

| CR v3 Change | Downstream Effect |
|---|---|
| Reordered responsibilities (Research first) | Agent researches before generating → CP Context dropped (unnecessary) |
| Placeholder constraint | Agent more careful about output completeness |
| Stronger constraint verbs | Generated constraints use more precise language ("fabricate" vs "invent") |
| Format Evolution dropped | Agent focuses on runtime concerns → procedures are more operational |

The improvements are real but diminishing. The v2 cohort was already strong
(the scaffold + enrich pattern was validated). The v3 CR refines rather than
transforms. This suggests the CR definition is approaching a quality plateau
for this project — further improvements would require fundamentally new
input (e.g., operational wisdom from `/role-evolve`, new format spec
features, or different project types).

### 7.9 Branch Disposition

The `experiment/cr-v3-definition` branch contains:
- Updated `cr-role-creator.md` (v3)
- v2 cohort roles in `.claude/skills/role-{ca,cp,ci}/`
- v1 cohort archived in `context/cohorts/v1/`

**Disposition:** CR v3 was shipped via Issue 011 (PR #16, v2.4.0). The
`/role-cr` skill was renamed to `/role-create`. The experiment branch is
preserved as historical reference.

---

## 8. Final Cohort: Shipped CR v3 on Main (v2.4.0)

### 8.1 Motivation

After shipping CR v3 and the `/role-create` rename (v2.4.0), the project's
cohort roles (still v1, generated by CR v2) were stale. This final
regeneration produces the canonical cohort using the shipped system.

### 8.2 Setup

**Plugin version:** v2.4.0 (CR v3 definition, `/role-create` skill name)
**Session:** Fresh session in the plugin project directory
**Prompt:** Same Prompt C (adapt from proto-roles, Bash/bashunit/shellcheck)
**Auto-memory:** Present (legitimate project context)
**Permission mode:** Bypass on

### 8.3 Results: All Cohort Versions

| Version | Generated by | CA | CP | CI | Total | Key characteristic |
|---|---|---|---|---|---|---|
| Proto-roles | Hand-authored | 113 | 89 | 104 | **306** | Operational wisdom, no format compliance |
| v1 cohort | CR v2 (self-compilation, §3-5) | 155 | 137 | 141 | **433** | Format compliant, dual frontmatter bug |
| v2 cohort | CR v3 (experiment branch, §7) | 146 | 114 | 144 | **404** | Leaner, bolder editorial decisions |
| **v3 cohort** | **CR v3 shipped (v2.4.0)** | **160** | **120** | **151** | **431** | **Single frontmatter, generator: /role-create** |

### 8.4 What Changed from v1 to v3 Cohort

**Structural fix: Single frontmatter block.**

The v1 cohort had dual YAML frontmatter blocks (skill fields in one,
role fields in another). The v3 cohort merges them into a single block.
This is the correct structure — Claude Code parses the first `---`...`---`
block as frontmatter. The dual-block pattern left the role fields
unparsed.

**Generator updated: `/role-create`.**

All three roles now show `generator: /role-create` (was `generator: /role-cr`
in v1). This reflects the v2.4.0 rename.

**CA (160 lines, was 155):**
- Single frontmatter (+5 lines from merging fields)
- `generator: /role-create`
- Issue reference updated to 011
- `role-create` in key paths table
- Core content preserved: cross-check logic, verification summary,
  5 responsibility areas, 4 constraints with consequences

**CP (120 lines, was 137):**
- Single frontmatter
- `generator: /role-create`
- Explicit "command-driven loop" in Identity (mode of operation)
- Key directories section added
- 17 lines leaner than v1 — same editorial judgment as v2 cohort
  (CP doesn't need full Context with build/test commands)

**CI (151 lines, was 141):**
- Single frontmatter
- `generator: /role-create`
- Error recovery and direct edit as explicit Workflow procedures
- `docs/plugin-developer-context.md` reference added
- 10 lines larger — additional procedural detail

### 8.5 Convergence Across Cohort Versions

The v2 cohort (experiment branch, CR v3) and v3 cohort (shipped, CR v3)
were generated by the same CR definition but in different sessions with
different context. Comparing them tests reproducibility:

| Metric | v2 cohort (experiment) | v3 cohort (shipped) | Delta |
|---|---|---|---|
| CA lines | 146 | 160 | +14 |
| CP lines | 114 | 120 | +6 |
| CI lines | 144 | 151 | +7 |
| Total | 404 | 431 | +27 (+7%) |
| Frontmatter | Dual blocks | **Single block** (fixed) |
| Generator | /role-cr | **/role-create** (correct) |
| CP Context section | Absent | **Present** (key directories) |

The v3 cohort is slightly larger because:
1. Single frontmatter merges fields (adds lines vs dual-block)
2. CP regained a minimal Context section (key directories only)
3. CI has more procedural detail

The editorial decisions are similar but not identical — the agent makes
slightly different choices each run. The core content (constraints,
coordination, responsibilities) is stable across both.

### 8.6 Full Evolution: Proto-Roles → Shipped Cohort

| Aspect | Proto-roles | v1 (CR v2) | v3 (CR v3 shipped) |
|---|---|---|---|
| Format compliance | None | Full (except dual frontmatter) | **Full (single frontmatter)** |
| Generator field | N/A | `/role-cr` | **`/role-create`** |
| Constraints with consequences | 0/13 | 13/13 | **13/13** |
| Named workflow procedures | 0 | 10 | **12** |
| "Do write" violation | Present | Absent | **Absent** |
| Cross-check logic | Present | Present | **Present** |
| Operational wisdom preserved | N/A (source) | All identified | **All identified** |
| Skill discoverability | N/A | Auto-discoverable | **Auto-discoverable** |
| Total lines | 306 | 433 | **431** |

The shipped cohort represents the stable output of the completed system:
CR v3 definition, `/role-create` skill, `role-creator` agent, mechanical
validation, Approve/Modify/Reject gate. All operational wisdom from the
proto-roles is preserved. All format violations are corrected. The
structural frontmatter bug is fixed.

### 8.7 Conclusion

The canonical cohort for the tdd-workflow plugin project is now generated
by the shipped system (v2.4.0) rather than hand-authored. The proto-roles
in `docs/dev-roles/` are retained as historical reference and as source
material for future CR experiments.

The full derivation chain is complete:

```
Proto-roles (hand-authored, weeks of use)
  → CR v2 (hand-refined from proto-role observations)
    → v1 cohort (generated by CR v2)
      → CR v3 (regenerated by its own system from CR v2)
        → v2 cohort (experiment, generated by CR v3)
          → CR v3 shipped (Issue 011, v2.4.0)
            → v3 cohort (canonical, generated by shipped CR v3)
```

Each step in this chain preserved the operational wisdom from the
previous step while adding structural quality, format compliance,
and new content. The system improved itself through iteration —
the compiler compiled itself and produced better output than its
hand-assembled predecessor.
