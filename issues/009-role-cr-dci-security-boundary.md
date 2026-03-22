# Issue 009: /role-cr DCI Security Boundary Fix

## Problem

The `/role-cr` skill uses `!`cat ${CLAUDE_PLUGIN_ROOT}/...`` to inject
reference files via DCI. Claude Code blocks `cat` when the plugin cache
path is outside the project's working directory:

```
Shell command permission check failed: cat in
'/home/.../.claude/plugins/cache/...' was blocked.
For security, Claude Code may only concatenate files from the allowed
working directories for this session.
```

When DCI fails, the skill's mechanical procedure is interrupted. CR
"recovers" by reading files manually, but the recovery introduces
non-deterministic gaps — critique phase skipped, approve gate skipped,
validation skipped. The interruption corrupts the procedural chain.

### Root Cause

`cat` is subject to Claude Code's working directory security boundary.
Plugin scripts (like `load-conventions.sh`) are NOT subject to this
boundary because they execute as bash scripts, not as `cat` commands.

### Evidence

- E2E test 2026-03-22: DCI failed with security error, CR skipped
  critique and approval phases, wrote files without validation
- Earlier E2E test 2026-03-21: DCI failed silently, CR manually searched
  for files and recovered partially
- `project-conventions` skill uses a script (`load-conventions.sh`) which
  works because scripts have different permissions than `cat`

## Fix

Replace `cat` commands in `/role-cr` SKILL.md with a script that outputs
the reference content. Follow the `load-conventions.sh` pattern:

```bash
#!/bin/bash
# Outputs CR role definition and format spec for DCI injection
# Called via !`cmd` in skills/role-cr/SKILL.md

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cat "$PLUGIN_ROOT/skills/role-init/reference/cr-role-creator.md"
echo ""
echo "---"
echo ""
cat "$PLUGIN_ROOT/skills/role-init/reference/role-format.md"
```

The SKILL.md changes from:
```
!`cat ${CLAUDE_PLUGIN_ROOT}/skills/role-init/reference/cr-role-creator.md`
...
!`cat ${CLAUDE_PLUGIN_ROOT}/skills/role-init/reference/role-format.md`
```

To:
```
!`${CLAUDE_PLUGIN_ROOT}/scripts/load-role-references.sh`
```

## Scope

### In Scope

1. `scripts/load-role-references.sh` — new script that outputs both reference files
2. `skills/role-cr/SKILL.md` — replace two `cat` DCI commands with one script DCI command
3. Tests for the new script and updated skill

### Out of Scope

- CR role file content changes (stable)
- Format spec changes (stable)
- Validator changes (stable)

## Acceptance Criteria

- [ ] `load-role-references.sh` outputs cr-role-creator.md + role-format.md content
- [ ] `/role-cr` SKILL.md uses the script instead of `cat`
- [ ] DCI injection works from projects outside the plugin directory
- [ ] shellcheck clean on new script
- [ ] All existing tests pass
