# CMake Integration for GoogleTest

## CMakeLists.txt Setup

```cmake
cmake_minimum_required(VERSION 3.14.0)
project(my_project VERSION 0.1.0 LANGUAGES C CXX)

# Fetch Google Test
include(FetchContent)
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG v1.14.0
)
FetchContent_MakeAvailable(googletest)

# Main executable
add_executable(${PROJECT_NAME} main.cpp)

# Test executable
enable_testing()
add_executable(${PROJECT_NAME}_test
  test/example_test.cpp
)
target_link_libraries(${PROJECT_NAME}_test
  GTest::gtest_main
  GTest::gmock
)

# Register tests with CTest
include(GoogleTest)
gtest_discover_tests(${PROJECT_NAME}_test
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  PROPERTIES
    TIMEOUT 10
)
```

### Key Components

- **FetchContent**: Downloads GoogleTest automatically during cmake configure
- **enable_testing()**: Enables CTest support
- **target_link_libraries**: Links GTest::gtest_main (provides main()) and GTest::gmock
- **gtest_discover_tests**: Auto-registers tests with CTest, with configurable TIMEOUT

## Building and Running Tests

```bash
# Configure (first time only)
cmake -B build

# Build
cmake --build build

# Run all tests
ctest --test-dir build --output-on-failure

# Run specific test
ctest --test-dir build -R "BufferTest"

# Verbose output
ctest --test-dir build -V
```

## Adding New Test Files

1. Create test file in `test/` directory (e.g., `test/new_feature_test.cpp`)
2. Add to `add_executable` in CMakeLists.txt:
   ```cmake
   add_executable(${PROJECT_NAME}_test
     test/existing_test.cpp
     test/new_feature_test.cpp
   )
   ```
3. Rebuild: `cmake --build build`
4. Tests are auto-discovered by CTest

## References

- [GoogleTest CMake Integration](https://google.github.io/googletest/quickstart-cmake.html)
