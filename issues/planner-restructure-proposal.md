# TDD Planner Restructure — Move Approval to Main Thread

**Created:** 2026-03-01
**Status:** Proposed
**Discovered during:** plugin-dev evaluation session (v1.10.0)

## The Core Problem

Our tdd-planner is a **subagent** trying to do the work of the **main thread**. It handles research, plan building, user approval, lock file management, and file
writing — all inside a forked context. The built-in plan mode system deliberately splits these across two levels.

### How the Built-in Plan Mode Works

Main Thread (plan mode)
├── Delegates research → Plan subagent (read-only)
│                         └── Returns findings
├── Outputs plan as text (user sees it streaming)
├── Calls ExitPlanMode (system handles approval UI)
└── After approval → exits plan mode → writes files

The Plan subagent is **purely a researcher**. It never presents plans, never asks for approval, never writes files. The main thread owns the user interaction.

### Our Current Design (Fighting the System)

Main Thread
└── Spawns tdd-planner subagent (context: fork)
    ├── Research (30k+ tokens consumed)
    ├── Build plan internally
    ├── Output plan as text
    ├── Call AskUserQuestion ← UNRELIABLE (skipped under pressure)
    ├── rm .tdd-plan-locked ← Bash exception in plan mode
    ├── Write .tdd-progress.md ← via Bash redirect in plan mode
    └── Write planning archive ← via Bash redirect in plan mode

We gave a read-only subagent in plan mode the job of writing files and managing user interaction. Then we built lock files, retry counters, bash guard exceptions,
 and SubagentStop hooks to paper over the contradiction.

### Observed Symptom

The planner builds a complete plan but skips AskUserQuestion and tries to stop. The SubagentStop hook blocks it (up to 2 retries), then gives up. The main session
 sees the subagent finished without a valid plan and tries to redo everything. This happens even without auto-compaction, at high token usage.

## Proposed Restructure

Main Thread (via tdd-plan skill, inline)
├── Gathers git context
├── Spawns tdd-planner subagent (read-only researcher)
│   ├── Researches codebase
│   ├── Builds structured plan
│   └── Returns plan as text ← ONLY job
├── Outputs plan (user reads it)
├── Calls AskUserQuestion: Approve / Modify / Discard
│   ├── Modify → resumes subagent with feedback, repeats
│   ├── Discard → stops
│   └── Approve ↓
├── Writes .tdd-progress.md (main thread has Write tool)
├── Writes planning/ archive
└── Tells user to run /tdd-implement

This matches the built-in plan mode pattern and our own tdd-implement skill (which already runs inline and orchestrates subagents).

## What Gets Eliminated

| Component | Why It Existed | Why It's Gone |
|-----------|---------------|---------------|
| `.tdd-plan-locked` | Force subagent to call AskUserQuestion | Main thread handles approval natively |
| `.tdd-plan-approval-retries` | Prevent infinite SubagentStop blocking | No SubagentStop approval hook needed |
| `validate-plan-output.sh` (planner SubagentStop) | Enforce approval in subagent | Approval is in main thread |
| SubagentStart hook (planner) | Create lock + inject git context | Main thread gathers git context directly |
| SubagentStop hook (planner) | Run validate-plan-output.sh | Not needed |
| Lock gate in `planner-bash-guard.sh` | Block writes before approval | Planner never writes |
| `rm` exception in `planner-bash-guard.sh` | Allow removing lock file | No lock file |
| Compaction guard | Re-ask approval after context loss | AskUserQuestion is in main thread |
| AskUserQuestion in planner tools | Planner needed it for approval | Planner doesn't do approval |

## What Changes

| File | Change |
|------|--------|
| `skills/tdd-plan/SKILL.md` | Remove `context: fork` and `agent: tdd-planner`. Body becomes orchestration instructions (spawn subagent, present plan, get approval, write files) |
| `agents/tdd-planner.md` | Simplified to pure researcher. Remove AskUserQuestion from tools, remove approval sequence, remove compaction guard. Returns plan as text only |
| `hooks/planner-bash-guard.sh` | Remove lock gate logic and rm exception. Keep read-only command allowlist only |
| `hooks/hooks.json` | Remove SubagentStart and SubagentStop entries for tdd-planner |
| `hooks/validate-plan-output.sh` | May be repurposed for plan structure validation called by main thread, or removed |

## What Stays

- tdd-planner agent (as read-only researcher)
- `permissionMode: plan` on planner (truly read-only now)
- `planner-bash-guard.sh` (simplified — read-only bash enforcement only)
- Convention skills preloading
- Project memory on planner
- `validate-plan-output.sh` structure checks (sections, refactoring leak) — possibly called by main thread

## Key Advantages

1. **Reliability**: AskUserQuestion called by main thread — stable, never skipped
2. **Better Modify flow**: Resume planner subagent with user feedback, preserving full research context
3. **Context efficiency**: Research stays in subagent context, only plan text returns to main thread
4. **Simplicity**: ~200 lines of lock/retry/guard machinery eliminated
5. **Matches proven patterns**: Built-in plan mode + our own tdd-implement skill

## Test Impact

Many existing tests validate the lock mechanism (lock gate, rm exception, retry counter, SubagentStop approval). These tests would be **deleted**, not updated —
the mechanisms they test no longer exist. New tests needed for:
- Inline skill orchestration flow
- Simplified planner subagent (research-only)
- Main thread file writing after approval

## Implementation Notes

- Should be implemented via `/tdd-plan` (dogfooding)
- Significant refactor — touches skill, agent, bash guard, hooks.json, and ~50 tests
- The tdd-implement skill is the reference pattern for inline orchestration
- Start from current `main` (v1.10.0, commit 3ff5a9c)
