# Roles vs Anthropic's Conceptual Framework

> **Date:** 2026-03-19
> **Plugin version:** 1.14.1
> **Documentation source:** https://code.claude.com/docs/en/ (fetched 2026-03-19)
> **Related:** `role-to-agent-analysis.md` (same directory)

---

## Key Takeaway: Anthropic Has No "Role" Concept

Anthropic never uses the words "role", "persona", or "session identity" in
the Claude Code documentation. They provide **primitives** that can compose
into roles, but don't name the pattern:

| Our Concept | Anthropic's Primitive | Their Terminology |
|---|---|---|
| Role definition | Subagent `.md` file | "subagent" / "agent" |
| Role activation | `--agent` flag / `agent` setting (F13) | "run the main thread as a subagent" |
| Role constraints | `tools` + `disallowedTools` | "enforce constraints" / "tool restrictions" |
| Role knowledge | `skills` preloading (A8) | "specialize behavior" |
| Role enforcement | hooks + `agent_type` filtering | (no named pattern) |
| Role context | CLAUDE.md | "behavioral guidance" |
| Multi-role collaboration | Agent teams (experimental) | "team lead" / "teammates" |

---

## Critical Gotchas from the Docs

### 1. System prompt replacement

`--agent` replaces the default Claude Code system prompt **entirely**. The
subagent's markdown body becomes the system prompt. CLAUDE.md files still
load as user messages (not system prompt), so they survive, but built-in
instructions about tool usage, output formatting, etc. are gone. You must
provide everything the agent needs in your system prompt body.

> "The subagent's system prompt replaces the default Claude Code system
> prompt entirely, the same way `--system-prompt` does. CLAUDE.md files and
> project memory still load through the normal message flow."

### 2. CLAUDE.md is advisory, not enforced

The docs are explicit that CLAUDE.md is not a hard constraint mechanism:

> "CLAUDE.md content is delivered as a user message after the system prompt,
> not as part of the system prompt itself. Claude reads it and tries to
> follow it, but there's no guarantee of strict compliance, especially for
> vague or conflicting instructions."

> "Settings rules are enforced by the client regardless of what Claude
> decides to do. CLAUDE.md instructions shape Claude's behavior but are not
> a hard enforcement layer."

For hard constraints, tool restrictions (`tools`/`disallowedTools`) and
hooks with exit code 2 are the only enforcement mechanisms.

### 3. No "sole writer" concept for shared state

Anthropic's memory model is per-subagent (`memory: user|project|local`).
There's no built-in concept of one session owning shared state. Our
CA-owns-MEMORY.md pattern is a convention we invented, not something the
framework supports or enforces.

### 4. No inter-session communication

Outside experimental agent teams, Claude Code sessions can't talk to each
other. Our human-mediated handoff pattern (CA tells CI "proceed with
`/tdd-implement`") has no mechanical equivalent in the framework. Agent
teams provide inter-agent messaging but are experimental and disabled by
default (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).

### 5. Plugin agent restrictions (A27/D27)

Plugin subagents cannot use `hooks`, `mcpServers`, or `permissionMode` in
frontmatter — these are silently ignored. This means any role-as-plugin-agent
loses soft enforcement (hooks) and permission mode constraints. Only `tools`
and `disallowedTools` survive.

---

## Where We Align with Anthropic

- **Subagent definitions as specialized behavior** — our 6 work agents
  (planner, implementer, verifier, releaser, doc-finalizer, context-updater)
  are textbook subagent usage
- **`tools` allowlist as primary constraint** — confirmed as the correct
  mechanism over `permissionMode` for plugin agents
- **Skills preloading for domain knowledge** — our convention skills loaded
  into agents via the `skills` field
- **hooks.json + `agent_type` for enforcement** — the Issue 004/005 pattern
  is the correct approach for plugin-safe hook enforcement

---

## Where We Diverge from Anthropic

### Session architecture

**Anthropic's model:** One orchestrating session with delegated subagents.
The main thread spawns subagents for specific tasks; they run autonomously
and return results.

**Our model:** Three peer sessions (CA, CP, CI) with human-mediated
coordination. Each session has its own context window and identity. The
human developer switches between terminals and carries context verbally.

### Memory ownership

**Anthropic's model:** Per-agent memory scopes. Each subagent with
`memory: project` gets its own `MEMORY.md` in
`.claude/agent-memory/<name>/`.

**Our model:** CA is the sole memory writer. MEMORY.md is a cross-session
coordination artifact, not per-agent state. CP and CI read but never write.

### Identity persistence

**Anthropic's model:** The `agent` setting (F13) persists across session
resumes. The `--agent` flag sets it for the current session. Identity is
a configuration, not a conversation-level concept.

**Our model:** Roles are *session identity documents* — they define "who
the session is" across many interactions. The developer pastes or references
the role prompt at session start. Identity is conversational context, not
configuration.

### Constraint philosophy

**Anthropic's model:** Hard enforcement via tool restrictions and hooks.
CLAUDE.md is explicitly advisory. "Enforce constraints by limiting which
tools a subagent can use."

**Our model:** Convention-based trust. Constraints are defined in prose
(role documents) and followed because the developer chose that role. Only
the work agents have hard enforcement (tool allowlists, hooks).

---

## Mapping Our Vocabulary to Theirs

If we adopt Anthropic's vocabulary, our concepts translate as:

| What we say | What Anthropic would say |
|---|---|
| "Become CA" | `claude --agent ca-architect` |
| "Role definition" | "Subagent definition file" |
| "Role constraints" | "Tool restrictions" |
| "Role prompt" | "System prompt" (for `--agent`) or "CLAUDE.md instructions" (advisory) |
| "Three-session model" | No equivalent (closest: agent teams, experimental) |
| "CA owns memory" | No equivalent (per-agent memory is independent) |
| "Handoff to CI" | No equivalent outside agent teams |

---

## Implications for Future Work

### `/tdd-init-roles` concept

The skill would generate subagent definition files that can be used with
`--agent`. This aligns with Anthropic's framework: the output IS a subagent
file, it just serves a purpose (session identity) that Anthropic doesn't
name.

### Agent teams as future path

When agent teams stabilize, they could replace the manual three-terminal
pattern. The "team lead" maps loosely to CA, teammates to CP/CI. But the
current experimental status and fixed architecture (one lead, N workers)
doesn't map perfectly to our peer model.

### The naming gap is an opportunity

Anthropic provides primitives but no "role" abstraction. If `tdd-init-roles`
generates well-structured subagent files with clear identity, constraints,
and knowledge preloading, it's defining a pattern that Anthropic hasn't
named yet. The plugin could be opinionated about what a "role" means on
top of Anthropic's primitives.
