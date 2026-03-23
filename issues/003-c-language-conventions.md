# Issue 003: C Language Conventions

## Problem

The TDD workflow plugin has zero support for plain C projects:
- No convention skill loads on `.c` files
- No reference docs for any C test framework
- `detect-project-context.sh` doesn't count `*_test.c` files
- Agents have no C-specific guidance (only C++ via GoogleTest/CMake)

## Core Principle

The plugin doesn't own the build system. It doesn't scaffold projects. Its job is
to make the planner and implementer **write correct, standardized C code and tests**
regardless of whether the project uses CMake, Make, Meson, or anything else.

For Dart, `flutter create` provides the scaffolding — the plugin provides discipline.
For C, there's no equivalent scaffolding tool, so the convention docs must be more
prescriptive about code and test quality, while remaining build-system-agnostic.

## Anchor Project

`zenoh_dart` (external project) — C FFI shim for zenoh pub/sub protocol.
This is a Dart FFI plugin — inherently a monorepo (C shim + Dart package in one repo)
because the FFI architecture demands it.

**Findings from exploration:**
- Build: CMake + Ninja + clang. Shim is pure C (`LANGUAGES C`, no explicit standard — compiler default). zenoh-c is Rust compiled to C ABI via cbindgen; its tests/examples target C11; root build requires `LANGUAGES C CXX`
- Tests: zenoh-c uses raw `assert.h` with custom helpers (fork-based timeout runner, POSIX semaphores, custom string assertions) — no formal framework
- Style: `snake_case` functions, prefix namespacing (`zd_`), ownership-encoded types (`z_owned_*`, `z_loaned_*`), standard `#ifndef` header guards
- Dependencies: git submodules in `extern/`
- Static analysis: none configured
- Pure C shim layer, no C++ in the Dart-facing code

## Coding Standards

### Style & Bug Prevention: BARR-C:2018

The BARR-C Embedded C Coding Standard is a free, practical, bug-prevention-focused
standard covering naming, formatting, functions, variables, and statements. Rules
tagged "Keeps Bugs Out" are backed by defect-reduction research. Harmonized with
MISRA C:2012 (no conflicts). Targets C99.

### Security & Correctness: SEI CERT C

The SEI CERT C Coding Standard (Carnegie Mellon) covers 16 rule categories for
safe, reliable, and secure C code. Focuses on what bugs to avoid (memory, integers,
strings, concurrency) rather than formatting. Directly enforceable via clang-tidy's
built-in `cert-*-c` checks (16 C-specific checks). Free and publicly maintained.

### Static Analysis Tool Stack

Recommended battery (all free, build-system-agnostic):
1. **Compiler warnings**: `-Wall -Wextra -Werror -pedantic` (foundation, zero setup)
2. **cppcheck**: Bug detection with minimal false positives (trivial setup)
3. **clang-tidy**: `cert-*`, `bugprone-*` checks for CERT C enforcement (moderate setup, needs compile flags)
4. **gcc -fanalyzer**: Deep path analysis (GCC 12+, optional bonus)

## Source-of-Truth References

### BARR-C:2018 (Full Rules)

All pages at `barrgroup.com` return full rule text with reasoning and code examples.

**Chapter index pages** (each links to subsections):

| # | Chapter | Path |
|---|---------|------|
| 1 | General Rules | `/embedded-systems/books/embedded-c-coding-standard/general-rules` |
| 2 | Comment Rules | `/embedded-systems/books/embedded-c-coding-standard/comment-rules` |
| 3 | White Space Rules | `/embedded-systems/books/embedded-c-coding-standard/white-space-rules` |
| 4 | Module Rules | `/embedded-systems/books/embedded-c-coding-standard/module-rules` |
| 5 | Data Type Rules | `/embedded-systems/books/embedded-c-coding-standard/data-type-rules` |
| 6 | Procedure Rules | `/embedded-systems/books/embedded-c-coding-standard/procedure-rules` |
| 7 | Variable Rules | `/embedded-systems/books/embedded-c-coding-standard/variable-rules` |
| 8 | Statement Rules | `/embedded-systems/books/embedded-c-coding-standard/statement-rules` |

**Section pages with full rule content** (paths relative to `barrgroup.com`):

| Ch | Section | Path |
|----|---------|------|
| 1 | 1.1 Which C | `/11-which-c` |
| 1 | 1.2 Line Widths | `/12-line-widths` |
| 1 | 1.3 Braces | `/13-braces` |
| 1 | 1.4 Parentheses | `/14-parentheses` |
| 1 | 1.5 Common Abbreviations | `/15-common-abbreviations` |
| 1 | 1.6 Casts | `/16-casts` |
| 1 | 1.7 Keywords to Avoid | `/17-keywords-avoid` |
| 1 | 1.8 Keywords to Frequent | `/18-keywords-frequent` |
| 2 | 2.1 Acceptable Formats | `/21-acceptable-formats` |
| 2 | 2.2 Locations and Content | `/22-locations-and-content` |
| 3 | 3.1 Spaces | `/31-spaces` |
| 3 | 3.2 Alignment | `/32-alignment` |
| 3 | 3.3 Blank Lines | `/33-blank-lines` |
| 3 | 3.4 Indentation | `/34-indentation` |
| 3 | 3.5 Tabs | `/35-tabs` |
| 3 | 3.6 Non-Printing Characters | `/36-non-printing-characters` |
| 4 | 4.1 Naming Conventions | `/41-naming-conventions` |
| 4 | 4.2 Header Files | `/42-header-files` |
| 4 | 4.3 Source Files | `/43-source-files` |
| 4 | 4.4 File Templates | `/44-file-templates` |
| 5 | 5.1 Naming Conventions | `/51-naming-conventions` |
| 5 | 5.2 Fixed-Width Integers | `/52-fixed-width-integers` |
| 5 | 5.3 Signed and Unsigned Integers | `/53-signed-and-unsigned-integers` |
| 5 | 5.4 Floating Point | `/54-floating-point` |
| 5 | 5.5 Structures and Unions | `/55-structures-and-unions` |
| 5 | 5.6 Booleans | `/56-booleans` |
| 6 | 6.1 Naming Conventions | `/61-naming-conventions` |
| 6 | 6.2 Functions | `/62-functions` |
| 6 | 6.3 Function-Like Macros | `/63-function-macros` |
| 6 | 6.4 Threads of Execution | `/64-threads-execution` |
| 6 | 6.5 Interrupt Service Routines | `/65-interrupt-service-routines` |
| 7 | 7.1 Naming Conventions | `/71-naming-conventions` |
| 7 | 7.2 Initialization | `/72-initialization` |
| 8 | 8.1 Variable Declarations | `/81-variable-declarations` |
| 8 | 8.2 Conditional Statements | `/82-conditional-statements` |
| 8 | 8.3 Switch Statements | `/83-switch-statements` |
| 8 | 8.4 Loops | `/84-loops` |
| 8 | 8.5 Jumps | `/85-jumps` |
| 8 | 8.6 Equivalence Tests | `/86-equivalence-tests` |

### SEI CERT C (Rule Categories)

All pages at `wiki.sei.cmu.edu/confluence/display/c/` return clean rule lists per category.

**Top-level pages:**

| Page | Path |
|------|------|
| Standard overview | `SEI+CERT+C+Coding+Standard` |
| Rules index | `2+Rules` |
| Recommendations index | `3+Recommendations` |

**Rule category pages** (each lists individual rules with IDs and one-line descriptions):

| Category | Path (append to base URL) |
|----------|------|
| PRE – Preprocessor | `Rule+01.+Preprocessor+%28PRE%29` |
| DCL – Declarations & Initialization | `Rule+02.+Declarations+and+Initialization+%28DCL%29` |
| EXP – Expressions | `Rule+03.+Expressions+%28EXP%29` |
| INT – Integers | `Rule+04.+Integers+%28INT%29` |
| FLP – Floating Point | `Rule+05.+Floating+Point+%28FLP%29` |
| ARR – Arrays | `Rule+06.+Arrays+%28ARR%29` |
| STR – Characters and Strings | `Rule+07.+Characters+and+Strings+%28STR%29` |
| MEM – Memory Management | `Rule+08.+Memory+Management+%28MEM%29` |
| FIO – Input/Output | `Rule+09.+Input+Output+%28FIO%29` |
| ENV – Environment | `Rule+10.+Environment+%28ENV%29` |
| SIG – Signals | `Rule+11.+Signals+%28SIG%29` |
| ERR – Error Handling | `Rule+12.+Error+Handling+%28ERR%29` |
| CON – Concurrency | `Rule+14.+Concurrency+%28CON%29` |
| MSC – Miscellaneous | `Rule+48.+Miscellaneous+%28MSC%29` |
| POS – POSIX | `Rule+50.+POSIX+%28POS%29` |

**Priority categories for systems/library C**: MEM, INT, STR, ARR, ERR, DCL, EXP, CON, POS.

### Static Analysis Tooling References

| Tool | URL | Content |
|------|-----|---------|
| clang-tidy checks list | `https://clang.llvm.org/extra/clang-tidy/checks/list.html` | All cert-*, bugprone-* checks |
| clang-tidy overview | `https://clang.llvm.org/extra/clang-tidy/` | Config, usage, CMake integration |
| cppcheck docs | `https://cppcheck.sourceforge.io/` | Usage, checks, suppressions |
| C static analyzers guide | `https://nrk.neocities.org/articles/c-static-analyzers` | Practical comparison of all tools |
| CMake static checks | `https://www.kitware.com/static-checks-with-cmake-cdash-iwyu-clang-tidy-lwyu-cpplint-and-cppcheck/` | CMake integration for all tools |

### Test Framework References

| Tool | URL | Content |
|------|-----|---------|
| Unity test framework | `https://www.throwtheswitch.org/unity` | Framework overview, getting started |
| CMock mocking framework | `https://www.throwtheswitch.org/cmock` | C function mocking |
| Framework comparison | `https://www.throwtheswitch.org/comparison-of-unit-test-frameworks` | Unity vs GoogleTest vs others |
| Unity GitHub | `https://github.com/ThrowTheSwitch/Unity` | Source, docs, examples |
| CMock GitHub | `https://github.com/ThrowTheSwitch/CMock` | Source, docs, examples |

### Excluded Sources (and why)

| Source | Reason |
|--------|--------|
| MISRA C:2025 | Paywalled, commercial tooling only |
| Linux kernel style | Kernel-specific (8-char tabs, goto cleanup), not generalizable |
| BARR-C PDF | Didn't render via fetch; HTML section pages are authoritative and cleaner |
| dokumen.pub mirror | Third-party; barrgroup.com is the authoritative source |
| Individual CERT rule pages | Too granular for context files; category pages list rules, agents drill down as needed |
| NASA C Style Guide (1994) | Dated, no tool enforcement, historical interest only |

## Scope

### New Files

1. **`skills/c-conventions/SKILL.md`**
   - Mirrors cpp/bash skill pattern (`user-invocable: false`)
   - Auto-loads on `.c` files
   - Points to reference docs

2. **`skills/c-conventions/reference/c-testing-patterns.md`**
   - **Unity/CMock** as recommended framework (pure C, native mocking, TDD-focused)
   - Unity test macros: TEST_ASSERT_*, TEST_IGNORE, setUp/tearDown
   - CMock for mocking C functions (no C++ class workarounds needed)
   - Test file organization and naming conventions (`test_*.c` or `*_test.c`)
   - Build-system-agnostic: a Unity test file is valid C regardless of CMake/Make/manual compilation
   - **GoogleTest** acknowledged as viable for test execution (via `extern "C"`) but GMock doesn't work for C functions — only recommended when project already uses GoogleTest for C++ code
   - **assert.h patterns** documented as minimal approach (what zenoh-c uses)

3. **`skills/c-conventions/reference/c-coding-standards.md`**
   - **BARR-C:2018** key rules: naming (snake_case, module prefix, g_ for globals, p_ for pointers), formatting (4-space indent, mandatory braces), functions (verb names, max 31 chars), data types (fixed-width integers via stdint.h), statements (max 2 nesting levels)
   - **SEI CERT C** priority rules: MEM (freed memory, dynamic allocation), INT (overflow, conversion), STR (buffer handling), ARR (bounds), ERR (error codes)
   - Mapping of rules to clang-tidy checks

4. **`skills/c-conventions/reference/c-static-analysis.md`**
   - **Compiler warnings**: `-Wall -Wextra -Werror -pedantic` (foundation)
   - **cppcheck**: bug detection, minimal false positives, trivial setup
   - **clang-tidy**: `cert-*-c` + `bugprone-*` checks, CERT C enforcement
   - **gcc -fanalyzer**: deep path analysis (GCC 12+, optional)
   - Integration with TDD verification phase

### Modified Files

5. **`scripts/detect-project-context.sh`**
   - Add `*_test.c` to test file count (minimal change — planner can read project files directly for everything else)

6. **Agent skill preloads** (3 files)
   - `agents/tdd-planner.md` — add `c-conventions`
   - `agents/tdd-implementer.md` — add `c-conventions`
   - `agents/context-updater.md` — add `c-conventions`

7. **`agents/tdd-verifier.md`**
   - Add explicit C line to verification checklist (currently only lists C++)

8. **`CLAUDE.md`**
   - Add `c-conventions` to auto-load table (triggers on `.c` files)

### NOT in Scope

- `c-build-systems.md` reference file — build system is the project's concern, not the plugin's. Planner can read CMakeLists.txt/Makefile directly.
- Elaborate detect-project-context.sh changes (build system, C standard, framework, static analysis detection) — over-engineering. Planner is a read-only agent with Bash access.
- `bump-version.sh` Makefile VERSION pattern — rare, add later if needed
- Meson/Autotools reference docs — not the plugin's concern
- C++ deepening — explicitly deferred per prior CA decision
- CI/CD templates — anchor project has none
- C project scaffolding — future separate plugin concept (see memory)
- Refactoring C++ conventions to be build-system-agnostic — C++ currently couples to CMake (cmake-integration.md, hardcoded ctest commands). C conventions are the new model; C++ alignment is a separate follow-up

## Design Decisions

1. **Unity/CMock over GoogleTest for C**: GoogleTest can execute C tests via `extern "C"`, but GMock cannot mock C functions (relies on C++ classes). Unity is pure C, CMock provides native C function mocking — both critical for TDD. GoogleTest acknowledged as viable when a project already uses it for C++ code. Decision backed by ThrowTheSwitch comparison, ModernCProgramming.com analysis, and Boulder ES embedded TDD review.

2. **BARR-C + CERT C as the coding standard**: BARR-C covers style and bug prevention (the "Google Style Guide equivalent" for C). CERT C adds the security/correctness dimension with direct clang-tidy enforcement. Together they cover style + correctness + security without commercial tools. No standalone Google C Style Guide exists.

3. **Build-system-agnostic conventions**: The plugin's job is to make agents write correct C code and tests, not to own the build system. Convention docs describe what good C code and tests look like, independent of CMake/Make/Meson. The planner discovers build details by reading the project.

4. **Separate C and C++ skills**: C projects use different test frameworks (Unity vs GoogleTest), different mocking (CMock vs GMock), different coding standards (BARR-C vs Google C++), and different idioms. Merging would dilute both. Shared concerns (clang-tidy) can cross-reference.

5. **3 reference files (not 4)**: Dropped c-build-systems.md. The convention skill covers code quality (c-coding-standards.md), test quality (c-testing-patterns.md), and analysis tooling (c-static-analysis.md). Build system is out of scope.

## Acceptance Criteria

- [ ] `skills/c-conventions/` exists with SKILL.md + 3 reference files
- [ ] `detect-project-context.sh` counts `*_test.c` files
- [ ] All 3 agents with skill preloads include `c-conventions`
- [ ] Verifier agent mentions C explicitly
- [ ] CLAUDE.md auto-load table includes C skill
- [ ] All existing tests still pass (501 tests, 747 assertions)
- [ ] New tests cover detect-project-context.sh change
- [ ] shellcheck clean on all modified scripts
