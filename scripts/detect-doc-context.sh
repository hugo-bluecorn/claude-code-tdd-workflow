#!/bin/bash
# Detects documentation context for tdd-finalize-docs SKILL.md dynamic injection.
# Called via ! backtick preprocessing. Outputs key=value lines.

# README.md
if [ -f "README.md" ]; then
  echo "readme=README.md"
fi

# CLAUDE.md
if [ -f "CLAUDE.md" ]; then
  echo "claude_md=CLAUDE.md"
fi

# CHANGELOG.md
if [ -f "CHANGELOG.md" ]; then
  echo "changelog=CHANGELOG.md"
fi

# docs/ directory with .md files
if [ -d "docs" ]; then
  doc_files=$(find docs -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort | tr '\n' ',')
  doc_files="${doc_files%,}"  # remove trailing comma
  if [ -n "$doc_files" ]; then
    echo "docs_dir=docs"
    echo "doc_files=$doc_files"
  fi
fi
