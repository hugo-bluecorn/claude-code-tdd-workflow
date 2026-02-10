# Widget Testing Reference

## Core API

| Method | Purpose |
|--------|---------|
| `pumpWidget()` | Build widget tree |
| `pump()` | Trigger rebuild after interaction |
| `pumpAndSettle()` | Pump until no more animations |
| `tap()` | Simulate tap interaction |
| `enterText()` | Enter text into text field |
| `find` | Locate widgets in tree |

## Finder Methods

| Finder | Usage |
|--------|-------|
| `find.text('Hello')` | Find by text content |
| `find.byType(TextField)` | Find by widget type |
| `find.byIcon(Icons.add)` | Find by icon |
| `find.byKey(Key('myKey'))` | Find by key |
| `find.byWidgetPredicate(...)` | Find by predicate |

## Interaction Simulation

| Method | Usage |
|--------|-------|
| `tester.tap(finder)` | Tap a widget |
| `tester.enterText(finder, 'text')` | Enter text |
| `tester.drag(finder, offset)` | Drag a widget |
| `tester.longPress(finder)` | Long press |
| `tester.fling(finder, offset, speed)` | Fling gesture |

## Widget Test Pattern

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

## Best Practices

### Keep Widgets Small and Testable

```dart
// DON'T: Large, complex widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 200 lines of UI code...
    );
  }
}

// DO: Compose smaller, testable widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildContent(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => HeaderWidget();
  Widget _buildContent() => ContentWidget();
  Widget _buildFooter() => FooterWidget();
}

// Each sub-widget can be tested independently
```

## Troubleshooting

### Widget Not Found in Test

**Causes:** Widget not built, incorrect finder, widget hidden

**Solutions:**
```dart
// Debug: Print widget tree
debugPrintBeginFrame = true;

// Or use common issues:
await tester.pumpWidget(...); // Build widget
await tester.pump(); // Rebuild after interaction
await tester.pumpAndSettle(); // Wait for animations

// Verify widget exists before assertion
expect(find.byType(MyWidget), findsWidgets); // Should find at least one
```

### Text Field Input Not Working

```dart
// Correct way
await tester.enterText(find.byType(TextField), 'input');
await tester.pump(); // Rebuild to show text

// Common mistake
await tester.tap(find.byType(TextField));
// Forgot to rebuild after tap
```

### Async Operations Timeout

```dart
// Use pumpAndSettle() to wait for all async to complete
await tester.pumpAndSettle();

// Or specify timeout
await tester.pumpAndSettle(const Duration(seconds: 5));

// For specific futures
await tester.pumpAndSettle(const Duration(milliseconds: 500));
```

### Tests Are Slow

**Causes:** Network calls, file I/O, unnecessary waits

**Solutions:**
- Use mocks for external dependencies
- Use `pump()` instead of `pumpAndSettle()` when possible
- Split integration tests from unit tests
- Run unit tests frequently, integration tests less often
