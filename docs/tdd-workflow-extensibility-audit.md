# TDD Workflow Plugin — Claude Code Extensibility Audit

**Revision date:** 2026-02-14
**Plugin version:** 1.0.0
**Feature inventory:** extensibility-audit-prompt.md v2.1 (2026-02-14)
**Previous audit:** 2026-02-10 (v3 revision notes, pre-plugin state)

---

## How to use this document

This is a living reference for the tdd-workflow plugin. It tracks every Claude
Code extensibility feature (per the v2.1 inventory) against the plugin's
current implementation. Update it after each significant plugin change.

**Convention:** Status markers reflect the *current plugin state on disk*.

- ✅ Used — feature is implemented correctly
- ⚠️ Partial — referenced but incomplete; action item exists
- ❌ Gap — not used, should be; action item exists
- ⊘ Omitted — correctly excluded (reason in Exclusion Table §6)

---

## Official Documentation URLs

| Short Name | URL |
|---|---|
| sub-agents | https://code.claude.com/docs/en/sub-agents |
| skills | https://code.claude.com/docs/en/skills |
| hooks-guide | https://code.claude.com/docs/en/hooks-guide |
| hooks-ref | https://code.claude.com/docs/en/hooks |
| plugins | https://code.claude.com/docs/en/plugins |
| plugins-ref | https://code.claude.com/docs/en/plugins-reference |
| settings | https://code.claude.com/docs/en/settings |
| permissions | https://code.claude.com/docs/en/permissions |
| memory | https://code.claude.com/docs/en/memory |
| agent-teams | https://code.claude.com/docs/en/agent-teams |
| llms.txt | https://code.claude.com/docs/llms.txt |

---

## 1. Gap Analysis

### Category A — Subagents

#### Frontmatter Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| A1 | `name` | ✅ | `tdd-planner`, `tdd-implementer`, `tdd-verifier` |
| A2 | `description` | ✅ | All 3 have task-specific descriptions with trigger phrases |
| A3 | `tools` | ✅ | Planner: Read, Glob, Grep, Bash, AskUserQuestion. Implementer: Read, Write, Edit, MultiEdit, Bash, Glob, Grep. Verifier: Read, Bash, Glob, Grep |
| A4 | `disallowedTools` | ✅ | Planner: Write, Edit, MultiEdit, NotebookEdit, Task. Verifier: Write, Edit, MultiEdit |
| A5 | `model` | ⚠️ | Currently `sonnet` on planner/implementer, `haiku` on verifier. Decision made to upgrade planner/implementer to `opus` — not yet applied. **→ P1** |
| A6 | `permissionMode` | ✅ | Planner: `plan`. Verifier: `plan`. Implementer: default (needs write approval) |
| A7 | `maxTurns` | ✅ | Planner: 30. Implementer: 50. Verifier: 20 |
| A8 | `skills` | ✅ | Planner and implementer preload `dart-flutter-conventions` and `cpp-testing-conventions` |
| A9 | `memory` | ⚠️ | Implementer has `memory: project`. Planner does NOT — re-discovers codebase patterns each invocation. **→ S1** |
| A10 | `mcpServers` | ⊘ | No relevant MCP servers for TDD workflow |
| A11 | `hooks` (frontmatter) | ✅ | Implementer: PreToolUse + PostToolUse. Verifier: Stop. Planner: none yet **→ M1, M2** |

#### Behavioral Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| A12 | Subagent resumption | ⊘ | Planner is single-pass; implementer processes one slice per orchestrated invocation |
| A13 | `Task(agent_type)` restriction | ⊘ | Only for `--agent` main thread mode |
| A14 | Agent teams | ⊘ | Sequential slice execution; teams use ~7x tokens |
| A15 | Built-in agents | ✅ N/A | tdd-planner is a specialized Plan agent with TDD constraints |
| A16 | No-nesting constraint | ✅ | `Task` in planner's `disallowedTools` (redundant with system constraint, explicit intent) |
| A17 | Background execution | ⊘ | TDD phases are sequential by design; no parallel subagent use |
| A18 | Auto-compaction | ⊘ | Default behavior sufficient. Planner completes in 10-20 turns; implementer capped at 50 |
| A19 | CLI-defined subagents | ⊘ | Plugin provides filesystem-based agents; CLI override not needed |
| A20 | Scope precedence | ✅ N/A | Plugin agents discovered via plugin `agents/` directory |
| A21 | Disable specific subagents | ⊘ | No need to disable any TDD agents via permissions.deny |

#### Memory Details (A9)

| Scope | Status | Notes |
|-------|--------|-------|
| Implementer `project` | ✅ | `.claude/agent-memory/tdd-implementer/MEMORY.md` — accumulates test fixtures, assertion styles, edge cases |
| Planner `project` | ❌ | Not set. Should persist codebase research findings. **→ S1** |
| Verifier | ⊘ | Procedural work, no cross-session learning needed |

---

### Category B — Skills

#### Frontmatter Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| B1 | `name` | ✅ | `tdd-plan`, `tdd-implement`, `dart-flutter-conventions`, `cpp-testing-conventions` |
| B2 | `description` | ✅ | All skills have descriptions with trigger phrases |
| B3 | `argument-hint` | ❌ | `/tdd-plan` should have `argument-hint: "[feature description]"`. **→ N1** |
| B4 | `disable-model-invocation` | ✅ | Set on `/tdd-plan` |
| B5 | `user-invocable` | ⚠️ | Convention skills should have `user-invocable: false` (reference material, not commands). **→ N2** |
| B6 | `allowed-tools` | ⊘ | Agent tool restrictions take precedence |
| B7 | `model` | ⊘ | Agent frontmatter sets model |
| B8 | `context: fork` | ✅ | `/tdd-plan` uses `context: fork` |
| B9 | `agent` | ✅ | `/tdd-plan` specifies `agent: tdd-planner` |
| B10 | `hooks` (skill) | ⊘ | Agent frontmatter hooks sufficient |

#### String Substitutions

| # | Variable | Status | Notes |
|---|----------|--------|-------|
| B11 | `$ARGUMENTS` | ✅ | `/tdd-plan` uses `Plan TDD implementation for: $ARGUMENTS` |
| B12 | `$ARGUMENTS[N]` | ⊘ | Single-argument invocation; indexed access not needed |
| B13 | `${CLAUDE_SESSION_ID}` | ⊘ | No session-specific artifacts |

#### Advanced Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| B14 | Dynamic context injection (`!`) | ❌ | Should auto-detect test runner, test count, git branch. **→ S4** |
| B15 | `ultrathink` | ✅ | `/tdd-plan` SKILL.md includes `<!-- ultrathink -->` |
| B16 | Supporting files | ✅ | `tdd-plan/reference/` (2 templates), convention skills each have `reference/` dirs |
| B17 | Skills-in-subagents duality | ✅ | Both patterns used: `/tdd-plan` = skill→agent fork; conventions = agent preload |
| B18 | `Skill()` permission syntax | ⊘ | No skills need access restriction |
| B19 | Live change detection | ⊘ | Development convenience |
| B20 | Invocation matrix | ✅ N/A | `/tdd-plan` = `disable-model-invocation: true` (user only). Conventions = default (Claude can auto-load) |
| B21 | Subdirectory discovery | ⊘ | Not a monorepo plugin |
| B22 | Char budget | ⊘ | 4 skills well within 2% budget; no override needed |

---

### Category C — Hooks

#### Hook Events

| # | Event | Status | Notes |
|---|-------|--------|-------|
| C1 | `SessionStart` | ⊘ | Could detect in-progress TDD sessions. Low priority — planner completes in one context window. **→ N4** |
| C2 | `UserPromptSubmit` | ⊘ | Not relevant to TDD workflow |
| C3 | `PreToolUse` | ✅ | Implementer: `validate-tdd-order.sh` on `Write\|Edit\|MultiEdit`. Planner: none yet **→ M1** |
| C4 | `PermissionRequest` | ⊘ | `permissionMode: plan` on read-only agents eliminates dialogs; implementer needs interactive approval |
| C5 | `PostToolUse` | ✅ | Implementer: `auto-run-tests.sh` on `Write\|Edit\|MultiEdit` |
| C6 | `PostToolUseFailure` | ⊘ | No failure recovery logic needed |
| C7 | `Notification` | ⊘ | Desktop notification on slice completion would improve UX. **→ N3** |
| C8 | `SubagentStart` | ❌ | Should inject git context into planner at startup. **→ S5** |
| C9 | `SubagentStop` | ✅ | `hooks.json`: prompt-based hook on `tdd-implementer` validates R-G-R cycle. Planner: none yet **→ S2** |
| C10 | `Stop` | ✅ | Main thread: `check-tdd-progress.sh` prevents session end with pending slices. Verifier: prompt-based completeness check |
| C11 | `TeammateIdle` | ⊘ | No agent teams |
| C12 | `TaskCompleted` | ⊘ | Not relevant |
| C13 | `PreCompact` | ⊘ | Low priority (same reason as C1) |
| C14 | `SessionEnd` | ⊘ | No cleanup needed |

#### Hook Types

| # | Type | Status | Notes |
|---|------|--------|-------|
| C15 | `command` | ✅ | All file-based hooks (validate-tdd-order, auto-run-tests, check-tdd-progress). Anthropic best practice: prefer command for deterministic logic |
| C16 | `prompt` | ✅ | Verifier Stop hook + implementer SubagentStop (non-deterministic checks) |
| C17 | `agent` | ⊘ | Too expensive — spawns subagent for validation |

#### Hook Handler Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| C18 | `type` | ✅ | All hooks specify type |
| C19 | `command` | ✅ | Script paths use `${CLAUDE_PLUGIN_ROOT}` |
| C20 | `prompt` | ✅ | Verifier Stop + implementer SubagentStop |
| C21 | `model` (hook) | ⊘ | Default model sufficient for prompt hooks |
| C22 | `timeout` | ✅ | Set on SubagentStop (30s), Stop (10s) |
| C23 | `statusMessage` | ⊘ | Default spinner adequate |
| C24 | `once` | ⊘ | No one-time initialization needed |
| C25 | `async` | ⊘ | Sequential execution |

#### Hook Variables & Protocol

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| C26 | `$ARGUMENTS` | ✅ | SubagentStop hook uses `$ARGUMENTS` |
| C27 | `$CLAUDE_PROJECT_DIR` | ⊘ | Using `${CLAUDE_PLUGIN_ROOT}` instead (plugin context) |
| C28 | `${CLAUDE_PLUGIN_ROOT}` | ✅ | All hook commands use this for portable paths |
| C29 | `$CLAUDE_ENV_FILE` | ⊘ | No env var persistence needed |
| C30 | `$CLAUDE_CODE_REMOTE` | ⊘ | No remote-specific behavior |
<!-- CC addition: C31 $TOOL_INPUT added to match Doc A v2.1; appears in sub-agents docs as command-line variable -->
| C31 | `$TOOL_INPUT` | ⊘ | Appears in sub-agents docs as CLI variable for hook commands; not needed by current hooks (they read JSON from stdin) |
| C32 | Exit code 0 | ✅ | Used in all command hooks |
| C33 | Exit code 2 | ✅ | Used in `validate-tdd-order.sh` to block writes |
| C34 | Other exit codes | ✅ N/A | Not used; understood |
| C35 | `stop_hook_active` | ✅ | `check-tdd-progress.sh` checks this to prevent infinite loops |

#### JSON Output

| Feature | Status | Notes |
|---------|--------|-------|
| `systemMessage` | ✅ | `auto-run-tests.sh` returns test output as systemMessage |
| `decision`/`reason` | ✅ | `check-tdd-progress.sh` returns `{"decision": "block", "reason": ...}` |
| `additionalContext` | ❌ | SubagentStart hook for planner should use this. **→ S5** |
| `updatedInput` | ⊘ | No need to modify tool parameters |
| `permissionDecision` | ⊘ | Not using PermissionRequest hooks |
| `continue`/`stopReason` | ⊘ | Not using session-stopping hooks |
| `suppressOutput` | ⊘ | Hook output is useful for debugging |

---

### Category D — Plugins

#### Manifest Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| D1 | `name` | ✅ | `"tdd-workflow"` |
| D2 | `version` | ✅ | `"1.0.0"` |
| D3 | `description` | ✅ | Present and descriptive |
| D4 | `author` | ⊘ | Optional; can add later |
| D5 | `homepage` | ⊘ | No published docs yet |
| D6 | `repository` | ⊘ | Not yet on a public repo |
| D7 | `license` | ⊘ | LICENSE file exists at root; could add to manifest |
| D8 | `keywords` | ⊘ | Useful for marketplace discovery; premature |
| D9 | `commands` | ⊘ | No legacy commands |
| D10 | `agents` | ⊘ | Using default `agents/` directory |
| D11 | `skills` | ⊘ | Using default `skills/` directory |
| D12 | `hooks` | ⊘ | Using default `hooks/hooks.json` |
| D13 | `mcpServers` | ⊘ | No MCP servers |
| D14 | `lspServers` | ⊘ | No LSP servers. Dart LSP could help but adds complexity |
| D15 | `outputStyles` | ⊘ | No custom output styles |

#### Plugin Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| D16 | `${CLAUDE_PLUGIN_ROOT}` | ✅ | Used in all hook commands |
| D17 | Scopes | ⊘ | Depends on installation method; no explicit recommendation yet |
| D18 | Namespacing | ✅ N/A | Skills auto-namespaced as `/tdd-workflow:tdd-plan` etc. |
| D19 | `--plugin-dir` | ⊘ | Dev convenience |
| D20 | Plugin caching | ✅ N/A | Handled automatically by Claude Code |
| D21 | CLI commands | ✅ N/A | `claude plugin install <path>` documented in README |
| D22 | Marketplace sources | ⊘ | Not yet published |
| D23 | LSP servers | ⊘ | Could add Dart analysis server; complexity vs benefit |
| D24 | `strict: false` | ⊘ | Not in a marketplace |

#### Directory Structure

```
tdd-workflow/                               Status
├── .claude-plugin/
│   └── plugin.json                         ✅
├── agents/
│   ├── tdd-planner.md                      ✅ (pending: opus, memory, hooks)
│   ├── tdd-implementer.md                  ✅ (pending: opus, git commits)
│   └── tdd-verifier.md                     ✅
├── skills/
│   ├── tdd-plan/
│   │   ├── SKILL.md                        ✅ (pending: argument-hint, dynamic context)
│   │   └── reference/
│   │       ├── tdd-task-template.md        ✅
│   │       └── feature-notes-template.md   ✅
│   ├── tdd-implement/
│   │   └── SKILL.md                        ✅ (pending: branch creation)
│   ├── dart-flutter-conventions/
│   │   ├── SKILL.md                        ✅ (pending: user-invocable: false)
│   │   └── reference/  (4 files)           ✅
│   └── cpp-testing-conventions/
│       ├── SKILL.md                        ✅ (pending: user-invocable: false)
│       └── reference/  (3 files)           ✅
├── hooks/
│   ├── hooks.json                          ✅ (pending: planner SubagentStop, SubagentStart)
│   ├── validate-tdd-order.sh               ✅
│   ├── auto-run-tests.sh                   ✅
│   └── check-tdd-progress.sh              ✅
├── docs/
│   ├── version-control.md                  ✅
│   └── user-guide.md                       ✅
├── CLAUDE.md                               ✅
├── CHANGELOG.md                            ✅
├── README.md                               ✅
└── LICENSE                                 ✅

Files to add:
├── hooks/
│   ├── planner-bash-guard.sh               → M1
│   └── validate-plan-output.sh             → M2
```

---

### Category E — Memory / CLAUDE.md

#### Memory Locations

| # | Type | Status | Notes |
|---|------|--------|-------|
| E1 | Managed policy | ⊘ | Enterprise feature |
| E2 | Project memory | ✅ | `CLAUDE.md` at plugin root documents full workflow |
| E3 | Project rules (`.claude/rules/`) | ⊘ | Plugin uses CLAUDE.md directly; rules directory is for consuming projects, not the plugin itself |
| E4 | User memory | ⊘ | Personal preferences |
| E5 | User rules | ⊘ | Personal preferences |
| E6 | Local memory (`CLAUDE.local.md`) | ⊘ | No machine-specific overrides |
| E7 | Auto memory | ⊘ | Plugin relies on explicit `memory: project` on agents, not auto-memory |
| E8 | `@import` syntax | ⊘ | CLAUDE.md is self-contained; no imports needed |
| E9 | Path-specific rules | ⊘ | Plugin doesn't ship rules; consuming projects can add their own |
| E10 | Auto memory (200-line limit) | ✅ N/A | Agent memory (A9) uses this mechanism — first 200 lines of MEMORY.md auto-included |
| E11 | `/memory` command | ⊘ | Built-in, not a plugin concern |
| E12 | `/init` command | ⊘ | Built-in, not a plugin concern |
| E13 | `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | ⊘ | Not relevant |
| E14 | Child directory discovery | ⊘ | No subdirectory CLAUDE.md files |
| E15 | `--add-dir` + CLAUDE.md | ⊘ | Not relevant |

---

### Category F — Settings and Permissions

#### Permission Settings

| # | Key | Status | Notes |
|---|-----|--------|-------|
| F1 | `permissions.allow` | ⊘ | Agent tool restrictions sufficient |
| F2 | `permissions.deny` | ⊘ | Agent `disallowedTools` more targeted |
| F3 | `permissions.ask` | ⊘ | Not needed |
| F4 | `permissions.defaultMode` | ⊘ | Agents set their own `permissionMode` |
| F5 | `permissions.additionalDirectories` | ⊘ | Plugin works within project directory |

#### Key Settings

| # | Setting | Status | Notes |
|---|---------|--------|-------|
| F6 | `model` | ⊘ | Agents set their own model in frontmatter |
| F7 | `hooks` | ✅ | Plugin ships `hooks/hooks.json` |
| F8 | `env` | ⊘ | No environment variables needed |
| F9 | `disableAllHooks` | ⊘ | Consumer setting, not plugin concern |
| F10 | `allowManagedHooksOnly` | ⊘ | Enterprise feature |
| F11 | `allowManagedPermissionRulesOnly` | ⊘ | Enterprise feature |
| F12 | `language` | ⊘ | Consumer preference |
| F13 | `outputStyle` | ⊘ | No custom output style |
| F14 | `$schema` | ⊘ | Minor — could add to hooks.json for IDE autocomplete. **→ N5** |

#### Sandbox Settings

| # | Setting | Status | Notes |
|---|---------|--------|-------|
| F15 | `sandbox.enabled` | ⊘ | Consumer setting; plugin hooks are compatible with sandboxed execution |
| F16 | `sandbox.autoAllowBashIfSandboxed` | ⊘ | Consumer setting |
| F17 | `sandbox.excludedCommands` | ⊘ | Consumer setting |
| F18 | `sandbox.network.allowedDomains` | ⊘ | No network access needed by hooks |

#### Environment Variables

| # | Variable | Status | Notes |
|---|----------|--------|-------|
| F19 | `ANTHROPIC_MODEL` | ⊘ | Agents set model in frontmatter; env override is consumer-side |
| F20 | `CLAUDE_CODE_SUBAGENT_MODEL` | ⊘ | Same — consumer can override if desired |
| F21 | `MAX_THINKING_TOKENS` | ⊘ | `ultrathink` in skill content handles this |
| F22 | `CLAUDE_CODE_EFFORT_LEVEL` | ⊘ | Consumer preference |
| F23 | `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | ⊘ | Default compaction sufficient |
| F24 | `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | ⊘ | No background tasks used |
| F25 | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | ⊘ | No agent teams |
| F26 | `SLASH_COMMAND_TOOL_CHAR_BUDGET` | ⊘ | 4 skills well within budget |

---

## 2. Implementation Status

### What changed since the v3 audit (2026-02-10)

The v3 audit was written when only the planner existed as a raw subagent with
no skill wrapper, no hooks, and no plugin structure. Since then:

| v3 Recommendation | Status |
|---|---|
| Package as plugin with plugin.json | ✅ |
| Create `/tdd-plan` skill (context: fork, agent, disable-model-invocation) | ✅ |
| Create `/tdd-implement` orchestration skill | ✅ |
| Add `$ARGUMENTS` to `/tdd-plan` | ✅ |
| Add `ultrathink` to tdd-plan SKILL.md | ✅ |
| Add `maxTurns` to all agents | ✅ |
| Add `disallowedTools` to verifier | ✅ |
| Add `permissionMode: plan` to planner and verifier | ✅ |
| Add `memory: project` to implementer | ✅ |
| Add PreToolUse hook on implementer (`Write\|Edit\|MultiEdit`) | ✅ |
| Add PostToolUse hook on implementer (auto-run-tests) | ✅ |
| Add Stop hook on main thread (check-tdd-progress) | ✅ |
| Add SubagentStop hook on implementer (R-G-R validation) | ✅ |
| Add Stop hook on verifier (completeness check) | ✅ |
| Extract conventions into preloaded skills | ✅ |
| Add supporting files to skills | ✅ |
| Add CLAUDE.md documenting the workflow | ✅ |
| Migrate to modern skills format (from legacy commands/) | ✅ |

### Items beyond the v3 audit (designed in subsequent sessions)

| Item | Status |
|---|---|
| Format reliability fixes (re-read step + self-check in SKILL.md) | ✅ |
| FVM auto-detection in SKILL.md step 1 | ✅ |
| Version control integration — Layer 1 (auto-commits) | Designed, not applied |
| Version control integration — Layer 2 (branch creation) | Designed, not applied |
| Version control integration — Layer 3 (release workflow) | Designed, not applied |
| Project-conventions.md ephemeral state clarification | ✅ |
| User guide state management section | ✅ |

---

## 3. Prioritized Remaining Work

### P — Pending Decisions (apply immediately)

| # | Item | Effort | Rationale |
|---|------|--------|-----------|
| P1 | **Set `model: opus` on tdd-planner and tdd-implementer** | 2 lines | Decision made: quality over cost. Opus has better instruction-following across long contexts. Tradeoff: up to 350 Opus calls per full implementation run |

### M — Must-Have (correctness / safety)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| M1 | **Add planner Bash guard hook** | ~30 lines | Planner disallows Write/Edit/MultiEdit but Bash can still `echo > lib/file.dart`. PreToolUse command hook on `Bash` blocks output redirection outside `planning/` | C3, C15 |
| M2 | **Add planner Stop hook (plan output validator)** | ~40 lines | Planner can stop without producing a plan file or with missing sections. Checks: file in `planning/`, required sections present, zero `refactor:` commit types | C10, C15 |

### S — Should-Have (quality / robustness)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| S1 | **Add `memory: project` to tdd-planner** + memory instructions in agent prompt | 1+10 lines | Planner re-discovers codebase patterns every invocation. Memory persists architecture, naming, test framework findings | A9 |
| S2 | **Add SubagentStop hook for planner (anti-refactoring guard)** | ~15 lines | LLMs leak refactoring despite explicit negative instructions. Command hook scans plan for `refactor:` — defense-in-depth | C9, C15 |
| S3 | **Add `additionalContext` via SubagentStart for planner** | ~5 lines | Inject current branch, last commit, dirty file count. Planner gets immediate working context | C8 |
| S4 | **Add dynamic context injection to /tdd-plan** | ~5 lines | `!` backtick preprocessing auto-detects test runner, test count, git state. Reduces planner research by 2-3 turns | B14 |
| S5 | **Implement git auto-commit (Layer 1)** | ~15 lines in agent prompt | Implementer commits after each R-G-R phase: `test:`, `feat:`, `refactor:` | version-control.md |
| S6 | **Implement branch creation (Layer 2)** | ~5 lines in SKILL.md | `/tdd-implement` creates `feature/<name>` before first slice; skip if already on feature branch | version-control.md |

### N — Nice-to-Have (distribution / UX)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| N1 | **Add `argument-hint: "[feature description]"` to /tdd-plan** | 1 line | Autocomplete hint in `/` menu | B3 |
| N2 | **Add `user-invocable: false` to convention skills** | 2 lines | Prevents convention skills appearing as commands in `/` menu | B5 |
| N3 | **Add Notification hooks on slice completion** | ~5 lines | Desktop notifications for long multi-slice sessions | C7 |
| N4 | **Add SessionStart hook for TDD session detection** | ~10 lines | Detect `.tdd-progress.md` and inject state reminder | C1 |
| N5 | **Add `$schema` to hooks.json** | 1 line | IDE autocomplete: `"$schema": "https://json.schemastore.org/claude-code-settings.json"` | F14 |
| N6 | **Implement release workflow (Layer 3)** | ~80 lines | `/tdd-release` skill + `tdd-releaser` agent for CHANGELOG, PR creation | version-control.md |

---

## 4. Revised Component Specifications

Copy-paste-ready specs for P, M, and S items.

### 4.1 Model Upgrade (P1)

**`agents/tdd-planner.md`** — change:
```yaml
model: opus
```

**`agents/tdd-implementer.md`** — change:
```yaml
model: opus
```

### 4.2 Planner Memory (S1)

**`agents/tdd-planner.md`** — add to frontmatter:
```yaml
memory: project
```

**`agents/tdd-planner.md`** — add to system prompt body:
```markdown
## Memory

Your project memory accumulates knowledge across sessions. At the start of
each invocation, read your MEMORY.md (if it exists) for prior context. After
completing the plan, update it with discoveries:
- Architecture patterns and conventions observed
- Test framework and mocking library preferences
- Naming conventions beyond the standard rules
- Common edge cases or project-specific constraints
- File counts and structure landmarks (so future runs skip basic research)
```

### 4.3 Planner Bash Guard (M1)

**New file: `hooks/planner-bash-guard.sh`**

```bash
#!/bin/bash
# PreToolUse hook for tdd-planner: blocks Bash commands that write files
# outside the planning/ directory.
# Reads JSON from stdin. Exit 0 = allow, exit 2 = block.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Block output redirection to non-planning paths
# <!-- CC addition: This regex doesn't catch dd of=, python -c "open(...).write()", heredocs,
#      or curl -o. Defense-in-depth with permissionMode:plan, but consider a stricter allowlist
#      approach if the planner gains more Bash usage. -->
if echo "$COMMAND" | grep -qE '(^|[;&|])\s*(cat|echo|printf)\s.*>\s*[^|]' ; then
  if echo "$COMMAND" | grep -qE '>\s*(\./)?planning/' ; then
    exit 0
  fi
  echo "BLOCKED: Bash output redirection outside planning/ directory." >&2
  exit 2
fi

# Block tee to non-planning paths
if echo "$COMMAND" | grep -qE 'tee\s+' ; then
  if echo "$COMMAND" | grep -qE 'tee\s+(\./)?planning/' ; then
    exit 0
  fi
  echo "BLOCKED: tee to files outside planning/ directory." >&2
  exit 2
fi

# Block common file-creation commands targeting source/test paths
if echo "$COMMAND" | grep -qE '(cp|mv|touch|mkdir)\s+.*(lib/|test/|src/)' ; then
  echo "BLOCKED: Bash command modifies project source files. The planner is read-only." >&2
  exit 2
fi

exit 0
```

**`agents/tdd-planner.md`** — add to frontmatter:
```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/planner-bash-guard.sh"
```

### 4.4 Planner Plan Output Validator (M2)

**New file: `hooks/validate-plan-output.sh`**

```bash
#!/bin/bash
# Stop hook for tdd-planner: validates plan file produced with required
# sections and no refactoring leak.
# Reads JSON from stdin. Exit 2 = block (prevent stop).

INPUT=$(cat)

STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

PLAN_FILE=$(find planning/ -name "*.md" -mmin -30 -type f 2>/dev/null | sort -r | head -1)

if [ -z "$PLAN_FILE" ]; then
  echo "No plan file found in planning/ (modified in last 30 minutes). Save your plan before finishing." >&2
  exit 2
fi

MISSING=""
grep -qiE '^#{1,3}\s*.*feature analysis' "$PLAN_FILE" || MISSING="$MISSING Feature-Analysis"
grep -qiE '^#{1,3}\s*.*test specification|^#{1,3}\s*slice' "$PLAN_FILE" || MISSING="$MISSING Test-Specification/Slices"

if [ -n "$MISSING" ]; then
  echo "Plan file $PLAN_FILE is missing required sections:$MISSING" >&2
  exit 2
fi

if grep -qiE 'refactor:|refactoring phase|REFACTOR phase' "$PLAN_FILE"; then
  LEAKS=$(grep -niE 'refactor:|refactoring phase|REFACTOR phase' "$PLAN_FILE" | head -3)
  echo "REFACTORING LEAK in $PLAN_FILE:" >&2
  echo "$LEAKS" >&2
  exit 2
fi

exit 0
```

**`agents/tdd-planner.md`** — extend hooks in frontmatter:
```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/planner-bash-guard.sh"
  Stop:
    - hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-output.sh"
```

### 4.5 Anti-Refactoring SubagentStop Guard for Planner (S2)

**`hooks/hooks.json`** — add entry to `SubagentStop` array:

```json
{
  "matcher": "tdd-planner",
  "hooks": [
    {
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-output.sh",
      "timeout": 10
    }
  ]
}
```

### 4.6 SubagentStart Git Context Injection (S3)

**`hooks/hooks.json`** — add new event:

```json
"SubagentStart": [
  {
    "matcher": "tdd-planner",
    "hooks": [
      {
        "type": "command",
        "command": "echo \"{\\\"additionalContext\\\": \\\"Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown'). Last commit: $(git log --oneline -1 2>/dev/null || echo 'none'). Dirty files: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ').\\\"}\"",
        "timeout": 5
      }
    ]
  }
]
```

### 4.7 Dynamic Context Injection (S4)

**`skills/tdd-plan/SKILL.md`** — replace opening after frontmatter:

```markdown
# TDD Implementation Planning

<!-- ultrathink -->

Plan TDD implementation for: $ARGUMENTS

## Project Context (auto-detected)
- Test runner: !`which flutter >/dev/null 2>&1 && echo "flutter test" || echo "dart test"`
- Existing tests: !`find . \( -name "*_test.dart" -o -name "*_test.cpp" \) 2>/dev/null | wc -l | tr -d ' '` test files
- Current branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
- Uncommitted changes: !`git status --porcelain 2>/dev/null | wc -l | tr -d ' '` files
- FVM detected: !`test -f .fvmrc && command -v fvm >/dev/null 2>&1 && echo "yes (use fvm flutter)" || echo "no"`

## Process
```

### 4.8 Git Auto-Commit in Implementer (S5)

**`agents/tdd-implementer.md`** — add to system prompt body:

```markdown
## Git Workflow

After each confirmed phase transition, commit the changes:

- **RED confirmed:** `git add <test files>` then `git commit -m "test(<scope>): add tests for <slice name>"`
- **GREEN confirmed:** `git add <implementation files>` then `git commit -m "feat(<scope>): implement <slice name>"`
- **REFACTOR confirmed:** `git add <changed files>` then `git commit -m "refactor(<scope>): clean up <slice name>"`

If the REFACTOR phase is skipped, skip the refactor commit.
`<scope>` = primary module/feature, lowercase with hyphens (e.g., `location-service`).
Do NOT push — that happens in the release workflow.
```

### 4.9 Branch Creation (S6)

**`skills/tdd-implement/SKILL.md`** — add before "## Implementation Loop":

```markdown
## Step 0: Ensure Feature Branch

Before processing the first pending slice:
1. Check the current branch: `git branch --show-current`
2. If on `main` or `master`: derive a branch name from the feature title in `.tdd-progress.md` and `git checkout -b feature/<kebab-case-feature-name>`
3. If already on a `feature/` branch, skip (resume case)
4. If on any other branch, ask the user whether to continue or create a feature branch
```

---

## 5. Audit Prompt Reconciliation

The v2.0 audit prompt (`extensibility-audit-prompt.md`) discovered features
that the original v1.0 prompt and my previous audit missed entirely. Key
additions that affect the TDD plugin assessment:

| New Feature | Impact on Plugin |
|---|---|
| A17 Background execution | Correctly omitted — TDD is sequential |
| A18 Auto-compaction | Correctly omitted — default sufficient |
| A21 Disable subagents via permissions.deny | Correctly omitted — no agents need disabling |
| B3 `argument-hint` | Gap found → N1 |
| B5 `user-invocable` | Gap found → N2 |
| B14 Dynamic context injection (`!` backtick) | Gap found → S4 |
| B22 Char budget | Correctly omitted — within budget |
| C4 PermissionRequest hook | Correctly omitted — permissionMode handles this |
| C8 SubagentStart `additionalContext` output | Gap found → S3 |
| D14 `lspServers` | Correctly omitted — complexity vs benefit |
| D23 LSP servers (.lsp.json) | Same |
| E3 Project rules directory | Correctly omitted — plugin uses CLAUDE.md |
| E7 Auto memory | Correctly omitted — using explicit agent memory |
| E8 `@import` syntax | Correctly omitted — CLAUDE.md self-contained |
| F14 `$schema` | Minor gap → N5 |
| F15-F18 Sandbox settings | Correctly omitted — consumer settings |
| F19-F26 Environment variables | Correctly omitted — consumer settings |

The v2.0 audit prompt is now the **canonical feature inventory** for future
audits. The v1.0 prompt should be retired.

---

## 6. Correctly Excluded Features (Complete)

| # | Feature | Reason |
|---|---------|--------|
| A10 | `mcpServers` | No MCP servers provide value for TDD workflow |
| A12 | Subagent resumption | Single-pass planner; orchestrated-per-slice implementer |
| A13 | `Task(agent_type)` | Only for `--agent` main thread mode |
| A14 | Agent teams | Sequential execution; teams use ~7x tokens |
| A17 | Background execution | TDD phases are sequential by design |
| A18 | Auto-compaction override | Default compaction sufficient |
| A19 | CLI-defined subagents | Plugin provides filesystem agents |
| A21 | Disable subagents | No agents need disabling |
| B6 | `allowed-tools` (skill) | Agent restrictions take precedence |
| B7 | `model` (skill) | Agent frontmatter sets model |
| B10 | `hooks` (skill) | Agent frontmatter hooks sufficient |
| B12 | `$ARGUMENTS[N]` | Single-argument invocation |
| B13 | `${CLAUDE_SESSION_ID}` | No session-specific artifacts |
| B18 | `Skill()` permission | No skills need restriction |
| B19 | Live change detection | Development convenience |
| B21 | Subdirectory discovery | Not a monorepo |
| B22 | Char budget override | 4 skills within budget |
| C2 | `UserPromptSubmit` | Not relevant to TDD |
| C4 | `PermissionRequest` | `permissionMode: plan` eliminates dialogs |
| C6 | `PostToolUseFailure` | No failure recovery needed |
| C11 | `TeammateIdle` | No agent teams |
| C12 | `TaskCompleted` | Not relevant |
| C14 | `SessionEnd` | No cleanup needed |
| C17 | Hook type: `agent` | Too expensive for validation |
| C21 | `model` (hook) | Default sufficient |
| C23 | `statusMessage` | Default spinner adequate |
| C24 | `once` | No one-time init |
| C25 | `async` | Sequential execution |
| C29 | `$CLAUDE_ENV_FILE` | No env persistence needed |
| C30 | `$CLAUDE_CODE_REMOTE` | No remote-specific behavior |
| C31 | `$TOOL_INPUT` | Hooks read tool input via JSON stdin; CLI variable not needed |
| D4-D8 | Manifest metadata | Optional; add when publishing |
| D9-D15 | Manifest path overrides | Using default directory conventions |
| D14/D23 | LSP servers | Complexity vs benefit |
| D22 | Marketplace sources | Not yet published |
| E1 | Managed policy | Enterprise feature |
| E3-E5 | Rules directories | Plugin uses CLAUDE.md; rules are for consuming projects |
| E6 | Local memory | No machine-specific overrides |
| E7 | Auto memory | Using explicit agent memory |
| E8 | `@import` | CLAUDE.md self-contained |
| E9 | Path-specific rules | Plugin doesn't ship rules files |
| E11-E15 | Memory commands/flags | Built-in features, not plugin concerns |
| F1-F5 | Permission settings | Agent restrictions sufficient |
| F6 | `model` (settings) | Agent frontmatter sets model |
| F8-F13 | Misc settings | Consumer preferences |
| F15-F18 | Sandbox | Consumer settings; hooks compatible |
| F19-F26 | Environment variables | Consumer-side overrides |

---

*Audit completed 2026-02-14.*
*Feature inventory: extensibility-audit-prompt.md v2.1*
*Next audit: after implementing Layer 1-3 version control integration.*
