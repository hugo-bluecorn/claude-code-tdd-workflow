# GoogleMock Guide

## Creating Mock Classes

```cpp
#include <gmock/gmock.h>

class MockDatabase : public Database {
 public:
  MOCK_METHOD(bool, connect, (const std::string& host), (override));
  MOCK_METHOD(int, query, (const std::string& sql), (override));
  MOCK_METHOD(void, disconnect, (), (override));
};
```

### MOCK_METHOD Syntax

```cpp
MOCK_METHOD(return_type, method_name, (parameter_types), (qualifiers));
```

Qualifiers: `override`, `const`, `noexcept`, or combinations like `(const, override)`.

## Setting Expectations (EXPECT_CALL)

```cpp
using ::testing::Return;
using ::testing::_;

TEST(ClientTest, ConnectsToDatabase) {
  MockDatabase db;

  EXPECT_CALL(db, connect("localhost"))
      .Times(1)
      .WillOnce(Return(true));

  Client client(&db);
  EXPECT_TRUE(client.initialize());
}
```

### Cardinality

```cpp
EXPECT_CALL(mock, method(_)).Times(1);           // Exactly once
EXPECT_CALL(mock, method(_)).Times(AtLeast(1));   // One or more
EXPECT_CALL(mock, method(_)).Times(AtMost(3));    // Up to three
EXPECT_CALL(mock, method(_)).Times(Between(2,5)); // Between 2 and 5
EXPECT_CALL(mock, method(_)).Times(0);            // Never called
```

## Matchers

```cpp
using ::testing::_;           // Any value
using ::testing::Eq;          // Equals
using ::testing::Ne;          // Not equals
using ::testing::Lt;          // Less than
using ::testing::Gt;          // Greater than
using ::testing::StartsWith;  // String starts with
using ::testing::HasSubstr;   // String contains
using ::testing::IsNull;      // Pointer is null
using ::testing::NotNull;     // Pointer is not null
```

### Additional Matchers

```cpp
using ::testing::AllOf;        // All matchers match
using ::testing::AnyOf;        // At least one matches
using ::testing::Not;          // Negation
using ::testing::Property;     // Match object property
using ::testing::Field;        // Match struct field
using ::testing::Pair;         // Match std::pair
using ::testing::ElementsAre;  // Match container elements
```

## Actions

### Return Values

```cpp
EXPECT_CALL(mock, method(_))
    .WillOnce(Return(42))
    .WillRepeatedly(Return(0));
```

### Throw Exceptions

```cpp
EXPECT_CALL(mock, method(_))
    .WillOnce(Throw(std::runtime_error("connection failed")));
```

### Invoke Functions

```cpp
EXPECT_CALL(mock, method(_))
    .WillOnce(Invoke([](const std::string& input) {
      return static_cast<int>(input.size());
    }));
```

### Do Nothing

```cpp
EXPECT_CALL(mock, disconnect())
    .WillOnce(Return());  // void methods
```

### Multiple Actions in Sequence

```cpp
EXPECT_CALL(mock, query(_))
    .WillOnce(Return(1))
    .WillOnce(Return(2))
    .WillOnce(Throw(std::runtime_error("timeout")));
```

## References

- [GoogleMock for Dummies](https://google.github.io/googletest/gmock_for_dummies.html)
- [GoogleMock Cookbook](https://google.github.io/googletest/gmock_cook_book.html)
- [Matchers Reference](https://google.github.io/googletest/reference/matchers.html)
- [Actions Reference](https://google.github.io/googletest/reference/actions.html)
