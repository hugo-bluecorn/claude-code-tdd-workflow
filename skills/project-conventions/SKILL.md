---
name: project-conventions
description: >
  Dynamically loads project-relevant language conventions at agent startup.
  Replaces hardcoded convention skills with a single entry point that detects
  which languages a project uses and injects only the relevant conventions.
user-invocable: false
---

# Project Conventions

This skill dynamically loads convention documentation based on the languages
detected in the current project. It uses Dynamic Context Injection (DCI) to
invoke the load-conventions script at skill load time.

## Loaded Conventions

!`${CLAUDE_PLUGIN_ROOT}/scripts/load-conventions.sh`
