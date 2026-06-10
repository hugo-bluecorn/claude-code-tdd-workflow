# Competitive Landscape Refresh — June 2026 ("soul searching")

> **Date:** 2026-06-10 · **Author:** Claude (Opus 4.8) with Hugo
> **Supersedes:** `docs/marketplace-survey-2026-03-09.md` and the competitor framing in the two
> March assessment surveys. **Also corrects this doc's own first pass** (see Correction note).
> **Method:** WebSearch + direct WebFetch of the major GitHub lists, the official `marketplace.json`,
> ECC, and Anthropic docs. Figures are point-in-time (June 2026).

> **⚠️ Correction note.** The first version of this refresh (earlier same day) leaned on search-result
> *summaries* and concluded "our moat holds." A deeper dig **falsifies** that. It mis-categorized
> **`everything-claude-code` (ECC)** as a "firehose list" when it is a **full competing framework**,
> and it predated finding **Anthropic Dynamic Workflows** and **ECC `continuous-learning-v2`**. This
> is the exact introspective blind spot the evolution-review method (E7) warns about. The verdict
> below is the corrected one.

---

## 1. Honest executive summary

**We are not the reference point anymore, and we should stop framing the field around ourselves.**

- The **priority competitors are now ECC, Superpowers, and the platform itself** (Dynamic Workflows,
  agent teams, native memory) — not the light/narrow tools our March surveys benchmarked against
  (atdd, tdg, tdd-guard, a 53-plugin marketplace). Those are **deprioritized**.
- The "complete verified pipeline + multi-language conventions" **moat claim is falsified**: **ECC**
  ships multi-language TDD skills, language rule-packs, a verification-loop + eval-harness, multi-agent
  orchestration, **and** a continuous-learning/`/evolve` system — at ~211k★ and cross-harness, far
  beyond our scope.
- **Our emergence/role-evolve idea is not novel.** ECC's `continuous-learning-v2` is a shipped,
  more-mature instance of the same thesis (observe → extract instincts w/ confidence → evolve into
  skills/commands/agents).
- **The platform leapfrogged our orchestration.** Dynamic Workflows does plan → fan-out → adversarial
  refutation → converge → verify as a built-in primitive (up to 1,000 subagents). Our hand-rolled
  sequential planner→implementer→verifier is, in orchestration terms, behind.

**Residual wedge is thin and must be *defended*, not assumed:** disciplined focus/cohesion (one
rigorous TDD spine vs ECC's 261-skill sprawl), the PRIME-DIRECTIVE-clean composable architecture
(language-agnostic core + external convention-pack ecosystem + role/core separation), and a
conservative *committed, approve-gated* knowledge model. Whether the market values any of these over
breadth is **unproven**. This is the existential question for Hugo (§5).

---

## 2. The real priority competitors

### ECC — `everything-claude-code` (affaan-m / codelably) — the one we under-weighted
**Not a list — a framework.** ~211k★, cross-harness (Claude Code, Cursor, OpenCode, Codex, Gemini,
Zed, Copilot), 230+ contributors. Inventory: **64 agents** (11 QA/verification), **261 skills**,
**84 commands**, **29 rule files across 8 language packs**, 997–1282 internal tests.
- **Multi-language TDD:** `tdd-workflow` skill (RED-GREEN-IMPROVE, 80%+ coverage) + `tdd-guide`
  agent + per-language TDD skills (django/springboot/quarkus/laravel/golang/perl/swift/**cpp**).
- **Conventions:** `rules/` packs (TS/Python/Go/Swift/PHP/Perl/ArkTS) + pre/post-edit hooks.
- **Verification:** `verification-loop` (build+test+lint+typecheck+security), `eval-harness`
  (eval-driven dev, pass@k), **AgentShield** (red-team/blue-team/auditor, 1282 tests).
- **Pipeline:** `/ecc:plan` → implement-with-skill → `/code-review` → `/build-fix` → `/quality-gate`.
- **Orchestration:** `/multi-plan|execute|workflow`, DAG orchestration, tmux pane manager, autonomous loops.
- **Continuous learning (the one that stings — see §3).**

**Verdict:** a genuine superset on nearly every axis we claimed as differentiation, at far greater
scale and reach. We are smaller and narrower than ECC, full stop.

### Superpowers (obra) — owns TDD mindshare
42k → **177k★**, ~750–790k installs, **official marketplace**. TDD red-green-refactor + brainstorming
+ debugging + verification-before-completion gate + subagent-driven dev + skill-authoring. Its public
description still shows no separate full-suite verifier / language-conventions / release pipeline — so
**broad-but-shallow on verification & shipping remains true of Superpowers specifically** — but it
owns the cultural default for "TDD on Claude Code."

### Anthropic Dynamic Workflows — the platform leapfrog (NEW)
Shipped **May 28, 2026** (research preview; paid plans; on-by-default Max/Team). Claude **writes a JS
orchestration script on the fly**, a runtime fans out **dozens–1,000 subagents in parallel**, agents
attack from independent angles, **other agents try to refute the findings**, it **iterates until
convergence and verifies before folding in**. Proof point: Jarred Sumner ported Bun Zig→Rust, ~750k
LOC, 99.8% tests passing, ~11 days. This is **adversarial, self-verifying multi-agent orchestration as
a primitive** — strictly more powerful than our fixed sequential pipeline. (It is, in fact, the same
`Workflow` capability this very session can call.)

### Platform, cont. — native memory + agent teams
Native **auto-memory** (v2.1.59+, `~/.claude/projects/<project>/memory/`, MEMORY.md index + topic
files, machine-local) and **agent teams** (`/agent-teams`, communicating sessions) are now real. Native
memory's machine-local siloing is still the gap our committed `emergence/` + issue 018 address — but
see §3, the promotion idea is no longer ours alone.

### Deprioritized (no longer the reference frame)
`atdd`, `tdg`, `tdd-guard` (still a fine enforcement utility, now any-language/any-runner, cross-tool),
the old 53-plugin marketplace. Light/narrow relative to ECC/Superpowers/platform. Keep `atdd`'s
spec-guardian + mutation-testing ideas on the absorb list; otherwise demote.

---

## 3. The hardest finding — our emergence/role-evolve is not greenfield

ECC's **`continuous-learning-v2`** (inspired by the community **Homunculus** project) is a shipped
system that does what issue 019 proposes:

| Our design (issue 019 / emergence-memory-architecture) | ECC `continuous-learning-v2` (shipped) |
|---|---|
| Capture emergent knowledge | Hooks capture **every** PreToolUse/PostToolUse → JSONL store (100% deterministic in v2.1) |
| Promote to durable artifacts | **Evolution pipeline**: instincts cluster/evolve into **skills, commands, agents** (`/evolve`) |
| Confidence/validation | **Confidence scoring** on each atomic instinct + evidence + domain tags |
| Native-memory siloing concern | **v2.1 project-scoped instincts** to prevent cross-project contamination |
| Store | `~/.claude/homunculus/` (identity, observations, instincts, evolved artifacts) |

**Implication:** issue 019 must **study `continuous-learning-v2` first** and either *adopt* it or
*differentiate* sharply. Our only honest distinguishing angle is the **committed-to-git, human-curated,
approve-gated** `emergence/` (vs their local, auto-evolving store) — i.e. *conservative & reviewable*
vs *automatic & local*. That is a real but narrow difference, and it is unproven that it's better.

---

## 4. Honest differentiation audit

| Claimed differentiator | Honest status (June 2026) |
|---|---|
| Complete verified pipeline | **Falsified as unique** — ECC has plan→implement→review→build-fix→quality-gate + verification-loop |
| Multi-language conventions | **Falsified as unique** — ECC ships 8 language rule-packs + per-language TDD skills |
| Release/CHANGELOG/PR in-cycle | **Still relatively rare** in disciplined form; ECC's is deployment-automation-flavored, not TDD-commit-sequenced — a *thin* edge |
| Independent full-suite verifier as a hard phase gate | **Plausibly still sharper than peers** (separate read-only agent, full suite, tool-restricted) — but ECC's verification-loop + AgentShield are credible; needs head-to-head proof, not assertion |
| Multi-session collaborative roles (CA/CP/CI) | **Still distinctive** but crowded by agent-teams + Dynamic Workflows; personas (SuperClaude) and ECC Codex-roles exist |
| emergence/role-evolve | **Pre-empted** by ECC continuous-learning-v2; our edge = committed/curated/approve-gated (narrow, unproven) |
| PD-clean composable architecture (core ⊥ roles ⊥ packs) | **Genuinely distinctive** — ECC is batteries-included/monolithic; ours is decoupled. Real, if the market rewards it |
| Focus / cohesion / rigor (one TDD spine, not 261 skills) | **Our most defensible wedge** — but "smaller and more disciplined" only wins if demonstrated (the `experimental-results` rigor is the asset here) |
| Distribution | **Weak** — unlisted; ECC/Superpowers have 100k★-scale reach (R8/R9 necessary, not sufficient) |

---

## 5. Revised strategic implications

1. **Reframe the benchmark.** Stop comparing to atdd/tdg. Benchmark against **ECC, Superpowers, and
   the platform** (Dynamic Workflows, agent teams, native memory). Re-run E7 on a cadence; the field
   moved this far in *three months*.
2. **Don't reinvent — study `continuous-learning-v2`** before building issue 019. Adopt or sharply
   differentiate (committed/curated/approve-gated). Assume *no* first-mover advantage.
3. **Decide the re-platform question (E3/E4): ride Dynamic Workflows.** The platform now does
   adversarial, self-verifying, parallel orchestration. Maintaining a bespoke sequential 6-agent
   pipeline may be wasted effort. Seriously evaluate authoring the TDD cycle **as a Dynamic Workflow
   script** (plan → implement → independent-verify/refute → release) instead.
4. **Pick a defensible wedge — narrow and deepen, don't compete on breadth.** Honest candidates:
   (a) **rigor & cohesion & verifiability** (the disciplined, no-sprawl, empirically-validated TDD
   framework); (b) **the PD-clean composable convention-pack ecosystem** (a *framework + packs*, not a
   monolith); (c) a **vertical** (Flutter/Dart, leveraging the langpack work). This is **Hugo's call**
   and it's existential — "be a smaller ECC" is not viable.
5. **Distribution (R8/R9) is table-stakes, not a strategy.** Ship it, but it won't matter without (4).

---

## 6. E7 peer registry — revised tiers (last-reviewed 2026-06-10)

**Priority (benchmark against these):**
| Peer | Why priority | Watch |
|---|---|---|
| **ECC** (everything-claude-code) | superset framework, 211k★, cross-harness | continuous-learning-v2 / `/evolve`; rule-packs; verification-loop |
| **Superpowers** (obra) | owns TDD mindshare, official, 177k★ | skill-authoring-via-TDD; methodology defaults |
| **Anthropic Dynamic Workflows** | platform orchestration primitive | adversarial fan-out/refute/converge; the re-platform path |
| **Native memory + agent teams** (platform) | commoditize memory + multi-session | what they *don't* do = our remaining room |

**Watch (rising / adjacent):** `shinpr/claude-code-workflows`, `catlog22/Claude-Code-Workflow`,
`claude-studio`, `claude-mem`, `Deep Trilogy`, `SuperClaude`.
**Deprioritized (carry-over, demoted):** `atdd` (keep spec-guardian + mutation-testing ideas), `tdg`,
`tdd-guard`, VGV.

## 7. Ideas worth absorbing (feed E6)

- **Instinct/confidence + evolution pipeline** (ECC continuous-learning-v2) — the reference design for issue 019; adopt the confidence-scored, project-scoped pattern; differentiate on commit+curate+gate.
- **Adversarial cross-checking** (Dynamic Workflows) — independent agents *refute* findings before convergence; far stronger than single-pass verification. Adopt into the verifier.
- **Spec-guardian + mutation testing** (atdd) — still un-adopted.
- **Skill-authoring-via-TDD** (Superpowers) — apply our cycle to authoring convention packs.

---

## Sources

- Anthropic — [Dynamic Workflows blog](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) · [Workflows docs](https://code.claude.com/docs/en/workflows) · [memory](https://code.claude.com/docs/en/memory) · [subagents](https://code.claude.com/docs/en/sub-agents) · [InfoQ: Dynamic Workflows](https://www.infoq.com/news/2026/06/dynamic-workflows-claude-code/)
- ECC — [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) · [continuous-learning-v2 (pluginhub)](https://www.claudepluginhub.com/skills/codelably-everything-claude-code/continuous-learning-v2) · [continuous-learning-v2 SKILL.md](https://github.com/affaan-m/everything-claude-code/blob/main/skills/continuous-learning/SKILL.md)
- Competitors/lists — [Superpowers](https://claude.com/plugins/superpowers) · [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) (46.1k★) · [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) · [nizos/tdd-guard](https://github.com/nizos/tdd-guard) · [shinpr/claude-code-workflows](https://github.com/shinpr/claude-code-workflows) · [official marketplace.json](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json)
