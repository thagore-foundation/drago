# Drago

Drago is the package manager and daily build tool for Thagore.

It is implemented in pure `.tg` and compiled by `thagc`.

## Requirements

- `thagc` (v0.9+)
- `curl`
- `tar`
- `sha256sum`
- Windows now supported natively via PowerShell (no Git Bash required); POSIX tools still used on Linux/macOS.

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
- `drago add --git <url> [ref] --alias <name>`
- `drago add --path <dir> [version] --alias <name>`
- `drago remove <package>`
- `drago install`
- `drago install <package> [version]`
- `drago install --git <url> [ref] --alias <name>`
- `drago install --path <dir> [version] --alias <name>`
- `drago update [dependency|drago|thagc|toolchain|all]`
- `drago publish`
- `drago fmt`
- `drago check`
- `drago cache list|size|clean|purge|purge-unused`
- `drago audit`
- `drago tree`
- `drago why <package>`
- `drago outdated`
- Global build flags:
  - `--locked`
  - `--frozen`
  - `--offline`
  - `-p, --package <name>`
  - `--features <f1,f2>`
  - `--all-features`
  - `--no-default-features`

`--features` / `--all-features` / `--no-default-features` are supported in `build`, `run`, `check`, `test`, `install`, `update`, `tree`, `why`, and `outdated`.
`--package` selects one workspace member by package name or member path.
`drago install` installs all dependencies declared in `drago.toml`.
`drago install <package> [version]` is an npm-style alias of `drago add <package> [version]` (add + install one dependency).
`drago add --git ...` / `drago install --git ...` clone a git source into the local cache and record it in `drago.toml`.
`drago add --path ...` / `drago install --path ...` copy a local source tree into the local cache and record it in `drago.toml`.
External sources require `--alias <name>` and are rejected if that name already exists in the registry, to avoid ambiguous imports.
`drago update <dependency>` updates one dependency (instead of all selected dependencies).
`drago update drago` (or `drago update toolchain` / `drago update all`) runs `thagup` in default mode and updates both `drago` and `thagc`.
`drago update thagc` runs `thagup --without-drago` and updates `thagc` only.
Self-update uses `thagup.sh` on POSIX and `thagup.ps1` on Windows.
`--locked` blocks commands that would modify `drago.lock` and fails if lockfile is out of sync for build/read commands.
`--frozen` implies lockfile immutability and requires offline mode (`--offline` or `DRAGO_OFFLINE=1`) for networked commands.
`--offline` disables network fetches for registry/package resolution and relies on local cache/file-based registry.

External source installs are treated as unreviewed code. Drago prints a risk warning and requires either:

- `--yes`
- `DRAGO_ACCEPT_RISK=1`

## Workspace

Drago supports workspace roots with `[workspace].members`.

```toml
[workspace]
members = ["crates/a", "crates/b"]
```

- `drago build` / `drago check` / `drago test` at workspace root run for all members.
- `drago run` at workspace root requires exactly one member (otherwise it is ambiguous).
- Use `--package <name>` to target one member for `add/remove/build/run/test/check/install/update/tree/why/outdated`.
- Mutating dependency commands (`add/remove/install/update`) at workspace root auto-sync a merged root `drago.lock`.
- In workspace roots, `--locked` validates against the merged root `drago.lock` (all members), even when `--package` is used.
- `why` now reports transitive dependency chains when package sources are available in local cache.

## Optional Dependencies

Drago supports optional dependencies with feature activation:

```toml
[dependencies]
core = "1.0.0"
optdep = { version = "2.0.0", optional = true, default-features = false }

[features]
default = ["dep:optdep"]
extra = ["dep:optdep"]
```

- Optional dependencies are included when enabled by features (`dep:<name>` or `<name>` item).
- `--all-features` enables all feature-defined optional dependencies.
- `--no-default-features` disables the `default` feature set.

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
- `DRAGO_ACCEPT_RISK=1`: accept git/path dependency risk prompts for non-interactive installs
- `GITHUB_TOKEN`: required for `drago publish`
- `DRAGO_UPDATE_DRY_RUN=1`: pass `--dry-run` to `thagup` for self-update preview
- `DRAGO_THAGC_TAG`: pass `--tag <value>` to `thagup`
- `DRAGO_DRAGO_TAG`: pass `--drago-tag <value>` to `thagup`
- `DRAGO_CHANNEL`: pass `--channel <value>` to `thagup`
- `DRAGO_ARCH`: pass `--arch <value>` to `thagup`

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
  - Build matrix: Linux x86_64/aarch64, macOS x86_64/aarch64, Windows x86_64/aarch64.
  - Non-blocking lanes: macOS x86_64/aarch64 and Windows x86_64.
  - Publish platform bundles + per-platform SHA256 manifests to GitHub Releases.
