---
name: prime-directive
description: The hard boundary — tdd-* core must function without role-* files; skills are verbs, agents are nouns. Every change honors it.
metadata:
  type: feedback
---

**PRIME DIRECTIVE (verbatim, `CLAUDE.md`):** Roles (`/role-create` and generated `/role-*` skills) are a *recommended* approach, supported by experimental evidence — **not the only way**. The core TDD workflow (plan → implement → verify → release) **functions independently of role files. No agent, skill, hook, or script in the core workflow may check for, reference, or require role files.** Role skills use the `role-` prefix; core workflow skills use the `tdd-` prefix. **The naming enforces the technical boundary.**

**How to apply (every change you make):**
- `tdd-*` = core (mandatory, self-contained). `role-*` = optional role system. `project-*` = convention loading. A `tdd-*`/manifest/hook/convention component must NEVER require a `role-*` file. Verify with `explorations/features/roles/prime-directive-verification.md` (traces all components → zero role deps).
- **Skills are verbs** (`tdd-plan`, `tdd-implement`), **agents are nouns** (`tdd-planner`, `tdd-implementer`). The `/role-cr`→`/role-create` rename existed solely to satisfy this `prefix-verb` rule.
- **Adjective hazard (experimental finding):** adjectives in prompts act as directives — "optional" caused systematic deprioritization, so docs say "recommended," not "optional." Avoid weakening adjectives in agent/skill prompts.
- Latent blocker to watch: a plugin `dependencies` edge on a *convention* pack is fine; on a *role* pack it is a **blocker**. See [[decisions]] R1.
