# GoogleTest Patterns

> **Version note:** GoogleTest 1.17.0+ requires C++17 (raised from C++14).

## Test Structure (TEST Macro)

```cpp
#include <gtest/gtest.h>

// Simple test
TEST(TestSuiteName, TestName) {
  // Arrange
  int a = 5;
  int b = 3;

  // Act
  int result = add(a, b);

  // Assert
  EXPECT_EQ(result, 8);
}
```

## Test Fixtures (TEST_F)

```cpp
class BufferTest : public ::testing::Test {
 protected:
  void SetUp() override {
    buffer_ = std::make_unique<Buffer>(1024);
  }

  void TearDown() override {
    buffer_.reset();
  }

  std::unique_ptr<Buffer> buffer_;
};

TEST_F(BufferTest, InitiallyEmpty) {
  EXPECT_EQ(buffer_->size(), 0);
}

TEST_F(BufferTest, WriteIncreasesSize) {
  buffer_->write("hello", 5);
  EXPECT_EQ(buffer_->size(), 5);
}
```

## Assertions

### Fatal vs Non-Fatal

| Fatal (stops test) | Non-Fatal (continues) |
|--------------------|----------------------|
| `ASSERT_*` | `EXPECT_*` |

Use `EXPECT_*` by default. Use `ASSERT_*` when continuing makes no sense.

### Common Assertions

```cpp
// Boolean
EXPECT_TRUE(condition);
EXPECT_FALSE(condition);

// Equality
EXPECT_EQ(val1, val2);    // val1 == val2
EXPECT_NE(val1, val2);    // val1 != val2

// Comparison
EXPECT_LT(val1, val2);    // val1 < val2
EXPECT_LE(val1, val2);    // val1 <= val2
EXPECT_GT(val1, val2);    // val1 > val2
EXPECT_GE(val1, val2);    // val1 >= val2

// Strings
EXPECT_STREQ(str1, str2);     // C strings equal
EXPECT_STRNE(str1, str2);     // C strings not equal

// Floating point
EXPECT_FLOAT_EQ(val1, val2);  // Almost equal
EXPECT_NEAR(val1, val2, abs_error);

// Distance comparison (1.17+)
EXPECT_THAT(val, DistanceFrom(target, Le(tolerance)));  // General distance

// Exceptions
EXPECT_THROW(statement, exception_type);
EXPECT_NO_THROW(statement);

// Death tests (process termination)
EXPECT_DEATH(statement, regex);
```

## Parameterized Tests

```cpp
class FibonacciTest : public ::testing::TestWithParam<std::pair<int, int>> {};

TEST_P(FibonacciTest, ComputesCorrectly) {
  auto [input, expected] = GetParam();
  EXPECT_EQ(fibonacci(input), expected);
}

INSTANTIATE_TEST_SUITE_P(
    FibonacciValues,
    FibonacciTest,
    ::testing::Values(
        std::make_pair(0, 0),
        std::make_pair(1, 1),
        std::make_pair(2, 1),
        std::make_pair(5, 5),
        std::make_pair(10, 55)
    )
);
```

## Test Naming Convention

```
TEST(ClassName, MethodName_Scenario_ExpectedBehavior)
```

Examples:
```cpp
TEST(Buffer, Write_EmptyData_DoesNothing)
TEST(Buffer, Write_ValidData_IncreasesSize)
TEST(Buffer, Read_WhenEmpty_ReturnsZero)
TEST(SharedMemory, Create_InvalidName_ReturnsError)
```

## File Organization

```
project/
├── src/
│   ├── buffer.cpp
│   └── buffer.h
├── test/
│   ├── buffer_test.cpp
│   └── shared_memory_test.cpp
└── CMakeLists.txt
```

Test files mirror source structure with `_test.cpp` suffix.

## C++ Naming Reference

| Element | Style | Example |
|---------|-------|---------|
| Files | `snake_case` | `my_class.cpp`, `my_class.h` |
| Classes/Structs | `PascalCase` | `MyClass`, `SharedMemoryBuffer` |
| Functions | `snake_case` | `get_value()`, `calculate_offset()` |
| Variables | `snake_case` | `buffer_size`, `item_count` |
| Member variables | `snake_case_` (trailing underscore) | `buffer_size_`, `data_` |
| Constants | `kPascalCase` | `kMaxBufferSize`, `kDefaultTimeout` |
| Enums | `PascalCase` type, `kPascalCase` values | `enum class Color { kRed, kGreen }` |
| Macros | `UPPER_SNAKE_CASE` | `SHM_MAX_SIZE` |
| Namespaces | `snake_case` | `namespace shared_memory` |

## References

- [Google Test Documentation](https://google.github.io/googletest/)
- [Google Test GitHub](https://github.com/google/googletest)
