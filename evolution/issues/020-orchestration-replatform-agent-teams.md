# Issue 020: Re-platform the role/collaboration layer onto Agent Teams (orchestration decision)

**Status:** open (decision/design; **lean = Agent Teams for the collaboration layer**, pending caveats + maturity) · **Found:** 2026-06-10 (competitive refresh: the platform now ships Agent Teams + Dynamic Workflows; our hand-rolled multi-session CA/CP/CI orchestration is re-platformable)
**Type:** architecture decision → re-platform (build-vs-ride, E3/E4) · **Relates to:** `evolution/explorations/assessments/competitive-landscape-refresh-2026-06.md` (§4b, §5.3), `explorations/assessments/multi-session-paradigm-survey.md` §10.4 (the "Agent Teams maturation" risk — now realized), issue 017 / R23 (autonomy), issue 012 (gated skills can't AskUserQuestion from a subagent), the role system (CA/CP/CI), PRIME DIRECTIVE

## Decision (leaning)

Ride **Agent Teams** — **not** Dynamic Workflows — for the **role/collaboration layer**, keeping the
sequential TDD cycle inside a teammate. Lean, pending the caveats below and Agent Teams maturing past
experimental.

## Why Agent Teams over Dynamic Workflows

Our investment is **persistent, named, role-identified, human-gated collaboration**. Agent Teams models
exactly that; Dynamic Workflows is ephemeral, anonymous fan-out that **dissolves identity**. The mapping
is near 1:1:

| Our model | Agent Teams primitive |
|---|---|
| **CA** (hub, reviewer, orchestrator) | **Team lead** — spawns, assigns, synthesizes, approves plans |
| **CP / CI** (separate sessions) | **Teammates** — own context; *definable as **plugin** subagent roles and reused* |
| `.tdd-progress.md` slices | **Shared task list** — pending/in-progress/done, dependencies, file-locked claiming |
| `/tdd-plan` approval gate (CP→CA) | **"Require plan approval"** — teammate in read-only plan mode → lead approves/rejects-with-feedback → revise → resubmit |
| hook enforcement (validate-tdd-order, auto-run-tests, verifier) | **`TaskCreated` / `TaskCompleted` / `TeammateIdle`** hooks (exit 2 = block + feedback) |
| human-as-message-bus | **Mailbox** (direct inter-agent messaging) |

Crucially, **teammates can be plugin-defined subagent roles** (project/user/**plugin**/CLI scope) — so the
plugin ships CP/CI as roles the lead reuses.

## The tension: Agent Teams is parallel-optimized; our cycle is sequential

The docs are explicit: *"for sequential tasks, same-file edits, or work with many dependencies, a single
session or subagents are more effective."* The TDD cycle is exactly that. So **split by layer**:

- **Agent Teams = the collaboration/identity LAYER** — CA=lead; CP/CI=committed plugin teammate roles;
  shared task list; plan-approval gate; hook gates.
- **The sequential RED-GREEN-REFACTOR CYCLE stays inside CI** — CI still runs `/tdd-implement` internally,
  where the platform says sequential work belongs.
- **Optionally Dynamic Workflows *inside* the verifier** — for the adversarial refute-and-converge pass
  (strictly stronger verification than a single-pass check).

## Caveats (bank before betting hard)

- **Experimental** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, v2.1.32+). Limits: no in-process session
  resumption (`/resume`/`/rewind`), task-status can lag, **one team at a time**, **lead is fixed**, higher
  token cost (each teammate = a full instance).
- **Teams are ephemeral + prompt-created** — you cannot commit a team definition. *But* teammate **role
  defs are committable** as plugin subagents (that's what matters).
- **Lead auto-approves plans.** To keep our *hard* human gate (disable-model-invocation / R23), either the
  **human is the lead**, or move the gate into a `TaskCompleted` hook.
- **Teammates don't load skills from agent frontmatter** — `project-conventions` (DCI) must load at
  project level instead. Rewiring, but workable.
- Split panes require **tmux/iTerm2** (in-process mode works anywhere; relevant to our Linux story).

## PRIME-DIRECTIVE safety

Agent Teams is an **optional orchestration layer** for the role-based experience. Core `/tdd-*` MUST still
run **solo** — no team, no roles. (Consistent: Agent Teams is opt-in/experimental.) Teammate role defs are
`role-`-prefixed; core stays team-agnostic.

## Differentiation vs ECC

ECC hand-rolls orchestration (tmux pane manager + autonomous-loops). Riding the **first-party Agent Teams
primitive** with **committed plugin-defined roles** + **hook-enforced TDD gates** is a cleaner, more
durable story — a genuine wedge candidate, **if** Agent Teams matures.

## Open questions / decision points

- **Human gate:** human-as-lead vs `TaskCompleted` hook vs lead-criteria-in-prompt? (↔ R23, issue 012)
- **Dual source of truth:** reconcile `.tdd-progress.md` with the shared task list — one or both?
- **Conventions wiring:** project-level load for `project-conventions`.
- **Maturity gate:** prototype now (behind the experimental flag) vs wait for GA before roadmap weight?
- **Token cost:** acceptable for a long-running 3-session TDD team?

## Next steps — a spike

Prototype CA(lead)/CP/CI(teammates from plugin subagent defs) on a toy repo behind the experimental flag:
exercise the **plan-approval gate as the CP→CA loop** and a **`TaskCompleted` hook as the verifier gate**.
Assess fit/cost before committing roadmap weight.

## Note

Design decision, not a build commitment. Makes the multi-session survey's "monitor Agent Teams" (§10.4)
**actionable**.
