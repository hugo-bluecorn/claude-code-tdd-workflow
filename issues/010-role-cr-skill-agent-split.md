# Issue 010: Split /role-cr into Skill + Agent (No DCI)

## Problem

The `/role-cr` inline skill relies on the session maintaining procedural
state across interruptions. When DCI permission prompts interrupt the flow,
the recovery is non-deterministic — CR skips critique, validation, and the
approval gate. Tested across 6+ E2E runs: bypass-on produces correct output,
bypass-off consistently produces degraded output (no skill frontmatter,
verbatim source copying, skipped validation).

### Evidence

- Bypass-on: full critique, caught "Do write", proper approval gate,
  validated output, skill frontmatter present
- Bypass-off: DCI permission interrupts → CR recovers by skipping
  critique, approval, and validation. Files written with no YAML
  frontmatter, Identity says "tdd-workflow plugin" instead of target
  project, no `validate-role-output.sh` invoked
- Pattern is 100% reproducible across sessions

### Root Cause

Inline skills depend on conversational context continuity. DCI commands
execute at preprocessing time. If the permission prompt interrupts DCI,
the skill body loads with missing content. The model infers where it left
off and non-deterministically skips procedural steps.

## Solution

Split `/role-cr` into the `/tdd-plan` + `tdd-planner` pattern. **Remove
DCI entirely from the skill.** The agent reads references itself via Read
tool — no DCI, no permission prompt, no interruption.

```
/role-cr (inline skill, NO DCI)
  → Skill body = self-contained instructions (no !`cmd`)
  → Step 1: Gather developer input (conversational, main thread)
    - What roles? How many? Source roles to adapt?
    - Tech stack, architecture, constraints?
    - Workflow patterns?
  → Step 2: Spawn role-creator agent with serialized input
  → Step 3: Present agent output with Approve/Modify/Reject
  → Step 4: On Approve, write to .claude/skills/role-{code}/SKILL.md

role-creator agent (forked, read-only)
  → Reads cr-role-creator.md (CR workflow definition)
  → Reads role-format.md (format spec)
  → Reads source roles if provided
  → Researches target project
  → RTFM for unfamiliar tech (WebSearch, WebFetch)
  → Critiques mapped content against format spec
  → Generates role files with skill frontmatter
  → Runs validate-role-output.sh (hard fail)
  → Returns validated content as text (no Write tool)
```

### Why No DCI

The previous architecture used `!`cmd`` to inject CR definition and format
spec into the skill body at load time. This caused the permission prompt
that broke the procedural chain.

The agent reads these files itself via Read tool. Read tool doesn't
require special permissions for plugin paths. The references are part of
the agent's procedure, not the skill's preprocessing.

`load-role-references.sh` (Issue 009) is no longer used by the skill.
It can remain as a utility script or be removed in a cleanup pass.

## Scope

### In Scope

1. **`agents/role-creator/agent.md`** — new agent definition
   - System prompt: CR's mechanical procedure (research, critique,
     generate, validate)
   - Preloaded references via agent `skills:` field or direct Read
   - Tools: Read, Bash, Glob, Grep, WebSearch, WebFetch
   - No Write/Edit — agent returns text, skill writes
2. **`skills/role-cr/SKILL.md`** — rewrite to orchestration pattern
   - No DCI commands
   - Self-contained conversational instructions
   - Agent spawning with serialized context
   - Approval gate (Approve/Modify/Reject)
   - Write to disk on Approve only
3. **Tests** for agent definition and updated skill

### Out of Scope

- CR role file (`cr-role-creator.md` — stable, agent reads it)
- Format spec (`role-format.md` — stable, agent reads it)
- Validator (`validate-role-output.sh` — stable, agent invokes it)
- `load-role-references.sh` — can remain or be removed separately

## Key Design Decisions

- **No DCI in the skill.** The skill body is self-contained plain
  instructions. Nothing can interrupt it during preprocessing. This is
  the core fix — eliminating the root cause rather than working around it.
- **Agent has no Write/Edit tools.** It returns role file content as text.
  The skill writes to disk after approval. The approval gate is mechanical
  — the agent literally cannot write files.
- **Agent reads references via Read tool.** cr-role-creator.md and
  role-format.md are read as part of the agent's procedure, not injected
  via DCI. Read tool works on plugin paths without permission issues.
- **Agent runs validate-role-output.sh.** Validation is in the agent's
  procedural chain. The agent writes a temp file, runs the validator via
  Bash, and only returns content that passes. If validation fails, the
  agent fixes the issues and re-validates.
- **Conversational phase stays in the skill.** Multi-turn questions and
  answers happen in the main session. The skill serializes the developer's
  input into the agent's task prompt. The agent executes mechanically.
- **Agent follows the `/tdd-plan` + `tdd-planner` precedent.** Read-only
  agent returns text, skill handles approval and file writing. Proven
  pattern in this plugin.

## Acceptance Criteria

- [ ] Agent definition exists at `agents/role-creator/agent.md`
- [ ] Agent has Read, Bash, Glob, Grep, WebSearch, WebFetch tools (no Write/Edit)
- [ ] Agent reads cr-role-creator.md and role-format.md via Read tool
- [ ] Agent runs `validate-role-output.sh` and returns only validated content
- [ ] Agent output includes skill frontmatter (name, description, disable-model-invocation)
- [ ] Skill body contains NO DCI commands (no `!`cmd``)
- [ ] Skill orchestrates: gather input → spawn agent → present → approve → write
- [ ] Files only written to disk after explicit Approve
- [ ] Generated files written to `.claude/skills/role-{code}/SKILL.md`
- [ ] Works without bypass permissions — no permission prompts from the skill
- [ ] All existing tests pass
- [ ] E2E test: fresh project, no bypass, full procedure executes correctly
