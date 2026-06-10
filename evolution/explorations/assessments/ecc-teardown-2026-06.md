# ECC (everything-claude-code) — Exhaustive Teardown, June 2026

> **Date:** 2026-06-10 · **Author:** Claude (Opus 4.8) with Hugo
> **Method:** four parallel research agents, each line-by-line on a subsystem via the **GitHub tree
> API + raw `SKILL.md`/script files**, the Mintlify docs, indexers (claudepluginhub, skills.rest,
> playbooks, DeepWiki), and third-party reviews. **Supersedes the capability-level read** in
> `competitive-landscape-refresh-2026-06.md` §2–§3 with verified facts.
> **Honesty note:** figures verified against the live API where possible; everything unverified is
> flagged. This corrects my earlier guesses *in both directions* — some "moat" claims verify as real,
> some ECC capabilities are bigger than I said.

---

## 1. What ECC is (verified, live API 2026-06-10)

A **cross-harness "operator system" for agentic coding** — repo description: *"The agent harness
performance optimization system. Skills, instincts, memory, security, and research-first development
for Claude Code, Codex, Opencode, Cursor and beyond."*

- **Scale:** **212,262 stars · 32,585 forks · ≥233 contributors.** (README badge text "211.9K" is stale.)
- **Maintainer:** **Affaan Mustafa** (`affaan-m`), **single maintainer**, MIT. *(My earlier "codelably" credit is **unverified** — drop it.)*
- **Maturity caveats:** repo history was **rewritten** (created 2026-01-18, first commit on `main` 2026-02-14); 2,064 commits; `v2.0.0` shipped **2026-06-10**; ~weekly releases; 57 open issues.
- **Cross-harness:** Claude Code, Codex, Cursor, OpenCode, Gemini, Zed, Copilot (+ Kiro/Trae/Qwen/…), via **shared-source + thin per-harness adapters** (native event hooks where supported; instruction-backed where not, e.g. Codex).
- **Commercial layer:** `ecc.tools` GitHub App ("ECC Tools") — Free / **Pro $19/seat/mo** / Enterprise; npm `ecc-universal` + `ecc-agentshield`; GitHub Sponsors. So it's a **community OSS core + a paid SaaS audit layer** — a real business, not just a list.

## 2. Verified component inventory (git tree, not truncated)

| Component | Verified | Notes |
|---|---|---|
| Agents | **64** | `agents/*.md` |
| Skills | **261 dirs** (360 `.md`) | `skills/` |
| Commands | **84** | "legacy command shims" |
| Rules | **104 files / ~18 language packs** | *(not the "29 / 8 packs" I cited — that was stale)* |
| Hooks | 5 event types, `hooks.json` graph | profiles: `standard/minimal/strict` |
| Tests | "997 internal" (ECC) | AgentShield's "1282 tests/102 rules" is the **external** package, not ECC's suite |

## 3. Subsystem teardown

### 3a. TDD + verification — *our key axis*
- **`tdd-workflow` skill:** RED-GREEN-**REFACTOR** (I wrongly said "IMPROVE"), **80%+ coverage**.
  **Enforcement is instruction/phase-gate + git checkpoints — NOT a blocking hook.** ("Do not edit
  production code until this RED state is confirmed.")
- **`tdd-guide` agent:** Sonnet, **read-WRITE** (Read/Write/Edit/Bash/Grep) — it writes the tests *and*
  the code; **not an isolated checker.**
- **~15 per-language test skills** (`*-tdd`: django/laravel/springboot/quarkus; `*-testing`:
  go/rust/kotlin/python/csharp/fsharp/cpp/perl/react/swift/e2e).
- **`verification-loop`:** a **self-run** 6-phase checklist (build/typecheck/lint/test+cov/secscan/diff),
  gate-or-continuous. **`eval-harness`:** eval-driven dev, **pass@k / pass^k**, 3 grader types — genuinely
  novel, we have nothing like it. **AgentShield:** external security scanner, A–F grade, `--opus` runs a
  **red-team → blue-team → auditor** adversarial pipeline.
- **🔑 THE FINDING — no independent verifier gate.** The full 64-agent list contains **no dedicated,
  read-only, full-suite verifier as a hard phase gate.** Verification is self-checked/inline (the same
  `tdd-guide` writes *and* tests; `verification-loop` is self-run; the RED gate is instructional). The
  only hard programmatic block is `block-no-verify.js` (blocks `git --no-verify`). **Our read-only
  `tdd-verifier` running the COMPLETE suite as a gate has no structural equivalent in ECC** — verified
  line-by-line. *This re-validates a differentiator I'd flagged as "needs proof."*
- **Release:** ECC HAS a substantial pipeline (`release.sh`, signed `release-approval-gate.js`, GH
  Actions, CHANGELOG) — but it's for **publishing ECC itself** (bump across ~20 manifests, npm publish),
  **not a per-user-project TDD-commit-sequenced releaser** like ours. No `tdd-releaser`-style role.

### 3b. Continuous-learning-v2 / "Homunculus" — *the emergence/role-evolve axis*
- **Origin:** based on the community project **Homunculus** (`humanplane/homunculus`) — *"watches how you
  work, learns your patterns, evolves itself."*
- **Mechanism:** deterministic hooks (PreToolUse/PostToolUse, 100%) → **JSONL** observations → a
  **background Haiku observer** → atomic **instincts** (`trigger` + `confidence 0.3–0.9` + `domain` +
  `evidence`, YAML) → **`/evolve`** clusters them into **skills / commands / agents** (`--generate`).
- **Commands:** `/instinct-status`, `/evolve`, `/instinct-export`, `/instinct-import`, `/promote`,
  `/projects`. *(My earlier `/prune` is **unverified** — not found.)*
- **Storage — critical:** v2.1 deliberately stores **OUTSIDE `~/.claude`** (`CLV2_HOMUNCULUS_DIR` →
  `~/.local/share/ecc-homunculus`) to dodge Claude Code's sensitive-path guard. **Local, uncommitted,
  machine-local, personal.** Project-scoped via git-remote hash; auto-promote to global needs the same
  instinct in **2+ projects** AND **avg confidence ≥0.8**.
- **Native memory relationship:** **NOT documented — runs alongside/independent** (their store is
  *deliberately outside* `~/.claude`; ECC neither reads nor writes native auto-memory).
- **Adoption caveat:** the v2.1 `observer.enabled` defaults to **false**.

> **What this means for issue 019 (honest):** the *core idea is not novel* — Homunculus/ECC shipped
> "observe → confidence-scored knowledge → evolve into artifacts" first and more elaborately. **But our
> design is a genuinely different point in the space, not a worse copy:** ECC = **automatic, local,
> uncommitted, personal**; ours = **committed-to-git, human-curated, approve-gated, shared** (`emergence/`).
> Different *target* too — ours promotes into **role identities**, theirs into generic skills/commands/
> agents. The "team wiki vs personal episodic learner" framing holds. **Adopt their mechanics
> (confidence scoring, project-scoping, clustering); differentiate on commit + curate + gate.**

### 3c. Orchestration — *the Agent Teams axis (issue 020)*
**Hand-rolled — NOT Agent Teams, NOT Dynamic Workflows.** `dmux-workflows` (tmux pane manager),
`autonomous-loops` (a real DAG engine: sequential pipeline / infinite agentic loop / continuous-PR-loop /
**RFC-driven DAG with jj worktrees + merge-queue + eviction** — genuinely sophisticated), `/multi-*`
commands, `loop-operator` agent (stop-conditions, escalation triggers, observability). Spawns are
harness-agnostic CLI strings (`codex exec --task-file …`). **⇒ Confirms issue 020's wedge: riding the
first-party Agent Teams primitive is a cleaner, more durable story than ECC's tmux/jj hand-roll.**

### 3d. Conventions/rules + hooks
- **Rules:** 104 files / ~18 packs, loaded as **resident "always-follow" context (~5–8K tokens always
  loaded) — prompt-level, NOT hook-enforced.** Install caveat: rules *"cannot be distributed
  automatically,"* breaking "install once, get everything." **⇒ Our external convention-pack ecosystem
  (DCI-loaded, decoupled, pluggable) is architecturally distinct from ECC's bundled-in-repo prompt-rules.**
- **Hooks:** 5 events (PreToolUse can block; PostToolUse can't; Stop/SessionStart-End/PreCompact),
  `hooks.json` graph, runtime profiles + `ECC_DISABLED_HOOKS`. Concrete: Prettier auto-format, `tsc
  --noEmit`, secret detection, dev-server-blocker, session-summary/state persistence, pattern extraction.

## 4. Quality / cohesion — honest read
**Impressively engineered core, but leaning sprawl/firehose.** The most-cited review is literally titled
*"…the 82K-Star Agent Harness That's Dividing the Developer Community."* Documented criticisms: *"most
people just need a good CLAUDE.md, not an entire ecosystem"*; *"exceeds what most teams need"* (a
60–200-line CLAUDE.md covers ~80%); **incomplete install** (rules not auto-distributed); **star-vs-usage
skepticism** (few active Discussions despite high stars); **token cost** (resident rules + many MCPs can
drop usable context to ~70K). Narrow, genuine praise: the **code-reviewer agent**, the **TDD skill**, and
**session-summary hooks**. Numbers are **inconsistent across versions/sources** (a maturity smell), and
it's a **single-maintainer** project shipping weekly across 7 harnesses (bus-factor risk).

## 5. Honest head-to-head vs tdd-workflow (the payoff)

| Axis | ECC | tdd-workflow (us) | Verdict |
|---|---|---|---|
| Scale / reach / stars | 212k★, cross-harness, commercial | tiny, single-harness, unlisted | **ECC, decisively** |
| Breadth (skills/agents/langs) | 261 skills / 64 agents / ~18 packs | focused TDD spine + pack ecosystem | **ECC** |
| **Independent full-suite verifier gate** | **none** (self-checked/inline) | **dedicated read-only `tdd-verifier`** | **US (verified)** |
| TDD-commit-sequenced **releaser for the user's project** | release tooling for *itself* only | purpose-built releaser role | **US** |
| Convention delivery | bundled in-repo, prompt-level, can't auto-distribute | **decoupled external packs, DCI-loaded** | **US (architecture)** |
| Orchestration | sophisticated **hand-rolled** tmux/jj DAG | plan to **ride Agent Teams** (020) | **different bets; ours cleaner if AT matures** |
| Continuous learning / evolve | **shipped** (Homunculus instincts → skills/commands/agents) | designed (emergence/role-evolve), committed+curated+gated | **ECC on maturity; US on philosophy** |
| Eval harness (pass@k) / security pipeline | **yes** (eval-harness, AgentShield) | **none** | **ECC** |
| Docs | strong 3-tier guides | good but smaller | **ECC** |
| Cohesion / focus / rigor | sprawl/firehose, "divided community" | **one disciplined spine** | **US** |
| PRIME-DIRECTIVE clean separation (core ⊥ roles ⊥ packs) | monolithic | **decoupled** | **US** |

**Corrected verdict:** we are **not** "a smaller ECC," and shouldn't try to be. **ECC competes on
breadth + cross-harness + automatic-everything + a commercial layer.** Our **verified** ground is the
opposite and narrow: **disciplined-TDD rigor (the independent verification gate ECC lacks), clean
composable architecture (decoupled packs + PD separation), and a curated/committed knowledge
philosophy.** This is a **rigor/architecture play, not a feature race** — and "narrow and deepen" is now
*evidence-backed*, not hopeful.

## 6. Strategic implications (refined)

1. **Confirm the wedge: rigor + architecture, not breadth.** Defend the independent verifier gate, the
   decoupled convention-pack ecosystem, and the PD-clean separation — the things ECC verifiably does not have.
2. **Reposition issue 019.** Not "novel" — the *committed, curated, approve-gated, role-targeted*
   alternative to ECC's local/automatic/personal homunculus. Adopt their confidence-scoring + project-
   scoping mechanics; differentiate on commit+curate+gate.
3. **Issue 020's Agent Teams bet is validated** — ECC hand-rolls tmux/jj; riding the first-party primitive
   is a real differentiation if AT matures.
4. **R8/R9 remain table-stakes** but we compete on rigor, not catalog size.

## 7. Absorb from ECC (feed E6)
- **`eval-harness` (pass@k / pass^k, 3 grader types)** — eval-driven verification beyond pass/fail; strong fit for our verifier.
- **AgentShield's adversarial red→blue→auditor pipeline** — same pattern as Dynamic Workflows' refute-and-converge; adopt into verification.
- **Instinct confidence-scoring + project-scoping** — the reference for issue 019's promotion criteria.
- **3-tier docs (Shortform/Longform/Security)** — a docs-quality bar to aim at.
- **Session-summary + state-persistence hooks** — community-validated; complements native memory + `emergence/`.

---

## Sources (aggregate of four line-by-line investigations)
- Repo & API — [affaan-m/everything-claude-code → ECC](https://github.com/affaan-m/everything-claude-code) · GitHub tree/API (live 2026-06-10) · [raw README](https://raw.githubusercontent.com/affaan-m/everything-claude-code/main/README.md) · [cross-harness arch](https://raw.githubusercontent.com/affaan-m/everything-claude-code/main/docs/architecture/cross-harness.md)
- TDD/verify — raw `skills/{tdd-workflow,verification-loop,eval-harness,security-scan}/SKILL.md`, `agents/{tdd-guide,pr-test-analyzer,gan-evaluator}.md`, `scripts/hooks/block-no-verify.js`, `scripts/release.sh`, `scripts/release-approval-gate.js`, `.github/workflows/release.yml`
- Continuous-learning — raw `skills/continuous-learning-v2/SKILL.md`, `commands/{evolve,skill-create}.md`, [Mintlify continuous-learning guide](https://affaan-m-everything-claude-code.mintlify.app/guides/continuous-learning), [humanplane/homunculus](https://github.com/humanplane/homunculus), [DeepWiki](https://deepwiki.com/affaan-m/everything-claude-code)
- Orchestration/rules/hooks — raw `skills/{dmux-workflows,autonomous-loops}/SKILL.md`, `agents/loop-operator.md`, `hooks/README.md`, `rules/common/hooks.md`
- npm/commercial — [ecc-universal](https://registry.npmjs.org/ecc-universal/latest) · [ecc.tools/pricing](https://ecc.tools/pricing) · [ecc-agentshield](https://www.npmjs.com/package/ecc-agentshield)
- Reviews — [Medium: "…82K-Star Agent Harness Dividing the Community"](https://medium.com/@tentenco/everything-claude-code-inside-the-82k-star-agent-harness-thats-dividing-the-developer-community-4fe54feccbc1) · [Augment: "163K stars"](https://www.augmentcode.com/learn/everything-claude-code-hits-163k-stars) · [DEV: "I Wrote 200 Lines of Rules… It Ignored Them All"](https://dev.to/minatoplanb/i-wrote-200-lines-of-rules-for-claude-code-it-ignored-them-all-4639)

**Unverified / flagged:** "codelably" maintainer alias; exact MCP-server count (14) and hook-event count (8); per-harness sub-counts; AgentShield's 1282/98%/102 (external pkg, not ECC's suite); `/prune` command; "Cascade method"; the `marshall0524` agent mirror's provenance; true repo age (history rewrite).
