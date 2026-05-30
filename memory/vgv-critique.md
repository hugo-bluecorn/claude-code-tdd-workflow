---
name: vgv-critique
description: How this plugin compares to the VGV system — the moat to keep, the #1 gap (no design review), and what to learn without losing determinism.
metadata:
  type: project
---

Comparison to the **VGV system** (`vgv-wingspan` SDLC orchestrator + `vgv-ai-flutter-plugin`). The two are opposite ends of one spectrum: **this plugin = mechanical determinism** (narrow, hook-enforced, reproducible, cheap, language-agnostic); **VGV = LLM-judgment breadth** (full SDLC brainstorm→…→debrief, a 5-agent parallel review jury, batteries-included Flutter expertise — but **no test-first ordering**, soft/human gating, and high token cost).

**The moat — KEEP these, do not trade away:** mechanical **test-first ordering** (VGV has none), **deterministic blackbox verification** (VGV's jury is non-reproducible), **enforced context isolation**, **any-stack** enforcement, **low cost**, and **in-product self-audit** (the very upgrade machinery — VGV has none).

**The #1 gap VGV exposes:** the verifier only asks *"do tests pass?"* — it never reviews design/architecture/simplicity/conventions. **Passing tests ≠ good code.** Fix = a diverse-perspective review *complementing* the deterministic gate. Sequenced cheaply: **R4c** (test-quality review) is the affordable first slice; the **full design/architecture/simplicity jury is deferred (D-e)** on cost — when adopted, **graft it onto the deterministic spine as a SECOND post-green gate, never replacing the test gate**, and prefer on-demand (recallable) over per-build.

**Other VGV-exposed items:** plan-splitting in the planner; consider **release-please** vs the hand-rolled releaser; **R1 conventions delivery is adoption-critical** (VGV is batteries-included; this plugin is empty-out-of-box until a pack is wired).

**To handle in THIS plugin session** (deferred from the knowledge-pack engagement, Hugo): (a) decide whether to **elevate the full review-jury (D-e) to a Must** roadmap item; (b) add a **`Superseded-by-pattern` status** to the audit methodology (once `audit-methodology-vnext.md` is transplanted to `docs/extensibility/`) so the audit stops nagging to adopt a feature a peer proved unnecessary.

Full analysis: `research/plugin-upgrade/critique-vs-vgv.md`. (It also fixed a process gap in the evolution method — added **E7 — peer benchmark** (`evolution-review.md` v1.1): a *vetted peer registry* + a *codified peer-research agent* that **reuses the salvaged `context-updater` engine** from **R11a** — so retiring `/tdd-update-context` and powering competitor discovery are the same engine.) See [[upgrade-roadmap]] [[tdd-review]].
