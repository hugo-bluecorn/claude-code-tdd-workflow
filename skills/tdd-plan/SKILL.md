---
name: tdd-plan
description: >
  Create a TDD implementation plan for a feature. Spawns the tdd-planner
  as a research-only subagent, presents the plan for approval, and writes
  files after explicit user consent.
  Triggers on: "implement with TDD", "TDD plan", "test-driven".
argument-hint: "[feature description]"
disable-model-invocation: true
---

# TDD Implementation Planning

<!-- ultrathink -->

Read `.tdd-progress.md` in the project root. If it already exists with pending slices,
tell the user a plan is already in progress and suggest `/tdd-implement`. Then STOP.

## Step 0: Gather Context

Collect git context for the planner:
1. Current branch: `git branch --show-current`
2. Last commit: `git log --oneline -1`
3. Dirty files count: `git status --porcelain | wc -l`

## Step 1: Spawn Planner

Use the Agent tool to spawn the `tdd-planner` subagent with:
- subagent_type: `tdd-workflow:tdd-planner`
- prompt: Include the feature description ($ARGUMENTS) and git context gathered in Step 0

The planner will research the codebase and return a structured plan with
Given/When/Then test specifications for each slice.

If the planner returns without a complete plan (no slice specifications),
report the issue to the user and STOP.

## Step 2: Present Plan

Display the planner's output to the user so they can review the full plan.

## Step 3: Get Approval

Use AskUserQuestion with these options:
- **Approve** — proceed to write files
- **Modify** — user provides feedback for revision
- **Discard** — abandon the plan

### If Modify

Resume the planner subagent using the Agent tool's `resume` parameter,
passing the user's feedback. The planner will revise and return an updated plan.
Return to Step 2.

### If Discard

Tell the user the plan has been discarded. STOP — do NOT write any files.

## Step 4: Write Files (only after Approve)

1. Write `.tdd-progress.md` at the project root with the plan content.
   Add `**Approved:** <ISO 8601 timestamp>` to the header
   (after the Created/Last Updated lines).

2. Write a read-only archive to `planning/YYYYMMDD_HHMM_feature_name.md`
   using the structure from `reference/feature-notes-template.md`.

3. Run `hooks/validate-plan-output.sh` on the planning archive to verify
   structure (required sections, no refactoring leaks).

Tell the user to run `/tdd-implement` to start the implementation loop.

## Constraints

- Do NOT write any implementation code or test code
- Do NOT write files before getting explicit "Approve" via AskUserQuestion
- Do NOT call project detection scripts — the planner handles context detection
- Do NOT duplicate format/research instructions — the planner's body contains these
