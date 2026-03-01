# Drago

Drago is the package manager and daily build tool for Thagore.

It is implemented in pure `.tg` and compiled by `thagc`.

## Requirements

- `thagc` (v0.9+)
- `curl`
- `tar`
- `sha256sum`

## Build Drago

```bash
cd /media/lehungquangminh/QM_SSD/drago
THAGC=/media/lehungquangminh/QM_SSD/thagore/build-llvm21/compiler/thagc
$THAGC build src/main.tg -o drago.bin
```

## Commands

- `drago new <name>`
- `drago build`
- `drago run`
- `drago test`
- `drago add <package> [version]`
- `drago remove <package>`
- `drago install`
- `drago update`
- `drago publish`
- `drago fmt`
- `drago check`
- `drago cache list|size|clean|purge|purge-unused`
- `drago audit`

## Registry

Default registry source:

- `https://raw.githubusercontent.com/thagore-foundation/registry/main`

Override registry base for local testing:

```bash
export DRAGO_REGISTRY_BASE="file:///media/lehungquangminh/QM_SSD/drago/registry"
```

## Environment Variables

- `THAGC`: path to compiler binary (`thagc`)
- `DRAGO_TARGET`: optional target triple for cross compile
- `DRAGO_COLOR`: `auto` (default), `always`, `never`
- `DRAGO_BUILD_FLAGS`: build flags fingerprint for cache metadata
- `DRAGO_OFFLINE=1`: block network download and use local cache only
- `DRAGO_REGISTRY_BASE`: registry base URL override
- `GITHUB_TOKEN`: required for `drago publish`

## Notes

- No C/C++ sources in this repository.
- Runtime, filesystem, process, TOML, HTTP operations are through Thagore stdlib wrappers.

## Automation (GitHub Actions)

- `Drago CI` (`.github/workflows/ci.yml`)
  - Trigger: `push` to `main`, all pull requests.
  - Matrix: Linux (`x86_64`, `aarch64`), macOS (`x86_64`, `aarch64`), Windows (`x86_64`, `aarch64`) with parity to Thagore release lanes.
  - Steps: provision LLVM 21, install `thagc` from release tag (`v1.0.0`), build `drago`, run `drago check` and `drago test`, upload platform artifacts.
- `Drago Release` (`.github/workflows/release.yml`)
  - Trigger: tags `v*` (and manual dispatch).
  - Build matrix: Linux x86_64/aarch64, macOS x86_64/aarch64, Windows x86_64/aarch64 (macOS x86_64 lane is non-blocking).
  - Publish platform bundles + per-platform SHA256 manifests to GitHub Releases.
