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

See `reference/riverpod-guide.md` for the complete Riverpod 3.x state management
guide including provider types, ViewModel patterns, AsyncNotifier, family providers,
`ref.mounted` async safety, testing with overrides, and legacy provider migration.

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
