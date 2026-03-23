# Experimental Results — Role Creator (CR) Validation

> Documents the iterative design, implementation, and validation of the
> Role Creator feature for the tdd-workflow Claude Code plugin.
> Conducted 2026-03-21 to 2026-03-23 by Hugo (developer) and Claude Opus 4.6 (CA v0 session).

## Documents

### Primary Report

- **[Role CR Validation Report](./role-cr-validation-report.md)** — the main
  scientific report. Abstract, introduction, methodology (5 prompts, 12+
  experiments, 12 measurement criteria), results across 7 phases, discussion
  (11 findings including semantic framing principle and meta-definition
  analysis), conclusion (4 research questions answered), and 6 appendices.

### Supplementary Experiments

- **[Self-Compilation Experiment](./role-cr-self-compilation.md)** — CR
  generates roles for its own project. Compares proto-roles (hand-authored)
  against agent-generated roles. Includes CR self-regeneration (§6), cohort
  regeneration with improved CR (§7), final shipped cohort (§8), detailed
  evolution traces (§8.8), and full role text (Appendices E-G).

- **[Generalizability Experiment](./role-cr-generalizability.md)** — CR on
  zenoh-dart (Dart FFI + C shim wrapping zenoh-c). Validates that CR scales
  to complex, multi-language architectures. 512 lines of role output from a
  one-sentence project description. CA v0's final experiment.

### Reference Data

- **[Output Quality Comparison](./role-cr-test-comparison.md)** — comparison
  table across all role versions from hand-authored to shipped v2.4.0 output.
  7 key architectural findings.

- **[Chronological Experiment Log](./role-cr-experimental-log.md)** — detailed
  record of every experiment with setup, observations, and actions. Includes
  standardized prompts and prompt-to-experiment mapping.

- **[Design Decisions Log](./role-format-redesign.md)** — chronological record
  of design decisions with rationale. Superseded decisions marked.

## Key Findings

1. **Prompt-level procedural instructions are non-deterministic** — identical
   prompts produce different quality across runs (§5.1)
2. **DCI permission interruptions corrupt procedural chains** — the model's
   recovery from incomplete context is non-deterministic (§5.2)
3. **Forked agents provide mechanical enforcement** — clean context, restricted
   tools, no recovery ambiguity (§5.3)
4. **RTFM produces dramatically better output** — real API names vs
   plausible-sounding guesses (§5.4)
5. **Adapted generation with agents enriches rather than copies** — the
   "scaffold + enrich" pattern validates `/role-evolve` (§5.5)
6. **Role quality determines downstream output quality** — the causal chain
   from CR definition to file structure proposals is traceable (§5.8)
7. **Adjectives in system prompts are directives, not descriptions** —
   "optional" caused systematic deprioritization (§5.9)
8. **The meta-definition is a seed the agent grows** — three stated categories
   plus two emergent categories (§5.10)
9. **CR generalizes to cross-language architectures** — zenoh-dart produced
   the largest, richest roles with project-specific content no training data
   could provide (Generalizability Experiment)

## Shipped Versions

| Version | PR | Tests | Key Change |
|---|---|---|---|
| v2.1.0 | [#12](https://github.com/hugo-bluecorn/claude-code-tdd-workflow/pull/12) | 691 / 1010 | `/role-cr` inline skill + `validate-role-output.sh` |
| v2.2.0 | [#13](https://github.com/hugo-bluecorn/claude-code-tdd-workflow/pull/13) | 715 / 1042 | Output path → `.claude/skills/role-{code}/SKILL.md` |
| v2.2.1 | [#14](https://github.com/hugo-bluecorn/claude-code-tdd-workflow/pull/14) | 726 / 1058 | DCI `cat` → `load-role-references.sh` script |
| v2.3.0 | [#15](https://github.com/hugo-bluecorn/claude-code-tdd-workflow/pull/15) | 757 / 1109 | Skill+agent split, DCI eliminated |
| v2.4.0 | [#16](https://github.com/hugo-bluecorn/claude-code-tdd-workflow/pull/16) | 769 / 1123 | `/role-cr` → `/role-create` + CR v3 |
