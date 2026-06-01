#!/bin/bash
# SessionStart hook: fetches/refreshes convention packs into a local cache.
# NEVER blocks session start — always exits 0.
#
# Binding source: <project>/.claude/tdd-conventions.json, parsed via Slice 2's
# scripts/parse-binding.sh into TAB tuples "<source>\t<version>\t<dev>".
#
# Three cases per tuple (mirrors parse-binding's normalization):
#   1. dev marker present ("dev")        -> LOCAL pack, skip fetch entirely.
#   2. version == "legacy"               -> LEGACY behavior (back-compat):
#        fetchable source (http(s)://, file://) -> clone/pull conventions/<repo>
#        bare local path (no scheme)            -> skip (no fetch).
#   3. real version (any other value)    -> VERSIONED resolve:
#        cache key  conventions/<repo>@<version> (version is part of the key, so
#        upgrades never clobber). Scheme-less sources (e.g. github.com/org/pack,
#        per §8.6) are normalized to https://<source>; file:// and https:// clone
#        as-is. Clone the source then check out the tag (git clone --branch). A
#        pinned tag already cached is idempotent (tags are immutable — no pull).
#
# repo_name = basename(source) with a trailing ".git" stripped.
#
# Preserves the legacy guards: CLAUDE_PLUGIN_DATA unset -> exit 0; no config ->
# exit 0; failures log to stderr but never block. This hook does NOT reference,
# check for, or require any role file.
#
# C3 no-pack warn-and-proceed floor: after resolving, if a NON-bash language
# marker is present in the project but NO active pack resolved for it, emit an
# advisory to stderr naming the language and PROCEED (never block, no fallback
# command). bashunit stays the built-in default so bash-only / marker-less
# projects never warn.
#
# ADVISORY-ONLY marker->language map: used SOLELY to produce the human-readable
# C3 no-pack warning. It NEVER selects or drives any test/lint/format/build
# command -- command behavior remains fully pack-driven. Bash markers are
# deliberately absent (bashunit is the built-in default, never warned about).

# Exit gracefully if CLAUDE_PLUGIN_DATA is not set
if [ -z "${CLAUDE_PLUGIN_DATA:-}" ]; then
  exit 0
fi

conventions_dir="${CLAUDE_PLUGIN_DATA}/conventions"
config_file=".claude/tdd-conventions.json"

# Ensure conventions cache directory exists
mkdir -p "$conventions_dir"

# Resolve helper scripts (Slices 1/2/4) relative to this hook.
hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parse_binding="${hook_dir}/../scripts/parse-binding.sh"

# True for sources we can hand to `git clone` directly.
is_fetchable_url() {
  local src="$1"
  [[ "$src" == http://* ]] || [[ "$src" == https://* ]] || [[ "$src" == file://* ]]
}

# Derive a clean repo name: basename with trailing ".git" stripped.
repo_name_of() {
  basename "$1" .git
}

# Legacy clone-or-pull into conventions/<repo_name>.
fetch_legacy() {
  local source="$1"
  local repo_name cache_path
  repo_name=$(repo_name_of "$source")
  cache_path="${conventions_dir}/${repo_name}"

  if [ -d "$cache_path/.git" ]; then
    if ! git -C "$cache_path" pull --quiet; then
      echo "fetch-conventions: failed to pull $source" >&2
    fi
  else
    if ! git clone --quiet "$source" "$cache_path"; then
      echo "fetch-conventions: failed to clone $source" >&2
    fi
  fi
}

# Versioned resolve into conventions/<repo_name>@<version>, pinned to the tag.
fetch_versioned() {
  local source="$1" version="$2"
  local clone_url="$source"

  # Normalize a scheme-less source (e.g. github.com/org/pack) to https.
  if ! is_fetchable_url "$source"; then
    clone_url="https://${source}"
  fi

  local repo_name cache_path
  repo_name=$(repo_name_of "$source")
  cache_path="${conventions_dir}/${repo_name}@${version}"

  # Already cached at this immutable tag — nothing to do.
  if [ -d "$cache_path/.git" ]; then
    return 0
  fi

  if ! git clone --quiet --branch "$version" "$clone_url" "$cache_path"; then
    echo "fetch-conventions: failed to clone $source at version $version" >&2
    # Leave no partial cache dir behind.
    rm -rf "$cache_path"
  fi
}

# Stream normalized tuples from parse-binding and resolve each. With no config
# file there is simply no binding to resolve (the C3 floor below still runs).
if [ -f "$config_file" ]; then
  while IFS=$'\t' read -r source version dev; do
    [ -n "$source" ] || continue

    # Case 1: dev pack -> local, never fetched.
    if [ "$dev" = "dev" ]; then
      continue
    fi

    if [ "$version" = "legacy" ]; then
      # Case 2: legacy. Fetch only real URLs; skip bare local paths.
      if is_fetchable_url "$source"; then
        fetch_legacy "$source"
      fi
      continue
    fi

    # Case 3: real version -> versioned resolve.
    if [ -n "$version" ]; then
      fetch_versioned "$source" "$version"
    fi
  done < <(bash "$parse_binding" "." 2>/dev/null)
fi

# ---------------------------------------------------------------------------
# C3: no-pack warn-and-proceed floor (advisory only — never blocks, never runs
# a fallback command).
# ---------------------------------------------------------------------------

# ADVISORY-ONLY marker -> language label. Bash markers are intentionally absent.
# This map exists solely to NAME the language in the no-pack warning; it never
# selects a test/lint/format/build command.
c3_lang_for_marker() {
  case "$1" in
    pubspec.yaml) echo "Dart" ;;
    CMakeLists.txt | CMakePresets.json) echo "C/C++" ;;
    *) return 1 ;;
  esac
}

# Collect resolved pack dirs available this run: any dir under the conventions
# cache that contains a pack.json (new-schema <repo>@<version> dirs and legacy
# sub-pack dirs). Dirs without a pack.json are not "resolved packs".
resolved_packs=()
while IFS= read -r packjson; do
  [ -n "$packjson" ] || continue
  resolved_packs+=("$(dirname "$packjson")")
done < <(find "$conventions_dir" -mindepth 1 -maxdepth 2 -name pack.json 2>/dev/null)

# Determine the active packs for THIS project via the data-driven resolver.
active_packs=""
if [ "${#resolved_packs[@]}" -gt 0 ]; then
  resolve_active="${hook_dir}/../scripts/resolve-active-pack.sh"
  active_packs="$(bash "$resolve_active" "." "${resolved_packs[@]}" 2>/dev/null)"
fi

read_pack_for_c3="${hook_dir}/../scripts/read-pack.sh"

# A marker is "covered" when an active pack declares it in detect.markers.
c3_marker_covered() {
  local marker="$1" pack
  [ -n "$active_packs" ] || return 1
  while IFS= read -r pack; do
    [ -n "$pack" ] || continue
    if bash "$read_pack_for_c3" "$pack" detect.markers 2>/dev/null \
        | grep -Fxq "$marker"; then
      return 0
    fi
  done <<<"$active_packs"
  return 1
}

# For each advisory non-bash marker present at the project root with no active
# pack covering it, emit the C3 advisory naming its language. Then proceed.
for c3_marker in pubspec.yaml CMakeLists.txt CMakePresets.json; do
  [ -f "./$c3_marker" ] || continue
  if c3_lang="$(c3_lang_for_marker "$c3_marker")" && ! c3_marker_covered "$c3_marker"; then
    echo "fetch-conventions: no convention pack for ${c3_lang}; TDD will proceed on training data + session context only" >&2
  fi
done

exit 0
