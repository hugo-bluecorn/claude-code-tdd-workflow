# Plan-Mode Prompt: Fix Planner Agent Identity & Invocation Guardrails

> **Usage:** Pass the prompt section below to `/tdd-plan` so the planner
> researches the codebase, produces a structured fix plan, and archives the
> full incident analysis in `planning/` for permanent record.
>
> **Origin:** Issue `issues/001-planner-scope-creep.md` — analysis by
> session CB (2026-02-24) after reviewing CZ incident transcript and CA report.

---

## Prompt

```
Fix the tdd-planner agent identity mismatch and add invocation guardrails.

### Incident Summary

During a /tdd-plan session for a C++ project (Phase 2: z_sub Callback
Subscriber), the invoking session (CZ) manually launched tdd-workflow:tdd-planner
via the Task tool expecting research-only output. The planner — correctly
following its own system prompt — produced a full plan with slices,
Given/When/Then specs, and attempted AskUserQuestion approval. CZ interpreted
this as the planner "exceeding its scope," discarded the output, and rebuilt
the plan manually, bypassing the planner's approval flow, hooks, and lock-file
mechanism.

Post-incident analysis by a separate session (CA) proposed stripping the planner
down to a research-only agent. A third session (CB) reviewed the actual source
files and determined this would dismantle a working architecture to match an
incorrect mental model.

### Root Cause Analysis

Three contributing factors were identified:

**Factor 1 — Misleading agent description (root cause)**

The frontmatter description in `agents/tdd-planner.md` lines 3-6 says:

    "Codebase research agent for TDD planning... Read-only."

But the same file's system prompt (lines 29+) says:

    "Your job is to research a codebase and produce a structured TDD plan."

The agent has AskUserQuestion in its tools, an approval sequence, a lock-file
gate, and Write access after approval. "Read-only" and "research agent" are
both factually wrong. This mismatch caused CZ to form an incorrect mental
model of the planner's role.

**Factor 2 — No invocation guardrail**

The planner is designed to be invoked exclusively via /tdd-plan, which provides
the structured SKILL.md prompt (steps 0-10). Nothing prevents a session from
manually invoking it via the Task tool with a custom prompt. When this happens:
- The agent doesn't receive the SKILL.md structured process
- It falls back to its system prompt alone (less structured)
- The caller expects research; the agent produces a full plan
- Output quality is lower because the skill's careful step ordering is absent

**Factor 3 — Incorrect architecture understanding propagates**

CZ told the user the planner is "a read-only research helper" and "an optional
accelerator for the research step." CA's incident report inherited this framing
and proposed stripping the planner to research-only. Both are wrong — the skill
config (`agent: tdd-planner`, `disable-model-invocation: true`) proves the
planner IS the full planning process.

### What Must Change

#### Change 1: Update agent frontmatter description

File: `agents/tdd-planner.md`, lines 3-6

Replace the current description:
    "Codebase research agent for TDD planning. Invoked automatically
    when /tdd-plan skill runs. Explores project structure, test patterns,
    and architecture to inform plan creation. Read-only."

With an accurate description:
    "Autonomous TDD planning agent. Researches the codebase, decomposes
    features into testable slices with Given/When/Then specifications,
    presents plans for user approval via AskUserQuestion, and writes
    approved plans to .tdd-progress.md and planning/ archive. Invoke
    exclusively via /tdd-plan — do NOT launch manually via Task tool."

#### Change 2: Add identity and invocation guard to agent system prompt

File: `agents/tdd-planner.md`, after the frontmatter (after line 27)

Add a new section before the existing "You are a TDD planning specialist":

    ## Identity & Invocation

    You are the AUTONOMOUS TDD planning agent. Your role spans the full
    planning lifecycle: research, decompose, present, get approval, write
    files. You are NOT a research-only helper.

    You are designed to be invoked via the /tdd-plan skill, which provides
    a structured 10-step process (steps 0-10 in the skill prompt). If your
    invocation prompt does NOT contain that structured process (look for
    "## Process" with numbered steps 0 through 10), you were likely invoked
    manually via the Task tool. In that case:
    1. Inform the caller that you should be invoked via /tdd-plan
    2. Explain that manual invocation bypasses the structured skill process
    3. Return only raw research findings as a fallback (file paths, patterns
       observed, architecture notes) — do NOT attempt the full planning flow
       without the skill's structured process

#### Change 3: Update CLAUDE.md Plugin Architecture table

File: `CLAUDE.md`, Plugin Architecture table

Update the tdd-planner row from:
    | **tdd-planner** | Researches codebase, decomposes features into
    testable slices, produces structured plans | Read-only |

To:
    | **tdd-planner** | Full planning lifecycle: research, decompose,
    present for approval, write .tdd-progress.md and planning/ archive.
    Invoke via `/tdd-plan` only. | Read-write (gated by approval lock) |

#### Change 4: Add invocation warning to CLAUDE.md

File: `CLAUDE.md`, after the Available Commands section

Add:
    > **Important:** Do NOT manually invoke `tdd-workflow:tdd-planner` via
    > the Task tool. It is designed to run through `/tdd-plan`, which provides
    > the structured planning process. Manual invocation produces degraded
    > results because the agent's 10-step process (from the skill definition)
    > is absent.

### What Must NOT Change

- Do NOT strip the planner down to a research-only agent
- Do NOT remove AskUserQuestion from the planner's tools
- Do NOT remove the approval flow from the agent system prompt
- Do NOT remove the .tdd-plan-locked mechanism or bash guard hooks
- Do NOT modify the /tdd-plan skill's process steps (0-10)
- Do NOT change the skill config (agent: tdd-planner, context: fork,
  disable-model-invocation: true)

These are all load-bearing parts of the planner's architecture. The problem
is a labeling/guardrail issue, NOT an architecture issue.

### Constraints

- All changes are to markdown prompt files — no hook scripts, no skill config
- The agent must remain fully functional when invoked via /tdd-plan
- The agent must gracefully degrade when invoked manually (research-only fallback)
- Descriptions must be factually accurate about the agent's actual capabilities
- Changes should be minimal and surgical — do not reorganize or rewrite sections
  beyond what is needed to fix the identity mismatch
```

---

## Iteration Notes

After running this prompt, verify:
- [ ] Does the planner correctly update its own description without breaking the system prompt?
- [ ] Is the invocation guard section placed correctly (before existing content, not disrupting flow)?
- [ ] Does the CLAUDE.md table render correctly with the longer description?
- [ ] Is the planning archive comprehensive enough to serve as permanent incident record?
- [ ] Does the planner still function correctly via /tdd-plan after the changes?

## Expected Outcome

The planning archive in `planning/` should capture:
1. The full incident analysis (Factors 1-3)
2. The architectural context (why the planner is autonomous, not research-only)
3. The specific changes made (diffs or descriptions)
4. The decision to reject CA's proposed fix and why

This serves as the permanent record of the incident and its resolution.
