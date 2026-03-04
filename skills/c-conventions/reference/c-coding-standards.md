# C Coding Standards

Reference for writing safe, readable C code. Based on BARR-C:2018 for style
and bug prevention, and SEI CERT C for security and correctness. Includes
mappings to clang-tidy checks for automated enforcement.

## BARR-C:2018 Naming Conventions

BARR-C:2018 mandates consistent naming to prevent bugs caused by ambiguity.

### Identifiers

Use `snake_case` for all function names, variable names, and file names:

```c
/* functions */
void sensor_read_value(void);
int  buffer_get_count(const buffer_t *p_buf);

/* local variables */
int  sample_count = 0;
char file_name[MAX_PATH];
```

### Prefixes

BARR-C requires prefixes to distinguish scope and type at a glance:

| Prefix | Meaning | Example |
|--------|---------|---------|
| `g_`   | Global variable | `g_system_state` |
| `p_`   | Pointer parameter or variable | `p_data`, `p_next` |
| `pp_`  | Pointer-to-pointer | `pp_node` |

Module-level static variables use the module name as a prefix:

```c
static int sensor_reading_count = 0;  /* module-scoped, no g_ */
int g_error_count = 0;                /* true global, uses g_ */
```

### Type Names

Typedef names use a `_t` suffix. Struct tags mirror the typedef without
the suffix:

```c
typedef struct buffer {
    uint8_t *p_data;
    size_t   length;
} buffer_t;
```

## BARR-C:2018 Formatting Rules

### Brace Style

Opening brace on the same line as the control statement. Closing brace on
its own line. Always use braces, even for single-statement bodies:

```c
if (count > 0) {
    process_item();
}

for (int i = 0; i < count; i++) {
    buffer_add(p_buf, data[i]);
}
```

### Indentation

Use 4 spaces per indentation level. Never use tabs.

### Line Length

Limit lines to 80 characters. Break long function calls after a comma:

```c
result = calculate_checksum(
    p_buffer,
    buffer_length,
    CHECKSUM_CRC32
);
```

## BARR-C:2018 Function Rules

### Single Return Point

Each function should have a single return statement at the end. Use a
result variable to accumulate the return value:

```c
int parser_validate(const char *p_input)
{
    int result = PARSER_OK;

    if (p_input == NULL) {
        result = PARSER_ERR_NULL;
    } else if (strlen(p_input) == 0) {
        result = PARSER_ERR_EMPTY;
    }

    return result;
}
```

### Function Length

Keep functions under 75 lines (excluding comments). If a function is
longer, extract helper functions.

### Const Parameters

Mark pointer parameters as `const` when the function does not modify the
pointed-to data:

```c
size_t buffer_get_length(const buffer_t *p_buf);
int    string_compare(const char *p_str1, const char *p_str2);
```

## Fixed-Width Integer Types

Always use fixed-width integers from `stdint.h` instead of bare `int`,
`short`, or `long`. This eliminates platform-dependent size ambiguity:

```c
#include <stdint.h>

uint8_t  register_value;     /* exactly 8 bits, unsigned  */
int16_t  temperature;        /* exactly 16 bits, signed   */
int32_t  sample_reading;     /* exactly 32 bits, signed   */
uint64_t timestamp_us;       /* exactly 64 bits, unsigned */
```

Use `size_t` for array indices and sizes. Use `bool` from `stdbool.h`
for boolean values.

## SEI CERT C Priority Rules

SEI CERT C defines rules to prevent undefined behavior, security
vulnerabilities, and common programming errors in C. The following
categories are highest priority for code review and automated analysis.

### MEM -- Memory Management

Prevent use-after-free, double-free, and memory leaks:

- MEM30-C: Do not access freed memory
- MEM31-C: Free dynamically allocated memory when no longer needed
- MEM33-C: Allocate and copy structures with flexible array members dynamically
- MEM34-C: Only free memory allocated dynamically
- MEM35-C: Allocate sufficient memory for an object

After freeing a pointer, set it to NULL immediately:

```c
free(p_data);
p_data = NULL;
```

### INT -- Integer Overflow and Conversion

Prevent undefined behavior from integer overflow and narrowing conversions:

- INT30-C: Ensure unsigned integer operations do not wrap
- INT31-C: Ensure integer conversions do not result in lost or misinterpreted data
- INT32-C: Ensure signed integer operations do not result in overflow
- INT33-C: Ensure division and remainder operations do not result in divide-by-zero

Validate arithmetic before performing it:

```c
if (a > INT32_MAX - b) {
    /* overflow would occur */
    return ERR_OVERFLOW;
}
int32_t sum = a + b;
```

### STR -- String Handling

Prevent buffer overflows and off-by-one errors in string operations:

- STR31-C: Guarantee that storage for strings has sufficient space
- STR32-C: Do not pass a non-null-terminated character sequence to a library function
- STR34-C: Cast characters to unsigned char before converting to larger integer sizes
- STR38-C: Do not confuse narrow and wide character strings

Use `snprintf` instead of `sprintf`:

```c
char msg[64];
snprintf(msg, sizeof(msg), "value: %d", reading);
```

### ARR -- Array Bounds

Prevent out-of-bounds reads and writes:

- ARR30-C: Do not form or use out-of-bounds pointers or array subscripts
- ARR32-C: Ensure size arguments for variable length arrays are in a valid range
- ARR37-C: Do not add or subtract an integer to a pointer to a non-array object
- ARR38-C: Guarantee that library functions do not form invalid pointers
- ARR39-C: Do not add or subtract a scaled integer to a pointer

Always check array indices before access:

```c
if (index < array_size) {
    value = data[index];
}
```

## Mapping Rules to clang-tidy Checks

clang-tidy provides automated enforcement of CERT C and bug-prevention
rules. Enable these check groups in your `.clang-tidy` configuration:

### CERT C Checks

| clang-tidy Check | Rule | Description |
|------------------|------|-------------|
| `cert-err33-c` | ERR33-C | Detect unused return values from critical functions |
| `cert-msc30-c` | MSC30-C | Do not use the rand() function |
| `cert-str34-c` | STR34-C | Cast characters to unsigned char |
| `cert-err34-c` | ERR34-C | Detect errors from conversion functions |
| `cert-flp30-c` | FLP30-C | Do not use floating-point variables as loop counters |
| `cert-env33-c` | ENV33-C | Do not call system() |

### Bug-Prevention Checks

Complement CERT checks with bugprone-* checks that catch common C errors:

| clang-tidy Check | Description |
|------------------|-------------|
| `bugprone-sizeof-expression` | Suspicious sizeof usage |
| `bugprone-suspicious-memory-comparison` | Incorrect memcmp usage |
| `bugprone-undefined-memory-manipulation` | memset/memcpy on non-trivial types |
| `bugprone-branch-clone` | Identical branches in if/else |
| `bugprone-integer-division` | Integer division with float result |

### Minimal .clang-tidy Configuration

```yaml
Checks: >
  cert-*,
  bugprone-*,
  -bugprone-easily-swappable-parameters
WarningsAsErrors: ''
HeaderFilterRegex: '.*'
```

## References

- BARR-C:2018 Embedded C Coding Standard: https://barrgroup.com/embedded-systems/books/embedded-c-coding-standard/
- SEI CERT C Coding Standard: https://wiki.sei.cmu.edu/confluence/display/c/
- clang-tidy CERT checks: https://clang.llvm.org/extra/clang-tidy/checks/list.html
