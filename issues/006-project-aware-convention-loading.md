# Issue 006: Project-Aware Convention Loading

## Problem

The plugin's work agents (planner, implementer, context-updater) hardcode
all 4 convention skills in their `skills:` frontmatter:

```yaml
skills:
  - dart-flutter-conventions
  - cpp-testing-conventions
  - bash-testing-conventions
  - c-conventions
```

This preloads the **full content** of every convention skill into the
agent's context at startup — regardless of the project's actual tech stack.
A Rust + ROS 2 project gets Dart widget testing patterns, C BARR-C coding
standards, C++ GoogleTest recipes, and Bash shellcheck guides loaded into
every agent invocation. All irrelevant, all consuming tokens.

### Current Scale

4 convention skills, 18 reference files, 5,453 lines of reference content.
Three agents preload all of them. That's ~16,000 lines of convention content
loaded per feature (planner + implementer + context-updater), most of which
is irrelevant to any given project.

### Scaling Problem

Every new convention skill added (Rust, Python, Go, TypeScript, etc.) gets
hardcoded into every agent's `skills:` field. The context cost grows
linearly with the number of supported languages. At 8 conventions the
context budget becomes a real constraint; at 12+ it's untenable.

### Why This Blocks Other Work

- **`/tdd-init-roles`** — can't generate effective roles if agents
  underneath are loaded with irrelevant conventions. The role context says
  "this is a Rust project" but the planner is thinking about Dart patterns.
- **Future convention skills** — adding Rust, Python, or Go conventions
  requires touching all 3 agent frontmatter files and makes the problem
  worse.
- **Agent memory quality** — agents with `memory: project` accumulate
  learnings. Irrelevant convention content pollutes what they learn and
  remember.
- **Token cost** — unnecessary convention content burns tokens on every
  agent invocation with no benefit.

## Constraints

### Subagent skill loading

From the Claude Code docs:

> "Subagents don't inherit skills from the parent conversation; you must
> list them explicitly."

This means we cannot simply remove `skills:` from agent frontmatter and
rely on auto-invocation. Subagents have no skill discovery mechanism —
if a convention isn't in the `skills:` field, the agent doesn't know it
exists.

### Convention skill auto-invocation (main thread only)

Convention skills have `user-invocable: false` and description-based
triggers (e.g., "Triggers on: `.dart` files"). In the main thread, Claude
auto-loads them when it encounters relevant files. This mechanism does NOT
work inside subagents.

### Agent frontmatter is static

The `skills:` field in agent frontmatter is a static list. There is no
conditional logic, no variable substitution, no "load if project type
matches" mechanism. Whatever is listed is preloaded unconditionally.

### Plugin agent restrictions (A27/D27)

Plugin agents cannot use `hooks`, `mcpServers`, or `permissionMode` in
frontmatter. The `skills` field IS supported — this constraint doesn't
block convention loading, but it limits other mitigation strategies.

## Candidate Approaches

### A. Dynamic skill injection via skill body

The orchestration skills (`/tdd-plan`, `/tdd-implement`) run in the main
thread before spawning agents. They could detect the project type and
inject only relevant conventions into the agent's context via the skill
body text, rather than relying on frontmatter preloading.

**Pros:** No agent frontmatter changes, project-aware, scales to N languages.
**Cons:** Convention content goes through the skill body (context injection)
rather than the `skills:` mechanism. Need to verify whether skill body
content is visible to forked subagents.

### B. Project-type detection + per-language agent variants

Ship language-specific agent variants (e.g., `tdd-planner-dart.md`,
`tdd-planner-cpp.md`) that preload only relevant conventions. The
orchestration skills detect project type and spawn the right variant.

**Pros:** Clean separation, each agent loads only what it needs.
**Cons:** Combinatorial explosion — 3 agents x N languages = 3N agent
files. Multi-language projects need a "generic" variant or multiple
conventions loaded. Maintenance burden scales quadratically.

### C. Convention meta-skill with dynamic context injection

Replace the 4 individual convention skills in agent frontmatter with a
single `project-conventions` meta-skill that uses dynamic context injection
(`` !`cmd` ``) to detect the project type at load time and include only
relevant convention content.

**Pros:** Single skill in frontmatter, project-aware, scales to N languages.
**Cons:** Dynamic context injection (`` !`cmd` ``) has known issues with
the permission system (documented as B15 partial in the audit). Need to
verify it works inside subagent skill preloading.

### D. Remove conventions from agent frontmatter, inject via SubagentStart

Use SubagentStart hooks to detect project type and inject relevant
convention content via `additionalContext`. The agents ship with no
`skills:` field (or only non-convention skills).

**Pros:** Fully dynamic, project-aware, no agent frontmatter changes when
adding languages.
**Cons:** SubagentStart `additionalContext` is a string injected into
context, not full skill content. Size limits unknown. Convention reference
files (18 files, 5,453 lines) may be too large for `additionalContext`.
The content wouldn't be structured as a skill with reference files.

### E. Strip conventions from frontmatter, rely on detect-project-context.sh

The planner already runs `detect-project-context.sh` as its first step.
This script could be extended to output which convention skills are
relevant. The agent's system prompt could then instruct it to read the
relevant convention SKILL.md and reference files directly via Read/Glob.

**Pros:** Uses existing infrastructure, no new mechanisms, scales to N
languages.
**Cons:** Agents spend turns reading convention files instead of having
them preloaded. Increases turn count and latency. Relies on the agent
following system prompt instructions to read the right files.

### F. Configuration file in consuming project

A `.tdd-workflow.json` or `.claude/tdd-workflow.json` file in the consuming
project specifies which conventions to use:

```json
{
  "conventions": ["rust-conventions", "bash-testing-conventions"]
}
```

The orchestration skills read this file and somehow pass it to agents.

**Pros:** Explicit, user-controlled, project-specific.
**Cons:** Requires a new configuration mechanism. The `skills:` field in
agent frontmatter is static — there's no way to read a config file and
dynamically modify it. Would need one of approaches A-E to actually
implement the loading.

## Research Findings (2026-03-19)

Documentation research across 10 Claude Code doc pages. Key findings:

### Confirmed mechanisms

| Mechanism | Works? | Evidence |
|---|---|---|
| `${CLAUDE_PLUGIN_DATA}` persistent cache | **Yes** | `~/.claude/plugins/data/{id}/`. No size limits. Survives plugin updates. Deleted only on uninstall from last scope |
| `SessionStart` hook for first-run fetch | **Yes** | Explicitly documented pattern: check cache, fetch if stale, store in `${CLAUDE_PLUGIN_DATA}` |
| `` !`cmd` `` dynamic context injection in skills | **Yes** (direct invocation) | Shell preprocessing before content sent to Claude. Output replaces placeholder |
| `SubagentStart` + `additionalContext` | **Yes** | No documented size limits. Supports matchers for agent-specific injection |
| Cross-plugin skill references | **Maybe** | `plugin-name:skill-name` namespace likely works but not explicitly documented |
| MCP server for convention content | **Yes** (with limits) | Plugin `.mcp.json`, but 25K token default limit (`MAX_MCP_OUTPUT_TOKENS`). Plugin agents can't set `mcpServers` in frontmatter (A27/D27) |

### Critical unknown — RESOLVED

Whether `` !`cmd` `` preprocessing runs when a skill is preloaded into a
subagent via the `skills:` field. **Answer: YES.**

Confirmed from Claude Code source (`@anthropic-ai/claude-code@2.1.79`):
there is no separate code path for preloading vs direct invocation. Both
go through `getPromptForCommand()`, which always calls the DCI preprocessor
(`LF()`). The call chain:

1. Subagent startup iterates the `skills` list
2. Each skill calls `skill.getPromptForCommand("", context)`
3. `getPromptForCommand` runs `$ARGUMENTS`, `${CLAUDE_SKILL_DIR}`,
   `${CLAUDE_SESSION_ID}` substitutions
4. DCI preprocessor runs, executing all `` !`cmd` `` patterns
5. Fully-rendered content injected into subagent context

**One caveat:** DCI commands run through the subagent's permission context.
Plugin subagents inherit parent permissions, so this works in practice.

**Source:** Claude Code source analysis + GitHub Issue #27736 (confirms
preloaded skills are fully rendered).

### Key constraints confirmed

- **Subagents can't discover skills** — "you must list them explicitly"
- **`skills:` field is static** — no variable substitution, no conditionals
- **Plugin agents lose `mcpServers` in frontmatter** (A27/D27)
- **`additionalDirectories` can't be set by plugins** — plugin `settings.json`
  only supports the `agent` key currently
- **No plugin dependency mechanism** — plugins can't declare "requires plugin X"

### Revised vision: externalized conventions

Rather than making the `skills:` field dynamic, the deeper solution is to
**externalize convention content entirely**:

1. Convention content lives in external GitHub repos, not shipped with the
   plugin
2. A `SessionStart` hook fetches relevant conventions to
   `${CLAUDE_PLUGIN_DATA}/conventions/` on first run
3. Content is injected into agents via `` !`cmd` `` (if it works in
   `skills:` preloading) or `SubagentStart` + `additionalContext`
4. Users can point to their own convention repos for any language/framework
5. The plugin ships the framework; convention content is dependency-injected

This transforms the plugin from language-specific to language-agnostic.
Adding Rust conventions becomes "point at a repo" not "modify plugin agents."

### Confirmed architecture

With `` !`cmd` `` working in preloaded skills, the clean path is:

```
SessionStart hook                    Agent startup
─────────────────                    ─────────────
Check ${CLAUDE_PLUGIN_DATA}/    →    skills: [project-conventions]
  conventions/ for cached files           │
If stale/missing: fetch from         !`load-conventions.sh`
  configured GitHub repos                 │
Store locally                        Reads cached files, detects
                                     project type, outputs only
                                     relevant conventions
                                          │
                                     Agent receives project-specific
                                     convention content ✓
```

**Components:**
1. `SessionStart` hook — fetches convention repos to `${CLAUDE_PLUGIN_DATA}/conventions/`
2. `skills/project-conventions/SKILL.md` — single skill replacing 4 hardcoded convention skills
3. `scripts/load-conventions.sh` — detects project type, reads cached content, outputs relevant conventions
4. Agent frontmatter changes — `skills: [project-conventions]` replaces `skills: [dart-flutter-conventions, cpp-testing-conventions, bash-testing-conventions, c-conventions]`

**What the plugin ships:** The framework only — agents, orchestration
skills, hooks, scripts. Zero convention content. The plugin is
language-agnostic.

**What lives externally:** All convention content (Dart, C++, C, Bash,
Rust, Python, etc.) lives in separate GitHub repos. The existing 4
convention skills move out of the plugin into their own repos as the
"official" convention packages — maintained by us but not bundled.

**What users configure:** Which convention repos to fetch, via a project
or user setting. `/tdd-init-roles` can set this up during project
initialization. If no conventions are configured, agents run without
convention context — they still work, they just don't have
language-specific patterns preloaded.

## Design Decisions (2026-03-19)

1. **Version 2.0** — this is a breaking change. No migration path. Clean
   slate for convention loading.

2. **Convention repo format** — move existing convention skills as-is to a
   new GitHub repo. Keep the current structure (SKILL.md + reference/ dir).
   Add a minimal index file listing available conventions. Format refinement
   is future work.

3. **Config format** — KISS. `.claude/tdd-conventions.json`:
   ```json
   {
     "conventions": [
       "https://github.com/tdd-workflow/conventions",
       "/home/user/my-conventions"
     ]
   }
   ```
   URLs = fetch and cache. Paths = read directly. That's it.

4. **No backward compatibility** — existing users update to v2.0 and
   configure their convention sources. The 4 built-in convention skills
   are removed from the plugin and published as an external repo.

## Acceptance Criteria

1. Agents load only conventions relevant to the project's tech stack
2. Adding a new convention skill does NOT require modifying agent
   frontmatter files
3. Multi-language projects (e.g., Flutter + C FFI) load all relevant
   conventions
4. Projects using languages without convention skills (e.g., Rust) load
   no conventions and pay no context cost
5. The solution works for both plugin installs (marketplace) and local
   development (`--plugin-dir`)
6. Existing convention skill content and structure are preserved — this
   is a loading mechanism change, not a content rewrite

## Impact Assessment

- **Severity:** Architectural — affects all agents, all skills, all
  current and future conventions
- **Urgency:** Blocks `/tdd-init-roles` and any new convention skills
- **Scope:** Agent frontmatter, orchestration skills, possibly hooks.json
- **Risk:** Medium — changes how agents receive domain knowledge, which
  affects plan and implementation quality

## Not In Scope

- Writing new convention skills (Rust, Python, etc.)
- Changing convention skill content or structure
- Modifying the convention skill auto-invocation mechanism for the main
  thread (that works correctly)
- `/tdd-init-roles` implementation (blocked by this issue)
- Convention scaffolding — a future `/tdd-create-convention` skill that
  helps users create new convention packages from scratch when no existing
  package exists for their language/framework (separate issue)
- Context-updater agent scope — currently exists to update convention
  reference files locally. With conventions externalized, its purpose needs
  rethinking (keep for plugin? useful for customers? still needed?).
  For this issue: just remove convention skills from its frontmatter like
  the other agents. Scope redesign is a separate decision.
