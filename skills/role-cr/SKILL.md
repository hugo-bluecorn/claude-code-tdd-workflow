---
name: role-cr
description: >
  Create a project-specific role file. Spawns the role-creator agent to
  research the project, generate, and validate a role file, then presents
  the result for approval and writes to disk.
  Triggers on: "create role", "new role", "role file".
disable-model-invocation: true
---

# Role Creation

<!-- ultrathink -->

## Step 1: Gather Developer Input

Before spawning the agent, gather context from the developer:

1. **What role is needed?** (e.g., Code Architect, Reviewer, Planner)
2. **What is the tech stack?** (languages, frameworks, build tools)
3. **What workflow does the role participate in?** (code review, planning, implementation)
4. **Any specific constraints or conventions?** (team rules, style guides, compliance)

If the developer has already provided this information, proceed directly to Step 2.

## Step 2: Spawn Role-Creator Agent

Use the Agent tool to spawn the `role-creator` agent with:
- The developer's input from Step 1
- The target project path (current working directory)

The agent will research the project, read the CR role definition and format
spec, generate a role file, validate it, and return the validated content.

## Step 3: Present Result

When the agent returns, present the generated role file to the developer
with a summary of key decisions made. Ask the developer to choose one of:

- **Approve** — proceed to write the role file to disk
- **Modify** — provide feedback, re-spawn the agent with modifications
- **Reject** — nothing is written, the role is discarded

## Step 4: Write to Disk (only after Approve)

Only after the developer selects **Approve**:

1. Derive the role code from the `role:` frontmatter field (lowercase)
2. Create the output directory: `mkdir -p .claude/skills/role-{code}`
3. Add skill frontmatter to the generated role file:
   - `name: role-{code}` (e.g., `role-ca`)
   - `description:` one-line summary of the role's purpose
   - `disable-model-invocation: true`
4. Write the role file to `.claude/skills/role-{code}/SKILL.md`

Ensure `generator: /role-cr` is present in the role's YAML frontmatter.

Do NOT write any files before getting explicit approval in Step 3.

## Constraints

- Do NOT modify the target project's source code, tests, or scripts
- Do NOT run TDD workflow commands
- Do NOT write files before the developer selects Approve
- Do NOT leave any placeholder content in the generated role file
