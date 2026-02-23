# Context Updater Memory

## Last Check
- Date: 2026-02-23
- Run by: context-updater agent

## Framework Versions Found

| Framework | Version | Source |
|-----------|---------|--------|
| Flutter SDK | 3.41.2 | https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632 |
| Dart SDK | 3.11.0 | https://dart.dev/resources/language/evolution |
| Riverpod (flutter_riverpod) | 3.2.1 | https://github.com/rrousselGit/riverpod |
| GoogleTest | 1.17.0 | https://github.com/google/googletest/releases/tag/v1.17.0 |
| CMake | 4.2.3 (latest); 3.16 documented minimum | https://cmake.org/download/ |
| ShellCheck | 0.11.0 | https://github.com/koalaman/shellcheck/releases |
| bashunit | 0.33.0 (approx) | https://github.com/TypedDevs/bashunit |
| mockito (Dart) | 5.6.1 | https://pub.dev/packages/mockito/changelog |
| mocktail | 1.0.4 | https://github.com/felangel/mocktail |
| LLVM/Clang | 21.1.8 | https://github.com/llvm/llvm-project/releases |

## Breaking Changes Identified

### Applied
- GoogleTest 1.14.0 -> 1.17.0: C++ standard requirement raised from C++14 to C++17.
  Updated cmake-integration.md GIT_TAG, added CMAKE_CXX_STANDARD 17, updated
  cmake_minimum_required from 3.14 to 3.16.
- CMake 4.x removes backward compatibility with cmake_minimum_required < 3.5.
  Added note to cmake-integration.md. Documented minimum (3.16) is safe.
- Flutter deprecated tester.binding.window API (since 3.10+), replaced with
  tester.view in golden test examples.

### Not Applicable
- Dart 3.11: No new language features, only analyzer performance improvements.
  No reference file changes needed.
- Riverpod 3.2.1: Already documented, current.

## File Splits Performed
- project-conventions.md (536 lines) -> project-conventions.md (229) + riverpod-guide.md (244)
- test-patterns.md (411 lines) -> test-patterns.md (227) + test-recipes.md (196)

## Files Still Over 200 Lines (Deferred)
- bashunit-patterns.md: 323 lines (cohesive content, defer split)
- shellcheck-guide.md: 317 lines (cohesive content, defer split)
- project-conventions.md: 229 lines (slightly over, acceptable)
- riverpod-guide.md: 244 lines (slightly over, acceptable)
- test-patterns.md: 227 lines (slightly over, acceptable)

## URLs That Failed or Were Ambiguous
- https://github.com/flutter/flutter/releases -- Did not show stable releases,
  only betas. Used WebSearch fallback successfully.

## New Files Created
- clang-tooling.md (189 lines): clang-format, clang-tidy, sanitizers for C++
  testing. Fills gap from canonical source https://github.com/llvm/llvm-project.

## Notes for Next Run
- Monitor Riverpod for 4.x release (no signs yet as of 2026-02-23)
- Monitor bashunit for version 1.0 release
- Check if mockito 6.x is released (currently 5.6.1)
- GoogleTest 1.18+ may raise C++ requirement further
- LLVM 22.x expected stable release Q1 2026; check for new sanitizer features
