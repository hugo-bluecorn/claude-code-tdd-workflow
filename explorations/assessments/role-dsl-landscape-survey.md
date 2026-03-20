# Role/Prompt DSL Landscape Survey

> **Date:** 2026-03-20
> **Purpose:** Catalog concrete implementations of roles, personas, prompt DSLs, and structured session identity across the AI coding assistant ecosystem
> **Method:** GitHub search, web search, repository analysis
> **Scope:** Claude Code plugins, awesome repos, prompt/role DSLs, related ecosystems (Cursor, Copilot, Continue.dev, Aider, Windsurf)

---

## Executive Summary

The landscape is **rich but fragmented**. No single standard exists for defining AI agent roles. Instead, there are multiple partially-overlapping approaches at different abstraction levels:

1. **File-format standards** (Prompty, .prompt.yml, .prompt.md) focus on prompt serialization but have shallow role support (just a `system` message)
2. **Framework-level schemas** (LangGPT, GitAgent) attempt broader role definition with modules, composition, and identity
3. **Platform-native agent files** (Claude Code `.claude/agents/`, Copilot `.github/agents/`, Continue.dev config.yaml) define agent identity via YAML frontmatter + markdown body
4. **Identity separation patterns** (SOUL.md, IDENTITY.md, RULES.md) split "who" from "what" in agent configuration
5. **Role management tools** (claude-personas, persona) provide persona switching and activation

Our Role Definition Spec is **unique in combining**: session rationale, identity, responsibilities, anti-responsibilities, coordination protocol, state management, and project-specific context generation. No other implementation we found has this complete structure.

---

## 1. Prompt/Role DSL Projects

### 1.1 LangGPT (langgptai/LangGPT)
- **URL:** https://github.com/langgptai/LangGPT
- **Stars:** 11,775
- **What:** Structured prompt framework modeled on programming language concepts (modules, variables, composition)
- **Format:** Markdown with hierarchical headers; also supports YAML/JSON
- **Role definition structure:**
  ```markdown
  # Role: Expert_Name
  ## Profile
  - Author: X  |  Version: 1.0  |  Language: EN
  ## Goal
  ## Skills
  ## Rules
  ## Workflow
  ## Initialization
  ```
- **Key features:** Variable references (`<Rules>`, `<Language>`), modular composition, reusable sections
- **Schema/DSL:** Informal convention, not a formal schema. No JSON Schema, no validator
- **Academic paper:** arXiv:2402.16929 — "Rethinking Structured Reusable Prompt Design Framework for LLMs from the Programming Language"
- **Comparison to our Role DSL:** LangGPT is the closest conceptual ancestor to our approach. Both use markdown with defined sections. But LangGPT targets general prompt creation (chatbots, writing assistants), not session identity for multi-session collaboration. It has no concept of: session rationale, anti-responsibilities, coordination protocol, or project-specific context generation. Our spec is narrower in scope but deeper in structure.

### 1.2 GitAgent (open-gitagent/gitagent)
- **URL:** https://github.com/open-gitagent/gitagent
- **Stars:** 614
- **What:** Framework-agnostic, git-native standard for defining AI agents. "Your repository IS your agent."
- **Format:** `agent.yaml` manifest + `SOUL.md` identity + optional `RULES.md`, `DUTIES.md`, `AGENTS.md`
- **Schema:**
  ```yaml
  spec_version: "0.1.0"
  name: agent-name
  version: 1.0.0
  description: Brief description
  model:
    preferred: claude-opus-4-6
  compliance:
    risk_tier: high
    frameworks: [finra, federal_reserve, sec]
    supervision:
      human_in_the_loop: always
  ```
- **Key features:**
  - Git-based composition with `extends:` and `dependencies:` for inheritance
  - Framework-agnostic export to Claude Code, OpenAI, CrewAI, LangChain, GitHub Actions
  - Segregation of duties (SOD) with role permission matrices
  - Compliance-first design (FINRA, SEC, Federal Reserve)
  - Full directory structure: skills/, tools/, workflows/, knowledge/, memory/, hooks/, agents/
- **Comparison to our Role DSL:** GitAgent is the most ambitious project in this space — a full agent standard with compliance, SOD, and multi-framework export. However, it's enterprise/regulatory-focused. Its `SOUL.md` is closest to our Identity section, and its `DUTIES.md` maps to our Responsibilities/Anti-Responsibilities. It has no concept of session-level collaboration between multiple roles or project-specific context generation. The `extends:` composition pattern is interesting — our roles could benefit from inheritance.

### 1.3 Microsoft Prompty (microsoft/prompty)
- **URL:** https://github.com/microsoft/prompty
- **Stars:** 1,172
- **What:** Standardized prompt file format (.prompty) with formal JSON Schema
- **Format:** YAML frontmatter + Jinja2 template body
- **Schema:** Formal JSON Schema (draft-07) at `Prompty.yaml`
  - Fields: name, description, version, authors, tags, model (api, configuration, parameters, response), sample, inputs, outputs, template
  - Model configs: openai, azure_openai, azure_serverless
  - Parameters: temperature, max_tokens, top_p, frequency_penalty, seed, tools, response_format
- **Role support:** Minimal — roles appear only as message roles (system/user/assistant) in the Jinja2 body, not as first-class schema concepts
- **Comparison to our Role DSL:** Prompty is an LLM invocation format, not an identity format. It standardizes HOW you call an LLM, not WHO the session is. Its formal JSON Schema is admirable and worth studying for our own validation needs, but the domain is fundamentally different.

### 1.4 Microsoft Prompt Flow (microsoft/promptflow)
- **URL:** https://github.com/microsoft/promptflow
- **Stars:** 11,072
- **What:** End-to-end LLM app development framework with YAML-based flow definitions
- **Format:** `flow.dag.yaml` for DAG flows, `.prompty` for prompt templates
- **Role support:** Supports autonomous agent patterns but roles are implicit in prompt content, not structured
- **Comparison:** Infrastructure-level tool. Not relevant to role identity definition.

### 1.5 prompt-native/prompt-schema
- **URL:** https://github.com/prompt-native/prompt-schema
- **Stars:** 3
- **What:** JSON Schema defining a standard format for LLM prompts
- **Format:** Three JSON Schemas: completion, chat, text-to-image
- **Role support:** Chat schema likely includes message roles, but repo is dormant (last update May 2025)
- **Comparison:** Abandoned attempt at standardization. Too low-level for role definition.

### 1.6 deadbits/prompt-serve
- **URL:** https://github.com/deadbits/prompt-serve
- **Stars:** Low (< 50)
- **What:** YAML schema for storing/serving prompts via Git + API
- **Format:**
  ```yaml
  title: prompt-name
  uuid: ...
  description: ...
  category: ...
  provider: model-provider
  model: model-name
  model_settings: { temperature, top_k, top_p }
  prompt: prompt-text
  input_variables: [var1, var2]
  associations: [related-prompt-uuid]
  packs: [pack-uuid]
  ```
- **Role support:** No explicit role field. Prompts are atomic, not identity documents.
- **Comparison:** Prompt storage, not role definition.

### 1.7 Humanloop Prompt Files
- **URL:** https://humanloop.com/blog/prompt-files
- **What:** Proposed `.prompt` file format combining YAML + XML-like body
- **Format:** YAML header (model, temperature, tools) + `<system>/<user>/<assistant>` tags
- **Role support:** Roles as message types only, not identity definitions
- **Comparison:** Same category as Prompty — invocation format, not identity format.

### 1.8 GitHub .prompt.yml
- **URL:** https://docs.github.com/en/github-models/use-github-models/storing-prompts-in-github-repositories
- **What:** GitHub's native prompt file format for GitHub Models
- **Format:** `.prompt.yml` / `.prompt.yaml` with name, description, model, modelParameters, messages
- **Role support:** Messages have role field (system/user) but this is message typing, not session identity
- **Comparison:** Invocation format, not role definition.

---

## 2. Claude Code Plugin Ecosystem

### 2.1 VoltAgent/awesome-claude-code-subagents
- **URL:** https://github.com/VoltAgent/awesome-claude-code-subagents
- **Stars:** 14,473
- **What:** 100+ specialized Claude Code subagent definitions
- **Format:** Markdown files with YAML frontmatter
  ```yaml
  ---
  name: agent-organizer
  description: "Use when assembling multi-agent teams..."
  tools: Read, Write, Edit, Glob, Grep
  model: sonnet
  ---
  ```
  Body sections: Role Definition, Expertise Areas, Communication Protocol, Development Workflow, Implementation Checklist, Integration Points
- **Comparison to our Role DSL:** These are Claude Code subagent files (`.claude/agents/`), not session identity documents. They define WHAT a subagent does in a single delegated task, not WHO a session is across an ongoing collaboration. The body section structure (Role Definition, Expertise Areas, etc.) is informal — each agent defines different sections. No schema, no validation, no consistency enforcement.

### 2.2 alirezarezvani/claude-skills
- **URL:** https://github.com/alirezarezvani/claude-skills
- **Stars:** ~6,000
- **What:** 192+ skills & agent plugins organized by organizational role (engineering-team, product-team, c-level-advisor, marketing, finance)
- **Format:** SKILL.md with YAML frontmatter + organizational directory structure
- **Key feature:** Role-organized hierarchy (business-growth/, c-level/, engineering/, personas/)
- **Companion tool:** `claude-code-skill-factory` — generators for skills, agents, hooks, commands with templates
- **Comparison:** Domain-organized skill collection, not a role DSL. The organizational grouping is interesting (personas/ directory) but the actual persona definitions are plain-text instructions, not structured.

### 2.3 SuperClaude Framework (SuperClaude-Org/SuperClaude_Framework)
- **URL:** https://github.com/SuperClaude-Org/SuperClaude_Framework
- **Stars:** 21,700
- **What:** Configuration framework with "cognitive personas" and 30 slash commands
- **Personas:** 16 specialized agents (PM Agent, Deep Research, Security Engineer, Frontend Architect, etc.)
- **Format:** Personas implemented through slash commands (`/sc:*`) and MCP servers, not standalone definition files
- **Comparison:** Popular but personas are behavioral modes, not portable identity documents. No schema, no separation of definition from context. Commands ARE the personas — tightly coupled.

### 2.4 Anthropic Official Plugins (anthropics/claude-plugins-official)
- **URL:** https://github.com/anthropics/claude-plugins-official
- **What:** Official plugin directory. Includes `feature-dev` (with agents/), `code-simplifier` (with agents/), `plugin-dev` (with agents/)
- **Agent format:** Standard Claude Code `.claude/agents/*.md` with YAML frontmatter
- **Notable:** Even Anthropic's own plugins use the basic agent file format — no role DSL, no identity separation
- **Comparison:** Confirms that Claude Code's native agent format is the de facto standard in the ecosystem. Our Role DSL would build on top of this primitive.

### 2.5 Identity Separation Pattern

Several projects split agent identity across multiple files:

**aaronjmars/soul.md** (260 stars)
- **URL:** https://github.com/aaronjmars/soul.md
- Files: `SOUL.md` (who you are), `STYLE.md` (how you write), `SKILL.md` (operating modes), `MEMORY.md` (session continuity)
- Emphasizes specificity: concrete opinions, named influences, real contradictions
- Designed for personal AI clones, not development roles

**bkpaine1/CLAUDECODE** (low stars)
- Files: `MEMORY.md` (bootstrap), `SOUL.md` (voice/values), `IDENTITY.md` (role/self-concept), `USER.md` (developer profile)
- Bootstrap mechanism: MEMORY.md reads SOUL.md + IDENTITY.md + USER.md on session start

**GitAgent** (described above)
- Files: `SOUL.md` (identity), `RULES.md` (constraints), `DUTIES.md` (SOD), `AGENTS.md` (fallback)

**Clawdbot/OpenClaw**
- Files: `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`
- Modular file-based approach with composable separation of concerns

**Comparison:** The SOUL.md / IDENTITY.md pattern is the ecosystem's emergent answer to "how do we separate identity from instructions." Our Role DSL's split of **definition** (plugin-provided, stable) from **context** (project-specific, generated) is a more sophisticated version of this pattern, with the key distinction that our roles are collaborative session identities, not personal AI clones.

### 2.6 mushfoo/claude-personas
- **URL:** https://github.com/mushfoo/claude-personas
- **Stars:** 1
- **What:** Persona management with activation commands
- **Format:**
  ```yaml
  agent:
    name: Marcus
    id: security-analyst
    title: Senior Security Analyst
  persona:
    role: Expert Cybersecurity Professional
    style: vigilant, methodical, analytical
    identity: Security specialist...
    core_principles:
      - Assume breach
  ```
- **Activation:** `/persona activate security-analyst`, `/persona @analyst`
- **Comparison:** Closest to a role management system for Claude Code. Has YAML-structured persona definitions with identity, style, and principles. But very low adoption (1 star), no project-specific context generation, no multi-role collaboration.

### 2.7 JasperHG90/persona
- **URL:** https://github.com/JasperHG90/persona
- **Stars:** 10
- **What:** MCP server exposing a persona registry to any MCP-compatible client
- **Format:** Markdown files with YAML frontmatter in `.persona/` directory, metadata in Parquet
- **Key concept:** Personas = Roles (system prompts) + Skills (tools and instructions)
- **Comparison:** Interesting MCP-based approach. Registry concept is worth noting. But too small and focused on general LLM personas, not development collaboration.

---

## 3. Related Ecosystems

### 3.1 GitHub Copilot Custom Agents (.agent.md)
- **URL:** https://docs.github.com/en/copilot/reference/custom-agents-configuration
- **What:** Official agent definition format for GitHub Copilot
- **Format:** `.github/agents/AGENT-NAME.agent.md` with YAML frontmatter
- **Schema fields:**
  | Field | Type | Required | Description |
  |-------|------|----------|-------------|
  | `name` | string | No | Display name |
  | `description` | string | Yes | Purpose and capabilities |
  | `target` | string | No | `vscode` or `github-copilot` |
  | `tools` | list | No | Available tools (defaults to all) |
  | `model` | string | No | Model identifier |
  | `disable-model-invocation` | boolean | No | Prevent auto-selection |
  | `user-invocable` | boolean | No | Manual invocation only |
  | `mcp-servers` | object | No | MCP server configuration |
  | `metadata` | object | No | Key-value annotations |
- **Body:** Up to 30,000 characters of behavioral instructions
- **Key feature:** `handoffs` property for agent-to-agent transitions
- **Comparison:** Very similar to Claude Code's agent format. The `handoffs` property is notable — enables sequential agent workflows. No identity/context separation, no project-specific generation. But the formal configuration reference with documented fields is ahead of Claude Code's documentation.

### 3.2 Cursor (.cursorrules / Agent Skills)
- **URL:** https://github.com/PatrickJS/awesome-cursorrules (13k+ stars)
- **What:** `.cursorrules` files define project-specific AI behavior in Cursor
- **Format:** Plain text instructions, no formal schema. Community conventions only.
- **Role support:** Some community examples use PERSONA sections (e.g., "You are an experienced Product Manager")
- **Notable:** Cursor now supports Agent Skills (the open standard from Anthropic), installed to `.cursor/skills/`
- **Comparison:** No structured role system. `.cursorrules` is free-form text. The community has developed informal role conventions (PERSONA, TASK, CONTEXT, FORMAT — "PTCF framework") but nothing enforced by tooling.

### 3.3 Continue.dev
- **URL:** https://docs.continue.dev/customize/model-roles/intro
- **What:** Open-source AI coding assistant with YAML configuration
- **Roles:** Six predefined model roles: chat, autocomplete, edit, apply, embed, rerank
- **Format:** `config.yaml` with roles as model assignments
- **Prompts:** Markdown files with YAML frontmatter (name, description, invokable)
- **Rules:** `rules` property replaces legacy `systemMessage` — array of behavioral strings
- **Comparison:** Continue.dev's "roles" are model-routing labels (which model handles chat vs autocomplete), NOT session identities. Their prompts system is simple slash-command templates. No role DSL, no identity separation, no multi-session collaboration concept.

### 3.4 Aider
- **URL:** https://aider.chat/docs/config/adv-model-settings.html
- **What:** CLI-based AI coding assistant
- **Role support:** Minimal. `use_system_prompt` (bool), `system_prompt_prefix` (string). Chat modes (`/chat-mode`) switch between predefined behaviors.
- **Comparison:** No role/persona system. Technical prompt configuration only. The `/chat-mode` switching is the closest analog but modes are hardcoded, not user-defined.

### 3.5 Windsurf (Codeium)
- No formal role or persona system found. "Flow" technology maintains workspace sync but identity is implicit in the system prompt, not user-configurable.

---

## 4. Awesome Repositories (Curated Lists)

| Repository | Stars | Relevance |
|-----------|-------|-----------|
| [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | 29,320 | Largest Claude Code resource list. Catalogs skills, hooks, commands, agents |
| [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | 14,473 | 100+ subagent definitions. Best source of agent file patterns |
| [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) | 9,313 | Claude skills collection |
| [ComposioHQ/awesome-claude-plugins](https://github.com/ComposioHQ/awesome-claude-plugins) | 1,199 | Plugin catalog with adoption metrics |
| [Prat011/awesome-llm-skills](https://github.com/Prat011/awesome-llm-skills) | 1,018 | Cross-platform skills (Claude Code, Codex, Gemini CLI) |
| [rohitg00/awesome-claude-code-toolkit](https://github.com/rohitg00/awesome-claude-code-toolkit) | 861 | 135 agents, 35 skills, 42 commands |
| [ccplugins/awesome-claude-code-plugins](https://github.com/ccplugins/awesome-claude-code-plugins) | 638 | Plugin catalog |
| [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) | ~13,000 | .cursorrules collection — community role conventions |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | (official) | Official Copilot agents/skills/prompts collection |
| [EliFuzz/awesome-system-prompts](https://github.com/EliFuzz/awesome-system-prompts) | varied | Extracted system prompts from Claude Code, Cursor, Devin, etc. |
| [dair-ai/Prompt-Engineering-Guide](https://github.com/dair-ai/Prompt-Engineering-Guide) | 56k+ | General prompt engineering guide with structured prompting section |

**Key finding:** None of these awesome lists catalog role DSLs or structured identity formats as a category. They list agents, skills, and prompts — but don't distinguish between "task definition" and "identity definition."

---

## 5. Comparative Analysis

### Format Comparison

| Project | Format | Schema | Role Fields | Identity Separation | Composition | Multi-Role Collab |
|---------|--------|--------|-------------|-------------------|-------------|-------------------|
| **Our Role DSL** | Markdown sections | Informal (documented) | Session rationale, identity, responsibilities, anti-responsibilities, coordination, state | Definition + Context layers | Via plugin | Yes (CA/CP/CI) |
| **LangGPT** | Markdown headers | Informal | Profile, goal, skills, rules, workflow | No | Variable references | No |
| **GitAgent** | YAML + markdown files | YAML manifest | SOUL.md, RULES.md, DUTIES.md | Yes (multi-file) | `extends:` + dependencies | SOD roles |
| **Claude Code agents** | YAML frontmatter + MD | No formal schema | name, description, tools, model | No | No | No |
| **Copilot agents** | YAML frontmatter + MD | Documented fields | name, description, tools, model, target, handoffs | No | Via handoffs | Sequential only |
| **Prompty** | YAML + Jinja2 | JSON Schema (draft-07) | model, parameters, inputs/outputs | No | No | No |
| **SOUL.md pattern** | Markdown files | No schema | SOUL, STYLE, SKILL, MEMORY | Yes (multi-file) | No | No |
| **mushfoo/personas** | YAML persona block | Informal | name, id, title, role, style, identity, core_principles | No | No | Switching only |
| **Continue.dev** | YAML config | Documented | Model routing roles (chat, edit, etc.) | No | No | No |

### What Nobody Has

Based on this survey, these aspects of our Role Definition Spec appear to be **unique in the ecosystem**:

1. **Session rationale** — Why this role exists as a separate session. No other format explains the context isolation benefit.

2. **Anti-responsibilities** — Explicit "do NOT" scope boundaries. GitAgent's RULES.md comes closest but mixes constraints with identity.

3. **Coordination protocol** — How roles interact with each other (message format, handoff conventions). GitAgent has SOD but at the organizational level, not session level.

4. **Two-layer architecture** — Plugin-provided definition (stable) + project-generated context (evolving). No other system separates role template from project-specific instantiation.

5. **Project-specific context generation** — Automated research that populates role knowledge from codebase analysis. All other systems require manual authoring.

6. **Multi-session collaboration** — Roles designed to work together across concurrent sessions. GitAgent has sub-agents but in single-execution, not ongoing collaboration.

### What Others Have That We Could Adopt

1. **Formal JSON Schema validation** (from Prompty) — We could define a JSON Schema for our role format
2. **`extends:` composition** (from GitAgent) — Role inheritance for project-specific overrides
3. **Framework-agnostic export** (from GitAgent) — Export roles to Copilot `.agent.md` or other formats
4. **`handoffs` property** (from Copilot) — Formalize role-to-role transitions
5. **YAML frontmatter metadata** (from ecosystem consensus) — Standard machine-readable header
6. **Activation commands** (from mushfoo/personas) — `/role activate ca` pattern
7. **MCP server registry** (from JasperHG90/persona) — Expose roles via MCP for cross-tool access

---

## 6. Key Takeaways

### The Gap We Fill

The ecosystem has converged on a **YAML frontmatter + Markdown body** pattern for agent definitions, but nobody has formalized **session identity for multi-session collaboration**. The closest projects:

- **GitAgent** formalizes identity (SOUL.md) + constraints (RULES.md) + duties (DUTIES.md) but for single-agent compliance, not collaborative development workflows
- **LangGPT** provides structured prompt composition but without identity persistence or project adaptation
- **SOUL.md pattern** separates identity from instructions but for personal AI clones, not development roles

### Standards Convergence

The ecosystem is converging on:
- **YAML frontmatter** for machine-readable metadata (universal across Claude Code, Copilot, Continue.dev, Prompty)
- **Markdown body** for human-readable instructions (universal)
- **File-per-agent** rather than monolithic configuration (universal)
- **Tool restrictions** as hard constraints, not prompt suggestions (Claude Code, Copilot)

### Adoption Reality

- Most projects have **no schema** — definitions are convention-based plain text
- Only **Prompty** has a formal JSON Schema, and it's for prompt invocation, not identity
- **GitAgent** is the most ambitious standard attempt but is compliance/enterprise-focused
- The **SOUL.md pattern** is gaining organic traction (multiple independent implementations) as the community's answer to "where does identity go?"
- **SuperClaude** (21.7k stars) proves there's massive demand for structured agent personas, even without a formal schema

### Recommendation

Our Role Definition Spec occupies a genuinely novel position. If we formalize it with:
1. A YAML frontmatter header (for tooling compatibility)
2. A documented section schema (for validation)
3. The two-layer definition/context architecture (our unique contribution)
4. Activation support via multiple Claude Code primitives

...we would have the first structured session identity format designed for multi-session collaborative development. Nothing in the current ecosystem does this.

---

## Sources

- [LangGPT](https://github.com/langgptai/LangGPT) — 11,775 stars
- [GitAgent](https://github.com/open-gitagent/gitagent) — 614 stars
- [Microsoft Prompty](https://github.com/microsoft/prompty) — 1,172 stars
- [Microsoft Prompt Flow](https://github.com/microsoft/promptflow) — 11,072 stars
- [prompt-native/prompt-schema](https://github.com/prompt-native/prompt-schema) — 3 stars
- [deadbits/prompt-serve](https://github.com/deadbits/prompt-serve)
- [Humanloop Prompt Files](https://humanloop.com/blog/prompt-files)
- [GitHub .prompt.yml](https://docs.github.com/en/github-models/use-github-models/storing-prompts-in-github-repositories)
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) — 14,473 stars
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) — ~6,000 stars
- [alirezarezvani/claude-code-skill-factory](https://github.com/alirezarezvani/claude-code-skill-factory)
- [SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework) — 21,700 stars
- [Anthropic claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
- [soul.md](https://github.com/aaronjmars/soul.md) — 260 stars
- [CLAUDECODE identity](https://github.com/bkpaine1/CLAUDECODE)
- [mushfoo/claude-personas](https://github.com/mushfoo/claude-personas) — 1 star
- [JasperHG90/persona](https://github.com/JasperHG90/persona) — 10 stars
- [GitHub Copilot Custom Agents](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [GitHub Copilot Prompt Files](https://docs.github.com/en/copilot/tutorials/customization-library/prompt-files/your-first-prompt-file)
- [awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules)
- [Continue.dev Roles](https://docs.continue.dev/customize/model-roles/intro)
- [Continue.dev Prompts](https://docs.continue.dev/customize/deep-dives/prompts)
- [Aider Config](https://aider.chat/docs/config/adv-model-settings.html)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — 29,320 stars
- [awesome-claude-plugins](https://github.com/ComposioHQ/awesome-claude-plugins) — 1,199 stars
- [awesome-llm-skills](https://github.com/Prat011/awesome-llm-skills) — 1,018 stars
- [GitHub Blog: How to write a great agents.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [Claude Code Plugin Docs](https://code.claude.com/docs/en/plugins)
- [Claude Code Subagent Docs](https://code.claude.com/docs/en/sub-agents)
