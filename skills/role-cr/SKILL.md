---
name: role-cr
description: >
  Create a project-specific role file. Loads the CR (Role Creator) session
  role and the Role File Format spec, then guides role creation through
  research, critique, generation, and approval.
  Triggers on: "create role", "new role", "role file".
disable-model-invocation: true
---

# Role Creation

<!-- ultrathink -->

## Step 1: Load Reference Documents

The following reference documents are injected into this session at load time.

### CR Role Definition

!`cat ${CLAUDE_PLUGIN_ROOT}/skills/role-init/reference/cr-role-creator.md`

### Role File Format Specification

!`cat ${CLAUDE_PLUGIN_ROOT}/skills/role-init/reference/role-format.md`

## Step 2: Adopt CR Role

You are now operating as the **CR (Role Creator)** session defined above.
Follow the CR role's Identity, Responsibilities, Constraints, and Workflow
sections exactly as specified.

When generating role files, always set `generator: /role-cr` in the output
frontmatter to indicate this skill produced the file.

## Step 3: Research and Generate

Follow the CR Workflow section to:
1. Research the target project
2. Ask the developer about their workflow
3. Critique mapped content against the format spec
4. Generate the role file

## Step 4: Validate

Before presenting the role file to the user, run the validation script:

```
bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-role-output.sh <generated-file>
```

This calls `validate-role-output.sh` on the generated role file. If validation
fails, fix the issues and re-validate before proceeding.

## Step 5: Approval Gate

Present the generated role file to the user with a summary of decisions made.
Ask the user to choose one of:

- **Approve** -- proceed to write the role file to disk
- **Modify** -- user provides feedback, revise and return to Step 4
- **Reject** -- nothing is written, the role is discarded

## Step 6: Write to Disk (only after Approve)

Only after the user selects **Approve**:

1. Derive the role code from the `role:` frontmatter field (lowercase)
2. Create the output directory: `mkdir -p .claude/skills/role-{code}`
3. Add skill frontmatter to the generated role file:
   - `name: role-{code}` (e.g., `role-ca`)
   - `description:` one-line summary of the role's purpose
   - `disable-model-invocation: true`
4. Write the role file to `.claude/skills/role-{code}/SKILL.md`

Do NOT write any files before getting explicit approval in Step 5.

## Constraints

- Do NOT modify the target project's source code, tests, or scripts
- Do NOT run TDD workflow commands
- Do NOT write files before the user selects Approve
- Do NOT leave any placeholder content in the generated role file
