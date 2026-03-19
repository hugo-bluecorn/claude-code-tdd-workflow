#!/bin/bash
# Detects project type from current directory and outputs relevant convention
# content from cached convention repos. Called via !`cmd` DCI in SKILL.md.
#
# Environment:
#   CLAUDE_PLUGIN_DATA — path to plugin data directory containing
#     conventions/<repo-name>/<skill-dir>/ structure
#
# Config file (optional):
#   .claude/tdd-conventions.json — {"conventions": ["url_or_path", ...]}
#   Local paths are used directly; URLs resolve to cache paths.
#   Falls back to CLAUDE_PLUGIN_DATA/conventions/ when no config exists.
#
# Output: Convention SKILL.md and reference/*.md content to stdout

set -euo pipefail

# Set cache root (empty if CLAUDE_PLUGIN_DATA is unset — config local paths still work)
conventions_root=""
if [ -n "${CLAUDE_PLUGIN_DATA:-}" ]; then
  conventions_root="${CLAUDE_PLUGIN_DATA}/conventions"
fi

# ---------- Helpers ----------

# Returns 0 if any files matching the glob pattern exist (excluding .git/)
has_files() {
  local pattern="$1"
  [ "$(find . -name "$pattern" -not -path "./.git/*" 2>/dev/null | head -1 | wc -l)" -gt 0 ]
}

# Output convention content for a skill directory; returns 0 if content found
output_skill() {
  local skill_dir="$1"
  [ -d "$skill_dir" ] || return 1

  local found=false

  if [ -f "$skill_dir/SKILL.md" ]; then
    cat "$skill_dir/SKILL.md"
    found=true
  fi

  if [ -d "$skill_dir/reference" ]; then
    for ref_file in "$skill_dir/reference/"*.md; do
      [ -f "$ref_file" ] || continue
      echo ""
      cat "$ref_file"
      found=true
    done
  fi

  [ "$found" = true ]
}

# Populate convention_roots from cache directory subdirectories
scan_cache_roots() {
  [ -d "$conventions_root" ] || return 0
  for repo_dir in "$conventions_root"/*/; do
    [ -d "$repo_dir" ] || continue
    convention_roots+=("${repo_dir%/}")
  done
}

# ---------- Detect project types ----------

declare -a skills=()

# Dart/Flutter: pubspec.yaml
if [ -f "pubspec.yaml" ]; then
  skills+=("dart-flutter-conventions")
fi

# C++: CMakeLists.txt with .cpp source files
if [ -f "CMakeLists.txt" ] && has_files "*.cpp"; then
  skills+=("cpp-testing-conventions")
fi

# Bash: _test.sh files or .bashunit.yml
if [ -f ".bashunit.yml" ] || has_files "*_test.sh"; then
  skills+=("bash-testing-conventions")
fi

# C: .c source files
if has_files "*.c"; then
  skills+=("c-conventions")
fi

# Exit if no project types detected
if [ ${#skills[@]} -eq 0 ]; then
  exit 0
fi

# ---------- Resolve convention source directories ----------

declare -a convention_roots=()
config_file=".claude/tdd-conventions.json"

if [ -f "$config_file" ]; then
  # Try to parse config; fall back to cache on failure
  if sources=$(jq -r '.conventions[]?' "$config_file" 2>/dev/null) && [ -n "$sources" ]; then
    while IFS= read -r source; do
      [ -n "$source" ] || continue

      if [[ "$source" == http://* ]] || [[ "$source" == https://* ]]; then
        # URL: extract repo name, resolve to cache path
        repo_name=$(basename "$source" .git)
        cache_path="${conventions_root}/${repo_name}"
        [ -d "$cache_path" ] && convention_roots+=("$cache_path")
      elif [ -d "$source" ]; then
        # Local path: use directly
        convention_roots+=("$source")
      fi
      # Nonexistent paths are skipped silently
    done <<< "$sources"
  else
    # Malformed JSON or empty conventions: fall back to cache
    scan_cache_roots
  fi
else
  # No config file: fall back to scanning cache
  scan_cache_roots
fi

# Exit if no convention roots resolved
if [ ${#convention_roots[@]} -eq 0 ]; then
  exit 0
fi

# ---------- Output convention content ----------

output_generated=false

for root in "${convention_roots[@]}"; do
  for skill in "${skills[@]}"; do
    if output_skill "${root}/${skill}"; then
      output_generated=true
    fi
  done
done

if [ "$output_generated" = false ]; then
  exit 0
fi
