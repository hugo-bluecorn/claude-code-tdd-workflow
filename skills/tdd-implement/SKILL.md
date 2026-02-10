---
name: tdd-implement
description: >
  Execute TDD implementation for pending slices in .tdd-progress.md.
  Reads the progress file, finds pending slices, and runs each through
  tdd-implementer (red-green-refactor) then tdd-verifier (blackbox validation).
  Use to start or resume TDD implementation after /tdd-plan.
  Triggers on: "implement TDD", "run TDD slices", "continue TDD".
---

# TDD Implementation

Read `.tdd-progress.md` in the project root. If it does not exist, tell the user to run `/tdd-plan` first and stop.

## Implementation Loop

For each slice with a non-terminal status (not done, pass, complete, fail, or skip):

### 1. Invoke tdd-implementer

Pass the slice specification (test file, implementation file, test descriptions, implementation scope) to the `tdd-implementer` agent. The implementer executes the red-green-refactor cycle for that single slice.

### 2. Invoke tdd-verifier

After the implementer finishes, pass the slice's verification criteria to the `tdd-verifier` agent. The verifier runs the full test suite, static analysis, and checks plan criteria.

### 3. Handle the result

- **PASS**: Update the slice status to `done` in `.tdd-progress.md` and move to the next slice.
- **FAIL**: Report the failure details. Retry the slice with the implementer, passing the failure information. If it fails again, stop and report to the user.

### 4. Repeat

Continue until all slices are in a terminal state.

## Resume Support

If some slices are already `done`/`pass`, skip them and start from the first pending slice. This allows resuming interrupted sessions.

## Constraints

- Process slices in order — each may depend on the previous
- Do NOT skip slices or reorder them
- Do NOT modify tests written by the implementer
- Update `.tdd-progress.md` after each slice completes
