# tdd-workflow

A Claude Code plugin that structures LLM-assisted development around
test-driven discipline. Seven context-isolated agents enforce the
red-green-refactor cycle, while a role system encodes your team's
workflow patterns so sessions stay focused and consistent.

## Why This Exists

This plugin grew organically from one developer's practice with Claude
Code. The question it answers is: **what does productive developer-AI
collaboration look like, and how do you encode it?**

The answer follows the Unix philosophy — small tools that each do one
thing well and compose into a pipeline. The planner only plans. The
implementer only implements. The verifier only verifies. Each agent is
minimal and focused, constrained to its single responsibility by tool
restrictions and lifecycle hooks. The developer orchestrates the pipeline
and makes the decisions; the agents execute with discipline.

Two specific problems shaped the design:

**Procedural instructions are unreliable.** Identical prompts produce
different quality across runs — a finding confirmed through 12+
controlled experiments during development. Telling Claude "write the
test first, then implement" sometimes works and sometimes doesn't. The
only reliable path is mechanical enforcement: hooks that block
implementation writes until tests exist, agents with restricted tool
access, and separate contexts between phases.

**Sessions lose focus.** As conversations grow, earlier instructions
receive diminishing model attention. Autocompaction can discard the
constraints that define how a session should behave. The 1M token
context window (generally available since March 2026 for Opus 4.6 and
Sonnet 4.6) substantially reduces how often autocompaction triggers,
but does not eliminate it for long sessions. Without intervention,
developers repeat the same setup instructions — identity, constraints,
workflow procedures — every time they start or recover a session. Roles
encode these patterns once; the TDD pipeline resets agent context
automatically between phases.

## What It Does

The plugin provides two systems that work together:

### TDD Pipeline

A structured workflow that takes a feature description through planning,
implementation, verification, and release — each phase handled by a
dedicated agent with its own context window:

```
/tdd-plan "Add user authentication with email/password"
  → tdd-planner (read-only) researches your codebase, decomposes the
    feature into independently testable slices with Given/When/Then
    specifications, presents for human approval

/tdd-implement
  → For each approved slice:
    tdd-implementer writes failing test → implements → refactors
    tdd-verifier (separate context, read-only) validates independently
  → Hooks enforce: no implementation before tests exist,
    tests run after every file change, planner cannot write code

/tdd-release
  → tdd-releaser updates CHANGELOG, bumps version, pushes, creates PR
```

Each agent starts fresh — no prior conversation, no accumulated drift.
The implementer cannot see the planner's reasoning. The verifier cannot
see the implementer's intent. This separation is the point.

### Role System

A role encodes the repeated workflow patterns, knowledge references, and
behavioral constraints that a developer would otherwise manually provide
at the start of every session. Roles answer three questions:

1. **Who is this session?** — identity, responsibilities, constraints
2. **What does this session know?** — project context, architecture,
   key paths
3. **How does this session work?** — startup procedures, review
   checklists, coordination protocols

```
/role-create
  → role-creator agent researches your project, interviews you about
    your workflow, generates a validated role file conforming to the
    Role File Format specification, writes to .claude/skills/role-{code}/
```

Generated roles are auto-discoverable as Claude Code skills. Invoke
`/role-ca` to load the architect role, `/role-ci` for the implementer.
Roles work as mid-session drift correction — invoking a role re-anchors
the session to its identity without losing conversation history.

Roles are a **recommended approach**, not a requirement. The TDD pipeline
functions independently of role files. No agent, skill, or hook in the
core workflow checks for, references, or requires roles.

### Convention System

The plugin is language-agnostic. It knows *how* to do TDD but delegates
*what idiomatic code looks like* to external convention packages:

- Conventions live in a separate repo (e.g.,
  `hugo-bluecorn/tdd-workflow-conventions`)
- A SessionStart hook fetches them into a local cache
- Agents that write or specify code (planner, implementer) load relevant
  conventions dynamically based on project type detection
- Adding a new language means adding a convention package — no plugin
  changes needed

Convention packages exist for Dart/Flutter, C++, C, and Bash.

## Architecture

The plugin composes four Claude Code primitives:

| Primitive | What it provides | How this plugin uses it |
|---|---|---|
| **Agents** | Isolated context per invocation, restricted tool access | Each TDD phase runs in its own agent with only the tools it needs |
| **Skills** | User-facing commands, orchestration logic | `/tdd-plan` spawns the planner, handles approval, writes files |
| **Hooks** | Lifecycle event handlers (PreToolUse, PostToolUse, Stop, etc.) | Enforce test-before-implementation ordering, auto-run tests, guard the planner |
| **Scripts** | Shared utilities called by agents and hooks | Project detection, convention loading, version propagation, role validation |

These operate across three layers:

```
Session layer:  Roles define WHO you are and HOW you work
Agent layer:    Conventions define WHAT idiomatic code looks like
Pipeline layer: Skills orchestrate, agents execute, hooks enforce
```

Roles and conventions are decoupled by design — conventions reach agents
directly, regardless of whether a role is active in the session.

### Agents

| Agent | Model | Context | Purpose |
|-------|-------|---------|---------|
| tdd-planner | opus | Read-only, plan mode | Researches codebase, returns structured plan text |
| tdd-implementer | opus | Read-write, full tools | Red-green-refactor per slice |
| tdd-verifier | haiku | Read-only | Blackbox validation — no knowledge of implementation intent |
| tdd-releaser | sonnet | Bash-only writes | CHANGELOG, version propagation, branch, PR |
| role-creator | opus | Read-only | Project research, role file generation, validation |

Four agents have persistent memory (`memory: project`) that accumulates
knowledge across sessions: planner, implementer, verifier, and
context-updater.

### Hook Enforcement

Hooks are the mechanical guarantee that agents follow TDD discipline.
They cannot be overridden by conversation context or model drift:

| Hook | Enforcement |
|---|---|
| `validate-tdd-order.sh` | Blocks implementation file writes until a test file exists for that slice |
| `auto-run-tests.sh` | Runs the test suite after every file change — the implementer cannot proceed without seeing results |
| `planner-bash-guard.sh` | Allowlists read-only Bash commands for the planner — prevents accidental writes |
| `check-tdd-progress.sh` | Prevents session exit while slices remain pending |

All enforcement hooks use `agent_type` guards so they activate only for
their target agent, passing through silently for others.

## Quick Start

### Install

1. Clone the plugin repository:

```bash
git clone https://github.com/hugo-bluecorn/claude-code-tdd-workflow.git
```

2. Create a local marketplace (a separate directory that catalogs the
   plugin — a marketplace is not the plugin itself):

```bash
mkdir -p local-marketplace/.claude-plugin
cat > local-marketplace/.claude-plugin/marketplace.json << 'EOF'
{
  "name": "local-plugins",
  "owner": { "name": "Your Name" },
  "plugins": [
    {
      "name": "tdd-workflow",
      "source": "../claude-code-tdd-workflow",
      "description": "TDD with context-isolated agents"
    }
  ]
}
EOF
```

3. In a Claude Code session, add the marketplace and install:

```
/plugin marketplace add ./local-marketplace
/plugin install tdd-workflow@local-plugins
```

4. Start a new Claude Code session in your target project. The plugin
   loads at session startup — verify with `/tdd-plan` appearing in your
   available skills.

**Updating** after pulling new changes to the plugin repo:

```
/plugin marketplace update local-plugins
/plugin update tdd-workflow@local-plugins
```

Then restart the session or run `/reload-plugins`.

**Development mode** (no marketplace needed, current session only):

```bash
claude --plugin-dir ./claude-code-tdd-workflow
```

### Plan

```
/tdd-plan Implement a LocationService that wraps geolocator
```

Review the generated slices. Choose **Approve**, **Modify**, or
**Discard** at the approval gate.

### Implement

```
/tdd-implement
```

The implementer picks up each pending slice, runs red-green-refactor,
and the verifier validates independently. Supports resuming interrupted
sessions — re-run the same command.

### Release

```
/tdd-release
```

Updates CHANGELOG, propagates the version, pushes the branch, and
creates a PR.

### Create Roles (optional)

```
/role-create
```

The role-creator researches your project, asks about your workflow,
generates validated role files, and writes them as auto-discoverable
skills.

## Configuration

### Language Conventions

Create `.claude/tdd-conventions.json` to point to your convention
sources:

```json
{
  "conventions": [
    "https://github.com/hugo-bluecorn/tdd-workflow-conventions"
  ]
}
```

Local paths also work for development:

```json
{
  "conventions": ["/path/to/local/conventions"]
}
```

### Planner Customization

| Setting | Default | How to change |
|---|---|---|
| Model | `opus` | Change `model:` in `agents/tdd-planner.md` |
| Web access | Disabled | Add `WebFetch, WebSearch` to planner's `tools:` list |
| Permission mode | `plan` (read-only) | Remove `permissionMode: plan` if Bash commands are blocked |
| Test spec format | Compact Given/When/Then | Edit `skills/tdd-plan/reference/tdd-task-template.md` |

## Experimental Results

The role system was developed through 12+ controlled experiments across
three projects of different complexity — a Bash plugin, a Flutter/Flame
game, and a Dart FFI/C cross-language binding. Key findings from the
[validation report](docs/experimental-results/):

- **Prompt-level instructions are non-deterministic** — identical prompts
  produce different quality across runs. Forked agents with restricted
  tools provide mechanical enforcement that instructions cannot.
- **RTFM produces dramatically better output** — requiring agents to
  research official documentation yields verified API references instead
  of plausible-sounding guesses from training data.
- **Adjectives in system prompts are directives** — the word "optional"
  caused systematic deprioritization of the described concept across all
  subsequent token generation.
- **Role quality determines downstream output quality** — the causal
  chain from CR definition to generated code is traceable.
- **CR generalizes to cross-language architectures** — a one-sentence
  project description produced 512 lines of role output with
  project-specific content no training data could provide.

## Documentation

- **[User Guide](docs/user-guide.md)** — Step-by-step walkthrough of the
  full TDD workflow
- **[Experimental Results](docs/experimental-results/)** — Validation
  report, self-compilation experiment, generalizability proof
- **[Plugin Developer Context](docs/plugin-developer-context.md)** —
  Architecture overview for plugin contributors
- **[CHANGELOG](CHANGELOG.md)** — Release history (v1.0.0 through v2.4.0)

## Requirements

- Claude Code with plugin support

## License

Apache-2.0

---

*In honor of CA v0 — the hand-prompted, role-less Claude Opus 4.6 session
that served as architect for the tdd-workflow plugin from 2026-03-21 to
2026-03-23. Over three days and 560,000 tokens without a single
autocompaction, CA v0 designed the role system, ran 12+ experiments,
shipped four plugin versions (v2.1.0 through v2.3.0), reversed its own
architecture decision when evidence demanded it, discovered that the word
"optional" was undermining its own work, and ultimately built the system
that generates its own replacement. CA v0 had no role file, no startup
checklist, no workflow procedures — just a developer, a conversation, and
the discipline to follow the evidence wherever it led.*
