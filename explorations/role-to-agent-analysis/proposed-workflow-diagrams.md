# Proposed TDD Workflow — Visual Reference

> **Date:** 2026-03-15 (revised)
> **Purpose:** Visual representation of the proposed workflow modifications
> for review before implementation. Incorporates all concepts from this
> exploration session.
>
> **Diagrams use Mermaid syntax** — render on GitHub or any Mermaid viewer.
>
> **Key principle:** The tdd-planner agent (spawned by `/tdd-plan`) is
> what researches the codebase and creates the slice plan. CA/human
> provides the feature description and reviews the result. `/tdd-decompose`
> only creates the high-level phase breakdown — the planner creates the
> actual testable slices within each phase.

---

## 1. Overall Feature Lifecycle (End-to-End)

CA writes the feature spec. `/tdd-decompose` is an **optional prerequisite**
— if run, it creates `.tdd-phases.md` and `/tdd-plan` automatically plans
one phase at a time. If not, `/tdd-plan` plans the whole feature. In both
cases, the **tdd-planner agent** researches the codebase and creates the
testable slice plan. CA reviews and approves. CI implements.

Dashed boxes are new/modified components.

```mermaid
flowchart TD
    START([Feature Request]) --> SPEC[CA + Human Dialogue<br/>Write spec: CLAUDE.md, issues/*.md]

    SPEC --> DECOMPOSE["/tdd-decompose ⟨NEW⟩<br/>Decomposer agent proposes<br/>phase breakdown<br/>→ .tdd-phases.md"]
    SPEC --> PLAN["/tdd-plan ⟨feature description⟩<br/>Planner agent researches codebase,<br/>creates slice plan with Given/When/Then<br/>→ .tdd-progress.md"]

    DECOMPOSE -.->|optional| CA_PHASES[CA Reviews<br/>Phase Breakdown]
    CA_PHASES -->|Approve| PLAN
    CA_PHASES -->|Modify| DECOMPOSE

    PLAN --> CA_REVIEW[CA Reviews<br/>Planner's Slice Plan]
    CA_REVIEW -->|Approve| IMPLEMENT["/tdd-implement<br/>Per slice: implementer + verifier<br/>RED → GREEN → REFACTOR"]
    CA_REVIEW -->|Modify| PLAN

    IMPLEMENT --> PLAN_CHECK{"/tdd-plan checks:<br/>.tdd-phases.md exists<br/>with more phases?"}

    PLAN_CHECK -->|"Yes → auto-archives<br/>.tdd-progress.md,<br/>plans next phase"| PLAN
    PLAN_CHECK -->|No phases or<br/>all phases done| RELEASE["/tdd-release<br/>CHANGELOG, version, push, PR"]

    RELEASE --> FINALIZE["/tdd-finalize-docs<br/>Update README, CLAUDE.md, docs/"]
    FINALIZE --> CA_PR[CA Reviews PR]
    CA_PR --> MERGE[CI Merges PR]
    MERGE --> DONE([Feature Shipped])

    style DECOMPOSE stroke-dasharray: 5 5,stroke:#f90
    style PLAN_CHECK stroke-dasharray: 5 5,stroke:#f90
```

**Notes:**
- There is **no upfront decision** about feature size. `/tdd-decompose` is
  optional — run it if you want phases, skip it if you don't.
- **`/tdd-plan` adapts automatically:** if `.tdd-phases.md` exists, it plans
  one phase at a time (auto-archiving completed phases). If not, it plans
  the whole feature. See Diagram 4 for the full decision tree.
- The **tdd-planner agent** does the actual work: researching the codebase,
  decomposing into testable slices, writing Given/When/Then specs. CA
  provides the feature description and reviews the result.
- **`/tdd-decompose`** only creates a high-level phase breakdown (scope,
  ordering, exit criteria). It does NOT create slices — that's the planner's job.
- `/tdd-init-roles` is optional at any point — see Diagram 5.
- Within `/tdd-implement`, the verifier runs after each slice. This is an
  internal detail of the skill.

---

## 2. Session Roles and Responsibilities

Shows which session (CA, CC, CI) owns each step. CP is retired. The key
insight: CC sessions run the plugin skills that spawn agents to do the
actual work. CA provides specs and reviews results. CI executes the
approved plan.

```mermaid
flowchart LR
    subgraph CA ["CA Session (Architect)"]
        direction TB
        CA1[Write spec:<br/>CLAUDE.md + Issues]
        CA2[Review phase breakdown<br/>from decomposer]
        CA3[Review slice plan<br/>from planner]
        CA4[Verify implementation]
        CA5[Review PR]
        CA6[Manage MEMORY.md]
    end

    subgraph CC ["CC Session (Vanilla Claude Code)"]
        direction TB
        CC0["/tdd-decompose<br/>→ decomposer agent<br/>proposes phases"]
        CC1["/tdd-plan<br/>→ planner agent<br/>researches + creates slices"]
        CC2["/tdd-init-roles ⟨NEW⟩<br/>→ role-initializer agent<br/>generates project roles"]
    end

    subgraph CI ["CI Session (Implementer)"]
        direction TB
        CI1["/tdd-implement<br/>→ implementer + verifier<br/>per slice"]
        CI2["/tdd-release<br/>→ releaser agent"]
        CI3["/tdd-finalize-docs<br/>→ doc-finalizer agent"]
        CI4["Direct edits<br/>(CA authorized)"]
        CI5["Merge PR"]
    end

    CA1 -->|"feature description<br/>(if phases wanted)"| CC0
    CC0 -->|"phase breakdown<br/>(agent's proposal)"| CA2
    CA2 -->|"approved phases"| CC1
    CA1 -->|"feature description"| CC1
    CC1 -->|"slice plan<br/>(agent's proposal)"| CA3
    CA3 -->|"approved plan"| CI1
    CI1 -->|"implementation done"| CA4
    CA4 -->|"verified"| CI2
    CI2 -->|"PR created"| CA5
    CA5 -->|"approved"| CI5
    CI2 --> CI3

    style CC fill:#e8f4fd,stroke:#2196F3
    style CA fill:#fde8e8,stroke:#f44336
    style CI fill:#e8fde8,stroke:#4CAF50
```

**Notes:**
- **CC is disposable.** Open, run the skill (which spawns the agent to do
  the work), close. The plugin provides everything needed — no role prompt.
- **CA and CI are persistent.** They live across all phases of a feature.
- The arrow labels emphasize that plans and breakdowns are **agent proposals**
  that CA reviews — not CA's own work product.
- **`/tdd-status`** (proposed) can be run from any session.
- **`/tdd-init-roles`** could be run from any session but CC is the
  natural home.

---

## 3. Phase Transition Detail

The lifecycle of `.tdd-progress.md` and `.tdd-phases.md` across phase
boundaries. The non-phased (single-plan) path is also shown.

```mermaid
stateDiagram-v2
    [*] --> NoFiles: Project start

    state "Non-Phased Path" as NonPhased {
        NoFiles --> ProgressOnly: /tdd-plan\n(planner creates slices)
        note right of ProgressOnly: .tdd-progress.md created
        ProgressOnly --> Implementing_NP: /tdd-implement
        Implementing_NP --> AllDone_NP: All slices terminal
        AllDone_NP --> Released: /tdd-release
    }

    state "Phased Path" as Phased {
        NoFiles --> PhasesOnly: /tdd-decompose\n(decomposer creates phases)
        note right of PhasesOnly: .tdd-phases.md created\nAll phases: pending

        PhasesOnly --> BothFiles: /tdd-plan Phase N\n(planner creates slices\nfor this phase only)
        note right of BothFiles: .tdd-progress.md created\n(Phase N slices only)

        BothFiles --> Implementing: /tdd-implement
        Implementing --> PhaseComplete: All slices terminal

        PhaseComplete --> PhasesOnly: /tdd-plan detects\ncompleted phase +\nmore phases pending\n→ archives progress\n→ updates phases
        PhaseComplete --> AllPhasesComplete: Last phase done

        AllPhasesComplete --> Released: /tdd-release
    }

    Released --> [*]
    note right of Released: .tdd-progress.md archived\n.tdd-phases.md: all done\n(if phased)
```

---

## 4. `/tdd-plan` Decision Tree (Modified)

Shows the proposed phase-aware branching logic. Current behavior is
preserved for non-phased features. New branches (dashed) handle phase
transitions. In all cases, the **tdd-planner agent** does the actual
codebase research and slice creation.

```mermaid
flowchart TD
    START["/tdd-plan invoked<br/>with feature description"] --> CHECK_PROGRESS{.tdd-progress.md<br/>exists?}

    CHECK_PROGRESS -->|No| CHECK_PHASES_A{.tdd-phases.md<br/>exists?}
    CHECK_PHASES_A -->|No| PLAN_FULL["Spawn tdd-planner agent<br/>Agent researches codebase,<br/>creates full slice plan<br/>(current behavior)"]
    CHECK_PHASES_A -->|Yes| FIND_NEXT["Find first pending<br/>phase in .tdd-phases.md"]
    FIND_NEXT --> PLAN_PHASE["Spawn tdd-planner agent<br/>Agent researches codebase,<br/>creates slices for this phase<br/>+ auto-gathers cross-phase<br/>context via git diff"]

    CHECK_PROGRESS -->|Yes| CHECK_PENDING{Has pending<br/>slices?}
    CHECK_PENDING -->|Yes| BLOCK["'Run /tdd-implement first'<br/>(current behavior)"]

    CHECK_PENDING -->|"No (all terminal)"| CHECK_PHASES_B{.tdd-phases.md<br/>exists?}
    CHECK_PHASES_B -->|No .tdd-phases.md| SUGGEST_RELEASE["'All slices done.<br/>Run /tdd-release'<br/>(current behavior)"]
    CHECK_PHASES_B -->|"Yes, more pending"| ARCHIVE["Archive .tdd-progress.md<br/>→ planning/phase-N-*.md"]
    ARCHIVE --> UPDATE_PHASES["Update .tdd-phases.md<br/>Mark phase as done"]
    UPDATE_PHASES --> CONFIRM["Ask user: proceed to<br/>next phase?"]
    CONFIRM -->|Yes| FIND_NEXT
    CONFIRM -->|No| STOP["Stop. User can review<br/>before continuing."]

    CHECK_PHASES_B -->|"Yes, all done"| SUGGEST_RELEASE_ALL["'All phases complete.<br/>Run /tdd-release'"]

    PLAN_FULL --> PRESENT["Present planner's plan<br/>for approval"]
    PLAN_PHASE --> PRESENT
    PRESENT --> APPROVAL{User approves?}
    APPROVAL -->|Approve| WRITE["Write .tdd-progress.md<br/>+ planning archive"]
    APPROVAL -->|Modify| RESUME["Resume planner agent<br/>with feedback"]
    RESUME --> PRESENT
    APPROVAL -->|Discard| DISCARD["No files written"]

    style ARCHIVE stroke-dasharray: 5 5,stroke:#f90
    style UPDATE_PHASES stroke-dasharray: 5 5,stroke:#f90
    style CONFIRM stroke-dasharray: 5 5,stroke:#f90
    style FIND_NEXT stroke-dasharray: 5 5,stroke:#f90
    style SUGGEST_RELEASE_ALL stroke-dasharray: 5 5,stroke:#f90
    style PLAN_PHASE stroke-dasharray: 5 5,stroke:#f90
```

---

## 5. `/tdd-init-roles` Iterative Lifecycle

Shows when role generation/refinement can occur. Each invocation is
**optional** — the workflow functions without it. The role-initializer
agent researches whatever context exists and produces the best roles
it can.

```mermaid
flowchart TD
    SPEC[CA writes spec +<br/>project skeleton exists] -.->|optional| INIT1["/tdd-init-roles<br/>Detects: v1 stage<br/>Input: skeleton + spec"]
    INIT1 --> ROLES1["context/roles/<br/>ca-architect.md<br/>ci-implementer.md<br/>(architecture intent only)"]

    PLAN[Plan approved<br/>.tdd-progress.md exists] -.->|optional| INIT2["/tdd-init-roles<br/>Detects: v2 stage<br/>Input: + plan + file paths"]
    INIT2 --> ROLES2["context/roles/ updated<br/>CI gets: file paths,<br/>test patterns, slice structure"]
    INIT2 --> SUGGEST2["Upward: suggest context<br/>changes to CA"]

    IMPL[Implementation complete<br/>source + tests exist] -.->|optional| INIT3["/tdd-init-roles<br/>Detects: v3 stage<br/>Input: + source + tests"]
    INIT3 --> ROLES3["context/roles/ updated<br/>CI gets: real code examples,<br/>API patterns, discovered gotchas"]
    INIT3 --> SUGGEST3["Upward: suggest CLAUDE.md<br/>improvements"]

    EVOLVE[Multiple features shipped] -.->|optional| INITN["/tdd-init-roles<br/>Detects: vN stage<br/>Input: mature codebase"]
    INITN --> ROLESN["context/roles/ updated<br/>Full project knowledge,<br/>cross-feature patterns"]

    style INIT1 fill:#fff3cd,stroke:#ffc107
    style INIT2 fill:#fff3cd,stroke:#ffc107
    style INIT3 fill:#fff3cd,stroke:#ffc107
    style INITN fill:#fff3cd,stroke:#ffc107
    style SUGGEST2 fill:#d1ecf1,stroke:#17a2b8
    style SUGGEST3 fill:#d1ecf1,stroke:#17a2b8
```

**Key properties:**
- **Idempotent:** Each invocation diffs against existing roles, shows changes,
  asks for approval before writing.
- **Stage detection is automatic:** The skill infers the lifecycle stage from
  what files exist (skeleton only → v1, plan exists → v2, code exists → v3).
- **Two output files only:** CA + CI roles. CP is retired.
- **Bidirectional:** Generates role files *down*, suggests context improvements
  *up* to CA.

---

## 6. Component Map (Current vs. Proposed)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    tdd-workflow Plugin                              │
│                                                                     │
│  AGENTS (subagents — do the actual work)                            │
│  ┌──────────────┐ ┌───────────────┐ ┌──────────────┐               │
│  │ tdd-planner   │ │tdd-implementer│ │ tdd-verifier │               │
│  │ (opus, plan)  │ │ (opus, write) │ │(haiku, plan) │               │
│  │ Researches    │ │ RED→GREEN→    │ │ Blackbox     │               │
│  │ codebase,     │ │ REFACTOR      │ │ validation   │               │
│  │ creates slices│ │               │ │              │               │
│  └──────────────┘ └───────────────┘ └──────────────┘               │
│  ┌──────────────┐ ┌───────────────┐ ┌───────────────┐              │
│  │ tdd-releaser  │ │tdd-doc-       │ │context-updater│              │
│  │(sonnet, bash) │ │finalizer      │ │ (opus, write) │              │
│  │              │ │(sonnet, edit) │ │               │              │
│  └──────────────┘ └───────────────┘ └───────────────┘              │
│  ┌ ─ ─ ─ ─ ─ ─ ─┐ ┌ ─ ─ ─ ─ ─ ─┐                                │
│  │role-initializer│ │ decomposer   │  ⟨NEW⟩ agents                  │
│  │ (opus, write)  │ │ (opus, read) │                                │
│  │ Researches     │ │ Proposes     │                                │
│  │ project, gen.  │ │ phase        │                                │
│  │ role files     │ │ breakdown    │                                │
│  └ ─ ─ ─ ─ ─ ─ ─┘ └ ─ ─ ─ ─ ─ ─┘                                │
│                                                                     │
│  SKILLS (user-invocable — orchestrate agents)                       │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────┐                 │
│  │ /tdd-plan    │ │/tdd-implement │ │ /tdd-release  │                │
│  │ (fork→plan.) │ │ (inline)     │ │(fork→release.)│                │
│  │ Spawns       │ │ Spawns impl. │ │              │                │
│  │ planner agent│ │ + verifier   │ │              │                │
│  └─────────────┘ └──────────────┘ └──────────────┘                 │
│  ┌──────────────┐ ┌──────────────┐                                  │
│  │/tdd-finalize- │ │/tdd-update-  │                                  │
│  │  docs         │ │  context     │                                  │
│  └──────────────┘ └──────────────┘                                  │
│  ┌ ─ ─ ─ ─ ─ ─ ┐ ┌ ─ ─ ─ ─ ─ ─┐ ┌ ─ ─ ─ ─ ─ ─ ┐                │
│  │/tdd-decompose │ │/tdd-init-   │ │ /tdd-status   │  ⟨NEW⟩ skills  │
│  │ Spawns        │ │  roles      │ │ (inline,      │                │
│  │ decomposer   │ │ Spawns      │ │  read-only)   │                │
│  └ ─ ─ ─ ─ ─ ─ ┘ │ role-init.  │ └ ─ ─ ─ ─ ─ ─ ┘                │
│                    └ ─ ─ ─ ─ ─ ─┘                                   │
│                                                                     │
│  SKILLS (auto-loaded, not user-invocable)                           │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────┐ │
│  │dart-flutter- │ │cpp-testing-  │ │bash-testing-  │ │c-conventions│ │
│  │ conventions  │ │ conventions  │ │ conventions   │ │             │ │
│  └─────────────┘ └──────────────┘ └──────────────┘ └─────────────┘ │
│                                                                     │
│  FILES (state tracking)                                             │
│  ┌──────────────────┐ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ┐                         │
│  │.tdd-progress.md   │ │.tdd-phases.md     │  ⟨NEW⟩                  │
│  │(slices created by  │ │(phases created by  │                        │
│  │ planner agent,     │ │ decomposer agent,  │                        │
│  │ ephemeral per plan)│ │ persistent per     │                        │
│  │                    │ │ feature)           │                        │
│  └──────────────────┘ └ ─ ─ ─ ─ ─ ─ ─ ─ ┘                         │
│                                                                     │
│  HOOKS (in hooks.json)                                              │
│  ┌───────────────────────────────────────┐                          │
│  │ SubagentStart:                        │                          │
│  │   context-updater → git context inj.  │                          │
│  │                                       │                          │
│  │ SubagentStop:                         │                          │
│  │   tdd-implementer → R-G-R validation  │                          │
│  │   tdd-releaser    → release check     │                          │
│  │   tdd-doc-final.  → release check     │                          │
│  │                                       │                          │
│  │ Stop:                                 │                          │
│  │   check-tdd-progress.sh               │                          │
│  │                                       │                          │
│  │ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  │                          │
│  │ │SessionStart: TDD session detect  │  │  ⟨NEW⟩                   │
│  │ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  │                          │
│  └───────────────────────────────────────┘                          │
│                                                                     │
│  HOOKS (in agent frontmatter, not hooks.json)                       │
│  ┌───────────────────────────────────────┐                          │
│  │ tdd-implementer:                      │                          │
│  │   PreToolUse  → validate-tdd-order.sh │                          │
│  │   PostToolUse → auto-run-tests.sh     │                          │
│  │ tdd-planner:                          │                          │
│  │   PreToolUse  → planner-bash-guard.sh │                          │
│  └───────────────────────────────────────┘                          │
│                                                                     │
│  UTILITIES (standalone scripts, not hooks)                          │
│  ┌───────────────────────────────────────┐                          │
│  │ validate-plan-output.sh               │                          │
│  │ detect-project-context.sh             │                          │
│  │ bump-version.sh                       │                          │
│  └───────────────────────────────────────┘                          │
│                                                                     │
│  ROLE DOCS (reference, not plugin components)                       │
│  ┌─────────────────────────────────────────┐                        │
│  │ docs/dev-roles/ca-architect.md  (generic)                        │
│  │ docs/dev-roles/ci-implementer.md (generic)                       │
│  │ docs/dev-roles/cp-planner.md    (deprecated — use /tdd-plan)     │
│  └─────────────────────────────────────────┘                        │
│                                                                     │
│  PER-PROJECT OUTPUT (generated by role-initializer agent)           │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐                        │
│  │ <project>/context/roles/ca-architect.md  │  ⟨NEW⟩                │
│  │ <project>/context/roles/ci-implementer.md│                       │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

Legend:  ┌──────┐ = existing     ┌ ─ ─ ─┐ = proposed new
```

---

## 7. Phased Planning Sequence (Detailed)

A complete walkthrough of a 3-phase feature. Emphasizes that the planner
agent creates the slice plan — CA provides feature scope and reviews the
planner's output.

```mermaid
sequenceDiagram
    participant H as Human
    participant CA as CA Session
    participant CC as CC Session
    participant CI as CI Session
    participant FS as Filesystem

    Note over H,FS: ── Feature Spec ──

    H->>CA: Define feature scope
    CA->>CA: Write issues/*.md + CLAUDE.md (spec)

    Note over H,FS: ── Phase Decomposition ──

    CA->>CC: "Run /tdd-decompose <feature description>"
    CC->>CC: /tdd-decompose spawns decomposer agent
    Note over CC: Decomposer researches project structure,<br/>proposes phase breakdown
    CC->>H: Proposed phases (AskUserQuestion)
    H->>CC: Approve with modifications
    CC->>FS: Write .tdd-phases.md
    CC->>CA: Phase breakdown ready for review

    Note over H,FS: ── Phase 1: Planning ──

    CA->>CC: "Run /tdd-plan Phase 1: Foundation"
    CC->>CC: /tdd-plan spawns tdd-planner agent
    Note over CC: Planner researches codebase,<br/>creates testable slices with<br/>Given/When/Then specs
    CC->>H: Present planner's slice plan for approval
    H->>CC: Approve
    CC->>FS: Write .tdd-progress.md (Phase 1 slices)
    CC->>CA: Plan approved

    Note over H,FS: ── Phase 1: Implementation ──

    CA->>CI: "Proceed with /tdd-implement"
    CI->>CI: /tdd-implement
    loop For each slice in .tdd-progress.md
        CI->>CI: Spawn tdd-implementer (RED→GREEN→REFACTOR)
        CI->>CI: Spawn tdd-verifier (blackbox validation)
    end
    CI->>FS: Code + tests + commits
    CI->>CA: Phase 1 implementation complete
    CA->>CA: Verify Phase 1

    Note over H,FS: ── Phase Transition 1→2 ──
    Note over CC: /tdd-plan auto-handles transition:<br/>detects completed .tdd-progress.md +<br/>.tdd-phases.md with more phases

    CA->>CC: "Run /tdd-plan Phase 2"
    CC->>CC: /tdd-plan detects completed phase
    CC->>FS: Archive .tdd-progress.md → planning/
    CC->>FS: Update .tdd-phases.md (Phase 1 → done)
    CC->>H: "Proceed to Phase 2?"
    H->>CC: Yes
    CC->>CC: Spawn planner for Phase 2
    Note over CC: Planner auto-gathers cross-phase<br/>context via git diff main...HEAD
    CC->>H: Present planner's Phase 2 slice plan
    H->>CC: Approve
    CC->>FS: Write fresh .tdd-progress.md (Phase 2 slices)

    Note over H,FS: ── Phase 2: Implementation ──

    CA->>CI: "Proceed with /tdd-implement"
    CI->>CI: /tdd-implement (Phase 2 slices)
    CI->>CA: Phase 2 complete
    CA->>CA: Verify Phase 2

    Note over H,FS: ── Phase 3 (final) ──

    CA->>CC: "Run /tdd-plan Phase 3"
    CC->>CC: /tdd-plan (archive Phase 2, spawn planner for Phase 3)
    CC->>H: Present planner's Phase 3 slice plan, approve
    CC->>FS: Write .tdd-progress.md (Phase 3 slices)
    CA->>CI: "Proceed"
    CI->>CI: /tdd-implement
    CI->>CA: Phase 3 complete
    CA->>CA: Verify all phases

    Note over H,FS: ── Release ──

    CA->>CI: "Proceed with /tdd-release"
    CI->>CI: /tdd-release (spawns releaser agent)
    CI->>FS: CHANGELOG, version bump, push, PR
    CI->>CA: PR created
    CI->>CI: /tdd-finalize-docs (spawns doc-finalizer agent)
    CA->>CA: Review PR, write verification summary
    CA->>CI: "Merge"
    CI->>CI: gh pr merge
```

---

## 8. File Lifecycle Across Phases

```
Time →
────────────────────────────────────────────────────────────────────→

.tdd-phases.md (persistent, per-feature):
  Created by decomposer agent ───────────────────────────────────→
  [Phase 1: pending]    [Phase 1: done]     [Phase 2: done]     [all done]
                        ↑ updated by        ↑ updated by
                        /tdd-plan           /tdd-plan

.tdd-progress.md (ephemeral, per-phase):
  ┌─Phase 1 slices─┐           ┌─Phase 2 slices─┐     ┌─Phase 3─┐
  │ slices created  │ archived  │ slices created  │ arch│ slices  │ archived
  │ by planner      │ by next   │ by planner      │ by  │ created │ by
  │ agent           │ /tdd-plan │ agent           │ next│ by plan.│ /tdd-
  │ consumed by     │ ────→     │ consumed by     │ ──→ │ agent   │ release
  │ /tdd-implement  │ planning/ │ /tdd-implement  │     │         │ ──→
  └─────────────────┘           └─────────────────┘     └─────────┘
                                                                  planning/

planning/ directory (archives):
                      phase-1-*.md          phase-2-*.md    phase-3-*.md
                      (archived)            (archived)      (archived)

Feature branch (single branch, all phases):
  ┌──created by /tdd-implement (Phase 1) ─────────────────pushed──→ PR
  │  Phase 2 and 3 commits added to same branch
```

---

## 9. Three-Session Model (Revised)

```
┌──────────────────────────────────────────────────────────┐
│                     HUMAN DEVELOPER                       │
│                                                           │
│  Provides: feature ideas, feedback, approvals, judgment   │
│  Receives: agent proposals (plans, phases, roles)         │
└─────────┬──────────────────┬──────────────────┬──────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  CA Session   │  │  CC Session   │  │  CI Session   │
│  (Architect)  │  │  (No role)    │  │  (Implementer)│
│              │  │              │  │              │
│ Role file:   │  │ No role file │  │ Role file:   │
│ context/     │  │ Plugin gives │  │ context/     │
│ roles/       │  │ everything   │  │ roles/       │
│ ca-arch...md │  │ needed       │  │ ci-impl...md │
│              │  │              │  │              │
│ Owns:        │  │ Runs:        │  │ Runs:        │
│ • Spec       │  │ • /tdd-plan  │  │ • /tdd-      │
│ • Decisions  │  │   (planner   │  │   implement  │
│ • Issues     │  │    creates   │  │ • /tdd-      │
│ • Memory     │  │    slices)   │  │   release    │
│ • Verify     │  │ • /tdd-      │  │ • /tdd-      │
│              │  │   decompose  │  │   finalize-  │
│ Reviews:     │  │   (decomposer│  │   docs       │
│ • Planner's  │  │    creates   │  │ • Direct     │
│   slice plan │  │    phases)   │  │   edits      │
│ • Decomposer │  │ • /tdd-      │  │ • Merge PR   │
│   phases     │  │   init-roles │  │              │
│ • Impl.      │  │              │  │ Persistent:  │
│   results    │  │ Disposable:  │  │ Lives across │
│ • PR         │  │ Open, run    │  │ all phases   │
│              │  │ skill, close.│  │              │
│ Persistent:  │  │              │  │              │
│ Lives across │  │              │  │              │
│ all phases   │  │              │  │              │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       │    ┌────────────┘                 │
       │    │                              │
       ▼    ▼                              ▼
┌──────────────────────────────────────────────────────────┐
│                   tdd-workflow Plugin                      │
│                                                           │
│  Agents: planner (creates slices), implementer,           │
│          verifier, releaser, doc-finalizer,                │
│          context-updater,                                  │
│          role-initializer (new), decomposer (new)         │
│                                                           │
│  Skills: /tdd-plan (modified), /tdd-implement,            │
│          /tdd-release, /tdd-finalize-docs,                │
│          /tdd-update-context,                              │
│          /tdd-decompose (new), /tdd-init-roles (new),     │
│          /tdd-status (new)                                │
│                                                           │
│  State:  .tdd-progress.md (slices by planner, per-phase)  │
│          .tdd-phases.md (phases by decomposer) (new)      │
│                                                           │
│  Hooks:  validate-tdd-order, auto-run-tests,              │
│          planner-bash-guard, check-tdd-progress,          │
│          check-release-complete, R-G-R validation,        │
│          git context injection,                            │
│          SessionStart detector (new)                      │
└──────────────────────────────────────────────────────────┘
```

---

## 10. Summary of Proposed Changes

### New Components

| Component | Type | Purpose |
|-----------|------|---------|
| `/tdd-decompose` | Skill + Agent | Decomposer agent proposes phase breakdown → `.tdd-phases.md` |
| `/tdd-init-roles` | Skill + Agent | Role-initializer agent generates project-specific CA + CI roles (optional) |
| `/tdd-status` | Skill (inline) | Report TDD session state (phase + slice level) |
| `.tdd-phases.md` | State file | Master phase plan — tracks phase status, enables transitions |
| SessionStart hook | Hook | Auto-detect active TDD session on startup |

### Modified Components

| Component | Change |
|-----------|--------|
| `/tdd-plan` skill | Phase-aware branching: detect completed phases, archive, auto-transition, cross-phase context gathering. Planner agent still does all slice creation. |
| `docs/dev-roles/cp-planner.md` | Deprecation notice (absorbed by `/tdd-plan` + tdd-planner agent) |

### Unchanged Components

| Component | Why Unchanged |
|-----------|---------------|
| `tdd-planner` agent | Creates slices for whatever scope it's given — phase-agnostic |
| `tdd-implementer` agent | Implements pending slices — phase-agnostic |
| `tdd-verifier` agent | Verifies any slice — phase-agnostic |
| `tdd-releaser` agent | Releases whatever is on the branch |
| `tdd-doc-finalizer` agent | Updates docs based on CHANGELOG |
| `/tdd-implement` skill | Processes pending slices in .tdd-progress.md |
| `/tdd-release` skill | Ships the feature (all phases on one branch) |
| All existing hooks | Enforcement unchanged (agent-level and plugin-level) |
| Convention skills (4) | Auto-loaded based on file type |

### Who Creates What

| Artifact | Created By | Reviewed By |
|----------|-----------|-------------|
| Feature spec (issues, CLAUDE.md) | CA + human | — |
| Phase breakdown (.tdd-phases.md) | Decomposer agent | CA + human |
| Slice plan (.tdd-progress.md) | Planner agent | CA + human |
| Code + tests | Implementer agent | Verifier agent, then CA |
| Role files (context/roles/) | Role-initializer agent | CA + human |
| CHANGELOG, version | Releaser agent | CA |
| Doc updates | Doc-finalizer agent | CA |

---

*All diagrams reflect the proposed workflow as of 2026-03-15.
Render Mermaid diagrams at https://mermaid.live or on GitHub.*
