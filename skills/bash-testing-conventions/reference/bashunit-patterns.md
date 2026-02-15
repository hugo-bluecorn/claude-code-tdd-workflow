# bashunit Patterns

## Test Structure

bashunit discovers test functions by the `test_` prefix. Each function whose
name begins with `test_` is treated as an individual test case. Tests are
grouped per file -- one file acts as one test suite.

```bash
#!/bin/bash

function test_addition_returns_correct_sum() {
  local result
  result=$(( 2 + 3 ))

  assert_equals "5" "$result"
}

function test_string_contains_substring() {
  local haystack="hello world"

  assert_contains "world" "$haystack"
}
```

## Assertions

### Equality

```bash
assert_equals "expected" "$actual"       # Ignores ANSI codes / special chars
assert_same "expected" "$actual"         # Exact match including special chars
assert_not_same "unexpected" "$actual"
```

### String Assertions

```bash
assert_contains "needle" "$haystack"
assert_not_contains "needle" "$haystack"
assert_contains_ignore_case "needle" "$haystack"
assert_matches "^[0-9]+$" "$value"
assert_not_matches "pattern" "$value"
assert_string_starts_with "prefix" "$haystack"
assert_string_ends_with "suffix" "$haystack"
assert_empty "$value"
assert_not_empty "$value"
assert_line_count "3" "$multiline_output"
```

### Numeric Assertions

```bash
assert_less_than "10" "$actual"
assert_less_or_equal_than "10" "$actual"
assert_greater_than "0" "$actual"
assert_greater_or_equal_than "1" "$actual"
```

### Exit Code Assertions

```bash
my_command
assert_exit_code "0"               # Check exact exit code of previous command

my_command
assert_successful_code             # Exit code == 0

failing_command || true
assert_unsuccessful_code           # Exit code != 0

bad_command
assert_general_error               # Exit code == 1

nonexistent_command
assert_command_not_found           # Exit code == 127
```

### Command Execution Assertion

```bash
assert_exec "ls /tmp" --exit 0 --stdout "some_file"
assert_exec "false" --exit 1
assert_exec "echo hello" --stdout "hello"
```

### File and Directory Assertions

```bash
assert_file_exists "path/to/file"
assert_file_not_exists "path/to/file"
assert_file_contains "path/to/file" "search string"
assert_file_not_contains "path/to/file" "unwanted"
assert_is_file "path/to/file"
assert_is_file_empty "path/to/file"
assert_files_equals "expected_file" "actual_file"

assert_directory_exists "path/to/dir"
assert_directory_not_exists "path/to/dir"
assert_is_directory "path/to/dir"
assert_is_directory_empty "path/to/dir"
assert_is_directory_not_empty "path/to/dir"
assert_is_directory_readable "path/to/dir"
assert_is_directory_writable "path/to/dir"
```

### Array Assertions

```bash
local -a fruits=("apple" "banana" "cherry")
assert_array_contains "banana" "${fruits[@]}"
assert_array_not_contains "grape" "${fruits[@]}"
```

### Manual Failure

```bash
bashunit::fail "Custom failure message explaining what went wrong"
```

## Test Fixtures (Setup and Teardown)

bashunit provides four lifecycle hooks that run at different scopes.

### Per-Test Hooks

`set_up` runs before every `test_` function in the file.
`tear_down` runs after every `test_` function in the file.

```bash
#!/bin/bash

TEMP_FILE=""

function set_up() {
  TEMP_FILE=$(mktemp)
  echo "initial content" > "$TEMP_FILE"
}

function tear_down() {
  rm -f "$TEMP_FILE"
}

function test_file_has_initial_content() {
  assert_file_contains "$TEMP_FILE" "initial content"
}

function test_file_can_be_appended() {
  echo "extra" >> "$TEMP_FILE"
  assert_file_contains "$TEMP_FILE" "extra"
}
```

### Per-Script Hooks

`set_up_before_script` runs once before all tests in the file.
`tear_down_after_script` runs once after all tests in the file.

```bash
#!/bin/bash

TEST_DIR=""

function set_up_before_script() {
  TEST_DIR=$(mktemp -d)
  # Expensive one-time setup: create fixtures, start services, etc.
}

function tear_down_after_script() {
  rm -rf "$TEST_DIR"
  # One-time cleanup after all tests complete
}

function test_directory_was_created() {
  assert_directory_exists "$TEST_DIR"
}

function test_directory_is_writable() {
  assert_is_directory_writable "$TEST_DIR"
}
```

### Combining All Four Hooks

```bash
#!/bin/bash

DB_FILE=""
QUERY_RESULT=""

function set_up_before_script() {
  DB_FILE=$(mktemp)
  echo "id,name" > "$DB_FILE"
}

function set_up() {
  QUERY_RESULT=""
}

function tear_down() {
  QUERY_RESULT=""
}

function tear_down_after_script() {
  rm -f "$DB_FILE"
}

function test_db_file_exists() {
  assert_file_exists "$DB_FILE"
}
```

## Running Tests

### Run a Single Test File

```bash
bashunit test/path_test.sh
```

### Run All Tests in a Directory

```bash
bashunit test/
```

### Run a Specific Test by Name

Use the `--filter` flag to match test function names:

```bash
bashunit --filter "test_addition" test/math_test.sh
```

### Parallel Execution

```bash
bashunit test/ --parallel
```

### Simple Output (Dots)

```bash
bashunit test/ --simple
```

### Stop on First Failure

```bash
bashunit test/ --stop-on-failure
```

### Verbose Mode

```bash
bashunit test/ --verbose
```

## Test File Naming Convention

Test files must end with the `_test.sh` suffix. bashunit auto-discovers files
matching the `*_test.sh` glob when you pass a directory.

Examples:
- `math_test.sh`
- `string_utils_test.sh`
- `integration_api_test.sh`

## File Organization

Mirror the source directory structure inside a `test/` directory. Each source
script gets a corresponding test file with the `_test.sh` suffix.

```
project/
├── src/
│   ├── math.sh
│   ├── string_utils.sh
│   └── api/
│       └── client.sh
├── test/
│   ├── math_test.sh
│   ├── string_utils_test.sh
│   └── api/
│       └── client_test.sh
└── lib/
    └── bashunit
```

## Test Naming Convention

Test function names use `snake_case` and should describe the scenario and
expected behavior:

```
test_<unit>_<scenario>_<expected_behavior>
```

Examples:

```bash
function test_add_two_positive_numbers_returns_sum() { ... }
function test_parse_empty_input_returns_error() { ... }
function test_config_missing_file_uses_defaults() { ... }
```

## Bash Naming Reference

| Element | Style | Example |
|---------|-------|---------|
| Files | `snake_case` | `my_script.sh`, `string_utils.sh` |
| Test files | `snake_case` + `_test.sh` | `my_script_test.sh` |
| Functions | `snake_case` | `get_value()`, `calculate_total()` |
| Test functions | `test_` + `snake_case` | `test_get_value_returns_number()` |
| Local variables | `snake_case` | `local file_path`, `local item_count` |
| Global variables | `UPPER_SNAKE_CASE` | `TEMP_DIR`, `CONFIG_FILE` |
| Constants | `UPPER_SNAKE_CASE` + `readonly` | `readonly MAX_RETRIES=3` |

## References

- [bashunit Documentation](https://bashunit.typeddevs.com/)
- [bashunit GitHub](https://github.com/TypedDevs/bashunit)
- [bashunit Assertion Reference](https://bashunit.typeddevs.com/assertions)
