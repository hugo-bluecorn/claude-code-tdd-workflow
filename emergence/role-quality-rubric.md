# Role Quality Rubric

> Emergent quality knowledge for TDD-workflow session roles — the criteria a role
> must pass beyond the mechanical validator. Used by the author (and by a CE
> session) to assess every role. Distilled 2026-06-10 from the role-format spec,
> the self-compilation experiment's metrics, and this project's review practice.

A role is **good** when it clears two layers:

## Layer 1 — Mechanical (enforced by `scripts/validate-role-output.sh`, exit 0)
- [ ] Frontmatter delimiters; required `role:` `name:` `type:`.
- [ ] If `name:` starts with `role-` → also `description:` + `disable-model-invocation: true`.
- [ ] An Identity section is present.
- [ ] ≤ 400 lines (prefer ≤ 300).
- [ ] No `{placeholder}` / `TODO` / `TBD` in the body (outside code fences).
- [ ] Constraints are prohibition-phrased (`Never`/`Do not`/`Only`) and **each carries a consequence**.
- [ ] **Every referenced path exists on disk** (run with `--base-dir <target>`).

## Layer 2 — Judgment (the critique the validator cannot make)
- [ ] **Constraints carry real consequences**, not restatements — a session reading them understands the *systemic* cost, so it can't rationalise a violation. (Target: every constraint.)
- [ ] **Responsibilities are action → visible output** (`verb + object → artifact`). Never "understand X"; always "read X → produce Y".
- [ ] **Identity states the mode of operation** (conversational / command-driven / plan-mode / review), not just *what* the role does.
- [ ] **Grounded, never invented** — every path/command/convention is verified against the real project; no fabricated examples. (The path-existence check enforces paths; *commands* are honour-system — verify them.)
- [ ] **No CLAUDE.md duplication** — the role does not restate architecture / key-paths / commands that the project's auto-loaded `CLAUDE.md` already carries. Heavy project context lives in `emergence/project-context.md`; the role *references* it and stays lean (loadable identity, not a context dump).
- [ ] **Set-coherent coordination** — every peer the role names exists in the role set; both directions of each hand-off are defined with the hand-off *format* (paste / disk file). No dangling peer references.
- [ ] **Always-show-full + disk hand-off** — for roles that produce or review plans, the role mandates reproducing the FULL plan/verdict in-terminal AND persisting it to the project's disk bus (`specs/`, `planning/`, `.tdd-progress.md`, `emergence/`) — never relying on an ephemeral location as the hand-off.
- [ ] **No hedge-adjectives** — no "optional / lightweight / simple / just" framing; adjectives in instructions read as directives and deprioritise what they describe.
- [ ] **Single frontmatter block** (skill + role fields merged; not two consecutive `---` blocks).
- [ ] **Type correct** — `session` (a full identity) vs `context` (a supplemental doc loaded into any session).
- [ ] **Right altitude** — focused; sections are selected from the menu to fit *this* role, not copied wholesale.

## Verdict format (per role, written to `emergence/role-assessments/<role>.md`)
```
# Assessment: role-XX — {Name}
Validator: exit 0 (or the failure + fix)
Layer-2 findings: [PASS] / [FIX] per criterion, with line-ish references
Verdict: SHIP / REVISE
```
A role ships only at **validator exit-0 AND zero open [FIX] findings**.
