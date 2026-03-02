# C Testing Patterns

Reference for testing C code. Covers the Unity test framework, CMock for
mocking C functions, minimal assert.h usage, GoogleTest interop, and the
configure-build-test workflow.

## Unity Test Framework

Unity is a lightweight, portable test framework for C from ThrowTheSwitch.org.
It requires no dynamic memory allocation and runs on everything from embedded
targets to desktop operating systems.

### Test Structure

A Unity test file follows the setUp/tearDown pattern. Each test function
is registered in a test runner, and the framework calls setUp before each test
and tearDown after each test.

```c
#include "unity.h"
#include "module_under_test.h"

void setUp(void) {
    /* runs before every test */
}

void tearDown(void) {
    /* runs after every test */
}

void test_addition_returns_correct_sum(void) {
    TEST_ASSERT_EQUAL_INT(5, add(2, 3));
}

void test_addition_handles_zero(void) {
    TEST_ASSERT_EQUAL_INT(0, add(0, 0));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_addition_returns_correct_sum);
    RUN_TEST(test_addition_handles_zero);
    return UNITY_END();
}
```

### Common Assertion Macros

Unity provides assertion macros for every common comparison. Use the most
specific macro available -- it produces the best failure messages.

| Macro | Purpose |
|-------|---------|
| `TEST_ASSERT_TRUE(condition)` | Boolean true |
| `TEST_ASSERT_FALSE(condition)` | Boolean false |
| `TEST_ASSERT_EQUAL_INT(expected, actual)` | Integer equality |
| `TEST_ASSERT_EQUAL_STRING(expected, actual)` | String equality |
| `TEST_ASSERT_EQUAL_FLOAT(expected, actual)` | Float equality (within delta) |
| `TEST_ASSERT_NULL(pointer)` | Null pointer |
| `TEST_ASSERT_NOT_NULL(pointer)` | Non-null pointer |
| `TEST_ASSERT_EQUAL_MEMORY(expected, actual, len)` | Raw memory comparison |
| `TEST_ASSERT_EQUAL_INT_ARRAY(expected, actual, len)` | Integer array equality |

### Test File Naming

Name test files with a `_test.c` suffix that mirrors the source file:

- `src/parser.c` is tested by `test/parser_test.c`
- `src/utils/buffer.c` is tested by `test/utils/buffer_test.c`

This convention lets build systems and detection scripts discover test
files with a simple glob pattern (`*_test.c`).

## CMock -- Mocking C Functions

CMock generates mock implementations from C header files. It is part of the
ThrowTheSwitch.org ecosystem and integrates directly with Unity.

### How CMock Works

1. Point CMock at a header file (e.g., `hardware.h`).
2. CMock auto-generates `mock_hardware.h` and `mock_hardware.c`.
3. Your test includes `mock_hardware.h` instead of `hardware.h`.
4. Use Expect/Return macros to set up expectations.

```c
#include "unity.h"
#include "mock_hardware.h"
#include "controller.h"

void setUp(void) { /* nothing */ }
void tearDown(void) { /* nothing */ }

void test_controller_reads_sensor(void) {
    /* Expect hardware_read_sensor() to be called, return 42 */
    hardware_read_sensor_ExpectAndReturn(42);

    int result = controller_get_reading();
    TEST_ASSERT_EQUAL_INT(42, result);
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_controller_reads_sensor);
    return UNITY_END();
}
```

### Why CMock Over Other Approaches

Standard mocking tools like GoogleMock use C++ features (templates, virtual
methods) that are unavailable in C. CMock solves the fundamental problem of
mocking C functions by generating source-level replacements from headers.
This is linker-level substitution, which is the only reliable way to mock
free functions in C.

## Minimal Testing with assert.h

For small utilities or when adding a framework is impractical, the standard
library `assert.h` header provides a minimal testing approach:

```c
#include <assert.h>
#include "calculator.h"

int main(void) {
    assert(add(2, 3) == 5);
    assert(add(-1, 1) == 0);
    assert(multiply(3, 4) == 12);
    return 0;
}
```

Limitations of assert.h compared to Unity:

- No descriptive failure messages (just file/line/expression)
- Aborts on first failure (no summary of multiple failures)
- No setUp/tearDown lifecycle
- No test runner or discovery mechanism
- Disabled entirely by `NDEBUG` in release builds

Use assert.h only for quick sanity checks or bootstrapping. Migrate to Unity
for any project with more than a handful of tests.

## GoogleTest Interop

GoogleTest is a C++ framework. It cannot test C code directly because C
headers may not compile as C++. The solution is `extern "C"` linkage:

```cpp
// test_math_interop.cpp
#include "gtest/gtest.h"

extern "C" {
    #include "math_utils.h"
}

TEST(MathUtils, AdditionWorks) {
    EXPECT_EQ(5, add(2, 3));
}

TEST(MathUtils, SubtractionWorks) {
    EXPECT_EQ(1, subtract(3, 2));
}
```

The `extern "C"` block tells the C++ compiler to use C linkage for the
included header, preventing name mangling.

When to use GoogleTest for C code:

- The project already has a C++ test suite and you want a single framework
- You need GoogleMock for C++ components in the same project

When to prefer Unity instead:

- Pure C project with no C++ components
- Embedded or cross-compiled targets where C++ is unavailable
- You need CMock for mocking C functions (CMock integrates with Unity, not GoogleTest)

## Build-Then-Test Workflow

Unlike interpreted languages where tests run in a single command, C requires
a three-step configure-build-test sequence:

### Step 1: Configure

```sh
cmake -S . -B build
```

This generates the build system files. Run once, or again after changing
CMakeLists.txt.

### Step 2: Build

```sh
cmake --build build
```

This compiles source files and test executables. Must succeed before tests
can run.

### Step 3: Test

```sh
ctest --test-dir build --output-on-failure
```

This runs all registered test executables. The `--output-on-failure` flag
prints stdout/stderr only for failing tests, keeping output clean.

### Quick Iteration

During development, steps 2 and 3 are the inner loop:

```sh
cmake --build build && ctest --test-dir build --output-on-failure
```

Step 1 only needs to repeat when build configuration changes.

## Bootstrapping Unity with FetchContent

For projects using CMake, FetchContent is the simplest way to add Unity
without manual downloads or submodules:

```cmake
include(FetchContent)

FetchContent_Declare(
    unity
    GIT_REPOSITORY https://github.com/ThrowTheSwitch/Unity.git
    GIT_TAG        v2.6.0
)
FetchContent_MakeAvailable(unity)

enable_testing()

add_executable(calculator_test test/calculator_test.c)
target_link_libraries(calculator_test PRIVATE unity)
add_test(NAME calculator_test COMMAND calculator_test)
```

This downloads Unity at configure time, builds it as part of your project,
and registers the test executable with ctest.

For CMock, the same pattern applies -- declare a separate FetchContent block
for the CMock repository.

## References

- Unity documentation: https://www.throwtheswitch.org/unity
- CMock documentation: https://www.throwtheswitch.org/cmock
- GoogleTest user guide: https://google.github.io/googletest/
- CMake FetchContent: https://cmake.org/cmake/help/latest/module/FetchContent.html
