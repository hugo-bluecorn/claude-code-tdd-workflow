# Shared test fixtures — synthetic convention packs

These `pack.json` files are committed, synthetic convention packs used by the
R1 consumer fan-out slices (C0–C7). They are **not** real packs — each declares
just enough `detect`/`commands`/`standards` data to exercise the data-driven
resolve chain (`parse-binding.sh` → cache-dir location → `resolve-active-pack.sh`)
and the pack-driven consumers without any network clone.

Stable layout (each pack in its own dir, as a real resolved pack would be):

- `dart-fixture/pack.json` — single-step pack (`granularity:"file"`,
  `run:"flutter test {file}"`, markers `["pubspec.yaml"]`, extensions `[".dart"]`).
- `cpp-fixture/pack.json` — 3-step suite pack (`granularity:"suite"`,
  `setup:[...]` then `run:"ctest …"`, `variants`, markers `["CMakeLists.txt"]`,
  extensions `[".cpp",".hpp"]`).

These paths are stable; later slices reuse them. Do not move or rename them
without updating every consuming slice's tests.
