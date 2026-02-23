---
name: tdd-update-context
description: >
  Update all reference context markdown files to reflect current best practices,
  latest framework versions, and gaps. Researches via web search, performs gap
  analysis with breaking-change detection, proposes changes with priority ratings,
  and applies after approval. Triggers on: "update context", "update conventions",
  "refresh references".
context: fork
agent: context-updater
disable-model-invocation: true
---

# Update Plugin Context Reference Files

<!-- ultrathink -->

Update all reference context markdown files in the TDD workflow plugin to
reflect current best practices, latest framework versions, and any gaps
discovered through analysis. This is a structured research-propose-apply
workflow with mandatory user approval before any edits.

## Process

0. **Load and follow convention references** (mandatory, do this first):
   - Dart/Flutter projects: read every file in `skills/dart-flutter-conventions/reference/`
   - C++ projects: read every file in `skills/cpp-testing-conventions/reference/`
   - Bash projects: read every file in `skills/bash-testing-conventions/reference/`
   - Also read each convention `SKILL.md` for the quick-reference sections
   Note the framework versions, API patterns, and conventions currently documented.
   Do not proceed to step 1 until all reference files are loaded.

1. **Research current state** by reading every reference file thoroughly:
   - Note the framework versions documented in each file
   - Identify any internal inconsistencies between files in the same stack
   - Check cross-references between SKILL.md and its reference/ files
   - Count lines per file (flag any over 200 lines)

2. **Research latest versions** using canonical sources below and CLAUDE.md:
   - WebFetch each canonical URL to get the latest stable version
   - If WebFetch fails or returns vague results, use WebSearch as fallback
   - If WebSearch also fails, ask the user via AskUserQuestion
   - Also check CLAUDE.md for a `## Context Update Sources` section and
     include any URLs found there (user-managed, Tier 2 sources)

3. **Breaking changes analysis** (mandatory for each version delta):
   - For each framework where the documented version differs from latest:
     - Search for "<framework> migration guide <old> to <new>"
     - Search for "<framework> breaking changes <new>"
     - Identify minimum language/toolchain requirement changes
   - Flag these as CRITICAL — they can cause agent-generated code to fail
   - Check if any documented APIs have been removed, renamed, or deprecated

4. **Gap analysis** — compare current docs against latest official docs:
   - **Breaking**: Version or requirement changes that would cause failures
   - **Stale**: Documented patterns that are outdated or deprecated
   - **Missing**: Important patterns/APIs not yet documented
   - **Incorrect**: Factual errors or broken examples
   - **Style**: Formatting, organization, or clarity improvements
   - **OK**: Content that is current and accurate (no action needed)

4b. **New file detection** — if a canonical source has no corresponding
   reference file in the plugin, propose creating one. Example: if Clang
   tooling conventions are missing from the C++ stack, propose a new
   `reference/clang-tooling.md`.

5. **File size check** — for any reference file exceeding 200 lines:
   - Evaluate if the file can be split into logical sub-documents
   - Use natural concern boundaries (e.g., Flutter SDK vs external packages)
   - If > 400 lines with a clear boundary: recommend split now
   - If manageable: recommend deferring the split
   - Note which files reference it (SKILL.md, agent definitions)

6. **Present structured proposal** as text output:
   - Version comparison table (documented vs. latest, per framework)
   - Breaking changes summary (if any)
   - File-by-file change list with priority ratings (Critical / Important / Nice-to-have)
   - New files proposed (if any)
   - File size report
   - Estimated scope (files changing, lines added/removed)

7. **Get explicit approval** using AskUserQuestion with options:
   - Approve All — apply all proposed changes
   - Approve Critical Only — apply only Critical and Important changes
   - Discard — stop without editing any files

8. **Apply approved changes** using Edit for existing files and Write for
   new files. Preserve existing structure and style. Keep files under 200 lines.

9. **Commit** — ask the user via AskUserQuestion to approve the commit message,
   then stage and commit:
   ```
   git add <changed files>
   git commit -m "docs: update convention references"
   ```
   Do NOT bump the plugin version — reference content updates are `docs:` commits.
   Do add a CHANGELOG entry under the current version's Changed section.

10. **Optionally push + create PR** — ask via AskUserQuestion:
    - Push & PR — push branch and create PR via `gh pr create`
    - Push only — push without PR
    - Skip — leave changes local

11. **Update agent memory** with version findings for next run.

## Canonical Sources (Plugin)

Flutter/Dart SDK:
- https://github.com/flutter/flutter — Flutter SDK repo
- https://github.com/dart-lang/sdk — Dart SDK repo

Dart/Flutter External Packages:
- https://github.com/rrousselGit/riverpod — Riverpod repo
- https://github.com/dart-lang/mockito — mockito repo
- https://github.com/felangel/mocktail — mocktail repo

C++:
- https://github.com/google/googletest — GoogleTest repo
- https://cmake.org/download/ — CMake latest version
- https://github.com/llvm/llvm-project — Clang/LLVM repo

Bash:
- https://github.com/TypedDevs/bashunit — bashunit repo
- https://github.com/koalaman/shellcheck — ShellCheck repo

## Constraints

- Do NOT invent patterns or APIs — only document what exists in official sources
- Preserve existing file structure and organization style
- Keep reference files under 200 lines; flag files over 400 for splitting
- Prioritize patterns TDD agents actually need (test writing, assertions, project structure)
- Do not add framework content unrelated to testing workflows
- Do NOT modify agent definitions, hook scripts, workflow SKILL.md process steps,
  or planning templates — only reference content files and SKILL.md quick references
- If WebSearch/WebFetch are unavailable, fall back to AskUserQuestion for version info
