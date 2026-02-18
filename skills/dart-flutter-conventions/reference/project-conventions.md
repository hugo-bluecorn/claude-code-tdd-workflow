# Dart/Flutter Project Conventions

## Style Guide

- **SOLID Principles:** Apply SOLID principles throughout the codebase.
- **Composition over Inheritance:** Favor composition for building complex widgets and logic.
- **Immutability:** Prefer immutable data structures. Widgets (especially `StatelessWidget`) should be immutable.
- **State Management:** Separate ephemeral state and app state. Use a state management solution for app state to handle the separation of concerns.
- **Navigation:** Use `go_router` for declarative navigation, deep linking, and web support.

## Code Quality Rules

- Functions short and with a single purpose (strive for less than 20 lines)
- Line length: 80 characters or fewer
- Use `PascalCase` for classes, `camelCase` for members/variables/functions/enums, and `snake_case` for files
- Follow the official Effective Dart guidelines: https://dart.dev/effective-dart
- Sound null safety: leverage Dart's null safety features, avoid `!` unless the value is guaranteed to be non-null
- Proper `async`/`await` for asynchronous operations with robust error handling
- Use the `logging` package or `dart:developer` log function instead of `print`
- No files exceed 400 lines

## Identifier Naming (Effective Dart)

- **DO** name types using `UpperCamelCase`
- **DO** name extensions using `UpperCamelCase`
- **DO** name packages, directories, and source files using `lowercase_with_underscores`
- **DO** name import prefixes using `lowercase_with_underscores`
- **DO** name other identifiers using `lowerCamelCase`
- **PREFER** using `lowerCamelCase` for constant names
- **DO** capitalize acronyms and abbreviations longer than two letters like words (e.g., `HttpRequest` not `HTTPRequest`)
- **DON'T** use a leading underscore for identifiers that aren't private
- **DON'T** use prefix letters (like `kConstant`, `_mPrivate`)

## Import Organization

```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:io';

// 2. Package imports (alphabetical)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Local project imports (alphabetical)
import 'package:myapp/data/repositories/user_repository.dart';
import 'package:myapp/ui/home/home_viewmodel.dart';
import 'package:myapp/ui/core/widgets/custom_button.dart';
```

## Application Architecture (MVVM)

### Hybrid Organization

```
lib/
├── main.dart              # Application entry point
├── app.dart               # Root app widget
├── ui/                    # Organized by feature
│   ├── core/              # Shared UI components
│   │   ├── themes/
│   │   │   └── app_theme.dart
│   │   └── widgets/       # Reusable widgets
│   │       ├── buttons/
│   │       └── dialogs/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── home_viewmodel.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── profile_viewmodel.dart
├── data/                  # Organized by type
│   ├── repositories/      # Data access abstractions
│   │   ├── user_repository.dart
│   │   └── auth_repository.dart
│   ├── services/          # External integrations
│   │   ├── api_service.dart
│   │   └── storage_service.dart
│   └── models/            # API response models
│       ├── user_model.dart
│       └── auth_response.dart
└── routing/
    └── app_router.dart    # go_router configuration
```

**Why Hybrid:**
- UI organized by feature (features used together)
- Data organized by type (repositories/services used across features)
- Scalable and maintainable

### ViewModel Example (Synchronous Notifier)

```dart
// lib/ui/home/home_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class
class HomeState {
  final bool isLoading;
  final User? user;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  HomeState copyWith({bool? isLoading, User? user, String? error}) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

// ViewModel using Notifier (Riverpod 3.x, no codegen)
class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  Future<void> loadUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await ref.read(userRepositoryProvider).getUser(userId);
      // Always check ref.mounted after async gaps to prevent
      // state updates on disposed providers
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider definition
final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);
```

### ViewModel Example (AsyncNotifier)

```dart
// lib/ui/users/users_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// AsyncNotifier: build() returns FutureOr<T>, state is AsyncValue<T>
class UsersViewModel extends AsyncNotifier<List<User>> {
  @override
  FutureOr<List<User>> build() async {
    // Riverpod 3.x: ref.onDispose for cleanup
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);

    return await ref.read(userRepositoryProvider).getUsers(
      cancelToken: cancelToken,
    );
  }

  Future<void> addUser(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final users = await ref
          .read(userRepositoryProvider)
          .addUser(name);
      return users;
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Provider definition
final usersViewModelProvider =
    AsyncNotifierProvider<UsersViewModel, List<User>>(
  UsersViewModel.new,
);
```

### View Example (Sync State)

```dart
// lib/ui/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: switch (state) {
        HomeState(isLoading: true) =>
          const Center(child: CircularProgressIndicator()),
        HomeState(error: final error?) =>
          Center(child: Text('Error: $error')),
        HomeState(user: final user?) =>
          Center(child: Text('Welcome, ${user.name}')),
        _ => const Center(child: Text('Load a user')),
      },
    );
  }
}
```

### View Example (AsyncValue Pattern Matching)

```dart
// lib/ui/users/users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'users_viewmodel.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncNotifier state is AsyncValue<T> — a sealed class
    final usersAsync = ref.watch(usersViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      // Exhaustive switch on sealed AsyncValue
      body: switch (usersAsync) {
        AsyncData(:final value) => ListView.builder(
          itemCount: value.length,
          itemBuilder: (_, i) => ListTile(title: Text(value[i].name)),
        ),
        AsyncError(:final error) =>
          Center(child: Text('Error: $error')),
        AsyncLoading() =>
          const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
```

### Repository Pattern

```dart
// lib/data/repositories/user_repository.dart
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<void> updateUser(User user);
}

// lib/data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  UserRepositoryImpl(this._apiService, this._storageService);

  @override
  Future<User> getUser(String id) async {
    // Try cache first (offline-first)
    final cached = await _storageService.getUser(id);
    if (cached != null) return cached;

    // Fetch from API
    final response = await _apiService.fetchUser(id);
    final user = User.fromJson(response);

    // Cache for offline use
    await _storageService.saveUser(user);

    return user;
  }
}
```

## Naming Conventions

### Class Names by Role

Name classes by architectural role, not generic names:

**Good:**
- `HomeViewModel`
- `UserRepository`
- `ApiService`
- `LoginScreen`

**Avoid:**
- `HomeController` (vague)
- `DataManager` (vague)
- `Helper` (too generic)

### Directory Naming

- Use `ui/core/` instead of `widgets/` - Avoids confusion with Flutter SDK
- Descriptive names: `authentication/` not `auth/`
- Plural for collections: `models/`, `services/`, `screens/`
- Singular for layers: `domain/`, `data/`, `ui/`
- `snake_case` for directories: `feature_name/`

### File Naming

- Use `snake_case`: `user_profile_screen.dart`
- Match class names: `UserProfileScreen` in `user_profile_screen.dart`
- Test files: `user_profile_screen_test.dart` (`_test.dart` suffix)
- One class per file (exceptions for tightly coupled classes)

## Test Directory Organization

Tests should mirror the `lib/` directory structure:

```
test/
├── ui/                    # Widget tests
│   ├── home/
│   │   ├── home_screen_test.dart
│   │   └── home_viewmodel_test.dart
│   └── profile/
│       └── profile_screen_test.dart
├── data/                  # Unit tests for data layer
│   ├── repositories/
│   │   └── user_repository_test.dart
│   └── services/
│       └── api_service_test.dart
├── domain/                # Unit tests for business logic
│   └── usecases/
│       └── get_user_usecase_test.dart
└── helpers/               # Test utilities
    ├── mocks.dart
    └── test_data.dart
```

## File Size Guidelines

- No files exceed 400 lines
- Functions < 20 lines

## State Management

**Riverpod 3.x (Required):** Use `flutter_riverpod: ^3.2.1` for app-level state
management and dependency injection. **No code generation** — use the manual
provider API throughout. Do NOT add `riverpod_annotation` or `riverpod_generator`.

### Provider Types

| Provider | Use Case | State Type |
|----------|----------|------------|
| `NotifierProvider` | Mutable sync state (ViewModels) | `T` |
| `AsyncNotifierProvider` | Mutable async state (data loading) | `AsyncValue<T>` |
| `StreamNotifierProvider` | Mutable stream state (WebSocket, realtime) | `AsyncValue<T>` |
| `Provider` | Computed/derived values, DI | `T` |
| `FutureProvider` | Read-only async data | `AsyncValue<T>` |
| `StreamProvider` | Read-only stream data | `AsyncValue<T>` |

### Basic Notifier Pattern

```dart
final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

// Use in widget with ConsumerWidget
class CounterWidget extends ConsumerWidget {
  const CounterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}
```

### AutoDispose

Providers are disposed when no widget is listening. Use `.autoDispose` for
screen-scoped state that should not persist across navigation:

```dart
final detailProvider = NotifierProvider.autoDispose<DetailViewModel, DetailState>(
  DetailViewModel.new,
);

final userProvider = FutureProvider.autoDispose<User>((ref) async {
  // ref.keepAlive() to prevent disposal during navigation transitions
  ref.keepAlive();
  return await ref.read(userRepositoryProvider).getUser();
});
```

### Family Providers

Pass arguments to providers via constructor injection (3.x pattern):

```dart
final cropDetailProvider =
    NotifierProvider.family<CropDetailViewModel, CropDetailState, int>(
  (int cropId) => CropDetailViewModel(cropId),
);

class CropDetailViewModel extends Notifier<CropDetailState> {
  CropDetailViewModel(this.cropId);
  final int cropId;

  @override
  CropDetailState build() => const CropDetailState();
}

// Usage: ref.watch(cropDetailProvider(42))
```

Combine with autoDispose: `NotifierProvider.autoDispose.family<N, S, A>(...)`.
Order matters: `.autoDispose` must come before `.family`.

### Ref in Riverpod 3.x

`Ref` is a sealed class with no type parameters. Key methods:

```dart
// In Notifier methods (ref available via Notifier base class):
ref.read(provider)              // Read once, no rebuild
ref.watch(provider)             // Watch and rebuild on change
ref.listen(provider, callback)  // Listen without rebuild
ref.invalidateSelf()            // Force this provider to rebuild
ref.onDispose(() => cleanup())  // Lifecycle cleanup
ref.mounted                     // Check if still active (critical for async!)
```

### Async Safety with ref.mounted

After any `await` in a Notifier method, always check `ref.mounted` before
updating state. This prevents race conditions when a provider is disposed
during an async gap:

```dart
Future<void> loadData() async {
  final data = await fetchData();
  if (!ref.mounted) return;  // Provider was disposed during await
  state = data;
}
```

### Legacy Providers (Do NOT Use)

These are moved to `import 'package:riverpod/legacy.dart'` and should NOT
be used in new code:
- `StateProvider` — replaced by `NotifierProvider`
- `StateNotifierProvider` — replaced by `NotifierProvider`
- `ChangeNotifierProvider` — replaced by `NotifierProvider`

### Equality Filtering

Riverpod 3.x uses `==` to filter state updates by default. Providers only
notify listeners when the new state is not equal to the previous state.
Override `updateShouldNotify` in a Notifier to customize this behavior.

### Testing with Provider Overrides

```dart
testWidgets('test with overrides', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(FakeUserRepository()),
        counterProvider.overrideWith(() => Counter()),
      ],
      child: const MyApp(),
    ),
  );
});
```

**Built-in Solutions for Ephemeral State Only:** For widget-local state that does not
leave the widget (e.g., animation controllers, form field focus, toggle visibility),
Flutter's built-in solutions are appropriate:
- `ValueNotifier` with `ValueListenableBuilder` for single values
- `Streams` with `StreamBuilder` for async event sequences
- `Futures` with `FutureBuilder` for single async operations

These are NOT alternatives to Riverpod for app state. Any state that a ViewModel
manages, that crosses widget boundaries, or that represents business logic MUST
use Riverpod as shown in the ViewModel and View examples above.

## Conventional Commits

| Type | Purpose |
|------|---------|
| feat | New functionality |
| fix | Bug fixes |
| refactor | Code restructuring, no behavior change |
| docs | Documentation only |
| test | Test additions/fixes |
| chore | Maintenance, dependencies |

## Official References

Key takeaways from Flutter AI Rules:
- `dart:developer` log function for logging
- `package:checks` for assertions
- MVVM as recommended architecture
- `go_router` for navigation
- 80 character line length

| Need | Official | Recommended |
|------|----------|-------------|
| State Management (app state) | Riverpod 3.x | flutter_riverpod ^3.2.1 (no codegen) |
| State Management (ephemeral) | Built-in (ValueNotifier, ChangeNotifier) | Built-in |
| Navigation | go_router | go_router |
| Serialization | json_serializable | dart_mappable |
| Linting | flutter_lints | flutter_lints |
| Testing | package:checks | package:checks |
| Logging | dart:developer | dart:developer |
| Architecture | MVVM | MVVM |

- Flutter AI Rules: https://github.com/flutter/flutter/blob/main/docs/rules/rules.md
- Flutter Architecture Guide: https://docs.flutter.dev/app-architecture/guide
- Flutter Architecture Recommendations: https://docs.flutter.dev/app-architecture/recommendations
- Effective Dart: https://dart.dev/effective-dart
- Riverpod: https://riverpod.dev/
- go_router: https://pub.dev/packages/go_router
