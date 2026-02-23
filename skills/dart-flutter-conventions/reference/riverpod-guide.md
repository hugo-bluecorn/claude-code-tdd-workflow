# Riverpod 3.x State Management Guide

**Riverpod 3.x (Required):** Use `flutter_riverpod: ^3.2.1` for app-level state
management and dependency injection. **No code generation** -- use the manual
provider API throughout. Do NOT add `riverpod_annotation` or `riverpod_generator`.

## Provider Types

| Provider | Use Case | State Type |
|----------|----------|------------|
| `NotifierProvider` | Mutable sync state (ViewModels) | `T` |
| `AsyncNotifierProvider` | Mutable async state (data loading) | `AsyncValue<T>` |
| `StreamNotifierProvider` | Mutable stream state (WebSocket, realtime) | `AsyncValue<T>` |
| `Provider` | Computed/derived values, DI | `T` |
| `FutureProvider` | Read-only async data | `AsyncValue<T>` |
| `StreamProvider` | Read-only stream data | `AsyncValue<T>` |

## Basic Notifier Pattern

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

## ViewModel Example (Synchronous Notifier)

```dart
// lib/ui/home/home_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  final bool isLoading;
  final User? user;
  final String? error;

  const HomeState({this.isLoading = false, this.user, this.error});

  HomeState copyWith({bool? isLoading, User? user, String? error}) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  Future<void> loadUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ref.read(userRepositoryProvider).getUser(userId);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);
```

## ViewModel Example (AsyncNotifier)

```dart
class UsersViewModel extends AsyncNotifier<List<User>> {
  @override
  FutureOr<List<User>> build() async {
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    return await ref.read(userRepositoryProvider).getUsers(
      cancelToken: cancelToken,
    );
  }

  Future<void> addUser(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(userRepositoryProvider).addUser(name);
    });
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

final usersViewModelProvider =
    AsyncNotifierProvider<UsersViewModel, List<User>>(UsersViewModel.new);
```

## View Example (AsyncValue Pattern Matching)

```dart
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: switch (usersAsync) {
        AsyncData(:final value) => ListView.builder(
          itemCount: value.length,
          itemBuilder: (_, i) => ListTile(title: Text(value[i].name)),
        ),
        AsyncError(:final error) => Center(child: Text('Error: $error')),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
```

## AutoDispose

Use `.autoDispose` for screen-scoped state that should not persist:

```dart
final detailProvider = NotifierProvider.autoDispose<DetailViewModel, DetailState>(
  DetailViewModel.new,
);

final userProvider = FutureProvider.autoDispose<User>((ref) async {
  ref.keepAlive(); // Prevent disposal during navigation transitions
  return await ref.read(userRepositoryProvider).getUser();
});
```

## Family Providers

Pass arguments via constructor injection (3.x pattern):

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

Combine: `NotifierProvider.autoDispose.family<N, S, A>(...)`.
Order matters: `.autoDispose` must come before `.family`.

## Ref in Riverpod 3.x

`Ref` is a sealed class with no type parameters. Key methods:

```dart
ref.read(provider)              // Read once, no rebuild
ref.watch(provider)             // Watch and rebuild on change
ref.listen(provider, callback)  // Listen without rebuild
ref.invalidateSelf()            // Force this provider to rebuild
ref.onDispose(() => cleanup())  // Lifecycle cleanup
ref.mounted                     // Check if still active (critical for async!)
```

## Async Safety with ref.mounted

After any `await`, always check `ref.mounted` before updating state:

```dart
Future<void> loadData() async {
  final data = await fetchData();
  if (!ref.mounted) return;  // Provider was disposed during await
  state = data;
}
```

## Legacy Providers (Do NOT Use)

Moved to `import 'package:riverpod/legacy.dart'`:
- `StateProvider` -- replaced by `NotifierProvider`
- `StateNotifierProvider` -- replaced by `NotifierProvider`
- `ChangeNotifierProvider` -- replaced by `NotifierProvider`

## Equality Filtering

Riverpod 3.x uses `==` to filter state updates by default. Override
`updateShouldNotify` in a Notifier to customize this behavior.

## Testing with Provider Overrides

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

## Ephemeral State (Built-in Only)

For widget-local state (animation controllers, form field focus, toggle
visibility), Flutter built-ins are appropriate:
- `ValueNotifier` with `ValueListenableBuilder` for single values
- `Streams` with `StreamBuilder` for async event sequences
- `Futures` with `FutureBuilder` for single async operations

These are NOT alternatives to Riverpod for app state. Any state that a
ViewModel manages, that crosses widget boundaries, or that represents
business logic MUST use Riverpod.

## References

- Riverpod: https://riverpod.dev/
