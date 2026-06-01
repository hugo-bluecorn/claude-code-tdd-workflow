# R1 Language-Pack Interface — Design Proposal & Contract

> **Status:** Ratifiable proposal (2026-05-31). Feeds roadmap **R1** (Wave 2) + Decision #6.
> **Origin:** authored by the **advisor session** (the conventions workspace) and handed to the **plugin session** (this `tdd-workflow` repo). **Self-contained** — everything needed for the plugin-side R1 build is in this doc; no external workspace needs to be read.
> **Context (in *this* repo):** `memory/upgrade-roadmap.md` (R1 + Decision #6) · `memory/decisions.md` · `docs/extensibility/audit.md`. Audit refs below (`Cxx`/`Bxx`) name that inventory's hook/skill entries — the underlying features live in Claude Code's **hooks** & **skills** docs; verify there.
> **What this is:** the interface between the language-agnostic `tdd-workflow` core and per-language convention packs. **§8 = the ratifiable contract · §9 = your worklist · §1–§7,§10 = the rationale.**
> **Roles:** *plugin session* = you (this repo — the plugin-side build); *advisor session* = the counterpart that authored this + maintains the language packs. This copy is a handoff snapshot; propose contract changes back through Hugo.

## 1. Architecture — the component model (decided in dialogue 2026-05-31)

**Pack = a standalone, language-specific git repo (a *component*), decoupled from any project.** Separate *what the plugin works **with*** (conventions = policy) from *what it works **on*** (the code = content). Supersedes the earlier "two starter-template projects sharing a directory structure" framing.

Why the component model beats starter-templates:
- A shared *project* layout imposes our structure on the user and fights each language's native layout (Dart `lib/`, C++ `src/include/`).
- Starter-templates only help greenfield; a standalone pack points at **any** project, new or existing.
- A pack-as-component versions + ships independently — the natural realization of R1's `userConfig`/`skills-dir` delivery.
- Handles multi-language projects (a Flutter app with native C++) cleanly — both packs activate.

**The interface is the pack CONTRACT, not a project layout.** "Shared directory structure" doesn't vanish — it **moves** from the user's project (now unconstrained; created by native tooling: `flutter create`, `cmake`, `cargo new`) to the *pack repo's* small internal layout, which burdens no consumer. The dart-pack ≡ cpp-pack symmetry requirement lives there.

**Consumer project structure is unconstrained.** Detection is by language *markers*, never an imposed layout. Test-file *placement* is a pack convention (declared in the standards), not a plugin assumption.

## 2. Corrections / retractions (don't relitigate)
- ❌ *"Local marketplace + skills-dir register packs in place (adjacency)"* — **INVALID.** Marketplace / `userConfig` / `skills-dir` address packs by explicit **source** (URL/path); filesystem location is irrelevant. Pack placement = pure filing choice.
- ❌ *Skill-centric delivery as the primary mechanism* — **WRONG for discovery** (see §5). Detection is a HOOK concern; skills demoted to progressive-disclosure standards delivery.

## 3. The pack contract — three parts
Every pack declares, symmetrically across languages:
1. **Detect** — file extensions + project markers.
2. **Test-command** — how to run tests (see §4 — richer than a string).
3. **Standards** — the convention docs (markdown).

## 4. Headline finding — test-command SHAPE diverges (why cpp went first)
| | Dart | C++ |
|---|---|---|
| Shape | single command | **configure → build → test** (3-step, stateful build dir) |
| Granularity | **per-file** (`flutter test {file}`) | **whole-suite** (`ctest`; `-R <name>` subset) |
| Variants | one mode | `tdd-asan` / `tdd-tsan` (CMakePresets) |
| Canonical | `flutter test {file}` (fvm-aware) | `cmake --preset tdd-asan && cmake --build build-tdd-asan && ctest --preset tdd-asan --output-on-failure` |

→ The manifest's `test` field must model **optional setup/build + run, per-file vs suite, named variants** — NOT an `ext→string` map. #1 input for the `auto-run-tests.sh` dispatcher (plugin side — yours). A dart-only design would have baked a single per-file string and broken on C++ day one.

## 5. Delivery — HOOK-centric detection (the bootstrapping fix)
**The problem:** skills load at session start (descriptions only; bodies on *model-invoke*) and a *new* skill dir needs a **restart** (audit B31/B33/B35) — so a skill can't DISCOVER the project type (circular), and a skill only ever feeds the **model**, never the `PostToolUse` test-runner *script*.

**Two consumers, two lifecycles:** the model (standards) and the hooks (detection + test-command). Skills serve neither discovery nor the script consumer.

**Right primitives — all on the `SessionStart` hook the plugin already has (R7 made it `async`):**
| Need | Audit primitive |
|---|---|
| Deterministic detection at startup | `SessionStart` (C1) + `async` (C44); `Setup` (C2) for headless/CI |
| Inject standards into model + subagents | `additionalContext` (C82), incl. `SubagentStart` (C13) for tdd planner/implementer |
| Hand test-command to the dispatcher | `CLAUDE_ENV_FILE` (C73) — export `TDD_ACTIVE_PACK`/test-cmd; `PostToolUse` (C8) reads it |
| Make a skills-dir pack live without restart | `reloadSkills` (C83) |
| Re-detect on project change | `watchPaths`→`FileChanged` (C83/C23); `CwdChanged` (C22) |

**Corrected SessionStart flow:**
```
SessionStart (startup|resume) ── deterministic script ──►
  1. scan cwd for markers (pubspec.yaml / CMakeLists.txt)        ← discovery, no skill needed
  2. resolve matching pack(s) from userConfig pointers
  3. read each pack's pack.json (detect + test-command)
  4. emit:
     • additionalContext = pack index + key rules (model)         ← C82, capped 10k chars (C89)
     • CLAUDE_ENV_FILE   = export TDD_ACTIVE_PACK / test-cmd       ← C73, PostToolUse dispatcher reads it
     • reloadSkills      = make the pack's SKILL live this session ← C83
     • watchPaths        = [pubspec.yaml, CMakeLists.txt]         ← re-detect via FileChanged/CwdChanged
```
No circularity: the hook discovers + wires **before** the model acts and **independent of** skill loading.

**Skill's remaining role:** bulk standards via progressive disclosure. `additionalContext` is capped at 10k chars (C89) and the 9 standards docs exceed that, so the hook injects only the *index + test-command*; the heavyweight docs ride the skills-dir `SKILL` (body-on-invoke; budget per B28) or direct Read, made live by `reloadSkills`. Skills move from *the mechanism* to *the progressive-disclosure layer the hook activates*. `pack.json` = shared data both hooks read.

## 6. cpp template inventory (the "before" / 2nd reference)
`~/bluecorn/claude/langpacks/claude-cpp-template` (cloned 2026-05-31, HEAD `ded6eb2` — readable shared location). **Conflates** three concerns + is **pre-plugin**:
- **Code project:** `src/ include/ app/ tests/ ext/ cmake/` + `CMakeLists.txt` + `CMakePresets.json`.
- **Standards:** `context/standards/*.md` (9: coding-standards, tdd, tooling, commits, versioning, changelog, cmake, googletest, version-control) + `context/README.md` index. (`context/libraries/` project-specific; `context/project/` human-only.)
- **Claude wiring:** does NOT use the tdd plugin — hand-rolls `/tdd-new /tdd-test /tdd-workflow` in `.claude/commands/*.md` + loads standards via `@context/standards/*.md` imports in `.claude/CLAUDE.md`. The "embeds standards, not yet a pack" state, mechanism visible.
- **Test-command:** CMakePresets `tdd-asan` (addr+UB+coverage) / `tdd-tsan` (thread+UB); `ctest --preset … --output-on-failure`.
- **Tool configs** `.clang-format`/`.clang-tidy` live in PROJECT root (↔ dart `analysis_options.yaml`) — pack ships canonical, materialized into the project.

## 7. Harmonization worklist (cpp ↔ dart pack)
| Aspect | cpp | dart (advisor-maintained `dart-flutter-conventions`) | Proposed |
|---|---|---|---|
| Standards dir | `context/standards/` | `reference/` | **`standards/`** |
| Index/entry | `context/README.md` + `@`-imports | `SKILL.md` (skill frontmatter) | **`SKILL.md`** (harmonize UP — skills-dir-ready) |
| Machine manifest (detect+test) | none | none | **NET-NEW for both** (`pack.json`) |
| Loading | `@`-imports + local commands | plugin auto-load | **plugin + pack** (SessionStart hook + userConfig→skills-dir) |
| Detect model | markers+ext | markers+ext | same ✓ |

**dart is AHEAD on packaging** (its `SKILL.md` is already skills-dir-shaped; cpp's `@`-imports are legacy) → harmonize up. cpp drops its local commands for the plugin (that repo's task).

## 8. The contract — ratifiable proposal (pending plugin-side sign-off)

### 8.1 Pack repo layout (harmonized)
```
<lang>-conventions/               ← a version-tagged git repo (§10)
├── pack.json                   ← manifest: detect + test + standards + (opt) projectFiles   [NET-NEW]
├── .claude-plugin/plugin.json  ← OPTIONAL — makes it a skills-dir plugin (distribution a/b)
├── SKILL.md                    ← skills-dir entry + standards index (progressive-disclosure body)
└── standards/*.md              ← the convention docs
```

### 8.2 `pack.json` schema
| Field | Type | Purpose |
|---|---|---|
| `schemaVersion` | int | pack.json schema version (fwd-compat) |
| `name` · `version` | string · semver | pack id (cache key) · its own version (binding/cache) |
| `language` | string | human label |
| `detect.extensions` | string[] | extensions → per-file test dispatch |
| `detect.markers` | string[] | project-root files (any-of) → project-type match |
| `test.granularity` | `"file"`\|`"suite"` | run the edited file's tests vs the whole suite |
| `test.setup` | string[]? | build/configure steps before testing (compiled langs); omit for single-step |
| `test.run` | string | the test command; placeholders `{file}` `{filter}` `{variant}` `{root}` |
| `test.variants` | {name,default}[]? | named build/test variants (asan/tsan) |
| `test.passOn` | `"exitZero"` | pass/fail = process exit code (dispatcher/verifier contract) |
| `standards.index` · `.dir` | string · string | entry doc (`SKILL.md`) · docs dir (`standards/`) |
| `projectFiles` | string[]? | OPTIONAL tool-configs the pack materializes into the project root |

### 8.3 Both packs, filled (same schema; only `test` changes shape)
```jsonc
// dart-flutter-conventions/pack.json
{ "schemaVersion": 1, "name": "dart-flutter-conventions", "version": "1.0.0", "language": "Dart/Flutter",
  "detect": { "extensions": [".dart"], "markers": ["pubspec.yaml"] },
  "test": { "granularity": "file", "run": "flutter test {file}", "passOn": "exitZero" },
  "standards": { "index": "SKILL.md", "dir": "standards/" },
  "projectFiles": ["analysis_options.yaml"] }
// (fvm-aware: dispatcher prefixes `fvm ` when .fvmrc/.fvm present)

// cpp-conventions/pack.json
{ "schemaVersion": 1, "name": "cpp-conventions", "version": "1.0.0", "language": "C/C++",
  "detect": { "extensions": [".cpp",".hpp",".cc",".h"], "markers": ["CMakeLists.txt","CMakePresets.json"] },
  "test": { "granularity": "suite",
            "setup": ["cmake --preset {variant}", "cmake --build build-{variant}"],
            "run": "ctest --preset {variant} --output-on-failure",
            "variants": [ {"name":"tdd-asan","default":true}, {"name":"tdd-tsan"} ],
            "passOn": "exitZero" },
  "standards": { "index": "SKILL.md", "dir": "standards/" },
  "projectFiles": [".clang-format",".clang-tidy"] }
```
`.sh → bashunit` is a **built-in core default** (plugin self-hosting, Decision #6) — the dispatcher's fallback when no pack matches the edited extension.

### 8.4 SessionStart hook — responsibilities (evolves the existing async fetch hook)
1. **Trigger:** `SessionStart` (startup|resume|clear) `async:true`; also `Setup` (headless/CI); re-run on `CwdChanged` + `FileChanged` (armed by `watchPaths`).
2. **Resolve bindings:** project binding (committed, portable — §10/§8.6) → user `userConfig` default → none (precedence).
3. **Detect:** scan cwd→repo-root for each candidate pack's `markers`/`extensions` → active pack(s). *(Replaces the 4 hardcoded dirnames.)*
4. **Resolve to local path:** ensure each bound pack is in the per-machine cache (channel a: installed; c: clone/fetch `URL@version`) → pack dir.
5. **Read** each `pack.json`.
6. **Emit `hookSpecificOutput`:** `additionalContext` = SKILL index + key rules + standards list (≤10k chars, C89), also at `SubagentStart` for the tdd planner/implementer · `CLAUDE_ENV_FILE` = `export TDD_ACTIVE_PACK=<dir>` + resolved `test` · `reloadSkills:true` (if skills-dir-delivered) · `watchPaths:[<markers>]`.
7. **Multi-pack:** >1 match → inject all standards + export an `{ext→test}` map.
8. **Degrade:** no pack → no-op; core `tdd-*` works pack-less (PRIME-safe).

### 8.5 PostToolUse dispatcher (`auto-run-tests.sh`) — responsibilities
1. **Trigger:** `PostToolUse` matcher `Edit|Write|MultiEdit`.
2. Read `TDD_ACTIVE_PACK`/`test` from env; **fallback** `.sh→bashunit` if no pack matches the edited extension.
3. Pick the pack by the edited file's **extension** (multi-pack).
4. `setup` present and build stale → run `setup` (`{variant}`=default).
5. Run `test.run` — `{file}` for `granularity:file`; whole-suite for `granularity:suite` (opt `{filter}`).
6. Pass/fail by **exit code**; feed failure back (`decision:block` + reason).
> Open: impl→test mapping for `granularity:file` (e.g. `lib/{n}.dart → test/{n}_test.dart`) — per-pack refinement; MVP runs the edited file if it's a test, else the suite.

### 8.6 Project binding (committed, portable — §10)
```jsonc
// .claude/tdd-conventions.json  — evolved to accept URLs + versions; abs-path = back-compat only
{ "packs": [
    { "source": "github.com/hugo-bluecorn/dart-flutter-conventions", "version": "1.0.0" }
    // dev-mode escape hatch: { "source": "~/bluecorn/claude/langpacks/dart-flutter-conventions", "dev": true }
] }
```

## 9. Plugin-side worklist (you) — ratify / implement (§8 proposes; you decide)
§8 turns the earlier open questions into a concrete proposal; what remains is plugin-side sign-off + implementation:
1. **`pack.json` schema** (§8.2–8.3) — ratify, esp. the `test{}` shape (`setup[]`/`run`/`granularity`/`variants`/`passOn`). Home = `pack.json` (chosen over `SKILL` frontmatter — hooks consume it).
2. **SessionStart hook** (§8.4) — evolve the existing async fetch hook into detect→resolve→inject/export/`reloadSkills`.
3. **PostToolUse dispatcher** (§8.5) — convert `auto-run-tests.sh` from the hardcoded chain to the pack-driven dispatcher; `.sh→bashunit` fallback.
4. **Resolver** (§8.6) — which distribution channel(s) first ((a) self-hosted marketplace install reuses CC cache/version; (c) direct-URL resolver we build); version-pin/lock for reproducibility.
5. **Binding file** — evolve `.claude/tdd-conventions.json` to git-URL+version (abs-path = back-compat); define the `userConfig` user-level default.
6. **Refinements** — impl→test mapping for `granularity:file`; multi-pack standards merge + precedence when >1 pack matches.

## 10. Distribution & binding (residence + cross-developer) — DECIDED 2026-05-31

**The langpack itself is ALWAYS just a git repo** (`pack.json` + `standards/` + optionally a `.claude-plugin/plugin.json` to make it a skills-dir plugin). Canonical home — full stop.

**Two declarations — don't conflate:**
- **Pack manifest** (`pack.json`, *inside* the pack) — what the pack IS (detect + test-command + standards).
- **Project binding** (*in the consuming project*, committed) — which pack a project USES, by **portable reference (git-URL + version)**, never an absolute local path. This is what travels to every developer.

**Three residences, three roles:**
1. **Canonical = version-tagged git repo** (`github.com/<owner>/dart-flutter-conventions` + tags) — the one portable address any developer can name. Source of truth.
2. **Author working copy = local path** (under `~/bluecorn/claude/langpacks/…`) — authoring/dev-mode only; never shipped in a binding.
3. **Consumer copy = per-machine resolved cache** — the plugin resolves the binding ref → fetches into that developer's own cache. No absolute path crosses machines.

**Binding precedence:** project binding (committed, portable) > user-level `userConfig` default > none → every developer on a shared repo gets the same pack + version.

**Distribution = a SEPARATE, optional choice of how consumers get + version the repo:**
| Channel | What | When |
|---|---|---|
| **(a) self-hosted CC marketplace** | list the langpack in *your own* `marketplace.json`; consumer `add`s once + `install`s → CC clones/caches/version-pins (`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`) | versioned, multi-consumer; reuses CC's install machinery; *your* infra |
| **(b) skills-dir, no marketplace** (audit D48) | consumer drops the repo (+`.claude-plugin/plugin.json`) into a skills dir → loads in place as `<name>@skills-dir` | lightest; no version machinery; project use needs workspace trust (B32) |
| **(c) direct git-URL ref** | the project binding / `userConfig` names git-URL+version; the plugin resolves it | no marketplace, no install; private/team packs |

> **Terminology lock:** "marketplace" = the **CC marketplace *mechanism*** (a `marketplace.json` registry), **self-hosted** here — NOT the official/public `claude-plugins-official`, NOT a generic registry. A marketplace is **optional** (b/c skip it); its only value is the install→cache→version-pin UX.

**Concrete R1 gap:** the current `.claude/tdd-conventions.json` binds via an **absolute path** (`{"conventions":["/abs/path/…"]}`) → author-only. R1 must make the binding accept **git-URL + version** + resolve/cache it.

**Resolver ↔ SessionStart hook (§5):** detection picks the *language* → the project binding picks the specific *pack + version* → the resolver fetches it to the local cache → the hook reads the cached `pack.json`. (Channel (a) offloads resolve/cache/version to CC; (b)/(c) the plugin/git does it.)

## 11. Locations (shared)
- **langpacks home:** `~/bluecorn/claude/langpacks/` (filing choice; no architectural weight).
- **cpp reference:** `~/bluecorn/claude/langpacks/claude-cpp-template` (the 2nd-language reference — readable).
- **dart pack:** advisor-maintained `dart-flutter-conventions`, published to its own repo — you consume the **contract** (§8), not the pack source.
- **plugin:** this repo (`~/bluecorn/claude/claude-code-tdd-workflow/`) — where the plugin-side R1 work lands.
