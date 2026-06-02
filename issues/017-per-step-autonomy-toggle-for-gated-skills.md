# Issue 017: Per-step autonomy toggle for the user-gated TDD skills

**Status:** open (logged, build deferred) · **Found:** 2026-06-02 (dogfooding the BF-001/BF-003 cycle — the model could not advance the loop because `/tdd-plan` and `/tdd-release` are user-gated)
**Type:** new capability → **MINOR (target 2.9.0)** · **Relates to:** issue 012 (gated skills + AskUserQuestion), `memory/disable-model-invocation-autonomy-tension.md`, roadmap R13 (`/tdd-green` autopilot), R22 (headless SDK recipe)

## Problem

Four skills are user-gated via static frontmatter `disable-model-invocation: true`:
`tdd-plan`, `tdd-release`, `tdd-finalize-docs`, `tdd-update-context`. `tdd-implement`
is the only model-invocable step. This is the correct **safe default** for ordinary use
(a human decides when to plan, release, finalize docs, refresh context).

But in **development / dogfood cycles** — like fixing the plugin's own bugs, or any
headless/unattended run — the model cannot advance the loop: it stalls at every gate
waiting for a human to type the command. The gate is all-or-nothing and baked into
frontmatter, so there is no way to relax it for a trusted session, per step.

## Why a config flag alone cannot fix it

`disable-model-invocation` is **static frontmatter**, evaluated once at plugin load.
No runtime config can flip it. Per-step, per-session control therefore requires moving
enforcement out of frontmatter and into a **hook**.

## Proposed design — dynamic, per-step gate (default-deny)

1. **Remove** `disable-model-invocation` from the 4 gated skills (they become
   *technically* model-invocable).
2. **Add `hooks/gate-skill-invocation.sh` as a PreToolUse hook on the `Skill` tool**
   (alongside the existing `validate-tdd-order.sh` PreToolUse entries). Logic:
   - skill not in the gated set → allow (no decision).
   - gated, autonomy **off** for that step (**default**) → return
     `permissionDecision: deny` with a reason instructing the model that the step is
     user-gated and to ask the user to run `/tdd-<step>` or enable autonomy.
     **This reproduces today's behavior byte-for-byte.**
   - gated, autonomy **on** for that step → allow.
   The hook re-reads config on every Skill call, so the gate is live.
3. **The toggle's setter is the one irreducible human gate.** A new
   `/tdd-autonomy <steps> on|off|status` skill — itself `disable-model-invocation: true`
   — writes the per-step config. Because only a human can type `/tdd-autonomy`, and the
   enforcement hook reads that config fresh each call, **the human always opens the gate**;
   the model cannot enable its own autonomy through the sanctioned path.

### Config shape

`.claude/tdd-workflow.local.json` (project-local, gitignored):

```json
{ "autonomy": { "tdd-plan": true, "tdd-release": true,
                "tdd-finalize-docs": false, "tdd-update-context": false } }
```

Open design questions for the build cycle:
- **Session-scoping / TTL** — should autonomy auto-expire (per-session, or after N minutes)
  so a left-on flag doesn't silently persist into an ordinary later session? Leaning yes:
  default to session-scoped, with an explicit `--persist` for long dev runs.
- **`status` output** — `/tdd-autonomy status` prints the current per-step state.
- **Granularity** — per-step (above) vs. a single `all` switch. Per-step is the ask.

## Known soft boundary (document, don't over-engineer)

The model holds `Write`/`Edit`, so it could edit `.claude/tdd-workflow.local.json`
directly rather than via `/tdd-autonomy`, bypassing the human gate. The **strong**
guarantee lives on the human-typed command + default-deny hook; the file-write path is a
**soft** boundary. Mitigations to weigh in the build: (a) instruct the model not to write
that file; (b) have the same PreToolUse hook also guard `Write`/`Edit` against that path;
(c) accept it as a documented boundary (consistent with the DCI security-boundary handling
in issue 009 — the system's real guarantees are convention + the hard frontmatter gate on
the one setter). Threat model is "don't let the model silently/accidentally run gated steps
in a normal session," not "defend a model actively subverting its own sandbox."

## PRIME DIRECTIVE

No role coupling anywhere: the hook, the config, and `/tdd-autonomy` are core `tdd-*`
plumbing and must not reference, check for, or require any role file. The gate concerns
*model-invocation autonomy*, orthogonal to roles.

## Acceptance (for the future build cycle — each test asserts the ACTION)

- Default (no config) → model invocation of `tdd-plan` is **denied** by the hook (assert
  the deny decision + reason emitted), exactly as the frontmatter gate did.
- `/tdd-autonomy tdd-plan on` written → model invocation of `tdd-plan` is **allowed**
  (assert allow), while `tdd-release` (still off) is **denied** (per-step isolation).
- `/tdd-autonomy ... off` / status round-trips the config.
- `tdd-implement` is never gated regardless of config (unchanged).
- No `role-*` reference introduced (PD guard).

## Practical note

Because a session runs the *installed* plugin, this feature only takes effect after a
plugin reinstall — it cannot retroactively unblock the session that requests it. Build it,
reinstall, then subsequent dogfood/headless cycles run unattended per-step.
