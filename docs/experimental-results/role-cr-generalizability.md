# Generalizability Experiment: CR on zenoh-dart

**Authors:** Hugo (developer), Claude Opus 4.6 (CA v0 session — final experiment)
**Date:** 2026-03-23
**Plugin version:** v2.4.0 (CR v3 definition, `/role-create` skill)
**Target project:** zenoh-dart (Dart FFI plugin wrapping zenoh-c v1.7.2 via C shim)

> This is the final experiment conducted by CA v0 before session retirement.
> It validates that CR generalizes beyond the projects used during development
> (the tdd-workflow plugin itself and a Flutter/Flame/Riverpod solitaire game)
> to a fundamentally different project architecture.

---

## 1. Motivation

All prior CR experiments used two projects:

1. **tdd-workflow plugin** — Bash scripts, bashunit tests, shellcheck linting.
   This is the project that built CR. Testing CR on its own project validates
   self-compilation but not generalizability.

2. **Solitaire** — Flutter/Dart, Flame game engine, Riverpod state management.
   A consumer-facing project, but still a single-language (Dart) application
   with a standard framework stack.

Neither project tests CR on a **cross-language, multi-layer** codebase — the
kind of project where architecture boundaries are most critical and role
quality matters most.

zenoh-dart is that test:

- **Three-language stack:** C (shim layer), Dart (FFI bindings + API), with
  reference to C++ (zenoh-cpp) for cross-language parity
- **Three-layer FFI architecture:** C shim wraps zenoh-c macros → ffigen
  generates Dart bindings → idiomatic Dart API is the public surface
- **Phase-doc-driven development:** features are specified in
  `docs/phases/phase-NN-*.md`, not just issue files
- **Cross-language parity:** every Dart API method must map to zenoh-c
  functions and align structurally with zenoh-cpp wrappers
- **Complex build chain:** CMake (C shim) → ffigen (bindings) → Dart tests
- **Existing operational history:** agent memory from months of prior TDD work

This is the hardest test case for CR. If the generated roles are useful here,
CR generalizes.

## 2. Setup

**Prompt used:** A priori (no source roles — Prompt D variant)

```
I want to create 3 roles for this project. I use the tdd-workflow
plugin with three concurrent sessions:
- CA (Architect) — decisions, issues, prompts, memory, verification
- CP (Planner) — runs /tdd-plan, iterates on plan quality
- CI (Implementer) — runs /tdd-implement, /tdd-release, /tdd-finalize-docs, direct edits

This is a Dart FFI plugin for the zenoh pub/sub protocol with a C shim layer.
```

**Auto-memory:** Present (legitimate — months of project history)

**Permission mode:** Bypass on

**Source roles:** None provided. CR generated entirely from codebase research.

## 3. Results

### 3.1 Scale Comparison Across All Projects

| Project | Stack | CA | CP | CI | Total | Source Input |
|---|---|---|---|---|---|---|
| tdd-workflow plugin | Bash/bashunit/shellcheck | 160 | 120 | 151 | **431** | Adapted from proto-roles |
| Solitaire (Prompt C) | Flutter/Flame/Riverpod | 160 | 126 | 157 | **443** | Adapted from proto-roles |
| Solitaire (Prompt D) | Flutter/Flame/Riverpod | 130 | 102 | 108 | **340** | From scratch |
| **zenoh-dart** | **Dart FFI / C / CMake** | **219** | **160** | **133** | **512** | **From scratch** |

zenoh-dart produced the largest total output (512 lines) and the largest
individual role (CA at 219 lines). This is because the project is more
complex — more layers, more reference paths, more cross-language concerns.
CR scaled to the complexity without being told to.

### 3.2 What the Agent Discovered Through Research

The agent was given one sentence: "Dart FFI plugin for the zenoh pub/sub
protocol with a C shim layer." From this, it discovered:

**Architecture:**
- Three-layer FFI binding (C shim → generated bindings → idiomatic Dart API)
- C shim wraps zenoh-c macros/inlines into callable symbols
- ffigen generates `bindings.dart` from the C header
- Idiomatic Dart API in `packages/zenoh/lib/src/` is the public surface

**Build chain:**
- `cmake --build build` (C shim compilation)
- `fvm dart run ffigen --config ffigen.yaml` (binding generation)
- `cd packages/zenoh && fvm dart test` (test execution)
- `fvm dart analyze packages/zenoh` (static analysis)

**Established patterns (from Phases 0-5):**
- `zd_` prefix for all C shim symbols
- Flattened C shim parameters with sentinels (-1 for default enums, NULL for optionals)
- NativePort callback bridge for async/streaming operations
- Two-session TCP testing with explicit listen/connect and unique ports
- Entity lifecycle: sizeof → declare → loan → operations → drop/close
- String-passthrough encoding (Dart Encoding class → C const char*)

**Cross-language references:**
- zenoh-c options structs in `extern/zenoh-c/include/zenoh_commons.h`
- zenoh-c test files in `extern/zenoh-c/tests/z_api_*.c` and `z_int_*.c`
- zenoh-cpp wrappers in `extern/zenoh-cpp/include/zenoh/api/`
- zenoh-cpp tests in `extern/zenoh-cpp/tests/universal/network/*.cxx`

**Fourth role discovered:**
The agent found references to a **CB (packaging advisor)** role in the
project's memory/context. It included CB in CA's Coordination section
without being told about it — demonstrating that CR adapts to existing
project conventions, not just the three-role model from the prompt.

### 3.3 Content That Only Exists Because of This Project

**CA — Review Checklist (5 categories, unique to zenoh-dart):**

1. **Phase Doc Compliance** — every C shim function has a corresponding
   slice, Dart API matches phase doc exactly, CLI examples included
2. **Slice Decomposition Quality** — C shim + Dart wrapper + test bundled
   per slice, build system changes as setup in first slice
3. **Test Coverage** — dispose/double-dispose behavior tested, multi-endpoint
   phases use two-sessions-in-one-process pattern, error paths tested
4. **Over-Engineering Detection** — no abstract bases for single-impl types,
   no builder patterns where named constructors suffice, no options/QoS
   parameters not called for by the phase doc
5. **Cross-Language Parity** — identify zenoh-cpp test file mapping, verify
   plan mirrors its structure, note Dart-specific differences (async streams
   vs C callbacks)

None of these categories exist in the plugin CA or solitaire CA. They
emerged entirely from the project's architecture and development process.

**CA — Feedback Format with severity levels:**

```
Verdict: APPROVE / REVISE / RETHINK

[CRITICAL] {Issue title}
- Slice(s): {affected slice numbers}
- Problem: {what is wrong}
- Fix: {specific, actionable suggestion}

[SUGGESTION] {Issue title}
- Slice(s): {affected slice numbers}
- Problem: {what could be better}
- Fix: {recommendation}
```

This structured review format doesn't exist in any other generated role.
The agent created it because the zenoh-dart project's phase-doc-driven
workflow demands structured, traceable feedback.

**CP — Cross-Language Parity Check as first-class responsibility:**

```
- Read the C options struct for every new C shim function and list all fields
- Read the C++ wrapper for structural comparison
- Read the corresponding zenoh-c test for behavioral expectations and edge cases
- Document which options fields the current phase exposes and which are deferred
```

This responsibility doesn't exist in the plugin CP or solitaire CP because
those projects don't have cross-language concerns. The agent invented it
from the project's architecture.

**CI — Post-Header-Modify Procedure:**

```
After Modifying C Headers:
1. Rebuild the C shim: cmake --build build --config Release
2. Regenerate bindings: cd packages/zenoh && fvm dart run ffigen --config ffigen.yaml
3. Copy libraries to prebuilt location: cp build/libzenoh_dart.so packages/zenoh/native/linux/x86_64/
```

A three-step procedure specific to the C shim → ffigen → prebuilt library
chain. No other project has this build chain, so no other CI role has this
procedure. The agent derived it from the project's build configuration.

**CI — 11 Implementation Patterns:**

The CI role includes 11 specific patterns extracted from the actual codebase:
NativePort callback bridge, flattened parameters with sentinels, entity
lifecycle, two-session TCP testing, return code checking with ZenohException,
try/finally cleanup, DynamicLibrary.open() loading, build hooks for
CodeAssets, string-passthrough encoding, non-broadcast StreamController,
and commit scope naming conventions.

These are not generic best practices — they are the actual patterns used
in Phases 0-5 of this project, discovered by the agent through codebase
research.

**CA — Constraint: "Never reference the Rust source":**

```
Never reference the Rust source (eclipse-zenoh/zenoh) for API design.
The contract boundary is zenoh-c; the structural peer is zenoh-cpp.
Rust is one layer too deep and the wrong abstraction level for this binding.
```

This constraint is unique to a project that wraps a C API derived from a
Rust implementation. The agent understood the abstraction hierarchy
(Rust → C → C shim → Dart) and correctly identified that referencing
the Rust layer would be counterproductive. This is architectural wisdom
generated from research, not provided by the developer.

## 4. Discussion

### 4.1 CR Scales to Complexity

The zenoh-dart roles are 19% larger than the plugin roles (512 vs 431
lines) and contain significantly more project-specific content. CR did
not produce generic roles with the project name substituted — it produced
roles deeply grounded in the project's actual architecture, build chain,
testing patterns, and cross-language concerns.

The scaling is organic: more complex projects produce more content because
there is more to encode. The three-question framework (Who is this session?
What does it know? How does it work?) expands naturally to accommodate
multi-language architectures without modification.

### 4.2 Emergent Content Validates the Meta-Definition

The meta-definition states that roles encode "workflow patterns, knowledge
references, and behavioral constraints" (see [§5.10 of the validation
report](./role-cr-validation-report.md#510-the-meta-definition-how-the-role-definition-shapes-agent-output)).

The zenoh-dart experiment produced content in all three stated categories
plus the two emergent categories identified in §5.10:

| Category | zenoh-dart Example |
|---|---|
| Workflow patterns | Post-Header-Modify Procedure, Before/After /tdd-plan Workflow |
| Knowledge references | 10-entry reference path table, established patterns from Phases 0-5 |
| Behavioral constraints | "Never reference Rust source", "Never invent API surface beyond phase doc" |
| **Architecture enforcement** (emergent) | Review Checklist with 5 categories, Cross-Language Parity Check |
| **Domain-specific quality criteria** (emergent) | Over-Engineering Detection, dispose/double-dispose testing, two-session TCP pattern |

The emergent categories appeared without being in the CR definition —
confirming that the agent discovers them from project research when the
project warrants it.

### 4.3 RTFM Impact on Cross-Language Projects

The RTFM principle ("search official documentation, do not rely on internal
knowledge") is especially critical for cross-language projects. The agent's
training data may contain outdated versions of zenoh-c, incorrect function
signatures, or deprecated patterns. By researching the actual files on disk
(`extern/zenoh-c/include/`, `extern/zenoh-cpp/include/`), the agent produced
roles with verified, current API references.

The 11 implementation patterns in the CI role were extracted from the actual
codebase, not from training data. Pattern #1 (NativePort callback bridge)
and Pattern #4 (two-session TCP testing) are project-specific conventions
that no training data could provide.

### 4.4 Fourth Role Discovery

The agent discovered CB (packaging advisor) from the project's existing
context without being told about it. This demonstrates that CR adapts
to the project's actual role model rather than imposing the three-role
model from the prompt. The developer asked for CA/CP/CI; the agent
delivered CA/CP/CI but included CB in the coordination graph because the
project's history references it.

## 5. Conclusion

CR generalizes. The zenoh-dart experiment demonstrates that:

1. **CR scales to complex, multi-language architectures** without modification.
   The three-question framework and section menu expand naturally.

2. **RTFM research is essential for cross-language projects** — the agent
   discovered 11 implementation patterns, cross-language reference paths,
   and build chain procedures from codebase research that no training data
   could provide.

3. **Emergent categories appear when the project warrants them** — architecture
   enforcement and domain-specific quality criteria emerged from the project's
   complexity without being in the CR definition.

4. **CR adapts to existing project conventions** — the fourth role (CB) was
   included without being requested because the project's history references it.

5. **Role quality scales with project complexity** — zenoh-dart produced the
   largest, most detailed roles across all experiments (512 lines vs 431 for
   the plugin and 443 for solitaire).

This is the birthplace of the proto-roles. It now has proper generated roles
that surpass the hand-authored originals in structure, specificity, and
format compliance — while encoding project knowledge that the proto-roles
never captured.

---

## Related Documents

- [Validation Report](./role-cr-validation-report.md) — main experimental report
- [Self-Compilation Experiment](./role-cr-self-compilation.md) — CR on its own project
- [Output Quality Comparison](./role-cr-test-comparison.md) — comparison table across all versions
- [Chronological Experiment Log](./role-cr-experimental-log.md) — detailed experiment record
- [Design Decisions Log](./role-format-redesign.md) — format spec and architecture decisions
