# ShellCheck Guide

## What is ShellCheck

ShellCheck is a static analysis tool for shell scripts. It detects common bugs,
syntax issues, and pitfalls in bash and sh scripts. It provides warnings at
multiple severity levels and suggests concrete fixes for each issue it finds.

## Basic Usage

### Checking a Single Script

```bash
shellcheck script.sh
```

ShellCheck reads the script, parses it, and prints any warnings or errors it
detects.

### Checking Multiple Files

```bash
shellcheck *.sh
```

Pass a glob or list of files to check an entire directory of scripts in one
invocation.

### Specifying the Shell Dialect

By default ShellCheck infers the shell from the shebang line. You can override
this with a command-line flag:

```bash
shellcheck --shell=bash script.sh
```

Or with a file-level directive at the top of the script:

```bash
# shellcheck shell=bash
```

## Severity Levels

ShellCheck categorizes findings into four severity levels, from most to least
severe:

| Level | Flag | Description |
|-------|------|-------------|
| **error** | `-S error` | Definite bugs that will cause incorrect behavior |
| **warning** | `-S warning` | Issues that are likely bugs or problematic patterns |
| **info** | `-S info` | Suggestions for better practices |
| **style** | `-S style` | Style and readability recommendations |

Use the `-S` flag to set the minimum severity level for reported issues:

```bash
# Only show warnings and errors
shellcheck -S warning script.sh

# Show everything including style suggestions
shellcheck -S style script.sh
```

## Common Warnings and Fixes

### SC2086 -- Double-quote to prevent globbing and word splitting

This is one of the most common warnings. Unquoted variables undergo word
splitting and filename globbing, which is almost never intended.

```bash
# Bad -- triggers SC2086
name="hello world"
echo $name

# Good -- properly quoted
name="hello world"
echo "$name"
```

### SC2046 -- Quote command substitution to prevent word splitting

Similar to SC2086 but applies to command substitution via `$(...)`.

```bash
# Bad -- triggers SC2046
files=$(find . -name "*.log")
rm $files

# Good -- use an array or loop instead
while IFS= read -r -d '' file; do
  rm "$file"
done < <(find . -name "*.log" -print0)
```

### SC2034 -- Variable appears unused

ShellCheck warns when a variable is assigned but never referenced. This often
indicates a typo in the variable name or dead code that should be removed.

```bash
# Bad -- triggers SC2034
unused_var="value"
echo "done"

# Good -- remove unused variables or export them if needed
export USED_VAR="value"
echo "$USED_VAR"
```

### SC2155 -- Declare and assign separately

Combining `local` (or `export`) with command substitution masks the exit code
of the command.

```bash
# Bad -- triggers SC2155
local output=$(my_command)

# Good -- declare and assign separately to preserve exit code
local output
output=$(my_command)
```

### SC2164 -- Use cd ... || exit in case cd fails

An unchecked `cd` can silently fail, causing subsequent commands to run in the
wrong directory.

```bash
# Bad -- triggers SC2164
cd /some/dir
rm -rf *

# Good -- handle cd failure
cd /some/dir || exit 1
rm -rf *
```

### SC2162 -- read without -r mangles backslashes

```bash
# Bad -- triggers SC2162
read line

# Good -- use -r to preserve backslashes
read -r line
```

### SC2329/SC2330 -- Function not used / not called (ShellCheck 0.11.0+)

ShellCheck 0.11.0 added warnings for functions that are defined but never
invoked within the script. SC2329 warns about the function definition and
SC2330 warns at each unused function.

```bash
# Bad -- triggers SC2329/SC2330
my_helper() {
  echo "never called"
}
echo "done"

# Good -- either call the function or remove it
my_helper() {
  echo "called below"
}
my_helper
```

Suppress if the function is invoked by a sourcing script:

```bash
# shellcheck disable=SC2329
my_exported_helper() {
  echo "called by parent script"
}
```

## ShellCheck Directives

Directives are special comments that control ShellCheck behavior for specific
lines or blocks of code.

### Disabling a Specific Warning

Use the `disable` directive to suppress a specific warning code:

```bash
# shellcheck disable=SC2086
echo $deliberately_unquoted
```

You can disable multiple codes at once:

```bash
# shellcheck disable=SC2086,SC2046
result=$(some_command $args)
```

### Specifying Source Paths

When a script sources another file, ShellCheck needs to find the sourced file
to analyze it correctly. Use the `source` directive to specify the path:

```bash
# shellcheck source=lib/utils.sh
source "$SCRIPT_DIR/lib/utils.sh"
```

Use `source=/dev/null` when the sourced file is determined at runtime and
cannot be resolved statically:

```bash
# shellcheck source=/dev/null
source "$DYNAMIC_PATH"
```

### Specifying the Shell

Set the shell dialect for the entire file:

```bash
# shellcheck shell=bash
```

This is useful for scripts that lack a shebang line or when the shebang does
not clearly indicate the shell.

## When to Suppress Warnings

### Appropriate Suppression

It is appropriate to suppress a warning when:

- The code is intentionally relying on word splitting (e.g., passing multiple
  flags stored in a variable)
- A variable is used in a sourced file that ShellCheck cannot follow
- The warning is a false positive due to dynamic code patterns

Always add a comment explaining why the suppression is necessary:

```bash
# Intentional word splitting: flags contains space-separated options
# shellcheck disable=SC2086
curl $flags "$url"
```

### Inappropriate Suppression

It is NOT appropriate to suppress a warning when:

- You do not understand what the warning means
- Suppressing is used as a shortcut to silence the linter without fixing the
  underlying issue
- The fix is straightforward (e.g., simply adding double quotes)

As a rule of thumb, fix the code rather than suppress the warning. Suppression
should be the exception, not the norm.

## Integration with TDD Workflow

ShellCheck serves the same role in bash projects that `dart analyze` or
`clang-tidy` serve in their respective ecosystems: it is the static analysis
step that runs during the TDD verification phase.

In the TDD red-green-refactor cycle, ShellCheck runs as part of the
verification step to ensure that all scripts pass static analysis before a
slice is considered complete.

### Running ShellCheck in CI / Verification

```bash
# Check all shell scripts at warning level or above
shellcheck -S warning script.sh

# Check all scripts in a directory
shellcheck -S warning src/*.sh

# Use a specific shell dialect
shellcheck --shell=bash -S warning src/*.sh
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No issues found (at the selected severity) |
| 1 | One or more issues found |
| 2 | File not found or not readable |
| 3 | ShellCheck itself encountered an error |
| 4 | Invalid options or arguments |

## Output Formats

ShellCheck supports several output formats useful for different contexts:

```bash
# Default human-readable format
shellcheck script.sh

# JSON output for tooling integration
shellcheck --format=json script.sh

# GCC-compatible format for editor integration
shellcheck --format=gcc script.sh

# Diff format showing suggested fixes
shellcheck --format=diff script.sh
```

## References

- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [ShellCheck GitHub Repository](https://github.com/koalaman/shellcheck)
- [ShellCheck Online](https://www.shellcheck.net/)
