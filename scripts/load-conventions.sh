#!/bin/bash
# Detects project type from current directory and outputs relevant convention
# content from cached convention repos. Called via !`cmd` DCI in SKILL.md.
#
# Environment:
#   CLAUDE_PLUGIN_DATA — path to plugin data directory containing
#     conventions/<repo-name>/<skill-dir>/ structure
#
# Output: Convention SKILL.md and reference/*.md content to stdout

set -euo pipefail

# Exit gracefully if CLAUDE_PLUGIN_DATA is not set
if [ -z "${CLAUDE_PLUGIN_DATA:-}" ]; then
  exit 0
fi

conventions_root="${CLAUDE_PLUGIN_DATA}/conventions"

# Exit gracefully if conventions directory doesn't exist
if [ ! -d "$conventions_root" ]; then
  exit 0
fi

# ---------- Detect project types ----------

detect_dart=false
detect_cpp=false
detect_bash=false
detect_c=false

# Dart/Flutter: pubspec.yaml
if [ -f "pubspec.yaml" ]; then
  detect_dart=true
fi

# C++: CMakeLists.txt with .cpp source files
if [ -f "CMakeLists.txt" ]; then
  cpp_count=$(find . -name "*.cpp" -not -path "./.git/*" 2>/dev/null | head -1 | wc -l)
  if [ "$cpp_count" -gt 0 ]; then
    detect_cpp=true
  fi
fi

# Bash: _test.sh files or .bashunit.yml
if [ -f ".bashunit.yml" ]; then
  detect_bash=true
else
  bash_count=$(find . -name "*_test.sh" -not -path "./.git/*" 2>/dev/null | head -1 | wc -l)
  if [ "$bash_count" -gt 0 ]; then
    detect_bash=true
  fi
fi

# C: .c source files
c_count=$(find . -name "*.c" -not -path "./.git/*" 2>/dev/null | head -1 | wc -l)
if [ "$c_count" -gt 0 ]; then
  detect_c=true
fi

# ---------- Map detected types to convention directory names ----------

declare -a skills=()

if [ "$detect_dart" = true ]; then
  skills+=("dart-flutter-conventions")
fi
if [ "$detect_cpp" = true ]; then
  skills+=("cpp-testing-conventions")
fi
if [ "$detect_bash" = true ]; then
  skills+=("bash-testing-conventions")
fi
if [ "$detect_c" = true ]; then
  skills+=("c-conventions")
fi

# Exit if no project types detected
if [ ${#skills[@]} -eq 0 ]; then
  exit 0
fi

# ---------- Output convention content ----------

output_generated=false

# Search all subdirectories under conventions/ (supports multiple repos)
for repo_dir in "$conventions_root"/*/; do
  [ -d "$repo_dir" ] || continue

  for skill in "${skills[@]}"; do
    skill_dir="${repo_dir}${skill}"
    [ -d "$skill_dir" ] || continue

    # Output SKILL.md
    if [ -f "$skill_dir/SKILL.md" ]; then
      cat "$skill_dir/SKILL.md"
      output_generated=true
    fi

    # Output all reference/*.md files
    if [ -d "$skill_dir/reference" ]; then
      for ref_file in "$skill_dir/reference/"*.md; do
        [ -f "$ref_file" ] || continue
        echo ""
        cat "$ref_file"
        output_generated=true
      done
    fi
  done
done

# Ensure clean exit even if no output was generated
if [ "$output_generated" = false ]; then
  exit 0
fi
