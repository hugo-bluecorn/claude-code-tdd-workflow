#!/bin/bash
# Detects project context for tdd-plan SKILL.md dynamic injection.
# Called via ! backtick preprocessing. Outputs key=value lines.

# Test runner
if command -v flutter >/dev/null 2>&1; then
  echo "test_runner=flutter test"
elif command -v dart >/dev/null 2>&1; then
  echo "test_runner=dart test"
else
  echo "test_runner=not detected"
fi

# Test file count
COUNT=$(find . \( -name "*_test.dart" -o -name "*_test.cpp" -o -name "*_test.sh" \) 2>/dev/null | wc -l | tr -d ' ')
echo "test_count=$COUNT"

# Current branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "branch=$BRANCH"

# Uncommitted changes
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
echo "dirty_files=$DIRTY"

# FVM detection
if [ -f ".fvmrc" ] && command -v fvm >/dev/null 2>&1; then
  echo "fvm=yes (use fvm flutter)"
else
  echo "fvm=no"
fi
