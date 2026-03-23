# Appendix A: Output Quality Comparison

> Supplementary material to the Role CR Validation Report.
> Comparison of CA role output quality across all test iterations.

## Role CR Test Comparison (2026-03-21 to 2026-03-23)

Comparison of the CA (Architect) role generated for the solitaire project across all
test iterations. Each test used the same target project (Flutter Klondike solitaire
with Flame + Riverpod 3.x) but different CR implementations.

### Comparison Table

| Aspect | Plugin CA (hand-authored) | Test 1 (single, no source) | Tests 2-4 (adapt source, skill-only) | Test 5 bypass (adapt, RTFM) | v2.3.0 E2E (skill+agent) |
|---|---|---|---|---|---|
| Lines | 113 | 108 | 128-133 | ~140 | 130 |
| Frontmatter | None | Role only | Role only | Role + skill (inconsistent) | Role + skill (correct) |
| `generator` | N/A | manual | manual or /role-init (varied) | /role-cr | /role-cr |
| "Do write" bug | Present | Absent | Present/absent (non-deterministic) | Absent | Absent |
| Constraints with consequences | No | No | No/partial | Yes | Yes — all four |
| Architecture boundary | Not explicit | Rich (4-layer, pure Dart) | Thin (one-line) | Rich (Flame/Riverpod/bridge) | Rich + specific APIs (RiverpodComponentMixin, addToGameWidgetBuild) |
| Workflow sections | Handoff Patterns only | None | None | None | 3 concrete procedures (Issue, Plan Review, Impl Review) |
| RTFM research | N/A | Only when URL given | No | Yes (3 agents) | Yes (web search in agent) |
| Validation ran | N/A | No | No | No (bypass skipped it) | Yes — agent ran validator, fixed errors, re-validated |
| Approval gate | N/A | No (wrote first) | No (wrote first) | Sometimes | Yes — Approve/Modify/Reject before write |
| Skill discovery | N/A | N/A | N/A | N/A | Auto-discoverable as `/role-ca` |
| Permission bypass required | N/A | N/A | N/A | Yes | No |

### What Each Version Taught Us

**Plugin CA (hand-authored, predates format spec):**
- Written by someone who used the workflow for weeks
- Contains operational wisdom (crash-recovery cross-check, verification summary template)
- Lacks format compliance — no frontmatter, old section names, "Do write" permission-as-constraint
- Baseline for content quality, but not format quality

**Test 1 (single role, no source files, 2026-03-21):**
- CR given brief prompt + Flame GitHub URL
- Spawned research agents → produced richest architecture boundaries of early tests
- Creative output: combined sections, dropped Coordination for single-developer
- Proved CR can generate useful roles from minimal input
- Finding: giving CR freedom (no source files to copy) produces better output

**Tests 2-4 (adapt source roles, skill-only, 2026-03-21):**
- CR given three existing dev-role files to adapt
- Too deferential to source material — near-verbatim copy with project name substitution
- "Do write" non-constraint carried through non-deterministically
- Constraints lacked consequences despite format spec requiring them
- Added Critique phase (Test 3) which improved 5/10 issues
- Tests 3-4 showed non-deterministic regression — same prompt, different quality
- Finding: prompt-level refinements have diminishing returns

**Test 5 bypass (RTFM, skill-only with bypass, 2026-03-22):**
- Added RTFM instruction: research unfamiliar tech, don't rely on internal knowledge
- With bypass on: full critique, proper approval gate, all constraints caught
- Without bypass: DCI permission interrupted procedural chain, CR skipped steps
- Finding: RTFM is highest-impact addition; DCI interruption is the root cause of quality degradation

**v2.3.0 E2E (skill+agent, no bypass, 2026-03-23):**
- Skill gathers input conversationally (no DCI, no interruption)
- Agent spawned in forked context — fresh procedural chain, no recovery needed
- Agent reads refs via Bash cat (not DCI, not Read tool)
- Agent validates with validate-role-output.sh, fixes errors, re-validates
- Skill presents output with mechanical Approve/Modify/Reject gate
- Three agents ran in parallel for three roles simultaneously
- No bypass needed — normal tool approvals don't corrupt procedural chain
- Best output quality: specific API names, concrete workflow procedures, all constraints with consequences

### What the v2.3.0 Agent Version Uniquely Produces

1. **Three concrete Workflow procedures** — step-by-step checklists for Writing an Issue,
   Reviewing a Plan, and Reviewing an Implementation with specific commands
2. **Implementation Review checks specific API patterns** — names actual classes to verify
   (Notifier/AsyncNotifier, RiverpodAwareGameWidget)
3. **Responsibilities use action → output format** — every responsibility says what to do
   AND what artifact it produces
4. **Mechanical validation** — agent wrote temp file, ran validator, caught path issues,
   fixed them, re-validated before returning
5. **Identity describes mode of operation** — "You operate conversationally... you produce
   written artifacts rather than code"

### What's Lost Compared to Hand-Authored

- **Cross-check logic** — "if MEMORY.md says X but .tdd-progress.md shows Y, trust
  .tdd-progress.md." Operational wisdom from weeks of usage. Would come from `/role-evolve`.
- **Verification Summary Format template** — specific PR review template (test count delta,
  assertion count delta, etc.). The agent mentions review but doesn't define the template.

### Key Architectural Findings

1. **Inline skills cannot maintain procedural state across interruptions.** Any interruption
   (DCI permission, tool approval) breaks the chain. Recovery is non-deterministic.
2. **Forked agents execute procedures mechanically** because they start with a clean context.
   No prior interruption to recover from.
3. **DCI should be avoided in skills that need procedural reliability.** The agent reads
   references itself — no DCI, no permission prompt, no interruption.
4. **The /tdd-plan + tdd-planner pattern is the proven model** for any operation that needs
   both conversation (skill) and mechanical execution (agent).
5. **RTFM (research unfamiliar tech) produces dramatically better output** — real API names
   vs plausible-sounding guesses. The difference matters for downstream consumers (CI using
   the role to write code).
