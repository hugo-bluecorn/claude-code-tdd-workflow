# Clang Tooling for C++ Testing

Testing-relevant Clang/LLVM tools: formatting, static analysis, and runtime
sanitizers. Based on LLVM/Clang 21.x (latest stable: 21.1.8).

## clang-format for Test Files

Use a `.clang-format` file at the project root. Test files inherit the same
style as production code. Recommended settings for GoogleTest projects:

```yaml
# .clang-format
BasedOnStyle: Google
ColumnLimit: 100
IndentWidth: 2
BreakBeforeBraces: Attach
AllowShortFunctionsOnASingleLine: Inline
SortIncludes: CaseSensitive
```

Run formatting:

```bash
# Format all source and test files
clang-format -i src/*.cpp src/*.h test/*_test.cpp

# Check formatting without modifying (CI mode)
clang-format --dry-run --Werror src/*.cpp test/*_test.cpp
```

## clang-tidy for Test Code

clang-tidy performs static analysis using a compile command database. Generate
one with CMake:

```bash
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

### Recommended Checks for Test Targets

Create a `.clang-tidy` file. Exclude checks that produce false positives in
GoogleTest macro expansions:

```yaml
# .clang-tidy
Checks: >
  -*,
  bugprone-*,
  modernize-*,
  performance-*,
  readability-identifier-naming,
  -bugprone-easily-swappable-parameters,
  -modernize-use-trailing-return-type
WarningsAsErrors: ''
HeaderFilterRegex: '.*'
```

Key check categories for testing:

| Category | Examples | Purpose |
|----------|----------|---------|
| `bugprone-*` | `bugprone-use-after-move`, `bugprone-dangling-handle` | Catch common bugs |
| `modernize-*` | `modernize-use-override`, `modernize-use-nullptr` | Enforce C++17 idioms |
| `performance-*` | `performance-unnecessary-copy-initialization` | Avoid test overhead |

### Running clang-tidy

```bash
# Run on all source files using compile database
clang-tidy -p build src/*.cpp

# Run on test files only
clang-tidy -p build test/*_test.cpp

# Apply fixes automatically
clang-tidy -p build --fix src/*.cpp
```

Suppress specific warnings inline with `// NOLINT` or `// NOLINTNEXTLINE`:

```cpp
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
TEST(Calculator, Add_TwoPositives_ReturnsSum) { ... }
```

## Sanitizers for Test Targets

Sanitizers instrument test binaries at compile time to detect runtime errors.
They integrate with GoogleTest and CTest without code changes.

### CMake Sanitizer Configuration

Add sanitizer options to your CMakeLists.txt as a build option:

```cmake
option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
option(ENABLE_TSAN "Enable ThreadSanitizer" OFF)

if(ENABLE_ASAN)
  add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
  add_link_options(-fsanitize=address)
endif()

if(ENABLE_UBSAN)
  add_compile_options(-fsanitize=undefined)
  add_link_options(-fsanitize=undefined)
endif()

if(ENABLE_TSAN)
  add_compile_options(-fsanitize=thread)
  add_link_options(-fsanitize=thread)
endif()
```

### Building and Running with Sanitizers

```bash
# AddressSanitizer: detects memory errors (use-after-free, buffer overflow)
cmake -B build-asan -DENABLE_ASAN=ON
cmake --build build-asan
ctest --test-dir build-asan --output-on-failure

# UndefinedBehaviorSanitizer: detects UB (signed overflow, null deref)
cmake -B build-ubsan -DENABLE_UBSAN=ON
cmake --build build-ubsan
ctest --test-dir build-ubsan --output-on-failure

# ThreadSanitizer: detects data races in concurrent code
cmake -B build-tsan -DENABLE_TSAN=ON
cmake --build build-tsan
ctest --test-dir build-tsan --output-on-failure
```

### Sanitizer Compatibility

| Sanitizer | Can Combine With | Cannot Combine With |
|-----------|-----------------|---------------------|
| ASan | UBSan | TSan, MSan |
| UBSan | ASan, TSan | -- |
| TSan | UBSan | ASan, MSan |

Combined ASan + UBSan build:

```cmake
if(ENABLE_ASAN AND ENABLE_UBSAN)
  add_compile_options(-fsanitize=address,undefined -fno-omit-frame-pointer)
  add_link_options(-fsanitize=address,undefined)
endif()
```

### Controlling Sanitizer Behavior

Use environment variables when running tests:

```bash
# Abort on first ASan error (useful in CI)
ASAN_OPTIONS=halt_on_error=1 ctest --test-dir build-asan --output-on-failure

# Get full stack traces
ASAN_OPTIONS=symbolize=1 ASAN_SYMBOLIZER_PATH=$(which llvm-symbolizer) \
  ctest --test-dir build-asan --output-on-failure

# TSan: suppress known benign races
TSAN_OPTIONS=suppressions=tsan_suppressions.txt \
  ctest --test-dir build-tsan --output-on-failure
```

## Integration with TDD Workflow

In a TDD cycle, clang tools run during verification:

1. **RED/GREEN phases**: Build and run tests normally (no sanitizers needed)
2. **REFACTOR phase**: Run `clang-format` and `clang-tidy` for code quality
3. **Final verification**: Run test suite with ASan+UBSan enabled to catch
   memory errors and undefined behavior before marking a slice complete

Sanitizer builds are separate build directories and do not interfere with
the normal debug/release builds used during RED and GREEN phases.

## References

- [clang-format Documentation](https://clang.llvm.org/docs/ClangFormat.html)
- [clang-tidy Documentation](https://clang.llvm.org/extra/clang-tidy/)
- [AddressSanitizer](https://clang.llvm.org/docs/AddressSanitizer.html)
- [UndefinedBehaviorSanitizer](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html)
- [ThreadSanitizer](https://clang.llvm.org/docs/ThreadSanitizer.html)
- [LLVM Project GitHub](https://github.com/llvm/llvm-project)
