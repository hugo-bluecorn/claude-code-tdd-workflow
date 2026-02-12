# Feature Notes: {feature_name}

**Created:** {date}
**Status:** Planning

> This document is a read-only planning archive produced by the tdd-planner
> agent. It captures architectural context, design decisions, and trade-offs
> for the feature. Live implementation status is tracked in `.tdd-progress.md`.

---

## Overview

### Purpose
{Why does this feature exist? What problem does it solve?
Derived from the user's /tdd-plan input and codebase research.}

### Use Cases
- {Specific user scenario 1}
- {Specific user scenario 2}
- {Specific user scenario 3}

### Context
{Background information from codebase research needed to understand
this feature — existing patterns, related modules, prior art.}

---

## Requirements Analysis

### Functional Requirements
1. {Concrete requirement 1}
2. {Concrete requirement 2}
3. {Concrete requirement 3}

### Non-Functional Requirements
- {Performance requirement}
- {Code quality requirement}
- {Documentation requirement}

### Integration Points
- What other features does this integrate with?
- What APIs does this expose?
- What dependencies does this have?

---

## Implementation Details

### Architectural Approach
{How this feature will be implemented — patterns, layers, data flow.
Document WHY certain patterns were chosen so the implementer agent
(working in a separate context window) understands the rationale.}

### Design Patterns
- {Pattern 1}: {How it applies and why it was chosen}
- {Pattern 2}: {How it applies and why it was chosen}

### File Structure
```
{Planned file layout showing source and test files,
following project conventions discovered during research.}
```

### Naming Conventions
{Project-specific conventions discovered during codebase research.}

---

## TDD Approach

### Slice Decomposition

The feature is broken into independently testable slices, each following
the RED -> GREEN -> REFACTOR cycle. See `.tdd-progress.md` for the full
slice list with live status tracking.

**Test Framework:** {auto-detected from pubspec.yaml or CMakeLists.txt}
**Test Command:** {flutter test / ctest / dart test}

### Slice Overview
| # | Slice | Dependencies |
|---|-------|-------------|
| 1 | {Slice name} | None |
| 2 | {Slice name} | Slice 1 |
| 3 | {Slice name} | Slice 2 |

---

## Dependencies

### External Packages
- {Package 1}: {version constraint and reason}
- {Package 2}: {version constraint and reason}

### Internal Dependencies
- {Module/feature 1}: {why needed}
- {Module/feature 2}: {why needed}

---

## Known Limitations / Trade-offs

### Limitations
- {Limitation 1}: Why it exists and potential future improvements
- {Limitation 2}: Why it exists and potential future improvements

### Trade-offs Made
- {Trade-off 1}: What was chosen vs. what was sacrificed, and why
- {Trade-off 2}: What was chosen vs. what was sacrificed, and why

---

## Implementation Notes

### Key Decisions
- **{Decision 1}:** {What and why}
- **{Decision 2}:** {What and why}

### Future Improvements
- {Enhancement 1}: {description and when it would make sense}
- {Enhancement 2}: {description and when it would make sense}

### Potential Refactoring
- {Refactoring opportunity noted during planning — left for implementer
  to decide at implementation time}

---

## References

### Related Code
- {Paths to related implementations discovered during research}
- {Paths to related test files}

### Documentation
- {Links to internal or external docs relevant to this feature}

### Issues / PRs
- {Related issue or PR references, if any}
