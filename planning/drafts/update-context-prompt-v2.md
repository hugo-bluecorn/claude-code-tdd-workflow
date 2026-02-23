# Plan-Mode Prompt: Update Plugin Context Reference Files (v2)

> **Usage:** Copy the prompt section below and paste it when entering plan mode.
> After testing, iterate on this prompt before encoding as a skill + agent.
>
> **Changes from v1:** Added breaking-change detection phase, source verification
> step, file-size guidance, and clarified output is proposal-only (no edits).

---

## Prompt

```
Update all reference context markdown files in the TDD workflow plugin to
reflect current best practices, latest framework versions, and any gaps
discovered through analysis. This is a PROPOSAL ONLY — produce an actionable
change list, do not edit any files.

### Scope

The plugin lives at the project root and contains reference context files
that agents read during TDD planning and implementation. These files must
stay accurate and current. The files to evaluate and update:

**Dart/Flutter Conventions** (`skills/dart-flutter-conventions/`):
- `reference/test-patterns.md` — unit, widget, integration test patterns
- `reference/mocking-guide.md` — mockito, mocktail patterns
- `reference/widget-testing.md` — pumpWidget, Finder, interaction patterns
- `reference/project-conventions.md` — architecture, style, Riverpod state mgmt
- `SKILL.md` — convention overview and quick reference

**C++ Conventions** (`skills/cpp-testing-conventions/`):
- `reference/googletest-patterns.md` — TEST, TEST_F, assertions, parameterized
- `reference/cmake-integration.md` — CMakeLists.txt, FetchContent, ctest
- `reference/googlemock-guide.md` — MOCK_METHOD, EXPECT_CALL, matchers
- `SKILL.md` — convention overview and quick reference

**Bash Conventions** (`skills/bash-testing-conventions/`):
- `reference/bashunit-patterns.md` — test functions, assertions
- `reference/shellcheck-guide.md` — static analysis, common warnings
- `SKILL.md` — convention overview and quick reference

**Planning Templates** (`skills/tdd-plan/reference/`):
- `tdd-task-template.md` — slice format (Given/When/Then)
- `feature-notes-template.md` — planning archive format

**Agent Definitions** (`agents/`):
- `tdd-planner.md`, `tdd-implementer.md`, `tdd-verifier.md`, `tdd-releaser.md`

**Workflow Skills**:
- `skills/tdd-plan/SKILL.md`, `skills/tdd-implement/SKILL.md`, `skills/tdd-release/SKILL.md`

### Process

For each convention stack (Dart/Flutter, C++, Bash), follow this sequence:

#### Phase 1: Research Current State
1. Read every reference file in the stack thoroughly
2. Note the framework versions, API patterns, and conventions documented
3. Identify any internal inconsistencies between files in the same stack
4. Check cross-references between SKILL.md and its reference/ files

#### Phase 2: Research Latest Versions
5. Web search for the latest stable versions of each framework:
   - Dart/Flutter: Flutter SDK, Dart SDK, Riverpod, mockito, mocktail, flutter_test
   - C++: GoogleTest, GoogleMock, CMake (FetchContent patterns)
   - Bash: bashunit, shellcheck
6. When web search results are vague or missing specific version numbers,
   follow up by fetching the official release page or pub.dev/versions
   page directly. Do not leave version numbers as "unknown" — confirm them.

#### Phase 3: Breaking Changes & Migration (MANDATORY)
7. For each framework where the documented version differs from latest:
   - Web search for "<framework> migration guide <old_version> to <new_version>"
   - Web search for "<framework> breaking changes <new_version>"
   - Identify any minimum language/toolchain requirements that changed
     (e.g., C++ standard version, Dart SDK constraint, minimum CMake version)
   - Flag these as CRITICAL findings — they can cause agent-generated code
     to fail compilation or runtime
8. Check if any documented APIs have been removed, renamed, or deprecated
9. Look for commonly recommended patterns we're missing

#### Phase 4: Gap Analysis
10. Compare current documentation against latest official docs
11. Categorize findings per file as:
    - **Stale**: Documented patterns that are outdated or deprecated
    - **Missing**: Important patterns/APIs not yet documented
    - **Incorrect**: Factual errors or broken examples
    - **Breaking**: Version or requirement changes that would cause failures
    - **Style**: Formatting, organization, or clarity improvements
    - **OK**: Content that is current and accurate (no action needed)

#### Phase 5: File Size Check
12. For any reference file exceeding 200 lines, evaluate:
    - Can the file be split into logical sub-documents?
    - If splitting is recommended, identify the split boundary and new filenames
    - Note which other files reference it (SKILL.md step 0, agent definitions)
      and would need updating if split
    - Recommend: split now (if > 400 lines with clear boundary) or defer
      (if manageable or boundary is unclear)

#### Phase 6: Change Proposal
13. For each file that needs changes, present:
    - File path
    - Summary of changes (1-2 sentences)
    - Specific items: what to add, remove, or modify
    - Rationale for each change (link to source when possible)
14. Group changes by priority:
    - **Critical**: Breaking changes, incorrect versions, wrong API references
    - **Important**: Missing patterns that agents frequently need
    - **Nice-to-have**: Style/organization improvements

#### Phase 7: Cross-Cutting Concerns
15. After individual file analysis, check:
    - Are SKILL.md quick-references consistent with their reference/ files?
    - Do agent definitions correctly list all available convention skills?
    - Are version numbers consistent across all files in each stack?
    - Does CLAUDE.md accurately reflect the current plugin state?
    - If any files were proposed for splitting, are all downstream
      references accounted for?

### Constraints
- Do NOT invent patterns or APIs — only document what exists in official sources
- Preserve the existing file structure and organization style
- Keep reference files concise — agents read these into context window
- Each reference file should ideally stay under 200 lines; flag files over 400
- Prioritize patterns that TDD agents actually need (test writing, assertion
  selection, project structure)
- Do not add framework-specific content that doesn't relate to testing workflows
- This is a PROPOSAL — do not edit any files, only produce the change list

### Output Format
Present the plan as:
1. Version comparison table (documented vs. latest, per framework)
2. Breaking changes summary (if any)
3. Executive summary of findings per stack
4. File-by-file change list with priority ratings
5. Estimated scope (number of files changing, lines added/removed)
6. File size report (any files over 200 lines, split recommendations)
7. Implementation order (critical first, then important, then nice-to-have)
```

---

## Iteration Notes

### v1 Run (2026-02-23)
- [x] Did it successfully research latest versions via web search?
  - Yes, found Flutter 3.41.x, Dart 3.11.x, GoogleTest v1.17.0, CMake 4.2.x,
    bashunit 0.32.0, ShellCheck v0.11.0. Riverpod confirmed at 3.x (no major bump).
  - Weak spot: mocktail version not confirmed (web search too vague).
    v2 adds follow-up URL fetch instruction.
- [x] Was the gap analysis useful or too shallow?
  - Good granularity. Caught the critical C++17 requirement change.
  - Missing: didn't explicitly check for breaking changes as a mandatory step.
    v2 adds Phase 3 (Breaking Changes & Migration).
- [x] Did it propose changes at the right granularity?
  - Yes — file-by-file with priority ratings worked well.
- [x] Was the approval flow clear?
  - Yes, but the prompt didn't explicitly say "proposal only, don't edit."
    After plan approval, it immediately tried to edit files.
    v2 adds explicit PROPOSAL ONLY constraint.
- [x] How long did it take? (context window usage)
  - Moderate. 3 parallel explore agents + 7 web searches. Comfortable fit.
- [x] What should change in v2?
  - Added: Phase 3 (Breaking Changes & Migration) — mandatory
  - Added: Phase 5 (File Size Check) — for files over 200 lines
  - Added: Source verification instruction (follow up vague web searches)
  - Added: PROPOSAL ONLY constraint (no file edits)
  - Added: Version comparison table in output format
  - Added: Implementation order in output format

### v2 Run
- [ ] Did the breaking-change phase catch new issues?
- [ ] Did source verification resolve the mocktail version gap?
- [ ] Was the file-size check useful?
- [ ] Did the "proposal only" constraint prevent premature edits?
- [ ] What should change in v3?

---

## Path to Skill + Agent

Once this prompt is validated (2-3 iterations), encode it as:
- `skills/tdd-update-context/SKILL.md` — user-invocable skill (`/tdd-update-context`)
- `agents/context-updater.md` — fork-context agent with web search tools
- Add to `hooks/hooks.json` if approval gates are needed

### Encoding Considerations
- Agent needs WebSearch and WebFetch tools (for version verification)
- Fork context is essential — reading 17+ files bloats main context
- Approval gate: present proposal, user approves, then a second pass applies edits
- Consider: should the agent also produce a diff preview per file?
