# TDD Workflow Plugin — Claude Code Extensibility Audit

**Revision date:** 2026-03-18
**Plugin version:** 1.14.0
**Feature inventory:** audit-prompt.md v3.0 (2026-03-18)
**Previous audit:** audit-v1.6.6.md (2026-02-20, v2.1 inventory)

---

## How to use this document

This is a living reference for the tdd-workflow plugin. It tracks every Claude
Code extensibility feature (per the v3.0 inventory) against the plugin's
current implementation. Update it after each significant plugin change.

**Convention:** Status markers reflect the *current plugin state on disk*.

- ✅ Used — feature is implemented correctly
- ⚠️ Partial — referenced but incomplete; action item exists
- ❌ Gap — not used, should be; action item exists
- ⊘ Omitted — correctly excluded (reason in Exclusion Table §6)

---

## 1. Gap Analysis

### Category A — Subagents

#### Frontmatter Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| A1 | `name` | ✅ | All 6 agents: `tdd-planner`, `tdd-implementer`, `tdd-verifier`, `tdd-releaser`, `tdd-doc-finalizer`, `context-updater` |
| A2 | `description` | ✅ | All 6 have task-specific descriptions with trigger phrases |
| A3 | `tools` | ✅ | Planner: Read, Glob, Grep, Bash. Implementer: Read, Write, Edit, MultiEdit, Bash, Glob, Grep. Verifier: Read, Bash, Glob, Grep. Releaser: Read, Bash, Glob, Grep, AskUserQuestion. Doc-finalizer: Read, Bash, Glob, Grep, Edit. Context-updater: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, AskUserQuestion |
| A4 | `disallowedTools` | ✅ | Verifier: Write, Edit, MultiEdit. Releaser: Write, Edit, MultiEdit, NotebookEdit. Doc-finalizer: Write, MultiEdit, NotebookEdit. Context-updater: MultiEdit, NotebookEdit, Task |
| A5 | `model` | ✅ | Planner/implementer/context-updater: `opus`. Verifier: `haiku`. Releaser/doc-finalizer: `sonnet` |
| A6 | `permissionMode` | ✅ | Planner: `plan`. Verifier: `plan`. Others: default (correct — need interactive approval or write access) |
| A7 | `maxTurns` | ✅ | Planner: 30. Implementer: 50. Verifier: 20. Releaser: 30. Doc-finalizer: 30. Context-updater: 50 |
| A8 | `skills` | ✅ | Planner, implementer, context-updater preload all 4 convention skills: `dart-flutter-conventions`, `cpp-testing-conventions`, `bash-testing-conventions`, `c-conventions` |
| A9 | `memory` | ✅ | Planner: `project`. Implementer: `project`. Context-updater: `project`. Others: none (correct — procedural/independent work) |
| A10 | `mcpServers` | ⊘ | No MCP servers provide value for TDD workflow |
| A11 | `hooks` | ✅ | Planner: PreToolUse Bash guard. Implementer: PreToolUse + PostToolUse. Verifier: Stop (prompt). Releaser: Stop (command). Doc-finalizer: Stop (command). Context-updater: Stop (prompt) |
| A12 | `background` | ⊘ | TDD phases are sequential by design |
| A13 | `isolation` | ⊘ | Agents work on the same files; worktree isolation would break the workflow |

#### Behavioral Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| A14 | Subagent resumption | ⊘ | Planner is single-pass; implementer processes one slice per orchestrated invocation |
| A15 | `Agent(agent_type)` restriction | ⊘ | Only for `--agent` main thread mode; not applicable to plugin subagents |
| A16 | Agent teams | ⊘ | Sequential slice execution; teams would multiply tokens without benefit |
| A17 | Built-in agents | ✅ N/A | tdd-planner is a specialized Plan agent with TDD constraints |
| A18 | No-nesting constraint | ✅ | `Task` in context-updater's `disallowedTools` (redundant with system constraint, explicit intent) |
| A19 | Foreground/background | ⊘ | TDD phases are sequential by design; no parallel subagent use |
| A20 | Auto-compaction | ⊘ | Default behavior sufficient. All agents complete within maxTurns |
| A21 | CLI-defined subagents | ⊘ | Plugin provides filesystem-based agents; CLI override not needed |
| A22 | Scope precedence | ✅ N/A | Plugin agents discovered via plugin `agents/` directory |
| A23 | Disable specific subagents | ⊘ | No need to disable any TDD agents via permissions.deny |
| A24 | @-mention invocation | ✅ N/A | Skills invoke agents programmatically; user @-mentions not the primary pattern |
| A25 | `--agent` / `agent` setting | ⊘ | TDD agents are task-specific subagents, not session-wide agents |
| A26 | `/agents` command | ✅ N/A | Plugin agents appear in `/agents` automatically |
| A27 | Plugin agent restrictions | ✅ | **Mitigated** — see §3 item M1 (resolved in v1.14.0). Hook scripts have `agent_type` guards; all enforcement hooks are duplicated in `hooks.json` (PreToolUse ×2, PostToolUse ×1, SubagentStop ×5, SubagentStart ×2). Agent frontmatter hooks remain in place for local development. `permissionMode: plan` loss is accepted — `tools` allowlist provides equivalent protection |
| A28 | Transcript persistence | ⊘ | Default behavior sufficient; no custom cleanup needed |

#### Memory Details (A9)

| Scope | Status | Notes |
|-------|--------|-------|
| Planner `project` | ✅ | `.claude/agent-memory/tdd-planner/MEMORY.md` — persists architecture, naming, test framework findings |
| Implementer `project` | ✅ | `.claude/agent-memory/tdd-implementer/MEMORY.md` — accumulates test fixtures, assertion styles, edge cases |
| Context-updater `project` | ✅ | `.claude/agent-memory/context-updater/MEMORY.md` — persists framework version findings |
| Verifier `project` | ✅ | `.claude/agent-memory/tdd-verifier/MEMORY.md` — accumulates test runner commands, failure patterns, flaky tests, static analysis quirks |
| Releaser | ⊘ | Each release is independent, no cross-session learning needed |
| Doc-finalizer | ⊘ | Each release is independent |

---

### Category B — Skills

#### Frontmatter Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| B1 | `name` | ✅ | All 9 skills: 5 workflow (`tdd-plan`, `tdd-implement`, `tdd-release`, `tdd-finalize-docs`, `tdd-update-context`) + 4 convention |
| B2 | `description` | ✅ | All skills have descriptions with trigger phrases |
| B3 | `argument-hint` | ✅ | `/tdd-plan` has `argument-hint: "[feature description]"` |
| B4 | `disable-model-invocation` | ✅ | Set on `/tdd-plan`, `/tdd-release`, `/tdd-finalize-docs`, `/tdd-update-context` |
| B5 | `user-invocable` | ✅ | All 4 convention skills have `user-invocable: false` |
| B6 | `allowed-tools` | ⊘ | Agent tool restrictions take precedence |
| B7 | `model` | ⊘ | Agent frontmatter sets model |
| B8 | `context: fork` | ✅ | `/tdd-release`, `/tdd-finalize-docs`, `/tdd-update-context` use `context: fork` |
| B9 | `agent` | ✅ | `/tdd-release` → `tdd-releaser`. `/tdd-finalize-docs` → `tdd-doc-finalizer`. `/tdd-update-context` → `context-updater` |
| B10 | `hooks` (skill) | ⊘ | Agent frontmatter hooks handle this (though see A27 issue) |

#### String Substitutions

| # | Variable | Status | Notes |
|---|----------|--------|-------|
| B11 | `$ARGUMENTS` | ✅ | `/tdd-plan` uses `Plan TDD implementation for: $ARGUMENTS` |
| B12 | `$ARGUMENTS[N]` / `$N` | ⊘ | Single-argument invocation; indexed access not needed |
| B13 | `${CLAUDE_SESSION_ID}` | ⊘ | No session-specific artifacts |
| B14 | `${CLAUDE_SKILL_DIR}` | ⊘ | Skills reference files via relative paths from their directory; explicit variable not needed |

#### Advanced Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| B15 | Dynamic context injection (`!`) | ⚠️ | `!` backtick blocked by permission system — even via helper script. Replaced with planner step 1 running `detect-project-context.sh` directly. Same outcome, different mechanism |
| B16 | `ultrathink` | ✅ | `/tdd-plan` SKILL.md includes `<!-- ultrathink -->` |
| B17 | Supporting files | ✅ | `tdd-plan/reference/` (2 templates), `tdd-release/reference/` (version-control.md), all convention skills have `reference/` dirs (18 reference files total, 5,453 lines) |
| B18 | Skills-in-subagents duality | ✅ | Both patterns used: `/tdd-release` = skill→agent fork; conventions = agent preload |
| B19 | `Skill()` permission syntax | ⊘ | No skills need access restriction |
| B20 | Live change detection | ⊘ | Development convenience |
| B21 | Invocation matrix | ✅ N/A | `/tdd-plan` = `disable-model-invocation: true` (user only). Conventions = `user-invocable: false` (Claude only) |
| B22 | Subdirectory discovery | ⊘ | Not a monorepo plugin |
| B23 | Char budget | ⊘ | 9 skills within 2% budget; no override needed |
| B24 | Bundled skills | ⊘ | Claude Code built-in skills; not features for the plugin to adopt |

---

### Category C — Hooks

#### Hook Events

| # | Event | Status | Notes |
|---|-------|--------|-------|
| C1 | `SessionStart` | ⊘ | Could detect in-progress TDD sessions. Low priority — planner completes in one context window. **→ N2** |
| C2 | `InstructionsLoaded` | ⊘ | Not relevant to TDD workflow |
| C3 | `UserPromptSubmit` | ⊘ | Not relevant to TDD workflow |
| C4 | `PreToolUse` | ✅ | Implementer: `validate-tdd-order.sh` on `Write\|Edit\|MultiEdit`. Planner: `planner-bash-guard.sh` on `Bash`. Both also in `hooks.json` with `agent_type` guards for marketplace installs |
| C5 | `PermissionRequest` | ⊘ | `permissionMode: plan` on read-only agents eliminates dialogs |
| C6 | `PostToolUse` | ✅ | Implementer: `auto-run-tests.sh` on `Write\|Edit\|MultiEdit`. Also in `hooks.json` with `agent_type` guard for marketplace installs |
| C7 | `PostToolUseFailure` | ⊘ | No failure recovery logic needed |
| C8 | `Notification` | ⊘ | Desktop notification on slice completion would improve UX. **→ N1** |
| C9 | `SubagentStart` | ✅ | Context-updater: git branch, last commit, dirty file count via `additionalContext`. Tdd-planner: git context (branch, last commit, dirty file count) added in v1.14.0 |
| C10 | `SubagentStop` | ✅ | `hooks.json`: prompt hook on `tdd-implementer` validates R-G-R cycle. Command hooks on `tdd-releaser` and `tdd-doc-finalizer` validate branch pushed. Prompt hooks on `tdd-verifier` and `context-updater` added in v1.14.0 (total: 5 SubagentStop entries) |
| C11 | `Stop` | ✅ | Main thread: `check-tdd-progress.sh` prevents session end with pending slices. Agent frontmatter: verifier prompt check, releaser/doc-finalizer command check, context-updater prompt check |
| C12 | `TeammateIdle` | ⊘ | No agent teams |
| C13 | `TaskCompleted` | ⊘ | Not relevant |
| C14 | `ConfigChange` | ⊘ | Not relevant to TDD workflow |
| C15 | `WorktreeCreate` | ⊘ | No custom VCS needed |
| C16 | `WorktreeRemove` | ⊘ | No custom VCS needed |
| C17 | `PreCompact` | ⊘ | Low priority |
| C18 | `PostCompact` | ⊘ | Not relevant |
| C19 | `Elicitation` | ⊘ | No MCP servers |
| C20 | `ElicitationResult` | ⊘ | No MCP servers |
| C21 | `SessionEnd` | ⊘ | No cleanup needed |

#### Hook Types

| # | Type | Status | Notes |
|---|------|--------|-------|
| C22 | `command` | ✅ | All file-based hooks: validate-tdd-order, auto-run-tests, check-tdd-progress, planner-bash-guard, check-release-complete |
| C23 | `http` | ⊘ | No remote endpoints; all validation is local |
| C24 | `prompt` | ✅ | Verifier Stop hook, implementer SubagentStop, context-updater Stop hook |
| C25 | `agent` | ⊘ | Too expensive — spawns subagent for validation |

#### Hook Handler Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| C26 | `type` | ✅ | All hooks specify type |
| C27 | `command` | ✅ | Script paths use `${CLAUDE_PLUGIN_ROOT}` |
| C28 | `url` | ⊘ | No HTTP hooks |
| C29 | `headers` | ⊘ | No HTTP hooks |
| C30 | `allowedEnvVars` | ⊘ | No HTTP hooks |
| C31 | `prompt` | ✅ | Verifier Stop, implementer SubagentStop, context-updater Stop |
| C32 | `model` | ⊘ | Default model sufficient for prompt hooks |
| C33 | `timeout` | ✅ | Set on SubagentStop (30s implementer, 15s releaser/doc-finalizer), Stop (10s), SubagentStart (5s) |
| C34 | `statusMessage` | ⊘ | Default spinner adequate |
| C35 | `once` | ⊘ | No one-time initialization needed |
| C36 | `async` | ⊘ | Sequential execution |

#### Hook Variables & Protocol

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| C37 | `$ARGUMENTS` | ✅ | SubagentStop prompt hooks use `$ARGUMENTS` |
| C38 | `$CLAUDE_PROJECT_DIR` | ⊘ | Using `${CLAUDE_PLUGIN_ROOT}` instead (plugin context) |
| C39 | `${CLAUDE_PLUGIN_ROOT}` | ✅ | All hook commands use this for portable paths |
| C40 | `${CLAUDE_PLUGIN_DATA}` | ⊘ | No persistent plugin data needed yet |
| C41 | `$CLAUDE_ENV_FILE` | ⊘ | No env var persistence needed |
| C42 | `$CLAUDE_CODE_REMOTE` | ⊘ | No remote-specific behavior |
| C43 | Exit code 0 | ✅ | Used in all command hooks |
| C44 | Exit code 2 | ✅ | Used in validate-tdd-order, check-tdd-progress, check-release-complete, planner-bash-guard |
| C45 | Other exit codes | ✅ N/A | Not used; understood |
| C46 | `stop_hook_active` | ✅ | `check-tdd-progress.sh` and `check-release-complete.sh` check this to prevent infinite loops |
| C47 | `last_assistant_message` | ⊘ | Not needed — prompt hooks handle context retrieval |

#### JSON Output

| Feature | Status | Notes |
|---------|--------|-------|
| `systemMessage` | ✅ | `auto-run-tests.sh` returns test output as systemMessage |
| `decision`/`reason` | ✅ | `check-tdd-progress.sh` returns `{"decision": "block", "reason": ...}` |
| `additionalContext` | ✅ | SubagentStart hook for context-updater injects git context |
| `updatedInput` | ⊘ | No need to modify tool parameters |
| `hookSpecificOutput` | ⊘ | Not using event-specific control beyond standard patterns |

---

### Category D — Plugins

#### Manifest Fields

| # | Field | Status | Notes |
|---|-------|--------|-------|
| D1 | `name` | ✅ | `"tdd-workflow"` |
| D2 | `version` | ✅ | `"1.14.0"` |
| D3 | `description` | ✅ | Present and descriptive |
| D4-D8 | Metadata | ⊘ | Optional; add when publishing to marketplace |
| D9-D11 | Component paths | ⊘ | Using default directory conventions |
| D12-D15 | Config paths | ⊘ | Using default locations |

#### Plugin Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| D16 | `${CLAUDE_PLUGIN_ROOT}` | ✅ | Used in all hook commands |
| D17 | `${CLAUDE_PLUGIN_DATA}` | ⊘ | No persistent data needed (no npm/pip deps, no caches) |
| D18 | Scopes | ⊘ | Depends on installation method; no explicit recommendation yet |
| D19 | Namespacing | ✅ N/A | Skills auto-namespaced as `/tdd-workflow:tdd-plan` etc. |
| D20 | `--plugin-dir` | ⊘ | Dev convenience; documented in README |
| D21 | Plugin caching | ✅ N/A | Handled automatically by Claude Code |
| D22 | CLI commands | ✅ N/A | `claude plugin install <path>` documented in README |
| D23 | Marketplace sources | ⊘ | Not yet published |
| D24 | LSP servers | ⊘ | Could add Dart/C analysis server; complexity vs benefit |
| D25 | `strict: false` | ⊘ | Not in a marketplace |
| D26 | Plugin `settings.json` | ⊘ | No default settings needed; only `agent` supported and not applicable |
| D27 | Plugin agent restrictions | ✅ | **Mitigated** — see §3 item M1 (resolved in v1.14.0). Same as A27 |
| D28 | Path traversal | ✅ N/A | All paths are within plugin directory |

#### Directory Structure

```
tdd-workflow/                               Status
├── .claude-plugin/
│   └── plugin.json                         ✅
├── agents/
│   ├── tdd-planner.md                      ✅
│   ├── tdd-implementer.md                  ✅
│   ├── tdd-verifier.md                     ✅
│   ├── tdd-releaser.md                     ✅
│   ├── tdd-doc-finalizer.md                ✅
│   └── context-updater.md                  ✅
├── skills/
│   ├── tdd-plan/
│   │   ├── SKILL.md                        ✅
│   │   └── reference/  (2 templates)       ✅
│   ├── tdd-implement/
│   │   └── SKILL.md                        ✅
│   ├── tdd-release/
│   │   ├── SKILL.md                        ✅
│   │   └── reference/  (version-control)   ✅
│   ├── tdd-finalize-docs/
│   │   └── SKILL.md                        ✅
│   ├── tdd-update-context/
│   │   └── SKILL.md                        ✅
│   ├── dart-flutter-conventions/
│   │   ├── SKILL.md                        ✅
│   │   └── reference/  (6 files)           ✅
│   ├── cpp-testing-conventions/
│   │   ├── SKILL.md                        ✅
│   │   └── reference/  (4 files)           ✅
│   ├── bash-testing-conventions/
│   │   ├── SKILL.md                        ✅
│   │   └── reference/  (2 files)           ✅
│   └── c-conventions/
│       ├── SKILL.md                        ✅
│       └── reference/  (3 files)           ✅
├── hooks/
│   ├── hooks.json                          ✅
│   ├── validate-tdd-order.sh               ✅
│   ├── auto-run-tests.sh                   ✅
│   ├── check-tdd-progress.sh              ✅
│   ├── planner-bash-guard.sh               ✅
│   ├── validate-plan-output.sh             ✅
│   └── check-release-complete.sh           ✅
├── scripts/
│   ├── detect-project-context.sh           ✅
│   ├── detect-doc-context.sh               ✅
│   └── bump-version.sh                     ✅
├── docs/
│   ├── extensibility/                      ✅
│   ├── prompts/                            ✅
│   ├── archive/                            ✅
│   ├── dev-roles/                          ✅
│   ├── reference/                          ✅
│   ├── plugin-developer-context.md         ✅
│   ├── marketplace-survey-2026-03-09.md    ✅
│   └── user-guide.md                       ✅
├── CLAUDE.md                               ✅
├── CHANGELOG.md                            ✅
├── README.md                               ✅
└── LICENSE                                 ✅
```

---

### Category E — Memory / CLAUDE.md

#### Memory Locations

| # | Type | Status | Notes |
|---|------|--------|-------|
| E1 | Managed policy | ⊘ | Enterprise feature |
| E2 | Project memory | ✅ | `CLAUDE.md` at plugin root documents full workflow |
| E3 | Project rules (`.claude/rules/`) | ⊘ | Plugin uses CLAUDE.md directly; rules directory is for consuming projects |
| E4 | User memory | ⊘ | Personal preferences |
| E5 | User rules | ⊘ | Personal preferences |
| E6 | Local memory (`CLAUDE.local.md`) | ⊘ | No machine-specific overrides |
| E7 | Auto memory | ⊘ | Plugin relies on explicit `memory: project` on agents, not auto-memory |

#### Memory Features

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| E8 | `@import` syntax | ⊘ | CLAUDE.md is self-contained; no imports needed |
| E9 | Path-specific rules | ⊘ | Plugin doesn't ship rules; consuming projects can add their own |
| E10 | Auto memory (200-line limit) | ✅ N/A | Agent memory (A9) uses this mechanism — first 200 lines of MEMORY.md auto-included |
| E11 | `/memory` command | ⊘ | Built-in, not a plugin concern |
| E12 | `/init` command | ⊘ | Built-in, not a plugin concern |
| E13 | `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | ⊘ | Not relevant |
| E14 | `autoMemoryEnabled` | ⊘ | Consumer setting |
| E15 | `autoMemoryDirectory` | ⊘ | Consumer setting |
| E16 | Child directory discovery | ⊘ | No subdirectory CLAUDE.md files |
| E17 | `--add-dir` + CLAUDE.md | ⊘ | Not relevant |
| E18 | `claudeMdExcludes` | ⊘ | Consumer setting for monorepos |
| E19 | `InstructionsLoaded` hook | ⊘ | Not relevant to TDD workflow |
| E20 | Symlinks in rules | ⊘ | Plugin doesn't ship rules files |

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
| F6 | `permissions.disableBypassPermissionsMode` | ⊘ | Consumer setting |

#### Key Settings

| # | Setting | Status | Notes |
|---|---------|--------|-------|
| F7 | `model` | ⊘ | Agents set their own model in frontmatter |
| F8-F10 | Model config | ⊘ | Consumer-side model configuration |
| F11 | `hooks` | ✅ | Plugin ships `hooks/hooks.json` |
| F12 | `env` | ⊘ | No environment variables needed |
| F13 | `agent` | ⊘ | TDD agents are task-specific, not session-wide |
| F14-F33 | Other settings | ⊘ | Consumer preferences; not plugin concerns |
| F26 | `$schema` | ✅ | `hooks.json` has `$schema` |

#### Managed-Only Settings

| # | Setting | Status | Notes |
|---|---------|--------|-------|
| F34-F39 | All | ⊘ | Enterprise features; not plugin concerns |

#### Sandbox Settings

| # | Setting | Status | Notes |
|---|---------|--------|-------|
| F40-F57 | All | ⊘ | Consumer settings; plugin hooks are compatible with sandboxed execution |

#### Environment Variables

| # | Variable | Status | Notes |
|---|----------|--------|-------|
| F58-F69 | All | ⊘ | Consumer-side overrides; agents set model in frontmatter |

---

## 2. Implementation Status

### What changed since the v1.6.6 audit

The v1.6.6 audit was written against the v2.1 feature inventory. Since then:

| Change | Version |
|--------|---------|
| Generalized doc-finalizer: own agent, own skill | v1.7.0–v1.10.0 |
| Added bump-version.sh, detect-doc-context.sh | v1.11.0–v1.12.0 |
| Model assignments: doc-finalizer=sonnet, context-updater=opus | v1.12.0 |
| C language conventions: Unity/CMock, BARR-C:2018, SEI CERT C, static analysis | v1.13.0 |
| 617 tests, 875 assertions (from 237/298 at v1.6.6) | v1.13.0 |
| Plugin agent hook mitigation: agent_type guards + hooks.json dual delivery | v1.14.0 |
| SubagentStart for tdd-planner (git context), SubagentStop for verifier + context-updater | v1.14.0 |
| 691 tests, 970 assertions (+74 tests) | v1.14.0 |

### All items from v1.6.6 audit

| Item | Status |
|------|--------|
| P1: Set `model: opus` on tdd-planner and tdd-implementer | ✅ v1.1.0 |
| M1: Add planner Bash guard hook | ✅ v1.3.0 |
| M2: Add planner Stop hook (plan output validator) | ✅ v1.3.0 |
| S1: Add `memory: project` to tdd-planner | ✅ v1.4.0 |
| S2: Add SubagentStop hook for planner | ✅ v1.3.0 |
| S3: Add `additionalContext` via SubagentStart | ✅ v1.4.0 |
| S4: Add dynamic context injection to /tdd-plan | ✅ v1.4.0 (via script, not `!` backtick) |
| S5: Implement git auto-commit (Layer 1) | ✅ v1.5.0 |
| S6: Implement branch creation (Layer 2) | ✅ v1.5.0 |
| N1: Add `argument-hint` to /tdd-plan | ✅ v1.1.0 |
| N2: Add `user-invocable: false` to convention skills | ✅ v1.1.0 |
| N3: Add Notification hooks on slice completion | Open |
| N4: Add SessionStart hook for TDD session detection | Open |
| N5: Add `$schema` to hooks.json | ✅ v1.1.0 |
| N6: Implement release workflow (Layer 3) | ✅ v1.6.0 |

---

## 3. Prioritized Remaining Work

### M — Must-Have (Correctness / Safety)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| M1 | ~~**Mitigate plugin agent restrictions**~~ | ~~Medium~~ | **Resolved in v1.14.0.** `agent_type` guards added to all 3 enforcement scripts; all hooks duplicated in `hooks.json` (PreToolUse ×2, PostToolUse ×1, SubagentStop ×5, SubagentStart ×2). `permissionMode: plan` loss accepted — `tools` allowlist is equivalent. | A27, D27 |

### S — Should-Have (Quality / Robustness)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| S1 | ~~**Add SubagentStart git context for planner**~~ | ~~5 lines~~ | **Resolved in v1.14.0.** `hooks.json` SubagentStart for tdd-planner added, providing branch, last commit, and dirty file count | C9 |
| S2 | ~~**Add SubagentStop hook for verifier in hooks.json**~~ | ~~10 lines~~ | **Resolved in v1.14.0.** `hooks.json` SubagentStop for tdd-verifier and context-updater both added | C10 |

### N — Nice-to-Have (Distribution / UX)

| # | Item | Effort | Rationale | Ref |
|---|------|--------|-----------|-----|
| N1 | **Add Notification hooks on slice completion** | ~5 lines | Desktop notifications for long multi-slice sessions | C8 |
| N2 | **Add SessionStart hook for TDD session detection** | ~10 lines | Detect `.tdd-progress.md` and inject state reminder | C1 |
| N3 | **Add plugin manifest metadata (author, repository, keywords)** | ~10 lines | Prepare for marketplace publication | D4-D8 |

---

## 4. Revised Component Specifications

### 4.1 Mitigate Plugin Agent Restrictions (M1) — RESOLVED in v1.14.0

**Problem:** When installed as a marketplace plugin, agent frontmatter `hooks`
and `permissionMode` fields are silently ignored. This is a Claude Code
security design — plugin agents cannot escalate permissions or inject hooks.

**Solution implemented (v1.14.0):** Dual delivery via `agent_type` guards.

All three enforcement hook scripts (`planner-bash-guard.sh`,
`validate-tdd-order.sh`, `auto-run-tests.sh`) now extract `agent_type` from
the hook input JSON. If `agent_type` is non-empty and does not match the
target agent (in either namespaced `tdd-workflow:tdd-planner` or plain
`tdd-planner` format), the script exits 0 silently. This allows all three
scripts to be safely registered in `hooks.json` as session-level hooks
without interfering with other agents.

**`hooks.json` entries added:**
- PreToolUse: Bash matcher → `planner-bash-guard.sh` (timeout 5)
- PreToolUse: Write|Edit|MultiEdit matcher → `validate-tdd-order.sh` (timeout 10)
- PostToolUse: Write|Edit|MultiEdit matcher → `auto-run-tests.sh` (timeout 30)
- SubagentStop: `tdd-verifier` → prompt hook (timeout 30)
- SubagentStop: `context-updater` → prompt hook (timeout 30)
- SubagentStart: `tdd-planner` → git context (branch, last commit, dirty files)

**`permissionMode: plan` loss:** Accepted as non-issue. The `tools` allowlist
on planner and verifier agents already restricts them to read-only tools,
providing equivalent protection without requiring `permissionMode`.

**Agent frontmatter hooks:** Preserved unchanged. Both delivery paths coexist;
Claude Code deduplicates identical command hooks automatically.

**Current hooks.json summary:** PreToolUse (2), PostToolUse (1),
SubagentStop (5), SubagentStart (2), Stop (1).

### 4.2 SubagentStart Git Context for Planner (S1)

**`hooks/hooks.json`** — add entry to `SubagentStart` array:

```json
{
  "matcher": "tdd-planner",
  "hooks": [
    {
      "type": "command",
      "command": "echo \"{ \\\"additionalContext\\\": \\\"Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown'). Last commit: $(git log --oneline -1 2>/dev/null || echo 'none'). Dirty files: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ').\\\"}\""  ,
      "timeout": 5
    }
  ]
}
```

### 4.3 SubagentStop Hook for Verifier (S2)

**`hooks/hooks.json`** — add entry to `SubagentStop` array:

```json
{
  "matcher": "tdd-verifier",
  "hooks": [
    {
      "type": "prompt",
      "prompt": "The tdd-verifier has finished. Evaluate: $ARGUMENTS\n\nCheck:\n1. Did the verifier run the COMPLETE test suite (not just new tests)?\n2. Did it run static analysis (dart analyze, shellcheck, cppcheck, or equivalent)?\n3. Did it report a clear PASS or FAIL verdict?\n\nIf any check fails, respond with {\"decision\": \"block\", \"reason\": \"<what's missing>\"}.\nIf all checks pass, respond with {\"decision\": \"allow\"}.",
      "timeout": 30
    }
  ]
}
```

---

## 5. New Features Assessment (v3.0 additions)

Features new in the v3.0 inventory that weren't in v2.1, assessed for
relevance to this plugin:

| Feature | Relevant? | Assessment |
|---------|-----------|------------|
| A12 `background` | No | TDD is sequential |
| A13 `isolation` (worktree) | No | Agents share files |
| A24 @-mention | N/A | Works automatically |
| A25 `--agent` / `agent` setting | No | Task-specific agents |
| A27 Plugin agent restrictions | **Yes — Critical** | See M1 |
| B14 `${CLAUDE_SKILL_DIR}` | No | Relative paths sufficient |
| B24 Bundled skills | No | Built-in features |
| C2 `InstructionsLoaded` | No | Not relevant |
| C14 `ConfigChange` | No | Not relevant |
| C15-C16 `WorktreeCreate/Remove` | No | No custom VCS |
| C18 `PostCompact` | No | Not relevant |
| C19-C20 `Elicitation*` | No | No MCP servers |
| C23 `http` hook type | No | All validation is local |
| C40 `${CLAUDE_PLUGIN_DATA}` | No | No persistent data needed |
| C47 `last_assistant_message` | No | Prompt hooks handle context |
| D17 `${CLAUDE_PLUGIN_DATA}` | No | No npm/pip/cache deps |
| D26 Plugin `settings.json` | No | No default settings needed |
| E14-E15 Auto memory settings | No | Consumer settings |
| E18 `claudeMdExcludes` | No | Consumer setting |
| F8 `availableModels` | No | Agents set own model |
| F9 `modelOverrides` | No | Consumer setting |
| F40-F57 Expanded sandbox | No | Hooks compatible as-is |

---

## 6. Correctly Excluded Features (Complete)

| # | Feature | Reason |
|---|---------|--------|
| A10 | `mcpServers` | No MCP servers provide value for TDD workflow |
| A12 | `background` | TDD phases are sequential by design |
| A13 | `isolation` (worktree) | Agents work on shared files; isolation would break workflow |
| A14 | Subagent resumption | Single-pass planner; orchestrated-per-slice implementer |
| A15 | `Agent(agent_type)` restriction | Only for `--agent` main thread mode |
| A16 | Agent teams | Sequential execution; teams multiply tokens |
| A19 | Background execution | TDD phases sequential by design |
| A20 | Auto-compaction override | Default compaction sufficient |
| A21 | CLI-defined subagents | Plugin provides filesystem agents |
| A23 | Disable subagents | No agents need disabling |
| A25 | `--agent` / `agent` setting | Task-specific agents, not session-wide |
| A28 | Transcript persistence config | Default cleanup sufficient |
| B6 | `allowed-tools` (skill) | Agent restrictions take precedence |
| B7 | `model` (skill) | Agent frontmatter sets model |
| B10 | `hooks` (skill) | Agent frontmatter hooks handle this |
| B12 | `$ARGUMENTS[N]` / `$N` | Single-argument invocation |
| B13 | `${CLAUDE_SESSION_ID}` | No session-specific artifacts |
| B14 | `${CLAUDE_SKILL_DIR}` | Relative paths sufficient |
| B19 | `Skill()` permission | No skills need restriction |
| B20 | Live change detection | Development convenience |
| B22 | Subdirectory discovery | Not a monorepo |
| B23 | Char budget override | 9 skills within budget |
| B24 | Bundled skills | Claude Code built-in features |
| C2 | `InstructionsLoaded` | Not relevant to TDD |
| C3 | `UserPromptSubmit` | Not relevant |
| C5 | `PermissionRequest` | `permissionMode: plan` eliminates dialogs |
| C7 | `PostToolUseFailure` | No failure recovery needed |
| C12 | `TeammateIdle` | No agent teams |
| C13 | `TaskCompleted` | Not relevant |
| C14 | `ConfigChange` | Not relevant |
| C15-C16 | `WorktreeCreate/Remove` | No custom VCS |
| C17-C18 | `PreCompact/PostCompact` | Not relevant |
| C19-C20 | `Elicitation*` | No MCP servers |
| C21 | `SessionEnd` | No cleanup needed |
| C23 | `http` hook type | All validation is local |
| C25 | Hook type: `agent` | Too expensive for validation |
| C28-C30 | HTTP hook fields | No HTTP hooks |
| C32 | `model` (hook) | Default model sufficient |
| C34 | `statusMessage` | Default spinner adequate |
| C35 | `once` | No one-time init |
| C36 | `async` | Sequential execution |
| C40 | `${CLAUDE_PLUGIN_DATA}` | No persistent plugin data |
| C41 | `$CLAUDE_ENV_FILE` | No env persistence needed |
| C42 | `$CLAUDE_CODE_REMOTE` | No remote-specific behavior |
| C47 | `last_assistant_message` | Prompt hooks handle context |
| D4-D8 | Manifest metadata | Optional; add when publishing |
| D9-D15 | Manifest path overrides | Using default directory conventions |
| D17 | `${CLAUDE_PLUGIN_DATA}` | No persistent data needed |
| D23 | Marketplace sources | Not yet published |
| D24 | LSP servers | Complexity vs benefit |
| D25 | `strict: false` | Not in marketplace |
| D26 | Plugin `settings.json` | No default settings needed |
| E1 | Managed policy | Enterprise feature |
| E3-E5 | Rules directories | Plugin uses CLAUDE.md; rules for consuming projects |
| E6 | Local memory | No machine-specific overrides |
| E7 | Auto memory (plugin level) | Using explicit agent memory |
| E8 | `@import` | CLAUDE.md self-contained |
| E9 | Path-specific rules | Plugin doesn't ship rules |
| E11-E19 | Memory commands/settings | Built-in features or consumer settings |
| E20 | Symlinks in rules | Plugin doesn't ship rules |
| F1-F6 | Permission settings | Agent restrictions sufficient |
| F7-F10 | Model settings | Agent frontmatter sets model |
| F12-F33 | Other settings | Consumer preferences |
| F34-F39 | Managed-only settings | Enterprise features |
| F40-F57 | Sandbox settings | Consumer settings; hooks compatible |
| F58-F69 | Environment variables | Consumer-side overrides |

---

*Audit completed 2026-03-18 against v3.0 feature inventory.*
*Plugin version: 1.13.0. 6 agents, 9 skills, 7 hook scripts, 3 utility scripts.*
*617 tests, 875 assertions.*
*Critical finding: A27/D27 plugin agent restrictions affect all 6 agents.*
*Next audit: after M1 mitigation is implemented.*
