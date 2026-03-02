# Version Control & Git Workflow

This document describes the git workflow for projects using the TDD workflow plugin.

---

## Branching Strategy

### Branch Structure

```
main (protected, always deployable)
  ├── feature/add-user-authentication
  ├── feature/dashboard-widgets
  ├── fix/login-error-handling
  ├── docs/update-readme
  └── chore/update-dependencies
```

### Branch Types

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New functionality | `feature/add-user-profile` |
| `fix/` | Bug fixes | `fix/null-pointer-exception` |
| `docs/` | Documentation only | `docs/add-contributing-guide` |
| `refactor/` | Code restructuring, no behavior change | `refactor/extract-auth-service` |
| `test/` | Test additions/fixes only | `test/add-repository-tests` |
| `chore/` | Maintenance, dependencies, tooling | `chore/update-flutter-version` |

### Branch Naming

**Format:** `<type>/<short-description>`

- Use lowercase only
- Use hyphens to separate words (not underscores)
- Keep descriptions concise (2-5 words)
- Include ticket/issue number if applicable: `fix/issue-42-sync-timeout`

---

## Feature Branch Workflow

### Starting New Work

1. Ensure `main` is up to date:
   ```bash
   git checkout main
   git pull origin main
   ```

2. Create feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### During Development

- **Commit frequently** following TDD slice pattern (see below)
- **Push regularly** to remote for backup
- **Keep branch focused** on single feature/fix
- **Rebase on main** if branch lives longer than expected:
  ```bash
  git fetch origin
  git rebase origin/main
  ```

### Completing Work

1. Ensure all tests pass: `flutter test` or `ctest --test-dir build/`
2. Ensure analysis passes: `flutter analyze` or `dart analyze`
3. Ensure code is formatted: `dart format .`
4. Update CHANGELOG.md (required for every PR)
5. Push final changes
6. Create Pull Request

---

## TDD Commit Pattern

Each TDD slice maps to commits following the red-green-refactor cycle:

| Phase | Commit Type | Example |
|-------|-------------|---------|
| RED | `test:` | `test: add tests for LocationService` |
| GREEN | `feat:` | `feat: implement LocationService` |
| REFACTOR | `refactor:` | `refactor: clean up LocationService` |

The `test:` type is for tests that drive NEW features (TDD red phase). For adding tests to existing functionality, use `test:` as well but note the distinction in the commit body.

The refactor commit is optional — only create it if refactoring actually occurred.

---

## Commit Message Format

Use conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Where:
- **type**: feat, fix, docs, style, refactor, perf, test, chore
- **scope**: optional, the area affected
- **subject**: concise description (imperative mood, lowercase)
- **body**: optional, more detailed explanation
- **footer**: optional, references to issues (e.g., "Closes #123")

### Examples

```
feat: add user authentication support

Implements login and registration with JWT tokens.

fix: resolve null pointer exception in data processing

Added proper null checks before accessing object properties.

test: add LocationService unit tests

Tests for getCurrentPosition success and permission denied scenarios.
Part of TDD slice 1 for location feature.

refactor: simplify widget composition

Extracted complex nested widgets into smaller, reusable components.
```

---

## Pull Request Guidelines

### When to Create a PR

Always create a PR for any merge to `main`, even solo work (creates documentation trail).

### PR Format

```
## Summary
- Brief description of changes (1-3 bullets)

## Changes
- List of specific changes made

## Testing
- How the changes were tested
- Test commands run

## Checklist
- [ ] Tests pass
- [ ] Analysis passes
- [ ] Code formatted
- [ ] CHANGELOG.md updated
```

### Merging

**Preferred:** Squash and merge — creates clean, linear history with single commit per feature on `main`.

**Alternative:** Rebase and merge — use when individual commit history is valuable (each commit must be atomic and pass tests).

---

## Release and Tagging

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

0.1.0  → First internal release
0.2.0  → New feature added
0.2.1  → Bug fix
1.0.0  → First stable/production release
```

### Creating a Release

1. Ensure `main` is stable and all tests pass
2. Update version in `pubspec.yaml`
3. Update CHANGELOG.md — move `[Unreleased]` items to versioned section
4. Commit version bump: `git commit -am "chore(release): bump version to X.Y.Z"`
5. Create annotated tag: `git tag -a vX.Y.Z -m "Release X.Y.Z: Description"`
6. Push with tags: `git push origin main --tags`

---

## CHANGELOG Format

Use [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [Unreleased]

### Added
- Description of new features

### Changed
- Description of modified existing features

### Fixed
- Description of bug fixes

### Removed
- Description of removed features
```

Update CHANGELOG.md before every commit. This is the historical record of all changes.

---

## Special Cases

### Emergency Fixes

For critical fixes that need to bypass normal workflow, commit directly to `main` with clear documentation in the commit message.

### Large Changes

Break into multiple smaller commits where logically possible. Each commit should be independently buildable.

---

## References

- **Keep a Changelog:** https://keepachangelog.com/
- **Conventional Commits:** https://www.conventionalcommits.org/
- **Semantic Versioning:** https://semver.org/
