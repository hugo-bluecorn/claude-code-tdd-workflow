# Mocking Guide for Dart/Flutter

## Choosing a Mocking Strategy

Prefer fakes or stubs over mocks. Use mocks when behavior verification is needed.

## Mockito (Manual Mocks)

```dart
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('LoginScreen', () {
    testWidgets('shows error when login fails', (WidgetTester tester) async {
      final mockAuthService = MockAuthService();
      when(mockAuthService.login(any, any))
          .thenThrow(Exception('Login failed'));

      // Build widget with mock
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: mockAuthService),
        ),
      );

      // Interact and verify
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'password');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Login failed'), findsOneWidget);
    });
  });
}
```

## Mockito with @GenerateMocks

For type-safe generated mocks:

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([AuthService, UserRepository])
import 'my_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  test('example with generated mock', () {
    when(mockAuthService.login(any, any))
        .thenAnswer((_) async => true);

    // ... test code
    verify(mockAuthService.login('user', 'pass')).called(1);
  });
}
```

After adding @GenerateMocks, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Mocktail (No Code Generation)

Alternative that doesn't require build_runner:

```dart
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  test('example with mocktail', () {
    when(() => mockAuthService.login(any(), any()))
        .thenAnswer((_) async => true);

    // ... test code
    verify(() => mockAuthService.login('user', 'pass')).called(1);
  });
}
```

Key difference: mocktail uses closures for `when()` and `verify()`.

## Dependency Injection for Testability

```dart
// DON'T: Create dependencies inside widget
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // Hard to mock
    // ...
  }
}

// DO: Inject dependencies
class LoginScreen extends StatelessWidget {
  final AuthService authService;

  const LoginScreen({required this.authService});

  @override
  Widget build(BuildContext context) {
    // Uses provided authService, easy to mock in tests
  }
}
```

## build_runner Integration

```bash
# Generate mocks after adding @GenerateMocks
dart run build_runner build --delete-conflicting-outputs

# Watch mode (regenerate on file changes)
dart run build_runner watch --delete-conflicting-outputs
```
