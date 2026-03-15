# Proposed TDD Workflow — Visual Reference

> **Date:** 2026-03-15
> **Purpose:** Visual representation of the proposed workflow modifications
> for review before implementation. Incorporates all concepts from this
> exploration session.
>
> **Diagrams use Mermaid syntax** — render on GitHub or any Mermaid viewer.

---

## 1. Overall Feature Lifecycle (End-to-End)

Shows the complete flow from empty project to shipped feature, with all
proposed components. Dashed boxes are new/modified components.

```mermaid
flowchart TD
    START([New Project]) --> SKELETON[Project Skeleton<br/>flutter create / cpp-template]
    SKELETON --> CA_SPEC[CA + Human Dialogue<br/>Write CLAUDE.md, issues/*.md]

    CA_SPEC --> INIT_V1["/tdd-init-roles [v1]<br/>⟨NEW⟩ Generate initial CA + CI roles<br/>from skeleton + spec"]
    INIT_V1 --> DECOMPOSE{Feature size?}

    DECOMPOSE -->|"≤ 5 slices"| PLAN_SINGLE["/tdd-plan ⟨feature⟩<br/>Single-phase planning"]
    DECOMPOSE -->|"> 5 slices"| TDD_DECOMPOSE["/tdd-decompose<br/>⟨NEW⟩ Break into phases<br/>→ .tdd-phases.md"]

    TDD_DECOMPOSE --> CA_REVIEW_PHASES[CA Reviews Phase Breakdown]
    CA_REVIEW_PHASES -->|Approve| PLAN_PHASE["/tdd-plan ⟨Phase N scope⟩<br/>Phase-aware planning<br/>→ .tdd-progress.md"]
    CA_REVIEW_PHASES -->|Modify| TDD_DECOMPOSE

    PLAN_SINGLE --> CA_REVIEW_PLAN[CA Reviews Plan]
    PLAN_PHASE --> CA_REVIEW_PLAN

    CA_REVIEW_PLAN -->|Approve| IMPLEMENT["/tdd-implement<br/>RED → GREEN → REFACTOR<br/>per slice"]
    CA_REVIEW_PLAN -->|Modify| PLAN_PHASE

    IMPLEMENT --> CA_VERIFY[CA Verifies Implementation]
    CA_VERIFY --> MORE_PHASES{More phases<br/>in .tdd-phases.md?}

    MORE_PHASES -->|Yes| INIT_V2["/tdd-init-roles [v2+]<br/>⟨NEW⟩ Refine roles with<br/>new codebase knowledge"]
    INIT_V2 --> PLAN_PHASE

    MORE_PHASES -->|No| RELEASE["/tdd-release<br/>CHANGELOG, version, push, PR"]

    RELEASE --> FINALIZE["/tdd-finalize-docs<br/>Update README, CLAUDE.md, docs/"]
    FINALIZE --> CA_PR_REVIEW[CA Reviews PR<br/>Writes verification summary]
    CA_PR_REVIEW --> MERGE[CI Merges PR]
    MERGE --> DONE([Feature Shipped])

    style INIT_V1 stroke-dasharray: 5 5,stroke:#f90
    style TDD_DECOMPOSE stroke-dasharray: 5 5,stroke:#f90
    style INIT_V2 stroke-dasharray: 5 5,stroke:#f90
    style MORE_PHASES stroke-dasharray: 5 5,stroke:#f90
```

---

## 2. Session Roles and Responsibilities

Shows which session (CA, CC, CI) owns each step. CP is retired.

```mermaid
flowchart LR
    subgraph CA ["CA Session (Architect)"]
        direction TB
        CA1[Write CLAUDE.md + Issues]
        CA2[Review phase breakdown]
        CA3[Review plan]
        CA4[Verify implementation]
        CA5[Review PR + verification summary]
        CA6[Manage MEMORY.md]
    end

    subgraph CC ["CC Session (Vanilla Claude Code)"]
        direction TB
        CC1["/tdd-decompose"]
        CC2["/tdd-plan Phase N"]
        CC3["Iterate on plan<br/>(resume planner)"]
    end

    subgraph CI ["CI Session (Implementer)"]
        direction TB
        CI1["/tdd-implement"]
        CI2["/tdd-release"]
        CI3["/tdd-finalize-docs"]
        CI4["Direct edits<br/>(CA authorized)"]
        CI5["Merge PR"]
    end

    CA1 -->|"spec + prompt"| CC1
    CC1 -->|"phase breakdown"| CA2
    CA2 -->|"approved phases"| CC2
    CC2 -->|"plan"| CA3
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

---

## 3. Phase Transition Detail

The critical lifecycle of `.tdd-progress.md` and `.tdd-phases.md` across
phase boundaries.

```mermaid
stateDiagram-v2
    [*] --> NoFiles: Project start

    NoFiles --> PhasesOnly: /tdd-decompose
    note right of PhasesOnly: .tdd-phases.md created<br/>All phases: pending

    PhasesOnly --> BothFiles: /tdd-plan Phase 1
    note right of BothFiles: .tdd-progress.md created<br/>(Phase 1 slices only)

    BothFiles --> Implementing: /tdd-implement
    note right of Implementing: Slices go from<br/>pending → done

    Implementing --> PhaseComplete: All slices terminal

    PhaseComplete --> PhasesOnly: /tdd-plan Phase N+1<br/>(auto-archives .tdd-progress.md<br/>updates .tdd-phases.md)

    PhaseComplete --> AllPhasesComplete: Last phase done

    AllPhasesComplete --> Released: /tdd-release
    note right of Released: .tdd-progress.md archived<br/>.tdd-phases.md: all done

    Released --> [*]
```

---

## 4. `/tdd-plan` Decision Tree (Modified)

Shows the proposed phase-aware branching logic in `/tdd-plan`.

```mermaid
flowchart TD
    START["/tdd-plan invoked"] --> CHECK_PROGRESS{.tdd-progress.md<br/>exists?}

    CHECK_PROGRESS -->|No| CHECK_PHASES_A{.tdd-phases.md<br/>exists?}
    CHECK_PHASES_A -->|No| PLAN_FULL["Plan full feature<br/>(current behavior)"]
    CHECK_PHASES_A -->|Yes| FIND_NEXT["Find first unplanned<br/>phase in .tdd-phases.md"]
    FIND_NEXT --> PLAN_PHASE["Plan that phase<br/>→ fresh .tdd-progress.md"]

    CHECK_PROGRESS -->|Yes| CHECK_PENDING{Has pending<br/>slices?}
    CHECK_PENDING -->|Yes| BLOCK_IMPL["⛔ 'Run /tdd-implement first'<br/>(current behavior)"]

    CHECK_PENDING -->|No, all terminal| CHECK_PHASES_B{.tdd-phases.md<br/>exists with<br/>more phases?}
    CHECK_PHASES_B -->|No| SUGGEST_RELEASE["💡 'All slices done.<br/>Run /tdd-release'<br/>(current behavior)"]
    CHECK_PHASES_B -->|Yes| ARCHIVE["Archive .tdd-progress.md<br/>→ planning/phase-N-*.md"]
    ARCHIVE --> UPDATE_PHASES["Update .tdd-phases.md<br/>Mark phase as done"]
    UPDATE_PHASES --> CONFIRM["Ask CA: proceed to<br/>next phase?"]
    CONFIRM -->|Yes| FIND_NEXT
    CONFIRM -->|No| STOP["Stop. CA can review<br/>before continuing."]

    style ARCHIVE stroke-dasharray: 5 5,stroke:#f90
    style UPDATE_PHASES stroke-dasharray: 5 5,stroke:#f90
    style CONFIRM stroke-dasharray: 5 5,stroke:#f90
    style FIND_NEXT stroke-dasharray: 5 5,stroke:#f90
```

---

## 5. `/tdd-init-roles` Iterative Lifecycle

Shows when role generation/refinement occurs relative to the development
lifecycle.

```mermaid
flowchart TD
    SKELETON[Project Skeleton] --> SPEC[CA writes spec]
    SPEC --> INIT1["/tdd-init-roles [v1]<br/>Skeleton + spec → initial roles"]

    INIT1 --> ROLES1["context/roles/<br/>ca-architect.md<br/>ci-implementer.md<br/>(architecture intent only)"]

    ROLES1 --> PLAN1[Plan Phase 1]
    PLAN1 --> IMPL1[Implement Phase 1]
    IMPL1 --> INIT2["/tdd-init-roles [v2]<br/>+ plan + code → refined roles"]

    INIT2 --> ROLES2["context/roles/ updated<br/>CI gets: file paths, test patterns,<br/>build commands, code examples"]
    INIT2 --> SUGGEST["↑ Suggest context changes to CA<br/>(CLAUDE.md improvements)"]

    ROLES2 --> PLAN2[Plan Phase 2]
    PLAN2 --> IMPL2[Implement Phase 2]
    IMPL2 -.->|"repeat for more phases"| PLAN2

    IMPL2 --> INITN["/tdd-init-roles [vN]<br/>Full codebase → mature roles"]
    INITN --> ROLESN["context/roles/ updated<br/>CI gets: real code examples,<br/>discovered patterns, API references"]

    ROLESN --> RELEASE["/tdd-release"]

    style INIT1 fill:#fff3cd,stroke:#ffc107
    style INIT2 fill:#fff3cd,stroke:#ffc107
    style INITN fill:#fff3cd,stroke:#ffc107
    style SUGGEST fill:#d1ecf1,stroke:#17a2b8
```

---

## 6. Component Map (Current vs. Proposed)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    tdd-workflow Plugin                              │
│                                                                     │
│  AGENTS (subagents)                                                 │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │ tdd-planner   │ │tdd-implementer│ │ tdd-verifier │               │
│  │ (opus, plan)  │ │ (opus, write) │ │(haiku, plan) │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │ tdd-releaser  │ │tdd-doc-final.│ │context-updater│               │
│  │(sonnet, bash) │ │(sonnet, edit)│ │ (opus, write) │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
│  ┌ ─ ─ ─ ─ ─ ─ ┐                                                  │
│  │role-initializer│  ⟨NEW⟩ Researches project, generates roles      │
│  │ (opus, write) │                                                  │
│  └ ─ ─ ─ ─ ─ ─ ┘                                                  │
│  ┌ ─ ─ ─ ─ ─ ─ ┐                                                  │
│  │ decomposer    │  ⟨NEW⟩ Breaks features into phases               │
│  │ (opus, read)  │                                                  │
│  └ ─ ─ ─ ─ ─ ─ ┘                                                  │
│                                                                     │
│  SKILLS (user-invocable)                                            │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────┐                 │
│  │ /tdd-plan    │ │/tdd-implement│ │ /tdd-release  │                 │
│  │ (fork→plan.) │ │ (inline)    │ │(fork→release.)│                 │
│  └─────────────┘ └─────────────┘ └──────────────┘                 │
│  ┌─────────────┐ ┌─────────────┐                                   │
│  │/tdd-final.-  │ │/tdd-update-  │                                   │
│  │  docs        │ │  context     │                                   │
│  └─────────────┘ └─────────────┘                                   │
│  ┌ ─ ─ ─ ─ ─ ─┐ ┌ ─ ─ ─ ─ ─ ─┐ ┌ ─ ─ ─ ─ ─ ─ ┐                │
│  │/tdd-decompose│ │/tdd-init-   │ │ /tdd-status   │  ⟨NEW⟩          │
│  │(fork→decomp.)│ │  roles      │ │ (inline)      │                 │
│  └ ─ ─ ─ ─ ─ ─┘ │(fork→role-i.)│ └ ─ ─ ─ ─ ─ ─ ┘                │
│                   └ ─ ─ ─ ─ ─ ─┘                                   │
│                                                                     │
│  SKILLS (auto-loaded, not user-invocable)                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │dart-flutter- │ │cpp-testing-  │ │bash-testing-  │ │c-conventions│ │
│  │ conventions  │ │ conventions  │ │ conventions  │ │             │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
│                                                                     │
│  FILES (state tracking)                                             │
│  ┌─────────────────┐ ┌ ─ ─ ─ ─ ─ ─ ─ ─┐                          │
│  │.tdd-progress.md  │ │.tdd-phases.md    │  ⟨NEW⟩ Master phase plan │
│  │(current phase     │ │(all phases,       │                          │
│  │ slices, ephemeral)│ │ persistent)       │                          │
│  └─────────────────┘ └ ─ ─ ─ ─ ─ ─ ─ ─┘                          │
│                                                                     │
│  HOOKS                                                              │
│  ┌──────────────────────────────────────┐                          │
│  │ PreToolUse:  validate-tdd-order.sh   │                          │
│  │              planner-bash-guard.sh    │                          │
│  │ PostToolUse: auto-run-tests.sh       │                          │
│  │ SubagentStop: R-G-R validation       │                          │
│  │               check-release-complete │                          │
│  │ Stop:        check-tdd-progress.sh   │                          │
│  │              validate-plan-output.sh  │                          │
│  │              check-release-complete   │                          │
│  │ SubagentStart: git context injection  │                          │
│  │ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │                          │
│  │ │SessionStart: TDD session detect  │ │  ⟨NEW⟩                    │
│  │ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │                          │
│  └──────────────────────────────────────┘                          │
│                                                                     │
│  ROLE DOCS (reference, not components)                              │
│  ┌────────────────────────────────────────┐                        │
│  │ docs/dev-roles/ca-architect.md  (generic, bootstrap)            │
│  │ docs/dev-roles/ci-implementer.md (generic, bootstrap)           │
│  │ docs/dev-roles/cp-planner.md    (deprecated — use /tdd-plan)    │
│  └────────────────────────────────────────┘                        │
│                                                                     │
│  PER-PROJECT OUTPUT (generated by /tdd-init-roles)                  │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐                        │
│  │ context/roles/ca-architect.md  (project-specific)               │
│  │ context/roles/ci-implementer.md (project-specific)              │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

Legend:  ┌──────┐ = existing     ┌ ─ ─ ─┐ = proposed new
```

---

## 7. Phased Planning Sequence (Detailed)

A complete walkthrough of a 3-phase feature.

```mermaid
sequenceDiagram
    participant H as Human
    participant CA as CA Session
    participant CC as CC Session
    participant CI as CI Session
    participant FS as Filesystem

    Note over H,FS: ── Phase Decomposition ──

    H->>CA: Define feature scope
    CA->>CA: Write issues/*.md + CLAUDE.md
    CA->>CC: "Run /tdd-decompose <feature>"
    CC->>CC: /tdd-decompose
    CC->>FS: Research project structure
    CC->>H: Proposed phases (AskUserQuestion)
    H->>CC: Approve with modifications
    CC->>FS: Write .tdd-phases.md
    CC->>CA: Phase breakdown ready

    Note over H,FS: ── Phase 1 ──

    CA->>CC: "Run /tdd-plan Phase 1: Foundation"
    CC->>CC: /tdd-plan (reads .tdd-phases.md)
    CC->>FS: Write .tdd-progress.md (Phase 1 slices)
    CC->>CA: Plan ready for review
    CA->>CA: Review plan
    CA->>CI: "Proceed with /tdd-implement"
    CI->>CI: /tdd-implement (Phase 1 slices only)
    CI->>FS: Code + tests + commits
    CI->>CA: Phase 1 implementation complete
    CA->>CA: Verify Phase 1

    Note over H,FS: ── Phase Transition 1→2 ──

    CA->>CC: "Run /tdd-plan Phase 2: Data Layer"
    CC->>CC: /tdd-plan detects completed .tdd-progress.md
    CC->>FS: Archive .tdd-progress.md → planning/
    CC->>FS: Update .tdd-phases.md (Phase 1 → done)
    CC->>H: "Proceed to Phase 2?" (AskUserQuestion)
    H->>CC: Yes
    CC->>CC: Plan Phase 2 (reads git diff for cross-phase context)
    CC->>FS: Write fresh .tdd-progress.md (Phase 2 slices)

    Note over H,FS: ── Phase 2 ──

    CC->>CA: Plan ready for review
    CA->>CA: Review plan
    CA->>CI: "Proceed with /tdd-implement"
    CI->>CI: /tdd-implement (Phase 2 slices only)
    CI->>CA: Phase 2 complete
    CA->>CA: Verify Phase 2

    Note over H,FS: ── Phase 3 (final) ──

    CA->>CC: "Run /tdd-plan Phase 3: Wiring"
    CC->>CC: /tdd-plan (archive Phase 2, plan Phase 3)
    CC->>CA: Plan ready
    CA->>CI: "Proceed"
    CI->>CI: /tdd-implement
    CI->>CA: Phase 3 complete
    CA->>CA: Verify all phases

    Note over H,FS: ── Release ──

    CA->>CI: "Proceed with /tdd-release"
    CI->>CI: /tdd-release (all phases on one branch)
    CI->>FS: CHANGELOG, version bump, push, PR
    CI->>CA: PR created
    CA->>CA: Write verification summary
    CA->>CI: "Merge"
    CI->>CI: gh pr merge
```

---

## 8. File Lifecycle Across Phases

```
Time →
────────────────────────────────────────────────────────────────────→

.tdd-phases.md:
  Created by /tdd-decompose ─────────────────────────────────────→
  [Phase 1: pending] → [Phase 1: done] → [Phase 2: done] → [all done]

.tdd-progress.md:
  ┌─Phase 1 slices─┐           ┌─Phase 2 slices─┐     ┌─Phase 3─┐
  │ created by      │ archived  │ created by      │ arch│ ...     │ archived
  │ /tdd-plan       │ ────→     │ /tdd-plan       │ ──→ │         │ ────→
  │ consumed by     │ planning/ │ consumed by     │     │         │ planning/
  │ /tdd-implement  │           │ /tdd-implement  │     │         │
  └─────────────────┘           └─────────────────┘     └─────────┘

planning/ directory:
                      phase-1-*.md          phase-2-*.md    phase-3-*.md
                      (archived)            (archived)      (archived)

Feature branch:
  ┌──created────────────────────────────────────────────pushed──→ PR
  │  by /tdd-implement (Phase 1 slices on same branch as 2 and 3)
```

---

## 9. Three-Session Model (Revised)

```
┌──────────────────────────────────────────────────────────┐
│                     HUMAN DEVELOPER                       │
│                                                           │
│  Provides: feature ideas, feedback, approvals, judgment   │
│  Receives: plans, implementation results, verification    │
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
│ • Decisions  │  │ • /tdd-plan  │  │ • /tdd-impl. │
│ • Issues     │  │ • /tdd-decomp│  │ • /tdd-rel.  │
│ • Memory     │  │              │  │ • /tdd-fin.  │
│ • Verification│ │ Disposable:  │  │ • Direct edits│
│              │  │ Open, plan,  │  │              │
│ Persistent:  │  │ close.       │  │ Persistent:  │
│ Lives across │  │              │  │ Lives across │
│ all phases   │  │              │  │ all phases   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       │    ┌────────────┘                 │
       │    │                              │
       ▼    ▼                              ▼
┌──────────────────────────────────────────────────────────┐
│                   tdd-workflow Plugin                      │
│                                                           │
│  Agents: planner, implementer, verifier, releaser,        │
│          doc-finalizer, context-updater,                   │
│          role-initializer (new), decomposer (new)         │
│                                                           │
│  Skills: /tdd-plan, /tdd-implement, /tdd-release,         │
│          /tdd-finalize-docs, /tdd-update-context,          │
│          /tdd-decompose (new), /tdd-init-roles (new),     │
│          /tdd-status (new)                                │
│                                                           │
│  State:  .tdd-progress.md (ephemeral, per-phase)          │
│          .tdd-phases.md (persistent, per-feature) (new)   │
│                                                           │
│  Hooks:  validate-tdd-order, auto-run-tests,              │
│          check-tdd-progress, planner-bash-guard,           │
│          validate-plan-output, check-release-complete,     │
│          SessionStart detector (new)                      │
└──────────────────────────────────────────────────────────┘
```

---

## 10. Summary of Proposed Changes

### New Components

| Component | Type | Purpose |
|-----------|------|---------|
| `/tdd-decompose` | Skill + Agent | Break large features into phases |
| `/tdd-init-roles` | Skill + Agent | Generate project-specific CA + CI role files |
| `/tdd-status` | Skill (inline) | Report TDD session state (phase + slice level) |
| `.tdd-phases.md` | State file | Master phase plan (enables phase transitions) |
| SessionStart hook | Hook | Auto-detect active TDD session on startup |

### Modified Components

| Component | Change |
|-----------|--------|
| `/tdd-plan` | Phase-aware branching: archive completed phases, auto-transition |
| `docs/dev-roles/cp-planner.md` | Deprecation notice (absorbed by plugin) |

### Unchanged Components

| Component | Why Unchanged |
|-----------|---------------|
| `tdd-planner` agent | Plans whatever scope it's given — phase-agnostic |
| `tdd-implementer` agent | Implements pending slices — phase-agnostic |
| `tdd-verifier` agent | Verifies any slice — phase-agnostic |
| `tdd-releaser` agent | Releases whatever is on the branch |
| `tdd-doc-finalizer` agent | Updates docs based on CHANGELOG |
| `/tdd-implement` skill | Processes pending slices in .tdd-progress.md |
| `/tdd-release` skill | Ships the feature (all phases on one branch) |
| All hooks (except new) | Existing enforcement unchanged |
| Convention skills | Auto-loaded based on file type |

---

*All diagrams reflect the proposed workflow as of 2026-03-15.
Render Mermaid diagrams at https://mermaid.live or on GitHub.*
