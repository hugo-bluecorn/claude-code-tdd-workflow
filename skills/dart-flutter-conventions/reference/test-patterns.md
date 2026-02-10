# Dart/Flutter Test Patterns

## Unit Tests

Used for testing Dart code without any Flutter dependencies.

**When to use:**
- Business logic (validators, formatters, calculators)
- Service classes
- Repository classes
- Data models

**Example:**
```dart
// test/core/validators/email_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/validators/email_validator.dart';

void main() {
  group('EmailValidator', () {
    test('returns true for valid email', () {
      expect(validateEmail('user@example.com'), isTrue);
    });

    test('returns false for invalid email', () {
      expect(validateEmail('invalid'), isFalse);
    });

    test('returns false for empty string', () {
      expect(validateEmail(''), isFalse);
    });
  });
}
```

**Run unit tests:**
```bash
dart test test/core/validators/email_validator_test.dart
dart test                                            # Run all tests
dart test -v                                         # Verbose output
dart test --coverage                                 # Generate coverage report
```

## Widget Tests

Used for testing Flutter widgets and UI behavior.

**When to use:**
- Widget rendering and layout
- Button interactions
- Form validation UI
- State changes
- Navigation

**Example:**
```dart
// test/features/counter/presentation/counter_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/counter/presentation/counter_screen.dart';

void main() {
  group('CounterScreen', () {
    testWidgets('displays initial counter value', (WidgetTester tester) async {
      // Arrange: Build the widget
      await tester.pumpWidget(const MyApp());

      // Assert: Initial state
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('increments counter when fab is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const MyApp());

      // Act: Tap the FAB
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Assert: Counter incremented
      expect(find.text('1'), findsOneWidget);
    });
  });
}
```

**Run widget tests:**
```bash
flutter test test/features/counter/presentation/counter_screen_test.dart
flutter test -v                                      # Verbose output
```

## Integration Tests

Used for testing complete user workflows across multiple screens.

**When to use:**
- End-to-end user flows
- Multi-screen navigation
- Data persistence
- API integration
- Performance under real conditions

**Example:**
```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete user flow test', (WidgetTester tester) async {
      // Build the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to feature
      await tester.tap(find.byText('Feature Name'));
      await tester.pumpAndSettle();

      // Interact with form
      await tester.enterText(find.byType(TextField), 'input value');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify result
      expect(find.text('Success'), findsOneWidget);
    });
  });
}
```

**Run integration tests:**
```bash
flutter test integration_test/app_test.dart
flutter test integration_test/ -v                    # All integration tests
```

## Test Pattern Templates

### Unit Test (Arrange-Act-Assert)

```dart
void main() {
  group('Feature Name', () {
    test('when condition, then expected outcome', () {
      // Arrange
      final validator = EmailValidator();
      const email = 'test@example.com';

      // Act
      final result = validator.validate(email);

      // Assert
      expect(result, isTrue);
    });
  });
}
```

### Widget Test

```dart
void main() {
  group('FeatureWidget', () {
    testWidgets('displays content', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: FeatureWidget(),
        ),
      );

      // Act
      // (widget automatically rendered by pumpWidget)

      // Assert
      expect(find.text('Expected Text'), findsOneWidget);
    });

    testWidgets('when button tapped, then action occurs', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: FeatureWidget()));

      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Result'), findsOneWidget);
    });
  });
}
```

### Integration Test

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Integration Tests', () {
    testWidgets('complete user flow', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byText('Start'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FeatureScreen), findsOneWidget);
    });
  });
}
```

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
  await tester.binding.window.physicalSizeTestValue = const Size(800, 600);
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

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
