Audit all documentation and markdown files in the plugin repository for accuracy, consistency, and completeness against the current codebase.

## Scope

Every .md file in the project: README.md, CHANGELOG.md, CLAUDE.md, all files under docs/, skills/, and agents/. Include hooks.json if it contains descriptive comments.

## What to check

1. **Accuracy** — Do documented features, file paths, directory structures, command examples, and version numbers match the actual codebase? Flag anything that describes behavior the code doesn't implement, or omits behavior the code does implement.

2. **Consistency** — Do all documents agree with each other? Cross-reference version numbers, feature lists, file inventories, and architecture descriptions across all documentation files. Flag contradictions.

3. **Completeness** — Is every implemented feature reflected in the relevant documentation? Cross-check CHANGELOG entries against actual commits, README capabilities against actual functionality, and audit doc status against actual implementation state.

4. **Staleness** — Flag any references to planned/future work that has since been completed, any TODO/FIXME/TBD markers that can be resolved, and any "pending" statuses that should now read "done."

## Constraints

- Do not rewrite documentation style or restructure files — this is a consistency pass, not a rewrite.
- Fix factual errors and stale references in place.
- For anything ambiguous or requiring a judgment call, list it as a finding rather than silently changing it.
- Commit as: docs: align documentation with current codebase
