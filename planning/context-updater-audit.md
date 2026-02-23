# Context-Updater Agent & tdd-update-context Skill — Claude Code Extensibility Audit

**Audit date:** 2026-02-23
**Plugin version:** 1.6.6 (target: 1.7.0)
**Feature inventory:** extensibility-audit-prompt.md v2.1 (2026-02-14)
**Audit scope:** New components only — `context-updater` agent + `tdd-update-context` skill
**Source documents:**
- Approved plan: `planning/drafts/update-context-prompt-v2.md`
- Implementation plan: `~/.claude/plans/mossy-wishing-aurora.md`
- Existing audit (not re-audited): `docs/tdd-workflow-extensibility-audit.md`

---

## 1. Feature Inventory & Gap Analysis

### Category A — Subagents (`context-updater` agent)

#### Frontmatter Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| A1 | `name` | ✅ | `context-updater` |
| A2 | `description` | ✅ | Detailed description with scope boundaries and trigger phrases |
| A3 | `tools` | ⚠️ Partial | Lists `Read, Edit, Glob, Grep, Bash, WebSearch, WebFetch, AskUserQuestion`. **Missing `Write`** — plan scope includes creating NEW reference files (Step 4b: "propose creating one") but Write is not in the tools list. See **M1** |
| A4 | `disallowedTools` | ❌ Gap | Not specified. Should at minimum disallow `Task, NotebookEdit, MultiEdit`. Follows safety pattern from planner (`disallowedTools: Write, Edit, MultiEdit, NotebookEdit, Task`) and releaser (`disallowedTools: Write, Edit, MultiEdit, NotebookEdit`). See **M2** |
| A5 | `model` | ✅ | `opus` — justified: reads 17+ files, runs web searches, synthesizes structured proposal, then makes targeted edits. Comparable to tdd-planner complexity |
| A6 | `permissionMode` | ⊘ | Not specified (defaults to `default`). Correct — agent needs write approval for edits. Consistent with tdd-implementer pattern (also omits permissionMode) |
| A7 | `maxTurns` | ✅ | Set to 50. Estimated usage: ~5 (load) + ~10 (read) + ~15 (web) + ~5 (analysis) + ~2 (approval) + ~13 (edits) = ~50. Tight but achievable if critical edits are prioritized. See **N1** |
| A8 | `skills` | ✅ | Preloads all 3 convention skills (`dart-flutter-conventions`, `cpp-testing-conventions`, `bash-testing-conventions`). Same pattern as tdd-planner and tdd-implementer |
| A9 | `memory` | ✅ | `memory: project` — records version numbers, last-checked dates, known gaps for next run. Follows planner pattern |
| A10 | `mcpServers` | ⊘ | No MCP servers relevant |
| A11 | `hooks` (frontmatter) | ⚠️ Partial | Has Stop hook (prompt-based). Missing PreToolUse guard for Edit to constrain editable file paths. Plan explicitly defers this: "Adding a lock-file mechanism for Edit would add complexity without clear benefit for v1." Conscious deferral but worth flagging. See **S1** |

#### Behavioral Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| A12 | Subagent resumption | ⊘ | Single-pass maintenance task; no resume needed |
| A13 | `Task(agent_type)` restriction | ⊘ | Only for `--agent` main thread mode |
| A14 | Agent teams | ⊘ | Single-agent task; no parallel subagents needed |
| A15 | Built-in agents | ✅ N/A | context-updater is a specialized research+edit agent |
| A16 | No-nesting constraint | ⊘ | Task should be in disallowedTools (see M2) |
| A17 | Background execution | ⊘ | Sequential workflow; no parallel subagents |
| A18 | Auto-compaction | ⊘ | maxTurns: 50 should complete before compaction issues. If web searches are slow, could approach limit |
| A19 | CLI-defined subagents | ⊘ | Plugin provides filesystem-based agents |
| A20 | Scope precedence | ✅ N/A | Agent discovered via plugin `agents/` directory |
| A21 | Disable subagents | ⊘ | No need to disable |

#### Memory Details (A9)

| Scope | Status | Notes |
|-------|--------|-------|
| context-updater `project` | ✅ | `.claude/agent-memory/context-updater/MEMORY.md` — records version numbers, last-checked dates, known gaps |

**Gap:** The plan mentions memory instructions in the agent body ("record version numbers, last-checked dates, known gaps for next run") but the implementation plan's agent body specification says only "Memory: record version numbers, last-checked dates, known gaps for next run." This should follow the planner's explicit memory instruction pattern (see tdd-planner.md lines 83-91). See **S2**.

---

### Category B — Skills (`tdd-update-context` skill)

#### Frontmatter Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| B1 | `name` | ✅ | `tdd-update-context` |
| B2 | `description` | ✅ | Detailed description with trigger phrases: "update context", "update conventions", "refresh references" |
| B3 | `argument-hint` | ⊘ | Correctly omitted — skill scans all reference files, no arguments needed. Could accept optional stack filter in future (e.g., `/tdd-update-context dart`). See **N2** |
| B4 | `disable-model-invocation` | ✅ | Set to `true` — correct for maintenance task that only users should invoke |
| B5 | `user-invocable` | ✅ N/A | Defaults to `true` (correct for user-invoked maintenance skill) |
| B6 | `allowed-tools` | ⊘ | Agent tool restrictions take precedence |
| B7 | `model` | ⊘ | Agent frontmatter sets model |
| B8 | `context: fork` | ✅ | Correct — reading 17+ files bloats main context |
| B9 | `agent` | ✅ | Specifies `agent: context-updater` |
| B10 | `hooks` (skill) | ⊘ | Agent frontmatter hooks sufficient |

#### String Substitutions

| # | Variable | Status | Notes |
|---|----------|--------|-------|
| B11 | `$ARGUMENTS` | ⊘ | No arguments to pass (maintenance task scans all files) |
| B12 | `$ARGUMENTS[N]` | ⊘ | No indexed arguments |
| B13 | `${CLAUDE_SESSION_ID}` | ⊘ | No session-specific artifacts |

#### Advanced Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| B14 | Dynamic context injection (`!`) | ⊘ | Not needed — agent reads reference files directly. Unlike tdd-plan (which benefits from pre-loaded project context), the context-updater's research phase IS the file reading |
| B15 | `ultrathink` | ✅ | Plan includes `<!-- ultrathink -->` in SKILL.md body |
| B16 | Supporting files | ⚠️ Partial | Canonical source URLs are embedded inline in SKILL.md. Could be extracted to `reference/canonical-sources.md` for easier maintenance. The plan's rationale ("shipped with plugin, maintainer-controlled") justifies inline for v1, but a supporting file would reduce SKILL.md size. See **N3** |
| B17 | Skills-in-subagents duality | ✅ | `context: fork` + `agent: context-updater` (skill→agent fork pattern). Convention skills preloaded via agent `skills:` field (agent→skill pattern). Both patterns used correctly |
| B18 | `Skill()` permission | ⊘ | No access restriction needed |
| B19 | Live change detection | ⊘ | Development convenience |
| B20 | Invocation matrix | ✅ N/A | `disable-model-invocation: true` = user-only invocation (correct) |
| B21 | Subdirectory discovery | ⊘ | Not a monorepo |
| B22 | Char budget | ⊘ | Adding 1 skill (7 total) still within 2% budget |

---

### Category C — Hooks

#### Hook Events

| # | Event | Status | Notes |
|---|-------|--------|-------|
| C1 | `SessionStart` | ⊘ | Single-pass maintenance task; no session-resume detection needed |
| C2 | `UserPromptSubmit` | ⊘ | Not relevant |
| C3 | `PreToolUse` | ❌ Gap | No guard on Edit/Write to constrain editable file paths. The agent's instructions say "only reference content files and SKILL.md quick references" but nothing enforces this. A PreToolUse hook on `Edit|Write` could validate target paths against an allowlist (e.g., `skills/*/reference/*.md`, `skills/*/SKILL.md`, `CLAUDE.md`). Plan defers to v2. See **S1** |
| C4 | `PermissionRequest` | ⊘ | Default permission mode; agent needs interactive approval for edits |
| C5 | `PostToolUse` | ⊘ | Could validate file size after edits (stay under 200 lines). Low priority — instruction-based constraint is sufficient for v1. See **N4** |
| C6 | `PostToolUseFailure` | ⊘ | Plan handles WebFetch failures via instruction-based fallback (ask user). Sufficient for v1 |
| C7 | `Notification` | ⊘ | Could notify when proposal is ready for review. Low value for infrequent maintenance task. See **N5** |
| C8 | `SubagentStart` | ❌ Gap | Planner gets git context injected via SubagentStart hook (branch, last commit, dirty files). The context-updater would also benefit — dirty files warning before edits, branch info for commit workflow. See **S3** |
| C9 | `SubagentStop` | ⚠️ Partial | No hooks.json entry for context-updater. Plan notes: "For v1, the agent-level Stop hook is sufficient." However, existing pattern shows dual-layer validation: planner and releaser both have Stop in frontmatter AND SubagentStop in hooks.json. Plan consciously defers but breaks pattern consistency. See **S4** |
| C10 | `Stop` | ✅ | Agent frontmatter has prompt-based Stop hook validating workflow completion |
| C11 | `TeammateIdle` | ⊘ | No agent teams |
| C12 | `TaskCompleted` | ⊘ | Not relevant |
| C13 | `PreCompact` | ⊘ | maxTurns: 50 should complete before compaction |
| C14 | `SessionEnd` | ⊘ | No cleanup needed |

#### Hook Types

| # | Type | Status | Notes |
|---|------|--------|-------|
| C15 | `command` | ⊘ (partial) | Stop hook uses prompt type. Anthropic best practice: "prefer command for deterministic logic." The context-updater's Stop check ("did it research?", "did it ask approval?") is non-deterministic (needs LLM judgment about partial completions vs intentional abort). Prompt is appropriate here. However, a hybrid approach (command checks for markers, prompt for nuance) could work. See **N6** |
| C16 | `prompt` | ✅ | Stop hook appropriately uses prompt for nuanced completion check |
| C17 | `agent` | ⊘ | Too expensive for validation |

#### Hook Handler Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| C18 | `type` | ✅ | Stop hook specifies `type: prompt` |
| C19 | `command` | ⊘ N/A | Stop hook is prompt-based |
| C20 | `prompt` | ✅ | Stop hook has detailed validation prompt |
| C21 | `model` (hook) | ⊘ | Default model sufficient for prompt hook |
| C22 | `timeout` | ✅ | Set to 15 seconds on Stop hook |
| C23 | `statusMessage` | ⊘ | Default spinner adequate for infrequent task |
| C24 | `once` | ⊘ | No one-time initialization needed |
| C25 | `async` | ⊘ | Sequential execution |

#### Hook Variables & Protocol

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| C26 | `$ARGUMENTS` | ⊘ | Prompt Stop hook doesn't need hook input (it evaluates the agent's output) |
| C27 | `$CLAUDE_PROJECT_DIR` | ⊘ | No project-dir-relative scripts |
| C28 | `${CLAUDE_PLUGIN_ROOT}` | ⊘ | Stop hook is inline prompt, not a script reference |
| C29 | `$CLAUDE_ENV_FILE` | ⊘ | No env persistence |
| C30 | `$CLAUDE_CODE_REMOTE` | ⊘ | No remote-specific behavior |
| C31 | `$TOOL_INPUT` | ⊘ | Not needed |
| C32 | Exit code 0 | ⊘ N/A | Prompt hook uses `{ok: true/false}` protocol |
| C33 | Exit code 2 | ⊘ N/A | Prompt hook, not command |
| C34 | Other exit codes | ⊘ N/A | Prompt hook |
| C35 | `stop_hook_active` | ⊘ N/A | Prompt hooks handle this implicitly |

---

### Category D — Plugins

#### Manifest Updates

| # | Field | Status | Notes |
|---|-------|--------|-------|
| D1 | `name` | ✅ N/A | No change (`tdd-workflow`) |
| D2 | `version` | ✅ | Bump to `1.7.0` (new feature = minor version) |
| D3 | `description` | ⊘ | Could update to mention context updating capability. Low priority |

#### Directory Structure (additions)

```
tdd-workflow/
├── agents/
│   └── context-updater.md                 NEW
├── skills/
│   └── tdd-update-context/
│       └── SKILL.md                       NEW
```

No hooks.json changes in v1 (SubagentStop deferred). CLAUDE.md and CHANGELOG.md updated per plan.

---

### Category E — Memory / CLAUDE.md

| # | Type | Status | Notes |
|---|------|--------|-------|
| E2 | Project memory (CLAUDE.md) | ✅ | Plan updates CLAUDE.md with new command in Available Commands table |
| E8 | `@import` | ⊘ | Not needed |

**Note on Tier 2 sources:** The plan introduces a `## Context Update Sources` section in CLAUDE.md for user-managed URLs. This is a clean use of project memory (E2) — the user's CLAUDE.md survives plugin updates and the agent reads it as additional input. Well-designed pattern.

---

### Category F — Settings and Permissions

No new settings or permission requirements for the context-updater. All relevant settings are at the agent level (tools, model, hooks).

---

## 2. Prioritized Recommendations

### M — Must-Have (Correctness / Safety)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| M1 | **Add `Write` to agent tools list** | 1 word | Plan scope includes creating NEW reference files (Step 4b) but `Write` is not in the tools list. Without it, the agent cannot create files for new convention stacks | A3 |
| M2 | **Add `disallowedTools` to agent** | 1 line | Every other plugin agent specifies `disallowedTools`. The context-updater should disallow `MultiEdit, NotebookEdit, Task` at minimum. `MultiEdit` is unnecessary (single-edit-per-file precision is preferred for reference file updates), `NotebookEdit` is irrelevant, and `Task` prevents subagent nesting (A16 constraint) | A4, A16 |

### S — Should-Have (Quality / Robustness)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| S1 | **Add PreToolUse guard hook on `Edit\|Write` to constrain editable paths** | ~30 lines (script) + 5 lines (frontmatter) | The agent's description says "only reference content files and SKILL.md quick references" but nothing enforces this. A script could validate target file paths against an allowlist: `skills/*/reference/*.md`, `skills/*/SKILL.md`, `CLAUDE.md`. Prevents accidental edits to agent definitions, hook scripts, or workflow skills. Follows planner Bash guard pattern (M1 from original audit) | C3, A11 |
| S2 | **Add explicit memory instructions in agent body** | ~10 lines | The plan mentions memory use but the agent body specification is abbreviated. Should follow the tdd-planner pattern (tdd-planner.md lines 83-91) with specific instructions for what to record and when. This ensures the agent actually writes useful memory entries | A9 |
| S3 | **Add SubagentStart hook for git context injection** | ~5 lines (hooks.json) | Follows the existing planner pattern. Injects branch name, last commit, and dirty file count. Useful for: (1) warning about dirty files before making edits, (2) providing branch info for the commit workflow step | C8 |
| S4 | **Add SubagentStop entry in hooks.json** | ~10 lines | Both the planner and releaser have dual-layer validation (Stop in frontmatter + SubagentStop in hooks.json). The parent-context SubagentStop can validate artifacts the agent claims to have produced (e.g., were files actually modified?). Alternatively, the plan's deferral is acceptable for v1 if the agent-level Stop hook proves sufficient | C9 |

### N — Nice-to-Have (Distribution / UX)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| N1 | **Consider increasing maxTurns to 60** | 1 line | Estimated usage is ~50 turns. If web searches are slow or fail (requiring fallback to AskUserQuestion), the agent could hit the limit before completing edits. A buffer of 10 turns provides safety margin. Alternatively, keep 50 and add instruction to prioritize critical edits first | A7 |
| N2 | **Add `argument-hint` for optional stack filter** | 1 line | Future enhancement: `/tdd-update-context dart` to only update Dart/Flutter conventions. Would require `argument-hint: "[stack: dart|cpp|bash|all]"` and conditional logic in SKILL.md. Not needed for v1 | B3 |
| N3 | **Extract canonical URLs to supporting file** | 1 new file + SKILL.md reference | Move inline canonical source URLs to `skills/tdd-update-context/reference/canonical-sources.md`. Reduces SKILL.md size and makes URL maintenance easier. The SKILL.md would reference: "Read `reference/canonical-sources.md` for framework URLs" | B16 |
| N4 | **Add PostToolUse hook on Edit to verify file size** | ~20 lines | After each Edit, check the target file stays under 200 lines. Return `additionalContext` warning if exceeded. Low priority — instruction-based constraint sufficient for v1 | C5 |
| N5 | **Add Notification hook on proposal completion** | ~3 lines | Desktop notification when the proposal is ready for review. Low value for an infrequent maintenance task | C7 |
| N6 | **Consider hybrid Stop hook (command + prompt)** | ~30 lines | A command-based hook could check for deterministic markers (e.g., "were files modified?", "was AskUserQuestion called?") and a prompt hook handles nuance. Reduces LLM evaluation cost. Low priority — prompt-only is acceptable for infrequent task | C15 |

---

## 3. Revised Component Specifications

### 3.1 Agent Frontmatter — `agents/context-updater.md` (M1, M2, S2)

```yaml
---
name: context-updater
description: >
  Researches latest framework versions and best practices via web search,
  compares against current plugin reference files, produces a prioritized
  change proposal with breaking-change detection, and applies approved
  changes. Does NOT modify agent definitions, hook scripts, or workflow
  skills — only reference content files and SKILL.md quick references.
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, AskUserQuestion
disallowedTools: MultiEdit, NotebookEdit, Task
model: opus
maxTurns: 50
memory: project
skills:
  - dart-flutter-conventions
  - cpp-testing-conventions
  - bash-testing-conventions
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: >
            The context-updater agent is stopping. Check:
            1. Did it research latest framework versions via web search?
            2. Did it produce a structured change proposal?
            3. Did it ask for user approval before making edits?
            4. If approved, did it apply the changes?
            Respond {"ok": true} if the workflow completed or was
            intentionally aborted by the user (Discard).
            Respond {"ok": false, "reason": "..."} if the agent
            stopped prematurely without completing or getting user input.
          timeout: 15
---
```

**Changes from plan:**
- **M1:** Added `Write` to `tools` (enables new file creation per Step 4b)
- **M2:** Added `disallowedTools: MultiEdit, NotebookEdit, Task`

### 3.2 Agent Body Memory Instructions — `agents/context-updater.md` (S2)

Add to agent body (follows tdd-planner.md pattern):

```markdown
## Memory

Your project memory accumulates knowledge across sessions. At the start of
each invocation, read your MEMORY.md (if it exists) for prior context. After
completing the update, record:
- Framework version numbers found (e.g., "Flutter 3.41.2, GoogleTest 1.17.0")
- Date of last check (ISO 8601)
- Breaking changes identified and whether they were applied
- New canonical sources discovered or URLs that failed
- Files that were over 200 lines and whether splits were recommended
```

### 3.3 SubagentStart Hook — `hooks/hooks.json` (S3)

Add to the existing `SubagentStart` array:

```json
{
  "matcher": "context-updater",
  "hooks": [
    {
      "type": "command",
      "command": "echo \"{\\\"additionalContext\\\": \\\"Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown'). Last commit: $(git log --oneline -1 2>/dev/null || echo 'none'). Dirty files: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' '). WARNING: If dirty files > 0, warn user before making edits.\\\"}\"",
      "timeout": 5
    }
  ]
}
```

### 3.4 PreToolUse Edit Guard — `hooks/context-updater-edit-guard.sh` (S1)

New file for v1 or v2 (plan defers to v2):

```bash
#!/bin/bash
# PreToolUse hook for context-updater: constrains Edit/Write to in-scope paths.
# Reads JSON from stdin. Exit 0 = allow, exit 2 = block.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE_PATH=""

if [ "$TOOL" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
elif [ "$TOOL" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
else
  exit 0
fi

# Normalize to relative path
FILE_PATH="${FILE_PATH#$PWD/}"
FILE_PATH="${FILE_PATH#./}"

# Allowlisted paths for context-updater
ALLOWED=false

# Convention reference files
if echo "$FILE_PATH" | grep -qE '^skills/[^/]+/reference/.*\.md$'; then
  ALLOWED=true
fi

# Convention SKILL.md files (quick reference sections only)
if echo "$FILE_PATH" | grep -qE '^skills/[^/]+-conventions/SKILL\.md$'; then
  ALLOWED=true
fi

# CLAUDE.md project memory
if [ "$FILE_PATH" = "CLAUDE.md" ]; then
  ALLOWED=true
fi

# Agent memory (own memory file)
if echo "$FILE_PATH" | grep -qE '^\.claude/agent-memory/context-updater/'; then
  ALLOWED=true
fi

if [ "$ALLOWED" = false ]; then
  echo "BLOCKED: context-updater may only edit reference files, convention SKILL.md, and CLAUDE.md. Attempted: $FILE_PATH" >&2
  exit 2
fi

exit 0
```

If S1 is implemented, add to agent frontmatter:

```yaml
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/context-updater-edit-guard.sh"
  Stop:
    - hooks:
        - type: prompt
          prompt: >
            ...existing Stop hook prompt...
          timeout: 15
```

### 3.5 SubagentStop Hook — `hooks/hooks.json` (S4)

If implemented, add to the `SubagentStop` array:

```json
{
  "matcher": "context-updater",
  "hooks": [
    {
      "type": "prompt",
      "prompt": "The context-updater agent has finished. Evaluate: $ARGUMENTS\n\nCheck if:\n1. Latest framework versions were researched via web search or WebFetch\n2. A structured change proposal was presented to the user\n3. User approval was obtained before any edits\n4. Approved changes were applied (or user chose Discard)\n\nIf incomplete, respond {\"ok\": false, \"reason\": \"Incomplete workflow: [missing step]\"}.\nIf complete or intentionally aborted, respond {\"ok\": true}.",
      "timeout": 15
    }
  ]
}
```

---

## 4. Design Decision Review

The implementation plan includes a thorough design decisions section. This audit validates those decisions against the extensibility inventory:

| Decision | Audit Assessment |
|----------|-----------------|
| **Edit tool instead of Bash-only writes** | ✅ Correct. 11+ files with varied structures; Edit is the right tool. Releaser's Bash-only pattern is for single-file CHANGELOG insertion |
| **WebFetch-first with WebSearch fallback** | ✅ Good token optimization. Canonical URLs are known; no discovery needed. Fallback to AskUserQuestion if both fail is robust |
| **Opus model** | ✅ Justified by complexity (17+ file reads, web searches, structured proposal, targeted edits) |
| **No PreToolUse guard hook** | ⚠️ Deferred to v2 is acceptable but the guard script is straightforward (~30 lines). Recommend implementing if v1 testing reveals out-of-scope edits |
| **Convention skills loading in step 0** | ✅ Both agent frontmatter (`skills:` field) and SKILL.md step 0 handle this. Dual-loading pattern consistent with tdd-plan |
| **No version bump for docs commits** | ✅ Reference content updates are `docs:` commits. CHANGELOG entry without version bump is correct — reference file freshness is maintenance, not a feature release. However, the plugin.json bump to 1.7.0 is for the *skill/agent addition*, which IS a new feature |

---

## 5. Correctly Excluded Features

| # | Feature | Reason |
|---|---------|--------|
| A6 | `permissionMode` | Default mode (`default`) is correct — agent needs write approval for edits. Consistent with tdd-implementer pattern |
| A10 | `mcpServers` | No MCP servers provide value for reference file updates |
| A12 | Subagent resumption | Single-pass maintenance task; no resume needed |
| A13 | `Task(agent_type)` | Only for `--agent` main thread mode |
| A14 | Agent teams | Single-agent task; no parallelism benefit |
| A17 | Background execution | Sequential workflow (research → propose → approve → edit) |
| A18 | Auto-compaction override | maxTurns: 50 should complete before compaction issues |
| A19 | CLI-defined subagents | Plugin provides filesystem-based agents |
| A21 | Disable subagents | No agents need disabling |
| B3 | `argument-hint` | No arguments needed for v1 (scans all reference files) |
| B6 | `allowed-tools` (skill) | Agent tool restrictions take precedence |
| B7 | `model` (skill) | Agent frontmatter sets model |
| B10 | `hooks` (skill) | Agent frontmatter hooks sufficient |
| B11-B13 | String substitutions | No arguments or session ID needed |
| B14 | Dynamic context injection (`!`) | Agent reads files directly; pre-loaded context not beneficial |
| B18 | `Skill()` permission | No access restriction needed |
| B19 | Live change detection | Development convenience only |
| B21 | Subdirectory discovery | Not a monorepo |
| B22 | Char budget override | 7 skills within 2% budget |
| C1 | `SessionStart` | Single-pass task; no session-resume detection needed |
| C2 | `UserPromptSubmit` | Not relevant to reference file updates |
| C4 | `PermissionRequest` | Default permission mode handles approval |
| C6 | `PostToolUseFailure` | Instruction-based fallback (ask user) sufficient |
| C11 | `TeammateIdle` | No agent teams |
| C12 | `TaskCompleted` | Not relevant |
| C13 | `PreCompact` | Not needed at maxTurns: 50 |
| C14 | `SessionEnd` | No cleanup needed |
| C17 | Hook type: `agent` | Too expensive for validation |
| C21 | `model` (hook) | Default model sufficient for prompt hooks |
| C23 | `statusMessage` | Default spinner adequate for infrequent task |
| C24 | `once` | No one-time initialization needed |
| C25 | `async` | Sequential execution |
| C29 | `$CLAUDE_ENV_FILE` | No env persistence needed |
| C30 | `$CLAUDE_CODE_REMOTE` | No remote-specific behavior |
| C31 | `$TOOL_INPUT` | Hooks read from stdin; CLI variable not needed |
| D3 | `description` update | Low priority; current description adequate |
| D4-D8 | Manifest metadata | Optional; add when publishing |
| D9-D15 | Manifest path overrides | Using default directory conventions |
| E8 | `@import` | CLAUDE.md self-contained |
| F1-F5 | Permission settings | Agent tool restrictions sufficient |
| F15-F18 | Sandbox settings | Consumer settings |
| F19-F26 | Environment variables | Consumer-side overrides |

---

## 6. Summary

### Findings Count

| Tier | Count | Items |
|------|-------|-------|
| Must-Have | 2 | M1 (Write tool), M2 (disallowedTools) |
| Should-Have | 4 | S1 (Edit guard), S2 (memory instructions), S3 (SubagentStart), S4 (SubagentStop) |
| Nice-to-Have | 6 | N1-N6 |
| Correctly Excluded | 47 | See table above |

### Implementation Recommendation

**For v1 launch:** Apply M1, M2, S2, S3 (4 changes, ~20 lines total). These are low-effort, high-value corrections that align the design with established plugin patterns.

**Defer to v2:** S1 (Edit guard script), S4 (SubagentStop in hooks.json), N1-N6. These should be revisited after the first real-world run of `/tdd-update-context` to see if the agent edits out-of-scope files (S1) or hits the maxTurns limit (N1).

---

*Audit completed 2026-02-23.*
*Feature inventory: extensibility-audit-prompt.md v2.1*
*Scope: context-updater agent + tdd-update-context skill only.*
