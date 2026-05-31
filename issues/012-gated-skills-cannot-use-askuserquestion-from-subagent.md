# Issue 012: Gated skills can't use AskUserQuestion from their subagent (inert tool declaration)

**Status:** open · **Found:** 2026-05-31 (during the v2.4→v3 upgrade, R6→R14 dogfooding)

## Problem

`/tdd-release` (and, by the same mechanism, any flow that runs an approval-needing
agent as a subagent) **cannot present its `AskUserQuestion` approval gates from inside
the subagent.** When the user invokes `/tdd-release`, the releaser runs as a **subagent**;
subagents cannot call `AskUserQuestion`. So every release stops at the gate and **hands
back to the main thread**, which then re-presents the version/CHANGELOG/PR decisions as
plain text and collects a text approval.

This worked (the main thread drove every gate manually across PRs #18–#22), but it means
the skill's *designed* interactive approval gates are effectively dead inside the subagent.

## Evidence

- `agents/tdd-releaser.md` **declares `AskUserQuestion` in its `tools:`** — but as a
  subagent it can never invoke it. The declaration is **inert**, exactly like the inert
  frontmatter `hooks:` blocks R16 removed.
- Same inert `AskUserQuestion` declaration appears on other agents that run as subagents
  (e.g. `context-updater`; `tdd-planner` reaches approval via its spawning skill, not itself).
- Observed every release this engagement: the releaser subagent reported "AskUserQuestion
  unavailable in a subagent" and deferred the mutating steps (CHANGELOG/commit/push/PR) to
  the main thread.

## Root cause

Approval gates require the **interactive main thread**. A skill that spawns an agent to do
the work puts the gate on the wrong side of the subagent boundary. The `tools:`
declaration of `AskUserQuestion` on a subagent-only agent is a no-op.

## Related

- Sibling finding (the other half of the autonomy story): the **`disable-model-invocation`**
  gate on `/tdd-plan`, `/tdd-release`, `/tdd-finalize-docs`, `/tdd-update-context` means the
  *model* cannot self-trigger them either (only the user typing the slash command). Together
  these two constraints shape how much of the workflow can run unattended — relevant to
  roadmap **R13** (`/tdd-green` autopilot) and **R22** (headless SDK).

## Fix candidates (role-subsystem work — not scheduled here)

1. **Present gates from the main thread.** Keep the heavy/read-only work in the subagent
   (pre-flight, quality gates), but surface the approval `AskUserQuestion` from the
   orchestrating skill in the main context (where it actually works).
2. **Formalize a text-approval fallback** for headless/subagent contexts, so a gate degrades
   to a deterministic text protocol instead of silently no-op'ing.
3. **Remove the inert `AskUserQuestion`** from subagent-only agents' `tools:` (cleanup,
   mirrors R16's inert-hooks removal) so the declaration doesn't imply a capability the
   agent can't use.
4. Design an explicit **model-invocable / autopilot entrypoint** for the user-gated skills
   (for R13/R22) without stripping the human gate from the interactive path.

## Scope

Touches the role/release subsystem (agents' `tools:` declarations, the gated skills'
orchestration). PRIME-neutral. Pairs naturally with R11b (`/tdd-finalize-docs` rebuild,
which also adds an approval gate) and the R13/R22 autonomy work. Out of scope for Wave 1/2.
