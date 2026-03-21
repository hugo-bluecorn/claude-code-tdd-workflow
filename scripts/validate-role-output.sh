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

exit 0
