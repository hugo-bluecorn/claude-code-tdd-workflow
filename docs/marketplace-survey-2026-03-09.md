# Marketplace Plugin Survey — TDD Workflow Overlap Analysis

**Date:** 2026-03-09
**Author:** CA (Architect session)
**Purpose:** Evaluate plugins in Anthropic's official marketplace and community that complement or compete with the tdd-workflow plugin.

---

## Methodology

Surveyed the full marketplace catalog (53 plugins) from the
[marketplace.json](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json)
in `anthropics/claude-plugins-official`, plus community TDD plugins found via
web search. The catalog includes Anthropic first-party plugins, partner
integrations (sourced from external repos), and community-managed plugins.
Evaluated each for functional overlap with our six-agent TDD pipeline
(planner, implementer, verifier, releaser, doc-finalizer, context-updater)
and four convention skill sets (Dart/Flutter, C++, C, Bash).

---

## Official Anthropic Plugins

### High Relevance

#### superpowers ([github.com/obra/superpowers](https://github.com/obra/superpowers))

**In official marketplace.** Brainstorming, subagent-driven development with
built-in code review, systematic debugging, and red/green TDD. Also teaches
Claude how to author and test new skills. 42,000+ GitHub stars.

Implements a 7-phase lifecycle with TDD gates and checkpoints. Requires test
cases before writing code. Uses hard gates that enforce step-by-step validation
so no phase is skipped.

**Overlap:** Directly competes with our implementer (TDD enforcement) and
planner (structured lifecycle). Also covers debugging and brainstorming which
we don't.
**Gap:** No language-specific convention skills, no dedicated verifier agent,
no release pipeline, no context-updater. General-purpose rather than
language-aware.

**Verdict:** The most popular TDD-adjacent plugin in the marketplace. Broader
scope than ours (brainstorming, debugging) but shallower TDD discipline
(no independent verifier, no convention reference docs, no release automation).
Different enough to coexist — superpowers is a general productivity booster,
we are a specialized TDD pipeline.

#### feature-dev

7-phase feature development workflow: discovery, codebase exploration,
clarifying questions, architecture design, implementation, review, completion.
Launches parallel `code-explorer` agents for codebase understanding.

**Overlap:** Covers our planner's codebase research + implementer's build phase.
**Gap:** No TDD discipline — no test-first enforcement, no red-green-refactor,
no phase gates, no verification agent. It's a general feature workflow.

**Verdict:** Philosophically similar (structured multi-phase workflow) but
fundamentally different (no testing discipline). Not a replacement.

### Medium Relevance

#### code-review

4 parallel review agents with confidence-based scoring (0-100 scale, threshold 80).
Checks CLAUDE.md compliance, obvious bugs, and git blame context. Posts filtered
review comments on PRs.

**Overlap:** Partially overlaps with our verifier (post-implementation quality check).
**Gap:** PR-focused, not phase-gate focused. Doesn't verify test-first ordering
or red-green-refactor compliance.

#### pr-review-toolkit

6 specialized review agents: comment-analyzer, pr-test-analyzer,
silent-failure-hunter, type-design-analyzer, code-quality, code-simplifier.

**Overlap:** `pr-test-analyzer` checks behavioral vs line coverage, test quality,
edge cases — similar to our verifier's test suite validation.
**Gap:** All agents are PR-review-time only, not integrated into a TDD cycle.

**Verdict (both):** Complement our workflow at PR stage. Could be installed
alongside tdd-workflow for additional PR review depth.

#### greptile (external)

AI code review agent via MCP. Connects to Greptile service for automated PR
review with custom context (coding patterns, rules). Provides tools for
listing PRs, triggering reviews, searching comments.

**Overlap:** Alternative to code-review for PR-level quality checks.
**Gap:** Requires external service + API key. Not a TDD workflow.

#### coderabbit ([github.com/coderabbitai/claude-plugin](https://github.com/coderabbitai/claude-plugin))

**In official marketplace.** External validation using specialized AI + 40+
static analyzers. Catches bugs, security vulnerabilities, logic errors, edge
cases. Context-aware via AST parsing and codegraph. Incorporates CLAUDE.md
guidelines. Free to use.

**Overlap:** Competes with our verifier's static analysis and test suite checks.
**Gap:** PR-review-time only, not phase-gated. No TDD workflow.

**Verdict:** Strong complement — adds a layer of external static analysis
our verifier doesn't provide. Could run after `/tdd-release`.

#### qodo-skills ([github.com/qodo-ai/qodo-skills](https://github.com/qodo-ai/qodo-skills))

**In official marketplace.** Curated library of reusable AI agent capabilities
for code quality checks, automated testing, security scanning, and compliance
validation. Operates across the full SDLC from IDE to CI/CD.

**Overlap:** Automated testing and code quality checks overlap with our
verifier and convention skills.
**Gap:** Generic capabilities, not TDD-specific. No red-green-refactor
discipline.

**Verdict:** Complementary for teams wanting broader SDLC coverage beyond
our TDD-focused pipeline.

#### semgrep ([github.com/semgrep/mcp-marketplace](https://github.com/semgrep/mcp-marketplace))

**In official marketplace.** Catches security vulnerabilities in real-time and
guides Claude to write secure code. Specialized static analysis.

**Overlap:** Overlaps with our convention skills' security guidance (SEI CERT C,
OWASP patterns).
**Gap:** Security-only, no TDD workflow.

**Verdict:** Strong complement for security-sensitive projects. Could enhance
our verifier's security checks.

#### claude-md-management

Two tools: `claude-md-improver` skill (audits CLAUDE.md against codebase state)
and `/revise-claude-md` command (captures session learnings into CLAUDE.md).
By Isabella He (Anthropic).

**Overlap:** Our doc-finalizer updates CLAUDE.md and README after releases.
This plugin's audit capability catches drift between CLAUDE.md and actual
codebase state — something our doc-finalizer doesn't do (it only propagates
CHANGELOG changes forward).
**Gap:** Only targets CLAUDE.md files, not README, CHANGELOG, or other docs.
Not integrated into a release pipeline.

**Verdict:** Complementary. Could run periodically between releases to catch
CLAUDE.md drift that our doc-finalizer misses. The audit/scoring concept
could inform a future doc-finalizer enhancement.

**Follow-up:** Doc-finalizer redesign research in `memory/doc-finalizer-redesign.md`.

### Low Relevance

| Plugin | What it does | Overlap |
|--------|-------------|---------|
| **commit-commands** | `/commit`, `/commit-push-pr`, `/clean_gone` | Our releaser handles TDD-specific commit sequencing (test: / feat: / refactor:) |
| **code-simplifier** | Refactoring agent | Slight overlap with our refactor phase |
| **hookify** | Create enforcement hooks from natural language | Could enforce TDD rules but doesn't provide the workflow |
| **ralph-loop** | Iterative agent loop (Stop hook re-feeds prompt) | Different philosophy: brute-force iteration vs structured phases |
| **skill-creator** | Create/improve/eval skills | Could help build better convention skills |

### Complementary (No Overlap, Adds Value)

| Plugin | Value for tdd-workflow users |
|--------|----------------------------|
| **clangd-lsp** | Real-time C/C++ diagnostics alongside our c-conventions/cpp-conventions skills |
| **serena** (external) | Semantic code analysis via LSP. Could enhance planner's codebase exploration |
| **linear** (external) | Issue tracking via MCP. Could replace our manual `issues/*.md` pattern |
| **playwright** (external) | E2E/integration testing. Complements our unit/widget test focus |

### Complementary (No Overlap, Adds Value) — continued

| Plugin | Value for tdd-workflow users |
|--------|----------------------------|
| **context7** (external) | Up-to-date documentation lookup via MCP. Could complement our context-updater for fetching latest framework docs |
| **sonatype-guide** (external) | Dependency security analysis. Complements security checks in our convention skills |
| **sentry** (external) | Error monitoring integration. Useful for debugging production issues found by TDD |
| **atlassian** (external) | Jira/Confluence integration. Alternative to linear for issue tracking |
| **Notion** (external) | Knowledge base integration. Could store planning archives externally |
| **figma** (external) | Design-to-code bridge. Relevant for Flutter/frontend TDD projects |

### No Relevance

agent-sdk-dev, claude-code-setup, claude-opus-4-5-migration,
example-plugin, explanatory-output-style, frontend-design, learning-output-style,
playground, plugin-dev (we already use it), security-guidance, all LSP plugins
(clangd listed separately above; gopls, jdtls, kotlin, lua, php, pyright,
rust-analyzer, swift, typescript, csharp), asana, firebase, github, gitlab,
huggingface-skills, laravel-boost, pinecone, posthog, slack, stripe, supabase,
vercel, firecrawl, circleback.

---

## Community TDD Plugins (Not in Official Marketplace)

### tdd-guard ([github.com/nizos/tdd-guard](https://github.com/nizos/tdd-guard))

Hook-based TDD enforcement. Blocks agents that skip tests or over-implement.
Supports Jest, Vitest, Storybook, pytest, PHPUnit, Go 1.24+, Rust (cargo/nextest).

**Overlap:** Enforcement only — similar to what our verifier does at phase gates.
**Gap:** No planning, no workflow orchestration, no convention skills, no release pipeline.
Pure guard rails.

**Verdict:** Complementary. Could theoretically run alongside our plugin as
an additional enforcement layer, though our verifier already covers this role.

### tdg ([github.com/chanwit/tdg](https://github.com/chanwit/tdg))

Test-Driven Generation with `/tdg:init`, atomic commits, issue tracking integration.
Red-green-refactor cycle with language detection.

**Overlap:** Similar to our implementer — enforces red-green-refactor with
structured commits. Issue number tracking is something we don't require.
**Gap:** No planner agent, no verifier, no convention skills, no release pipeline,
no multi-language convention reference docs.

**Verdict:** Lighter alternative for teams that want TDD commit discipline
without the full planning/verification pipeline. Not a replacement.

### atdd ([github.com/swingerman/atdd](https://github.com/swingerman/atdd))

Acceptance Test Driven Development. Multi-agent team workflow inspired by
Robert C. Martin's methodology.

**Key differentiators:**
- **Two test streams:** acceptance tests (external behavior) + unit tests (internal design)
- **Spec Guardian agent:** detects implementation details leaking into specs
  (class names, endpoints, DB tables forbidden in Given/When/Then)
- **Pipeline Builder agent:** generates project-specific test parsers per language
- **Mutation testing:** introduces deliberate bugs to verify test strength
- **Strict spec format:** Given/When/Then in domain language only

**Overlap:** Given/When/Then spec format matches our planner's test specifications.
Multi-agent team structure mirrors our agent pipeline.
**Gap:** No language-specific convention skills, no release pipeline,
no context-updater for keeping references current.

**Verdict:** Most philosophically aligned competitor. The spec guardian and
mutation testing concepts are genuinely novel additions we don't offer.

---

## Competitive Position Summary

```
                    Planning  Test-First  Verification  Conventions  Release  Context
tdd-workflow        YES       YES         YES           YES (4 langs) YES     YES
superpowers         YES       YES         YES (review)  no            no      no
feature-dev         YES       no          no            no            no      no
code-review         no        no          YES (PR only) no            no      no
pr-review-toolkit   no        no          YES (PR only) no            no      no
coderabbit          no        no          YES (static)  no            no      no
qodo-skills         no        partial     partial       no            no      no
tdd-guard           no        YES (hooks) no            no            no      no
tdg                 no        YES         no            no            no      no
atdd                YES       YES         YES (mutation) no           no      no
```

**No single plugin replaces tdd-workflow.** Our plugin is unique in providing
the complete pipeline from planning through release with language-specific
convention enforcement.

---

## Actionable Findings

### Ideas to Absorb

1. **Spec Guardian concept (from atdd):** An agent or hook that flags
   implementation details in test specifications. Our planner's Given/When/Then
   specs could benefit from automated domain-language enforcement.

2. **Mutation testing (from atdd):** A verifier enhancement that introduces
   deliberate bugs to validate test strength. Could be a new verifier capability
   or a separate post-verification phase.

3. **Confidence scoring (from code-review):** Our verifier could score issues
   by confidence level and filter low-confidence findings, reducing noise.

4. **Issue number tracking (from tdg):** Linking commits to issue numbers
   creates better traceability. Our releaser could optionally include issue
   references in commit messages.

### Plugins Worth Installing Alongside

- **clangd-lsp** — real-time C/C++ diagnostics for projects using our
  c-conventions or cpp-conventions skills
- **serena** — deeper semantic code analysis could help the planner
- **pr-review-toolkit** — additional PR review depth after `/tdd-release`
- **coderabbit** — free external static analysis + AST-aware review (post-release)
- **semgrep** — real-time security vulnerability detection (complements convention skills)
- **context7** — up-to-date docs lookup (complements context-updater)

### No Action Needed

- **superpowers** — broader scope (brainstorming, debugging, TDD, skill authoring)
  but shallower TDD discipline. Different audience: general productivity vs
  specialized TDD pipeline. Coexists rather than conflicts.
- **feature-dev** — different philosophy, not competing for same users
- **tdd-guard** — our verifier already covers this role
- **tdg** — subset of our functionality
- **commit-commands** — our releaser is TDD-aware, theirs is generic
- **qodo-skills** — generic SDLC capabilities, no TDD specificity
