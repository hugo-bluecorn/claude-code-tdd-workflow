#!/bin/bash
# Validates role file structure and content.
# Usage: validate-role-output.sh <role-file-path>

FILE_PATH="${1:-}"

# Check argument provided
if [ -z "$FILE_PATH" ]; then
  echo "Usage: validate-role-output.sh <role-file-path>" >&2
  exit 1
fi

# Check file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "File not found: $FILE_PATH" >&2
  exit 1
fi

# Check for frontmatter delimiters
first_line=$(head -1 "$FILE_PATH")

if [ "$first_line" != "---" ]; then
  echo "Missing frontmatter: file must begin with --- delimiters" >&2
  exit 1
fi

# Extract frontmatter block (between first and second ---)
frontmatter=$(sed -n '2,/^---$/p' "$FILE_PATH" | sed '$d')

if [ -z "$frontmatter" ]; then
  echo "Missing frontmatter: no closing --- delimiter found" >&2
  exit 1
fi

# Validate required fields
missing=""
echo "$frontmatter" | grep -qE '^role:' || missing="$missing role"
echo "$frontmatter" | grep -qE '^name:' || missing="$missing name"
echo "$frontmatter" | grep -qE '^type:' || missing="$missing type"

if [ -n "$missing" ]; then
  echo "Missing required frontmatter fields:$missing" >&2
  exit 1
fi

# Check for Identity section (any heading level)
if ! grep -qE '^#{1,6} Identity' "$FILE_PATH"; then
  echo "Missing required section: Identity" >&2
  exit 1
fi

# Check line count does not exceed 400
line_count=$(wc -l < "$FILE_PATH")
if [ "$line_count" -gt 400 ]; then
  echo "File exceeds 400 lines (has $line_count lines)" >&2
  exit 1
fi

# Extract body (everything after closing frontmatter delimiter)
body=$(sed -n '/^---$/,$ p' "$FILE_PATH" | tail -n +2)

# Strip fenced code blocks from body for placeholder scanning
body_no_code=$(echo "$body" | awk '/^```/{skip=!skip; next} !skip{print}')

# Check for {placeholder} patterns in body (outside code blocks)
if echo "$body_no_code" | grep -qE '\{[a-zA-Z_][a-zA-Z0-9_]*\}'; then
  echo "Unresolved placeholder found in body (e.g., {word} pattern)" >&2
  exit 1
fi

# Check for TODO in body (outside code blocks)
if echo "$body_no_code" | grep -q 'TODO'; then
  echo "TODO found in body — all sections must be complete" >&2
  exit 1
fi

# Check for TBD in body (outside code blocks)
if echo "$body_no_code" | grep -q 'TBD'; then
  echo "TBD found in body — all sections must be complete" >&2
  exit 1
fi

# Constraint validation (only when Constraints section exists)
if grep -qE '^#{1,6} Constraints' "$FILE_PATH"; then
  # Extract constraints section: from Constraints heading to EOF,
  # then remove everything from the next heading onward
  constraints_section=$(sed -nE '/^#{1,6} Constraints/,$ p' "$FILE_PATH")
  # Remove the Constraints heading itself, then stop at next heading
  constraints_body=$(echo "$constraints_section" | tail -n +2 | sed -nE '/^#{1,6} /q; p')

  # Check for permission-phrased constraints ("Do <verb>" but not "Do not")
  if echo "$constraints_body" | grep -qE '^Do [^n]'; then
    echo "Constraint uses permission phrasing (\"Do ...\") — use prohibition phrasing (\"Never\", \"Do not\", \"Only\")" >&2
    exit 1
  fi

  # Check that constraint lines have consequences
  # Constraint lines start with **Never**, **Do not**, or **Only**
  constraint_lines=$(echo "$constraints_body" | grep -E '^\*\*(Never|Do not|Only)\*\*')
  if [ -n "$constraint_lines" ]; then
    # Process constraints body line by line, tracking constraint/consequence pairs
    prev_constraint=""
    while IFS= read -r line; do
      if echo "$line" | grep -qE '^\*\*(Never|Do not|Only)\*\*'; then
        # If there was a previous constraint without consequence, fail
        if [ -n "$prev_constraint" ]; then
          echo "Constraint lacks consequence: $prev_constraint" >&2
          exit 1
        fi
        # Check for consequence on same line (text after first period)
        after_period="${line#*.}"
        trimmed=$(echo "$after_period" | tr -d '[:space:]')
        if [ -n "$trimmed" ]; then
          # Consequence on same line — clear
          prev_constraint=""
        else
          # No consequence on same line — need it on next line
          prev_constraint="$line"
        fi
      else
        # Non-constraint line: if we're waiting for a consequence, check it
        if [ -n "$prev_constraint" ]; then
          strimmed=$(echo "$line" | tr -d '[:space:]')
          if [ -n "$strimmed" ]; then
            # Found consequence on next line
            prev_constraint=""
          fi
        fi
      fi
    done <<< "$constraints_body"

    # Check if last constraint had no consequence
    if [ -n "$prev_constraint" ]; then
      echo "Constraint lacks consequence: $prev_constraint" >&2
      exit 1
    fi
  fi
fi

exit 0
