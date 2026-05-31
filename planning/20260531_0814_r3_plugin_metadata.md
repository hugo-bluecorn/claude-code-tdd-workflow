# Feature Notes: R3 — Plugin manifest metadata

**Created:** 2026-05-31T06:14:40Z
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent (with values verified by the orchestrator). Live status is in `.tdd-progress.md`.

---

## Overview

### Purpose
Roadmap item R3 (Wave 1, P0, lens C, PRIME=neutral). Modernize the bare
`.claude-plugin/plugin.json` (currently only name/description/version) by adding
`author`, `repository`, `license`, and `$schema`. Unblocks all of Wave 2 (R1, R8, R9),
which depend on a complete, valid manifest.

### Use Cases
- Marketplace/distribution tooling reads author/repository/license from the manifest.
- Editors use `$schema` for autocomplete/validation of the manifest.

### Context
This repo IS the tdd-workflow plugin. The official Claude Code plugins-reference documents
all four fields for `plugin.json`. `$schema` is ignored by Claude Code at load time but is a
documented field used for editor tooling.

---

## Requirements Analysis

### Functional Requirements
1. `author` = object `{name, email}` with the user-specified values.
2. `repository` = the GitHub https URL (string).
3. `license` = `"Apache-2.0"` (SPDX; matches LICENSE file).
4. `$schema` = the canonical Claude Code Plugin Manifest schema URL.
5. Existing name/description/version preserved; manifest stays valid JSON.

### Non-Functional Requirements
- Falsifiable tests: empty-string / null values MUST fail (not pass).
- shellcheck clean; no new suite failures (floor stays 34).
- PRIME-neutral: no role-* reference in the manifest or test.

### Integration Points
- Blocks R1 (userConfig/skills-dir packs), R8 (marketplace.json), R9 (plugin validate --strict).

---

## Implementation Details

### Architectural Approach
Pure metadata addition to a JSON manifest. The design work is in sourcing REAL values
(no fabrication) and in falsifiable assertions.

### Sourced values & provenance (verified)
| Field | Value | Shape | Provenance |
|-------|-------|-------|-----------|
| author | `{"name":"Hugo Garcia","email":"hugo.a.garcia@gmail.com"}` | object | official plugins-reference example + schema; name/email user-specified |
| repository | `https://github.com/hugo-bluecorn/claude-code-tdd-workflow` | string URL | `git remote -v` |
| license | `Apache-2.0` | SPDX | repo LICENSE header (Apache License, Version 2.0) |
| $schema | `https://json.schemastore.org/claude-code-plugin-manifest.json` | https URL | code.claude.com plugins-reference (field table); verified HTTP 200, schema title "Claude Code Plugin Manifest" |

**Note:** an earlier candidate `.../claude-code-plugin.json` 404'd; the real id is
`claude-code-plugin-manifest.json`. `.claude-plugin/marketplace.json` does NOT exist here
(R8 will create it), so author could not be cross-checked against it.

### File Structure
```
.claude-plugin/plugin.json                          # +author,+repository,+license,+$schema
test/integration/plugin_manifest_metadata_test.sh   # NEW (8 tests)
```

---

## TDD Approach

### Slice Decomposition
Single slice (RED→GREEN→REFACTOR). See `.tdd-progress.md`.

**Test Framework:** bashunit. **Command:** `./lib/bashunit test/integration/plugin_manifest_metadata_test.sh` then `./lib/bashunit test/`.

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | Plugin manifest metadata fields | None |

---

## Dependencies

### External Packages
- None. (`jq` already used across the suite.)

### Internal Dependencies
- `lib/bashunit`.

---

## Known Limitations / Trade-offs

### Trade-offs Made
- `author` rendered as the canonical OBJECT shape rather than the string `"Name <email>"`
  the user typed — the docs/schema canonical form is the object; user approved.
- `$schema` is editor-only (Claude Code ignores it at load) — included anyway because the
  roadmap names it and it's a documented field; asserted to the exact canonical URL so a
  wrong/typo'd value fails.

---

## Implementation Notes

### Key Decisions
- **Source, don't guess:** every value traced to an authoritative source; the one unsourced
  candidate ($schema) was resolved by fetching the official docs and verifying the URL 200s.
- **Exact-URL assertion for $schema:** stronger than `^https://`, now that the canonical
  value is known.

### Potential Refactoring
- None anticipated.

---

## References

### Related Code
- `test/integration/release_version_test.sh`, `test/integration/external_conventions_repo_test.sh` (jq-on-manifest test patterns)
- `.claude-plugin/plugin.json`, `LICENSE`

### Documentation
- Claude Code plugins-reference: https://code.claude.com/docs/en/plugins-reference (plugin.json field table; `$schema` row)
- Schema: https://json.schemastore.org/claude-code-plugin-manifest.json
- Roadmap R3 (Wave 1), done-test `plugin_manifest_metadata_test.sh`

### Issues / PRs
- Roadmap R3; blocks Wave 2 (R1/R8/R9).
