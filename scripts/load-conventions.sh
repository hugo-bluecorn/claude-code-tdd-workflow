#!/bin/bash
# Emits the active convention pack's standards content for the current project.
# Called via !`cmd` DCI in SKILL.md (invoked with the project as the working dir).
#
# Resolution is DATA-DRIVEN via the R1 foundation (scripts/active-pack.sh):
#   1. PACK track (primary): active-pack.sh resolves the active pack dir(s) for
#      the project from the committed binding ($TDD_ACTIVE_PACK fast-path or
#      .claude/tdd-conventions.json), using each pack's declared detect data.
#      For every resolved pack we emit its standards content -- the location is
#      DERIVED from the pack manifest (standards.index + standards.dir), never a
#      hardcoded skill dirname. This replaces the four legacy literal-dirname
#      detection blocks (dart-flutter / cpp-testing / bash-testing / c).
#   2. LEGACY cache-scan fallback (preserved): if no pack resolves -- e.g. the
#      configured conventions repo is the historical SKILL.md layout with no
#      pack.json, or a malformed binding leaves no candidates -- fall back to the
#      original detect-by-marker + scan-the-cache behavior so existing
#      pack-less convention repos keep delivering content.
#
# Environment:
#   CLAUDE_PLUGIN_DATA — plugin data dir; conventions cache lives under
#     $CLAUDE_PLUGIN_DATA/conventions/<repo-name>/<skill-dir>/ (legacy fallback).
#   TDD_ACTIVE_PACK — optional in-session fast-path honored by active-pack.sh.
#
# Config file (optional, legacy fallback only):
#   .claude/tdd-conventions.json — {"conventions": ["url_or_path", ...]}
#
# Output: convention standards content (index + reference docs) to stdout.
# Degrade contract: no pack, no detected type, malformed binding, or missing
# cache all yield empty stdout and exit 0 -- never abort the caller (PRIME-safe;
# a pack-less bash project still works via the built-in bashunit default).
#
# This is a pure data accessor: it never references or requires any role file.

set -uo pipefail

# The project / working dir. DCI invokes this script with cwd = the project.
project_dir="$PWD"

# Sibling scripts live beside this one.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
active_pack="${script_dir}/active-pack.sh"
read_pack="${script_dir}/read-pack.sh"

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

# Emit a single pack's standards content (PACK track). The index file and the
# standards dir are read from the pack manifest -- the location is data-driven,
# not a hardcoded skill dirname. Returns 0 if any content was emitted.
output_pack_standards() {
  local pack_dir="$1"
  [ -d "$pack_dir" ] || return 1

  local index_rel dir_rel found=false
  index_rel="$(bash "$read_pack" "$pack_dir" standards.index 2>/dev/null || true)"
  dir_rel="$(bash "$read_pack" "$pack_dir" standards.dir 2>/dev/null || true)"

  # Emit the declared index file (e.g. SKILL.md), if present.
  if [ -n "$index_rel" ] && [ -f "${pack_dir%/}/${index_rel}" ]; then
    cat "${pack_dir%/}/${index_rel}"
    found=true
  fi

  # Emit every markdown doc under the declared standards dir, if present.
  if [ -n "$dir_rel" ] && [ -d "${pack_dir%/}/${dir_rel}" ]; then
    local ref_file
    for ref_file in "${pack_dir%/}/${dir_rel%/}/"*.md; do
      [ -f "$ref_file" ] || continue
      echo ""
      cat "$ref_file"
      found=true
    done
  fi

  [ "$found" = true ]
}

# Output convention content for a legacy skill directory (FALLBACK track);
# returns 0 if content found.
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

# ---------- 1. PACK track: data-driven resolution via the foundation ----------

pack_output_generated=false
while IFS= read -r pack_dir; do
  [ -n "$pack_dir" ] || continue
  if output_pack_standards "$pack_dir"; then
    pack_output_generated=true
  fi
done < <(bash "$active_pack" "$project_dir" 2>/dev/null)

# A resolved pack delivered content -> done (data-driven path satisfied).
if [ "$pack_output_generated" = true ]; then
  exit 0
fi

# ---------- 2. LEGACY cache-scan fallback ----------
# No pack resolved (pack-less conventions repo, no binding, or malformed
# binding). Fall back to the historical detect-by-marker + scan-the-cache
# behavior so existing SKILL.md-layout convention repos keep delivering content.

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
