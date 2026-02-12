# TDD Task: {feature_name}

**Status:** pending
**Created:** {date}
**Last Updated:** {date}

> The planner agent populates all `{...}` fields from codebase research
> and the user's feature description. Do not leave placeholders unfilled.

---

## Feature Description

{Brief description of what this feature does and why it's needed,
derived from the user's /tdd-plan input and codebase context.}

---

## Requirements

### Functional Requirements
- [ ] {Requirement 1}
- [ ] {Requirement 2}
- [ ] {Requirement 3}

### Non-Functional Requirements
- [ ] Performance consideration (if applicable)
- [ ] Code style / static analysis passes
- [ ] Documentation

---

## Test Specifications

### Slice N: {Slice Name}

**Status:** pending

#### Test 1: {Test Name}

**Description:** {What this test validates}

**Given:**
- {Precondition 1}
- {Precondition 2}

**When:**
- {Action or trigger}

**Then:**
- {Expected outcome 1}
- {Expected outcome 2}

**Test Code Location:** `test/{path}_test.dart` or `test/{path}_test.cpp`

#### Test 2: {Test Name}

**Description:** {What this test validates}

**Given:**
- {Precondition}

**When:**
- {Action}

**Then:**
- {Expected outcome}

**Test Code Location:** `test/{path}_test.dart` or `test/{path}_test.cpp`

#### Edge Cases / Error Conditions

**Description:** Handle edge cases and error scenarios

**Given:**
- {Edge case condition}

**When:**
- {Action under edge case}

**Then:**
- {Expected behavior for edge case}

**Test Code Location:** `test/{path}_test.dart` or `test/{path}_test.cpp`

---

## Implementation Requirements

### File Structure
- **Source:** `lib/{source_file}.dart` or `src/{source_file}.cpp`
- **Tests:** `test/{test_file}_test.dart` or `test/{test_file}_test.cpp`

### Test Framework Detection

The planner auto-detects the project's test framework:
- **Dart/Flutter:** Check `pubspec.yaml` for `flutter_test`, `test`, `mockito`, `bloc_test`, `integration_test`
- **C++:** Check `CMakeLists.txt` for `GTest`, `Catch2`, or project-specific framework

### Function/Class Signatures

```
// Define expected function/class signatures here
// Include parameters, return types, and documentation
```

### Dependencies Required
- [ ] {Dependency 1}
- [ ] {Dependency 2}
- [ ] External packages needed: {yes/no, list if yes}

### Edge Cases to Handle
- [ ] Empty/null inputs
- [ ] Boundary values (max/min)
- [ ] Invalid inputs
- [ ] Special characters or formats

---

## Acceptance Criteria

- [ ] All tests pass
- [ ] Code follows project style guidelines
- [ ] No static analysis errors (`dart analyze` / `clang-tidy`)
- [ ] Edge cases are handled
- [ ] No breaking changes to existing APIs
- [ ] Performance requirements met (if applicable)

---

## Implementation Notes

{Architectural decisions, design rationale, and known constraints
documented by the planner during codebase research.}

### Architectural Decisions
{Why certain patterns or approaches were chosen}

### Potential Refactoring Opportunities
{Noted for the implementer to consider after tests pass}

---

## Test Results Tracking

### Iteration 1 (RED Phase)

**Status:** pending
**Failing Tests:** {number}
**Notes:** {observations about expected test failures}

### Iteration 2 (GREEN Phase)

**Status:** pending
**Tests Passed:** 0/{total} -> {total}/{total}
**Notes:** {how the implementation satisfied the tests}

### Iteration 3 (REFACTOR Phase)

**Status:** pending
**Tests Status:** pass
**Refactoring Done:** {description of improvements, or skip if not needed}
**Notes:** {final code quality observations}

---

## Related Issues / Dependencies

- Depends on: {slices or features this slice requires}
- Blocks: {slices or features waiting on this}

---

## Status Vocabulary

Use these values for all status fields in this document
and in `.tdd-progress.md`:

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in-progress` | Currently being worked on |
| `done` | Completed successfully |
| `pass` | Test/verification passed |
| `fail` | Test/verification failed |
| `skip` | Intentionally skipped |
