# Plan-Mode Prompt: Update Plugin Context Reference Files

> **Usage:** Copy the prompt section below and paste it when entering plan mode.
> After testing, iterate on this prompt before encoding as a skill + agent.

---

## Prompt

```
Update all reference context markdown files in the TDD workflow plugin to
reflect current best practices, latest framework versions, and any gaps
discovered through analysis.

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

#### Phase 2: Research Latest Best Practices
5. Web search for the latest stable versions of each framework:
   - Dart/Flutter: Flutter SDK, Dart SDK, Riverpod, mockito, mocktail, flutter_test
   - C++: GoogleTest, GoogleMock, CMake (FetchContent patterns)
   - Bash: bashunit, shellcheck
6. Web search for any breaking changes, deprecations, or new recommended patterns
7. Check if any documented APIs have been removed or renamed
8. Look for commonly recommended patterns we're missing

#### Phase 3: Gap Analysis
9. Compare current documentation against latest official docs
10. Categorize findings per file as:
    - **Stale**: Documented patterns that are outdated or deprecated
    - **Missing**: Important patterns/APIs not yet documented
    - **Incorrect**: Factual errors or broken examples
    - **Style**: Formatting, organization, or clarity improvements
    - **OK**: Content that is current and accurate (no action needed)

#### Phase 4: Change Proposal
11. For each file that needs changes, present:
    - File path
    - Summary of changes (1-2 sentences)
    - Specific items: what to add, remove, or modify
    - Rationale for each change (link to source when possible)
12. Group changes by priority:
    - **Critical**: Broken/incorrect information that could cause agent errors
    - **Important**: Missing patterns that agents frequently need
    - **Nice-to-have**: Style/organization improvements

#### Phase 5: Cross-Cutting Concerns
13. After individual file analysis, check:
    - Are SKILL.md quick-references consistent with their reference/ files?
    - Do agent definitions correctly list all available convention skills?
    - Are version numbers consistent across all files?
    - Does CLAUDE.md accurately reflect the current plugin state?

### Constraints
- Do NOT invent patterns or APIs — only document what exists in official sources
- Preserve the existing file structure and organization style
- Keep reference files concise — agents read these into context window
- Each reference file should ideally stay under 200 lines
- Prioritize patterns that TDD agents actually need (test writing, assertion selection, project structure)
- Do not add framework-specific content that doesn't relate to testing workflows

### Output Format
Present the plan as:
1. Executive summary of findings per stack
2. File-by-file change list with priority ratings
3. Estimated scope (number of files changing, lines added/removed)
4. Any recommended structural changes (new files, file splits, etc.)
```

---

## Iteration Notes

After running this prompt in plan mode, note:
- [ ] Did it successfully research latest versions via web search?
- [ ] Was the gap analysis useful or too shallow?
- [ ] Did it propose changes at the right granularity?
- [ ] Was the approval flow clear?
- [ ] How long did it take? (context window usage)
- [ ] What should change in v2 of this prompt?

## Path to Skill + Agent

Once this prompt is validated (2-3 iterations), encode it as:
- `skills/tdd-update-context/SKILL.md` — user-invocable skill (`/tdd-update-context`)
- `agents/context-updater.md` — fork-context agent with web search tools
- Add to `hooks/hooks.json` if approval gates are needed
