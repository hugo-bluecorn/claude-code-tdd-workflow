#!/bin/bash
# Propagates a version string into all version-bearing files in the current directory.
# Usage: bump-version.sh <version>
# Outputs the list of updated files to stdout.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: bump-version.sh <version>" >&2
  exit 1
fi

VERSION="$1"
updated=()

# pubspec.yaml (Dart/Flutter)
if [[ -f "pubspec.yaml" ]]; then
  sed -i "s/^version: .*/version: $VERSION/" pubspec.yaml
  updated+=("pubspec.yaml")
fi

# package.json (Node.js)
if [[ -f "package.json" ]]; then
  sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" package.json
  updated+=("package.json")
fi

# .claude-plugin/plugin.json (Claude plugin)
if [[ -f ".claude-plugin/plugin.json" ]]; then
  sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" .claude-plugin/plugin.json
  updated+=(".claude-plugin/plugin.json")
fi

# Cargo.toml (Rust) — only the first version line (in [package] section)
if [[ -f "Cargo.toml" ]]; then
  sed -i "0,/^version = \"[^\"]*\"/s/^version = \"[^\"]*\"/version = \"$VERSION\"/" Cargo.toml
  updated+=("Cargo.toml")
fi

# pyproject.toml (Python)
if [[ -f "pyproject.toml" ]]; then
  sed -i "s/^version = \"[^\"]*\"/version = \"$VERSION\"/" pyproject.toml
  updated+=("pyproject.toml")
fi

# CMakeLists.txt (C/C++)
if [[ -f "CMakeLists.txt" ]]; then
  sed -i "s/\(project([^ ]* VERSION \)[^ )]*/\1$VERSION/" CMakeLists.txt
  updated+=("CMakeLists.txt")
fi

# Report results
if [[ ${#updated[@]} -eq 0 ]]; then
  echo "no version files found — no files updated." >&2
  exit 0
fi

for file in "${updated[@]}"; do
  echo "Updated: $file"
done
