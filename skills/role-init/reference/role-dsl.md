# Role DSL v1.0

> Formal grammar for TDD workflow session role files.
> The `role-initializer` agent reads this as its primary reference.
> Templates are instances; this is the law.

```role-dsl

# ═══════════════════════════════════════════════════════
#  TYPE SYSTEM
# ═══════════════════════════════════════════════════════

enum SectionKind   { FIXED, DYNAMIC, HYBRID }
enum RoleCode      { CA, CI, CP }
enum Lifecycle     { v1, v2, v3, vN }
enum ContentSource {
  template,          # from plugin reference/ files
  codebase,          # from Glob, Grep, Read of project files
  claude_md,         # from project CLAUDE.md
  agent_memory,      # from .claude/agent-memory/*/MEMORY.md
  auto_memory,       # from shared MEMORY.md
  user_input,        # from AskUserQuestion
  detect_script,     # from detect-project-context.sh
  convention_cache,  # from tdd-conventions.json sources
  git                # from git log, git status, git branch
}


# ═══════════════════════════════════════════════════════
#  DOCUMENT STRUCTURE
# ═══════════════════════════════════════════════════════

document RoleFile {
  header    : Header         @required
  body      : Section[]      @ordered @min(6)
  encoding  : UTF-8
  format    : Markdown (CommonMark)
  max_lines : 400            @warn_at(300)
}

document ContextFile extends RoleFile {
  # CP uses this variant — planning context, not session identity
  header    : ContextHeader  @required
  body      : Section[]      @ordered @min(3)
}


# ═══════════════════════════════════════════════════════
#  HEADERS
# ═══════════════════════════════════════════════════════

struct Header {
  role_code    : RoleCode           @render("# {value}")
  role_name    : string             @render("# {role_code} — {value}")
  rationale    : text               @max_sentences(2)
                                    @render("> **Why a separate session?** {value}")
  project      : string             @source(codebase)
  tech_stack   : string             @source(detect_script)
  generated    : datetime           @format(ISO-8601)
                                    @render("> **Generated:** {value} by /role-init (stage {stage})")
  stage        : Lifecycle
  generator    : literal("/role-init")
}

struct ContextHeader {
  title        : literal("CP — Planning Context")
  notice       : literal("This file provides project-specific planning context. The tdd-planner agent handles the behavioral role. Load this into any planning session to improve plan quality.")
  project      : string             @source(codebase)
  tech_stack   : string             @source(detect_script)
  generated    : datetime           @format(ISO-8601)
  stage        : Lifecycle
}


# ═══════════════════════════════════════════════════════
#  SECTION DEFINITIONS
# ═══════════════════════════════════════════════════════

# ─── FIXED Sections ───────────────────────────────────
# Identical across all projects. Source: plugin templates.
# The role-initializer copies these verbatim.
# /role-evolve must NEVER modify FIXED sections.

section Identity {
  kind     : FIXED
  scope    : [CA, CI]
  source   : [template]
  order    : 1
  rule     : "2-3 sentences. Establishes WHO this session is and HOW it operates."
  rule     : "Must reference relationship to other roles."
  content  : |
    ## Identity

    You are the **{header.role_code} ({header.role_name})** session for
    the {header.project} project. {role_specific_description}
}

section Responsibilities {
  kind     : FIXED
  scope    : [CA, CI]
  source   : [template]
  order    : 2
  rule     : "Organized by functional area, each with concrete actions."
  rule     : "Actions must be ACTIONABLE — not 'understand X' but 'read X and summarize Y'."
  rule     : "Each responsibility must produce a visible output."
  render   : |
    ## Responsibilities

    ### {area_name}
    - {specific_action_with_expected_output}
}

section Constraints {
  kind     : FIXED
  scope    : [CA, CI]
  source   : [template]
  order    : 3
  rule     : "Few and ABSOLUTE. Not preferences, not suggestions."
  rule     : "Each constraint must explain WHY — what breaks if violated."
  rule     : "Maximum 5 constraints per role."
  validate : constraint.count <= 5
  validate : each(constraint).has_reason == true
  render   : |
    ## Constraints

    - **{constraint}.** {reason}
}

section MemoryScope {
  kind     : FIXED
  scope    : [CA, CI]
  source   : [template]
  order    : 4
  rule     : "Defines reads/writes relationship to the four memory layers."
  rule     : "Must specify: auto-memory, agent memory, .tdd-progress.md, git."
  render   : |
    ## Memory

    {role_code} **{access_level}** shared memory.

    | Layer | Access | Purpose |
    |---|---|---|
    | Auto-memory (MEMORY.md) | {access} | {purpose} |
    | Agent memory | {access} | {purpose} |
    | .tdd-progress.md | {access} | {purpose} |
    | Git | {access} | {purpose} |
}

section HandoffPatterns {
  kind     : FIXED
  scope    : [CA, CI]
  source   : [template]
  order    : 8
  rule     : "Defines inputs and outputs of each inter-role interaction."
  rule     : "Handoffs are human-mediated — document what the human carries."
  render   : |
    ## Handoff Patterns

    ### To {other_role} ({purpose})
    {what_to_provide_and_format}

    ### From {other_role} ({purpose})
    {what_to_expect_and_action}
}


# ─── HYBRID Sections ──────────────────────────────────
# Fixed STRUCTURE from templates + dynamic CONTENT from research.
# The role-initializer fills in project-specific details within
# the fixed framework. /role-evolve may update dynamic content
# but must preserve the structure.

section StartupChecklist {
  kind     : HYBRID
  scope    : [CA, CI]
  source   : [template, auto_memory, git]
  order    : 5
  fixed    : "Numbered checklist structure, first 3 steps always identical."
  dynamic  : "Project-specific recovery steps appended."
  rule     : "Steps must be concrete and idempotent — safe to re-run."
  render   : |
    ## Startup Checklist

    On fresh start or recovery after interruption:

    1. Read `MEMORY.md` for current project state
    2. Read `.tdd-progress.md` if it exists (active TDD session)
    3. Check `git log --oneline -10` and `git branch` for recent activity
    4. {project_specific_recovery_step}
    5. {state_assessment}
    6. {what_to_do_next}
}

section WorkflowProcedures {
  kind     : HYBRID
  scope    : [CA, CI]
  source   : [template, convention_cache, codebase]
  order    : 6
  fixed    : "Procedure names and step structure."
  dynamic  : "Convention paths, file references, project-specific checks."
  rule     : "Encodes REPEATED instructions the developer would otherwise type manually."
  rule     : "Each procedure must be a numbered checklist the session follows WITHOUT prompting."
  rule     : "Convention references must point to DISCOVERED paths, not placeholders."

  # CA-specific procedures
  @scope(CA)
  render   : |
    ## Workflow Procedures

    ### Plan Review
    Before analyzing a plan from CP:
    1. Read MEMORY.md for current project state and decisions
    2. Read the issue file that prompted this plan
    3. Read convention docs at: {discovered_convention_paths}
    4. Read .tdd-progress.md (the plan output)
    5. Evaluate against acceptance criteria in the issue
    6. Check slice independence, test coverage, dependency ordering

    ### Verification
    After CI completes implementation:
    1. Read .tdd-progress.md for slice completion status
    2. Run: {test_command}
    3. Run: {static_analysis_command}
    4. Compare test counts: before vs after
    5. Review commit messages for conventional commit compliance
    6. Produce verification summary (see format below)

  # CI-specific procedures
  @scope(CI)
  render   : |
    ## Workflow Procedures

    ### Implementation Preparation
    Before running /tdd-implement:
    1. Read MEMORY.md for current project state
    2. Check `git status` for uncommitted changes from prior sessions
    3. Confirm correct feature branch: `git branch --show-current`
    4. Read .tdd-progress.md for pending slices
    5. Verify build environment: {build_verify_command}

    ### Post-Implementation Report
    After /tdd-implement completes:
    1. Count completed slices and test totals
    2. Note any deviations from the plan
    3. Report to CA and wait for verification
}

section ProjectContext {
  kind     : DYNAMIC
  scope    : [CA, CI, CP]
  source   : [codebase, claude_md, detect_script]
  order    : 7
  rule     : "Brief project overview — same across all three roles."
  rule     : "Must reference ACTUAL project values, never placeholders."
  validate : each(field).is_placeholder == false
  render   : |
    ## Project Context

    **Project:** {project_name}
    **Tech stack:** {language}, {framework}, {key_dependencies}
    **Architecture:** {pattern}
    **Build system:** {tool} — `{build_command}`
    **Test framework:** {tool} — `{test_command}`
    **Static analysis:** {tool} — `{analysis_command}`
}


# ─── DYNAMIC Sections ─────────────────────────────────
# Entirely generated from research. No template content.
# /role-evolve freely updates these.

section ArchitectureNotes {
  kind     : DYNAMIC
  scope    : [CA]
  source   : [codebase, claude_md, user_input]
  order    : 9
  rule     : "Key architectural patterns and WHY they were chosen."
  rule     : "Module boundaries and their contracts."
  rule     : "Known technical debt or constraints."
  render   : |
    ### Architecture Notes
    - {pattern}: {rationale}
    - {boundary}: {contract}
    - {debt_or_constraint}
}

section CrossRepoRelationships {
  kind     : DYNAMIC
  scope    : [CA]
  source   : [user_input, codebase]
  order    : 10
  rule     : "Only present if related projects exist."
  rule     : "Must specify relationship TYPE: shared protocol, dependency, consumer."
  optional : true
  render   : |
    ### Cross-Repo Relationships
    - **{related_project}** ({relationship_type}): {what_is_shared}
}

section DecisionHistory {
  kind     : DYNAMIC
  scope    : [CA]
  source   : [claude_md, auto_memory, user_input]
  order    : 11
  rule     : "Key decisions already made and their rationale."
  rule     : "Open questions or deferred decisions."
  render   : |
    ### Decision History
    - {decision}: {rationale}

    ### Open Questions
    - {question}
}

section VerificationFocus {
  kind     : DYNAMIC
  scope    : [CA]
  source   : [codebase, agent_memory, user_input]
  order    : 12
  rule     : "What to check carefully during verification for THIS project."
  rule     : "Common mistake patterns in this codebase."
  rule     : "May draw from verifier agent memory if available."
  render   : |
    ### Verification Focus Areas
    - {focus_area}: {why_it_matters}

    ### Common Mistake Patterns
    - {pattern}: {how_to_catch}
}

section ConventionReferences {
  kind     : DYNAMIC
  scope    : [CA, CP]
  source   : [convention_cache, detect_script]
  order    : 13
  rule     : "Paths to convention docs discovered during research."
  rule     : "Key patterns summarized (3-5 bullets), not full docs."
  rule     : "Tells the session WHERE to find detail, not the detail itself."
  render   : |
    ### Convention References

    Convention docs for this project:
    - {convention_path}: {what_it_covers}

    Key patterns:
    - {pattern_summary}
}

section BuildCommands {
  kind     : DYNAMIC
  scope    : [CI]
  source   : [detect_script, codebase]
  order    : 9
  rule     : "Full commands with flags, verified against project config."
  rule     : "Must include: build, test, analyze, format."
  validate : has(build) && has(test) && has(analyze) && has(format)
  render   : |
    ### Build & Test Commands

    | Action | Command |
    |---|---|
    | Build | `{build_command}` |
    | Test | `{test_command}` |
    | Analyze | `{analyze_command}` |
    | Format | `{format_command}` |
}

section CodeExamples {
  kind     : DYNAMIC
  scope    : [CI]
  source   : [codebase]
  order    : 10
  rule     : "2-4 representative examples EXTRACTED from actual source files."
  rule     : "Never invented or generic — must cite the source file."
  rule     : "Each example demonstrates a KEY PATTERN the implementer must follow."
  validate : examples.count >= 2 && examples.count <= 4
  validate : each(example).has_source_citation == true
  render   : |
    ### Key Patterns (from actual source)

    #### {pattern_name} (`{source_file}`)
    ```{language}
    {extracted_code}
    ```
}

section ImplementationConstraints {
  kind     : DYNAMIC
  scope    : [CI]
  source   : [codebase, claude_md, convention_cache]
  order    : 11
  rule     : "Project-specific constraints discovered during research."
  rule     : "Naming conventions, import ordering, error handling patterns."
  render   : |
    ### Implementation Constraints
    - {constraint}: {detail}
}

section CommonPitfalls {
  kind     : DYNAMIC
  scope    : [CI]
  source   : [user_input, agent_memory, codebase]
  order    : 12
  rule     : "Things that look right but break in THIS project."
  rule     : "May draw from implementer/verifier agent memory if available."
  render   : |
    ### Common Pitfalls
    - {pitfall}: {how_to_avoid}
}

section DecompositionPatterns {
  kind     : DYNAMIC
  scope    : [CP]
  source   : [user_input, codebase]
  order    : 2
  rule     : "How features SHOULD be sliced for this project."
  rule     : "This is HUMAN knowledge the planner can't discover."
  render   : |
    ### Decomposition Patterns
    - {pattern}: {when_to_use}
}

section SliceOrdering {
  kind     : DYNAMIC
  scope    : [CP]
  source   : [user_input, codebase]
  order    : 3
  rule     : "What must be planned first — shared modules, core abstractions."
  rule     : "Dependency chains the planner should respect."
  render   : |
    ### Slice Ordering Constraints
    - {constraint}: {rationale}
}

section TestBatching {
  kind     : DYNAMIC
  scope    : [CP]
  source   : [detect_script, user_input]
  order    : 4
  rule     : "Test environment setup requirements."
  rule     : "Preferred test granularity for this project."
  render   : |
    ### Test Strategy
    - Test granularity: {preference}
    - Environment setup: {requirements}
    - {additional_batching_note}
}

section PlanningLearnings {
  kind     : DYNAMIC
  scope    : [CP]
  source   : [user_input, agent_memory]
  order    : 5
  rule     : "What was underestimated in past plans."
  rule     : "What patterns led to scope creep."
  rule     : "Only present at v2+ lifecycle stages."
  optional : true
  render   : |
    ### Historical Planning Learnings
    - {learning}: {context}
}

section APISurface {
  kind     : DYNAMIC
  scope    : [CP]
  source   : [codebase]
  order    : 6
  rule     : "Key public classes, functions, interfaces."
  rule     : "What the planner needs to know to decompose effectively."
  render   : |
    ### API Surface
    - `{class_or_function}`: {purpose}
}


# ═══════════════════════════════════════════════════════
#  ROLE COMPOSITIONS
# ═══════════════════════════════════════════════════════
# Which sections compose into which role file.

compose CA : RoleFile {
  sections : [
    Identity,                  # FIXED    — who CA is
    Responsibilities,          # FIXED    — what CA does
    Constraints,               # FIXED    — what CA must not do
    MemoryScope,               # FIXED    — what CA reads/writes
    StartupChecklist,          # HYBRID   — recovery procedure
    WorkflowProcedures,        # HYBRID   — plan review, verification
    ProjectContext,            # DYNAMIC  — project overview
    HandoffPatterns,           # FIXED    — coordination with CP, CI
    ArchitectureNotes,         # DYNAMIC  — architecture for THIS project
    CrossRepoRelationships,    # DYNAMIC  — related projects (optional)
    DecisionHistory,           # DYNAMIC  — what's been decided
    VerificationFocus,         # DYNAMIC  — what to check carefully
    ConventionReferences       # DYNAMIC  — where to find conventions
  ]
}

compose CI : RoleFile {
  sections : [
    Identity,                  # FIXED    — who CI is
    Responsibilities,          # FIXED    — what CI does
    Constraints,               # FIXED    — what CI must not do
    MemoryScope,               # FIXED    — what CI reads/writes
    StartupChecklist,          # HYBRID   — recovery procedure
    WorkflowProcedures,        # HYBRID   — implementation prep, reporting
    ProjectContext,            # DYNAMIC  — project overview
    HandoffPatterns,           # FIXED    — coordination with CA
    BuildCommands,             # DYNAMIC  — build/test/analyze/format
    CodeExamples,              # DYNAMIC  — 2-4 from actual source
    ImplementationConstraints, # DYNAMIC  — project-specific rules
    CommonPitfalls             # DYNAMIC  — things that break
  ]
}

compose CP : ContextFile {
  sections : [
    ProjectContext,            # DYNAMIC  — project overview
    DecompositionPatterns,     # DYNAMIC  — how to slice features
    SliceOrdering,             # DYNAMIC  — dependency constraints
    TestBatching,              # DYNAMIC  — test strategy
    PlanningLearnings,         # DYNAMIC  — past mistakes (v2+)
    APISurface,                # DYNAMIC  — key classes/functions
    ConventionReferences       # DYNAMIC  — where to find conventions
  ]
}


# ═══════════════════════════════════════════════════════
#  VALIDATION RULES
# ═══════════════════════════════════════════════════════

validate RoleFile {
  # Structure
  assert header.role_code in [CA, CI]
  assert body.length >= 6
  assert body.is_ordered_by(section.order)

  # Content quality
  assert no_section.contains("{placeholder}")
  assert no_section.contains("TODO")
  assert no_section.contains("TBD")

  # FIXED section integrity
  assert each(section where kind == FIXED).matches_template == true

  # DYNAMIC section sourcing
  assert each(section where kind == DYNAMIC).has_source_citation == true

  # File paths
  assert each(mentioned_path).exists_on_disk == true

  # Code examples (CI only)
  assert each(code_example).extracted_from_actual_source == true
  assert each(code_example).source_file_cited == true
}

validate ContextFile {
  # Structure
  assert header.title == "CP — Planning Context"
  assert header.notice.contains("tdd-planner agent handles the behavioral role")
  assert body.length >= 3

  # Content quality
  assert no_section.contains("{placeholder}")
}


# ═══════════════════════════════════════════════════════
#  LIFECYCLE RULES
# ═══════════════════════════════════════════════════════

lifecycle {
  # /role-init generates fresh files
  on_init {
    FIXED   sections : copy_from(template)
    HYBRID  sections : merge(template.structure, research.content)
    DYNAMIC sections : generate_from(research)
  }

  # /role-evolve updates existing files
  on_evolve {
    FIXED   sections : NEVER_MODIFY
    HYBRID  sections : update(dynamic_content_only)
    DYNAMIC sections : regenerate_or_patch(from: agent_memory + auto_memory)
  }

  # /role-ca, /role-cp, /role-ci deliver into session
  on_deliver {
    load : role_file via DCI
    load : conventions via load-conventions.sh
    exec : startup_checklist
  }
}


# ═══════════════════════════════════════════════════════
#  SOURCE PRIORITY
# ═══════════════════════════════════════════════════════
# When sources conflict, higher priority wins.

priority {
  1 : user_input          # human always overrides
  2 : codebase            # actual code is ground truth
  3 : claude_md           # project documentation
  4 : agent_memory        # machine-learned knowledge
  5 : convention_cache    # language conventions
  6 : detect_script       # automated detection
  7 : template            # plugin defaults
}

```

---

## Reading Guide

| Concept | Meaning |
|---|---|
| `FIXED` | Content from plugin templates — identical across projects, never modified by evolve |
| `DYNAMIC` | Content generated from research — project-specific, freely updated by evolve |
| `HYBRID` | Fixed structure from templates + dynamic content from research |
| `@source(x)` | Where this value comes from |
| `@scope(ROLE)` | Section variant specific to a role |
| `@required` | Must be present in every valid file |
| `@optional` | May be absent (noted in section definition) |
| `validate` | Assertion that must be true for a valid role file |
| `compose` | Which sections make up each role's file |
| `priority` | Conflict resolution when sources disagree |
| `lifecycle` | What happens to each section kind during init/evolve/deliver |
