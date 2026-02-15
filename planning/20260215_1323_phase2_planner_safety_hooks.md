# Feature Notes: Phase 2 Planner Safety Hooks (M1, M2, S2)

**Created:** 2026-02-15
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
The tdd-planner agent is designed to be read-only — it has `Write`, `Edit`,
`MultiEdit`, and `NotebookEdit` in its `disallowedTools`. However, the `Bash`
tool can still write files via output redirection (`>`), destructive commands
(`rm`, `dd`), or scripting (`python -c`). Phase 2 closes this gap with three
safety hooks and also validates that the planner produces a complete plan file.

### Use Cases
- Prevent the planner from accidentally writing source files via Bash
- Ensure the planner always produces a plan file with required sections before stopping
- Detect refactoring leaks in plan content (LLMs tend to include refactoring steps despite instructions)
- Defense-in-depth: SubagentStop catches issues even if the Stop hook is bypassed

### Context
The tdd-workflow plugin (v1.2.0) has three agents: planner, implementer, and
verifier. The implementer already has PreToolUse and PostToolUse hooks
(`validate-tdd-order.sh`, `auto-run-tests.sh`). The main thread has a Stop
hook (`check-tdd-progress.sh`). The planner has NO hooks currently — this
feature adds its first hooks.

---

## Requirements Analysis

### Feature Analysis

1. `planner-bash-guard.sh` (M1): PreToolUse command hook on `Bash` matcher that
   allowlists read-only commands and blocks output redirection
2. `validate-plan-output.sh` (M2): Stop command hook that validates plan file
   existence, required sections, and absence of refactoring leaks
3. SubagentStop entry (S2): hooks.json entry for `tdd-planner` reusing the M2
   validator script as defense-in-depth
4. Integration: planner frontmatter updated with hooks; hooks.json updated with
   SubagentStop entry

### Non-Functional Requirements
- All hook scripts pass shellcheck -S warning
- All new scripts have bashunit test coverage
- Existing 143 tests remain green
- Existing hooks are NOT modified

### Integration Points
- `agents/tdd-planner.md` frontmatter — hooks added
- `hooks/hooks.json` — SubagentStop entry added
- Hook JSON protocol: read from stdin, exit 0 = allow, exit 2 = block

---

## Implementation Details

### Architectural Approach

**Allowlist over denylist (M1):** The Round 2 audit consensus determined that
an allowlist is strictly safer than a denylist regex. A denylist can't predict
every dangerous command (`dd`, `python -c`, heredocs, `curl -o`, etc.). With
an allowlist, only explicitly permitted read-only commands pass through. If the
planner needs a new command, it must be added to the allowlist.

**Shared validator (M2/S2):** `validate-plan-output.sh` serves double duty as
both the Stop hook (M2, fires when the agent tries to stop) and the
SubagentStop hook (S2, fires when the parent context stops the agent). This
is defense-in-depth — the same validation runs at two different lifecycle
points.

**Hook protocol:** All hooks follow the existing pattern:
- Read JSON from stdin (`INPUT=$(cat)`)
- Parse with `jq`
- Exit 0 = allow, exit 2 = block
- Error messages to stderr

### Design Patterns
- **Allowlist pattern (M1):** Extract base command, iterate allowlist, exact match
- **Guard clause pattern (M2):** `stop_hook_active` check first, then file existence, then content validation
- **Defense-in-depth (S2):** Same validator at SubagentStop catches what Stop might miss

### File Structure
```
hooks/
├── planner-bash-guard.sh          (NEW — M1)
├── validate-plan-output.sh        (NEW — M2, reused by S2)
├── hooks.json                     (MODIFIED — S2 SubagentStop entry)
├── validate-tdd-order.sh          (UNCHANGED)
├── auto-run-tests.sh              (UNCHANGED)
└── check-tdd-progress.sh          (UNCHANGED)

agents/
└── tdd-planner.md                 (MODIFIED — hooks frontmatter)

test/hooks/
├── planner_bash_guard_test.sh     (NEW)
└── validate_plan_output_test.sh   (NEW)
```

### Naming Conventions
- Hook scripts: `kebab-case.sh` (matches existing: `validate-tdd-order.sh`)
- Test files: `snake_case_test.sh` (matches existing: `validate_tdd_order_test.sh`)
- Test functions: `test_<unit>_<scenario>_<expected_behavior>()`

---

## TDD Approach

### Slice Decomposition

The feature is broken into independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** bashunit v0.32.0 (at `./lib/bashunit`)
**Test Command:** `./lib/bashunit test/`

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | Bash Guard — Command Allowlist | None |
| 2 | Bash Guard — Redirection Blocking | Slice 1 |
| 3 | Plan Validator — File Existence and Stop Hook Guard | None |
| 4 | Plan Validator — Section Checks and Refactoring Leak | Slice 3 |
| 5 | Integration — Planner Frontmatter and hooks.json SubagentStop | Slices 1-4 |

---

## Dependencies

### External Packages
- `jq`: JSON parsing in hook scripts (already used by existing hooks)
- `shellcheck`: Static analysis (already available system-wide)
- `bashunit`: Test framework v0.32.0 (at `./lib/bashunit`)

### Internal Dependencies
- `agents/tdd-planner.md`: Frontmatter modification for hooks
- `hooks/hooks.json`: SubagentStop array extension
- `docs/tdd-workflow-extensibility-audit.md` sections 4.3, 4.4, 4.5: Spec reference

---

## Known Limitations / Trade-offs

### Limitations
- **Redirection detection (M1):** The regex approach for detecting `>` cannot
  distinguish between output redirection and `>` appearing inside quoted
  strings (e.g., `grep '>' file`). This is a known limitation — the allowlist
  is the primary guard, and redirection detection is secondary defense.
- **30-minute freshness window (M2):** Plan files older than 30 minutes are
  treated as stale. If a planner session legitimately runs longer, this
  threshold may need adjustment.

### Trade-offs Made
- **Allowlist strictness vs flexibility:** An allowlist blocks unknown commands
  but requires manual updates when the planner needs a new tool. This was
  chosen over a denylist because safety > convenience for a read-only agent.
- **Shared script vs separate scripts (M2/S2):** Using one script for both
  Stop and SubagentStop simplifies maintenance but means both hooks have
  identical behavior. Separate scripts would allow differentiated validation
  but add maintenance burden.

---

## Implementation Notes

### Key Decisions
- **Allowlist approach (M1):** Round 2 CC×Web audit consensus — denylist
  regex couldn't catch `dd`, `python -c`, heredocs, `curl -o`. Allowlist is
  strictly safer.
- **Section name patterns (M2):** The grep patterns (`feature analysis`,
  `test specification`, `slice`) match against h1-h3 headings with
  case-insensitive matching to accommodate heading variations.
- **Template compatibility (M2):** The feature-notes-template heading
  `### Potential Refactoring` does NOT match the leak regex patterns
  (`refactor:`, `refactoring phase`, `REFACTOR phase`), preventing
  false positives from template boilerplate.

### Future Improvements
- **S1 — Planner memory:** Add `memory: project` to planner frontmatter
  so codebase research persists across sessions
- **S3 — SubagentStart context:** Inject git branch/commit/dirty-file
  context at planner startup via SubagentStart hook

---

## References

### Related Code
- `hooks/validate-tdd-order.sh` — existing PreToolUse hook pattern (implementer)
- `hooks/auto-run-tests.sh` — existing PostToolUse hook pattern (implementer)
- `hooks/check-tdd-progress.sh` — existing Stop hook pattern (main thread)
- `hooks/hooks.json` — existing SubagentStop/Stop configuration
- `agents/tdd-planner.md` — planner agent frontmatter
- `agents/tdd-implementer.md` — implementer with hooks for reference

### Documentation
- `docs/tdd-workflow-extensibility-audit.md` sections 4.3, 4.4, 4.5
- `skills/bash-testing-conventions/reference/bashunit-patterns.md`
- `skills/bash-testing-conventions/reference/shellcheck-guide.md`
