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

# Shared binding-iteration helper. SOURCE it so we share the ONE correct tuple
# split with active-pack.sh -- avoiding the dev-pack tab-collapse trap that a
# naive `IFS=$'\t' read` falls into (it mis-reads an empty version as "dev").
# shellcheck source=../scripts/iterate-binding.sh
. "${hook_dir}/../scripts/iterate-binding.sh"

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

# Resolve one normalized binding tuple. Invoked per-tuple by iterate_binding,
# which splits the fields correctly (preserving a dev pack's EMPTY version).
resolve_binding_tuple() {
  local source="$1" version="$2" dev="$3"
  [ -n "$source" ] || return 0

  # Case 1: dev pack -> local, never fetched.
  if [ "$dev" = "dev" ]; then
    return 0
  fi

  if [ "$version" = "legacy" ]; then
    # Case 2: legacy. Fetch only real URLs; skip bare local paths.
    if is_fetchable_url "$source"; then
      fetch_legacy "$source"
    fi
    return 0
  fi

  # Case 3: real version -> versioned resolve.
  if [ -n "$version" ]; then
    fetch_versioned "$source" "$version"
  fi
}

# Stream normalized tuples from the shared helper and resolve each. With no
# config file there is simply no binding to resolve (the C3 floor below still
# runs).
if [ -f "$config_file" ]; then
  iterate_binding "." resolve_binding_tuple
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

# Determine the active packs for THIS project via the unified committed-binding
# resolver. Unlike a fetch-cache scan, active-pack.sh also locates DEV packs
# (local, never fetched) from the committed binding -- so a bound-and-resolving
# dev pack correctly COVERS its marker and the no-pack advisory does not fire
# (issue 015 / BF-001). It emits one pack dir per line, exactly what
# c3_marker_covered's read loop below consumes.
active_packs="$(bash "${hook_dir}/../scripts/active-pack.sh" "." 2>/dev/null)"

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

# ---------------------------------------------------------------------------
# T1 (C4): projectFiles materialization -- non-destructive, warn-on-drift.
# ---------------------------------------------------------------------------
# For each ACTIVE pack (resolved via active-pack.sh, which -- unlike the C3
# cache scan above -- also locates DEV packs from the committed binding), read
# its projectFiles[] and materialize each into the PROJECT ROOT:
#   - absent in project     -> copy the pack's file in (the ONLY write);
#   - present & identical    -> no-op (silent);
#   - present but DIFFERENT   -> NEVER overwrite; emit a drift advisory naming
#                                the file to stderr; proceed.
# PRIME-safe: no active pack / no projectFiles -> no writes. Hook still exit 0s.
active_pack_for_t1="${hook_dir}/../scripts/active-pack.sh"
read_pack_for_t1="${hook_dir}/../scripts/read-pack.sh"

while IFS= read -r t1_pack; do
  [ -n "$t1_pack" ] || continue
  while IFS= read -r t1_file; do
    [ -n "$t1_file" ] || continue
    t1_src="${t1_pack%/}/${t1_file}"
    t1_dst="./${t1_file}"
    [ -f "$t1_src" ] || continue

    if [ ! -e "$t1_dst" ]; then
      # Absent -> copy the pack's file in (the only write).
      cp "$t1_src" "$t1_dst" 2>/dev/null || true
    elif ! cmp -s "$t1_src" "$t1_dst"; then
      # Present but different -> NEVER overwrite; warn naming the file.
      echo "fetch-conventions: project file ${t1_file} differs from convention pack; leaving your copy unchanged" >&2
    fi
    # Present & identical -> nothing to do.
  done < <(bash "$read_pack_for_t1" "$t1_pack" projectFiles 2>/dev/null)
done < <(bash "$active_pack_for_t1" "." 2>/dev/null)

exit 0
