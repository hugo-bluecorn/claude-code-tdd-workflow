---
name: cpp-testing-conventions
description: >
  C++ testing conventions using GoogleTest, CMake integration,
  and project-specific patterns. Loaded by TDD agents for C++ work.
user-invocable: false
---

# C++ Testing Conventions

## GoogleTest Structure
See `reference/googletest-patterns.md` for:
- TEST and TEST_F macros
- Test fixtures with SetUp/TearDown
- Assertion macros (EXPECT_* vs ASSERT_*)
- Parameterized tests

## CMake Integration
See `reference/cmake-integration.md` for:
- enable_testing() and find_package(GTest)
- add_executable / target_link_libraries / add_test
- CTest configuration

## Mocking
See `reference/googlemock-guide.md` for:
- MOCK_METHOD macro
- EXPECT_CALL with matchers
- Action specification (Return, Throw, Invoke)

## Running Tests
- Build: `cmake --build build/`
- Run all: `ctest --test-dir build/ --output-on-failure`
- Run specific: `ctest --test-dir build/ -R "TestName"`
- Verbose: `ctest --test-dir build/ -V`
