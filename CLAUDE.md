## TDD Workflow

This project has the TDD workflow installed. Available commands:

- `/tdd-plan <feature description>` — Create a test-driven implementation plan
- `/tdd-implement` — Start or resume TDD implementation for pending slices
- The workflow uses three agents: tdd-planner (research), tdd-implementer (code), tdd-verifier (validate)

If `.tdd-progress.md` exists at the project root, a TDD session is in progress.
Read it to understand the current state before making changes.

### TDD Rules
- Tests are ALWAYS written before implementation
- Each feature slice goes through RED → GREEN → REFACTOR
- Refactoring is an implementation-time decision, not planned in advance
- The verifier runs the COMPLETE test suite, not just new tests
