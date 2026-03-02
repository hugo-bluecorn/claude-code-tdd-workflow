# C Static Analysis

Reference for integrating static analysis into C projects. Covers compiler
warning flags, cppcheck, clang-tidy with CERT and bug-prevention checks,
GCC's interprocedural analyzer, and compile_commands.json generation. In the
TDD workflow, static analysis serves the same verification role that
`dart analyze` plays for Dart projects and `shellcheck` plays for Bash scripts.

## Tier 1: Compiler Warning Flags

The first line of defense is the compiler itself. Both GCC and Clang support
warning flags that catch many common errors at compile time with zero
additional tooling.

### Recommended Baseline

```sh
gcc -Wall -Wextra -Werror -pedantic -std=c11 -o output source.c
```

| Flag | Purpose |
|------|---------|
| `-Wall` | Enable most common warnings (unused variables, implicit fallthrough, etc.) |
| `-Wextra` | Enable additional warnings not covered by -Wall (unused parameters, sign comparison) |
| `-Werror` | Treat all warnings as errors -- prevents warning accumulation |
| `-pedantic` | Enforce strict ISO C compliance, reject compiler extensions |

### CMake Integration

```cmake
target_compile_options(my_target PRIVATE
    -Wall -Wextra -Werror -pedantic
)
```

For debug builds that run during TDD, always enable all four flags. For
release builds, some projects relax `-Werror` to avoid blocking on
third-party header warnings.

## Tier 2: cppcheck

cppcheck is a dedicated C/C++ static analysis tool that finds bugs the
compiler cannot detect, including memory leaks, null pointer dereferences,
and buffer overflows in cross-function paths.

### Basic Usage

```sh
cppcheck --enable=all --suppress=missingIncludeSystem --error-exitcode=1 src/
```

| Option | Purpose |
|--------|---------|
| `--enable=all` | Enable all check categories (style, performance, portability, information) |
| `--suppress=missingIncludeSystem` | Suppress noise from unavailable system headers |
| `--error-exitcode=1` | Return non-zero exit code on findings (for CI gating) |

### Using a compile_commands.json

When a project uses CMake, point cppcheck at the compilation database for
accurate include paths and defines:

```sh
cppcheck --project=build/compile_commands.json --error-exitcode=1
```

This eliminates false positives caused by missing include paths or incorrect
macro definitions.

### CMake Integration

```cmake
find_program(CPPCHECK cppcheck)
if(CPPCHECK)
    set(CMAKE_C_CPPCHECK
        ${CPPCHECK}
        --enable=all
        --suppress=missingIncludeSystem
        --error-exitcode=1
    )
endif()
```

This runs cppcheck automatically during compilation on every source file.

## Tier 3: clang-tidy

clang-tidy is a clang-based linter that performs deeper semantic analysis
than cppcheck. It enforces coding standards through configurable check
families, including CERT C safety rules and bug-prevention patterns.

### Key Check Families for C

| Check prefix | Purpose |
|-------------|---------|
| `cert-*` | SEI CERT C coding standard enforcement |
| `bugprone-*` | Common bug patterns (sizeof misuse, integer division, branch clones) |
| `clang-analyzer-*` | Path-sensitive analysis from the Clang Static Analyzer |
| `readability-*` | Code clarity (naming, braces, magic numbers) |

### CERT C Checks

These map directly to the SEI CERT C rules covered in c-coding-standards.md:

```sh
clang-tidy -checks='cert-*' -p build/ src/module.c
```

Important cert- checks for C projects:

- `cert-err33-c` -- Detect unused return values from critical functions
- `cert-msc30-c` -- Do not use rand() for security-sensitive code
- `cert-str34-c` -- Cast characters to unsigned char before conversion
- `cert-err34-c` -- Detect errors from string-to-number conversion functions
- `cert-env33-c` -- Do not call system()

### Bug-Prevention Checks

Complement CERT checks with bugprone- checks that catch common C errors:

```sh
clang-tidy -checks='bugprone-*' -p build/ src/module.c
```

Important bugprone- checks:

- `bugprone-sizeof-expression` -- Suspicious sizeof usage
- `bugprone-suspicious-memory-comparison` -- Incorrect memcmp usage
- `bugprone-undefined-memory-manipulation` -- memset/memcpy on non-trivial types
- `bugprone-branch-clone` -- Identical branches in if/else
- `bugprone-integer-division` -- Integer division with float result

### Configuration File

Place a `.clang-tidy` file in the project root:

```yaml
Checks: >
  cert-*,
  bugprone-*,
  clang-analyzer-*,
  -bugprone-easily-swappable-parameters
WarningsAsErrors: ''
HeaderFilterRegex: '.*'
```

### Running clang-tidy

```sh
clang-tidy -p build/ src/*.c
```

The `-p` flag points to the directory containing `compile_commands.json`.

## Generating compile_commands.json

clang-tidy and cppcheck both work best with a compilation database that
provides the exact compiler flags, include paths, and defines for each
source file. CMake generates this file automatically.

### CMake Configuration

```sh
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

The `CMAKE_EXPORT_COMPILE_COMMANDS` option tells CMake to write
`build/compile_commands.json` during the configure step. This file is a
JSON array with one entry per source file:

```json
[
  {
    "directory": "/path/to/build",
    "command": "cc -Wall -Wextra -I/path/to/include -c source.c",
    "file": "/path/to/src/source.c"
  }
]
```

### Symlink for Editor Integration

Many editors and language servers expect `compile_commands.json` in the
project root. Create a symlink:

```sh
ln -sf build/compile_commands.json compile_commands.json
```

## Tier 4: GCC -fanalyzer

GCC 12+ includes an interprocedural static analyzer that traces execution
paths across function boundaries. It detects issues that per-function
analysis cannot find, including use-after-free across call chains and
double-free paths.

### Basic Usage

```sh
gcc -fanalyzer -Wall -Wextra -c src/module.c
```

The `-fanalyzer` flag enables the analyzer during compilation. It runs as
part of the normal build and produces diagnostics in the same format as
compiler warnings.

### What GCC -fanalyzer Finds

The analyzer excels at cross-function issues:

- Use-after-free across function call boundaries
- Double-free paths through conditional logic
- NULL pointer dereference after failed allocation checks
- File descriptor leaks (open without close on error paths)
- Buffer overflows in interprocedural paths

### CMake Integration

```cmake
if(CMAKE_C_COMPILER_ID STREQUAL "GNU" AND
   CMAKE_C_COMPILER_VERSION VERSION_GREATER_EQUAL "12")
    target_compile_options(my_target PRIVATE -fanalyzer)
endif()
```

Guard the flag behind a version check because `-fanalyzer` is not available
in GCC versions before 12 and is not supported by Clang.

### Trade-offs

GCC -fanalyzer significantly increases compilation time because it performs
interprocedural analysis. For large codebases, consider running it only in
CI rather than during every local build.

## TDD Verification Integration

In the TDD workflow, static analysis runs during the verification phase
after tests pass. The four-tier stack serves the same role as `dart analyze`
for Dart or `shellcheck` for Bash -- catching bugs that tests alone miss.

### Recommended Verification Sequence

1. Compiler warnings (`-Wall -Wextra -Werror -pedantic`) -- every build
2. cppcheck -- every build or pre-commit
3. clang-tidy (`cert-*`, `bugprone-*`) -- every build or pre-commit
4. GCC `-fanalyzer` -- CI only (slow on large codebases)

### Gating Builds

All four tools can return non-zero exit codes on findings, making them
suitable for CI gate checks. A failing static analysis check should block
the build just like a failing test.

## References

- GCC warning options: https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
- cppcheck manual: https://cppcheck.sourceforge.io/manual.html
- clang-tidy checks: https://clang.llvm.org/extra/clang-tidy/checks/list.html
- GCC Static Analyzer: https://gcc.gnu.org/onlinedocs/gcc/Static-Analyzer-Options.html
- C static analyzer comparison: https://nrk.neocities.org/articles/c-static-analyzers
