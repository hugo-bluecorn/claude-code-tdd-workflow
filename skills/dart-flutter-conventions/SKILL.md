---
name: dart-flutter-conventions
description: >
  Dart and Flutter testing conventions, patterns, and project structure.
  Loaded automatically by TDD agents when working on .dart files.
user-invocable: false
---

# Dart/Flutter Testing Conventions

## Test File Placement
- Unit tests: `test/` mirroring `lib/` structure
- Widget tests: `test/` with `_test.dart` suffix
- Integration tests: `integration_test/`

## Test Structure
See `reference/test-patterns.md` for complete examples including:
- Unit test Arrange-Act-Assert pattern
- Widget test with pumpWidget/pumpAndSettle
- BLoC testing with bloc_test package
- Group and setUp/tearDown patterns

See `reference/test-recipes.md` for:
- Common scenarios (form validation, navigation, async operations)
- Best practices (test behavior not implementation, edge cases, golden tests)
- TDD phase commands and analysis commands

## Mocking
See `reference/mocking-guide.md` for:
- mockito with @GenerateMocks
- mocktail as alternative (no codegen)
- build_runner integration

## Widget Testing
See `reference/widget-testing.md` for:
- pumpWidget, pump, pumpAndSettle patterns
- Finder methods (find.text, find.byType, find.byIcon)
- Interaction simulation (tap, enterText, drag)

## Project Conventions
See `reference/project-conventions.md` for:
- MVVM pattern with hybrid organization
- Repository pattern for data access
- Naming conventions (snake_case files, PascalCase classes)
- File size guidelines
- Conventional Commits format
- CHANGELOG.md requirements

## State Management (Riverpod 3.x)
See `reference/riverpod-guide.md` for:
- Provider types (Notifier, AsyncNotifier, Family, AutoDispose)
- ViewModel and View patterns with ConsumerWidget
- Ref API and async safety with ref.mounted
- Testing with provider overrides
- Legacy provider migration

## Running Tests
- Single file: `flutter test test/path/to_test.dart`
- All tests: `flutter test`
- With coverage: `flutter test --coverage`
- Specific test: `flutter test --name "test name"`
