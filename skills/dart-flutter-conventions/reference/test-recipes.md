# Dart/Flutter Test Recipes

Common testing scenarios and best practices. For core test patterns and
templates, see `test-patterns.md`.

## Common Scenarios

### Form Validation

```dart
testWidgets('form validation shows error for invalid email', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());

  // Enter invalid email
  await tester.enterText(find.byType(TextField), 'invalid');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Verify error shown
  expect(find.text('Invalid email'), findsOneWidget);
});
```

### State Management

```dart
testWidgets('counter increments when button is tapped', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());

  // Initial state
  expect(find.text('0'), findsOneWidget);

  // Tap button
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();

  // Verify state changed
  expect(find.text('1'), findsOneWidget);
  expect(find.text('0'), findsNothing);
});
```

### Navigation

```dart
testWidgets('navigates to details screen when item tapped', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());

  // Tap item
  await tester.tap(find.text('Item 1'));
  await tester.pumpAndSettle();

  // Verify navigation
  expect(find.byType(DetailsScreen), findsOneWidget);
});
```

### Async Operations

```dart
testWidgets('loads data when screen opens', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle(); // Wait for all async operations

  // Verify data is loaded
  expect(find.text('Loaded Data'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

## Best Practices

### Test Behavior, Not Implementation

```dart
// DON'T: Test implementation details
expect(find.byWidgetPredicate((w) => w is Scaffold && w.floatingActionButton != null), findsOneWidget);

// DO: Test behavior and user-visible elements
expect(find.byType(FloatingActionButton), findsOneWidget);
expect(find.text('Add Item'), findsOneWidget);
```

### Test Edge Cases

```dart
void main() {
  group('EmailValidator', () {
    test('happy path: valid email', () {
      expect(validateEmail('user@example.com'), isTrue);
    });

    test('edge case: email with special characters', () {
      expect(validateEmail('user+tag@example.co.uk'), isTrue);
    });

    test('error case: missing @', () {
      expect(validateEmail('userexample.com'), isFalse);
    });

    test('edge case: empty string', () {
      expect(validateEmail(''), isFalse);
    });

    test('edge case: whitespace', () {
      expect(validateEmail('  '), isFalse);
    });
  });
}
```

### Golden Tests for UI Regression

For complex UI widgets, use golden tests to catch visual regressions:

```dart
testWidgets('widget looks correct', (WidgetTester tester) async {
  // Use tester.view (not the deprecated tester.binding.window)
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(const MyApp());

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('golden/my_widget.png'),
  );
});
```

## Running Tests by Phase

### RED Phase

```bash
flutter test test/features/[feature]_test.dart
# Expected: Tests fail (feature not implemented yet)
```

### GREEN Phase

```bash
flutter test test/features/[feature]_test.dart
# Expected: All tests pass (minimal implementation done)
```

### REFACTOR Phase

```bash
flutter test test/features/[feature]_test.dart
dart format lib/features/[feature]/
flutter analyze lib/features/[feature]/
# Expected: Tests pass, code formatted, no analysis issues
```

## Test Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/counter/presentation/counter_screen_test.dart

# Run with coverage
flutter test --coverage

# Verbose output
flutter test -v

# Watch mode (re-run on file changes)
flutter test --watch
```

### Analysis Commands

```bash
# Analyze code for issues
flutter analyze

# Fix common issues automatically
dart fix --apply

# Format code
dart format lib/

# Check formatting without changing
dart format --line-length=80 --output=none lib/
```

## References

- Flutter Testing Documentation: https://flutter.dev/docs/testing
- Flutter Test Package: https://pub.dev/packages/flutter_test
- Integration Test: https://pub.dev/packages/integration_test
- Mockito: https://pub.dev/packages/mockito
