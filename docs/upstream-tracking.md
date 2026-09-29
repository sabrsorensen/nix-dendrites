# Upstream tracking

Patches, overrides, forks and workarounds this repo carries against upstream
code, and how to tell when each can go. Last audited 2026-09-24.

## Items with an evaluation warning

These print a `warnings` entry on every host they affect, including the
recheck command, so they can't be forgotten. The warning text is the
authoritative record; this table is just an index.

| Item | Where | Hosts |
|---|---|---|
| flashrom `doCheck = false` (NixOS/nixpkgs#558302, fix PR #563332) | `modules/platforms/rpi/rpi-base/_rpi-base.nix` | RPi |
| pnpm 9.15.9 for six lockfile-v6 Decky plugins | `decky-catalog/packages/_pnpm9.nix`, `catalog.nix`, `_decky-loader.nix` | Steam Deck |
| decky-tabmaster pinned to v2.15.1 | `decky-catalog/packages/catalog.nix` | Steam Deck |
| unifideck built from the sabrsorensen fork (upstream #447) | `decky-catalog/packages/catalog.nix` | Steam Deck |
| appimage-run + libunwind | `modules/features/appimage/_appimage.nix` | appimage hosts |
| nmse's appimage-run + libunwind | `modules/features/nomanssky/_nmse.nix` | noMansSky hosts |
| azure-devops extension + keyring | `modules/platforms/wsl/wsl-work-home/_wsl-work-home.nix` | WSL |
| EOL dotnet 6/7 SDK insecure permits | `modules/platforms/wsl/wsl-work-home/` | WSL |
| Codex `daemon_auto_start = false` (openai/codex#48050) | `modules/home/codex/_codex.nix` | codex hosts |

`decky-catalog/` is `modules/platforms/steamdeck/_steamdeck/decky-catalog/`.

## Items without a warning

These are adaptations to NixOS or local choices rather than upstream bugs, so
they're expected to stay. Recheck them when bumping the relevant input or
package, mostly to catch upstream changes that make them unnecessary or that
they silently paper over.

### Forks

- **demlo** (`github:sabrsorensen/demlo/v3.8.1`,
  `modules/features/demlo/demlo.nix`). Copy of `gitlab.com/ambrevar/demlo`,
  which has been dormant since 2018. The only local commit updates it for
  current Go toolchains and adds flake packaging. This is effectively a
  permanent fork; only revisit if upstream comes back to life.

### Steam Deck / Decky

- **decky-loader `postPatch`**
  (`modules/platforms/steamdeck/_steamdeck/decky-loader/_decky-loader.nix`).
  Absolute `systemctl`/`python3` paths and an explicit PATH for helper
  subprocesses. Jovian's 3.2.8 already made the former PATH patch
  unnecessary; on each Jovian bump, check whether upstream has picked up more.
  `--replace-fail` breaks the build loudly if the patched code changes.
- **XR Gaming** (`decky-catalog/packages/xrgaming.nix`):
  - `main.py` source replacements for NixOS paths.
  - The `xrdriveripc.py` EXDEV fix (temp file written next to the config
    rather than in the read-only plugin dir). This is a genuine bug and
    could be upstreamed to PyXRLinuxDriverIPC.
  - Breezy Vulkan release payloads are pre-fetched at build time instead of
    Decky's runtime `remote_binary` download. Bump them together with the
    plugin.
  - `/usr/lib/libcurl.so` and `/usr/lib/libwayland-client.so` symlinks
    (`jovian/_jovian-core.nix`) exist for xrDriver's `find /usr/lib*` probe.
- **SDH-CssLoader / SDH-AnimationChanger**: `main.py` is replaced wholesale
  (`decky-catalog/packages/assets/vendor/*-main.py`), and CssLoader's theme
  install copies files instead of symlinking or hard-linking them. Because the
  whole file is replaced, upstream `main.py` changes are silently dropped. When
  bumping either plugin, diff upstream's `main.py` against the local copy.

### Desktop features

- **Armory** (`modules/features/armory/`). Pinned `armory-runtime-nixpkgs`
  for Python 2 / PyQt4, plus `SDM.py` argument-quoting fixes. Upstream
  Armory is dead; this stays for as long as the feature is used.
- **VSCode openssh `SSHCONF_CHECKPERM = 0` patch**
  (`modules/home/vscode/package/assets/openssh-nocheckcfg.patch`). A local
  policy choice. Check it still applies after openssh bumps.
- **Wine `powershell.exe` stub** (`modules/features/lutris/_powershell-stub.nix`,
  see `docs/lutris-renegade-x-launcher.md`). Needed until Wine/GE-Proton
  implement PowerShell, which is unlikely.
- **w3d-hub-launcher winetricks bootstrap**
  (`modules/features/w3d-hub-launcher/_package.nix`). Works around the
  launcher's own dependency-install step doing nothing. Check upstream
  launcher releases.

### Source-only inputs

These read files out of an upstream repo (`flake = false`) rather than using
its flake outputs, so they depend on upstream's repo layout. A layout change
fails evaluation loudly rather than silently.

- **reolink-cli** (`modules/features/reolink/`). Version comes from
  upstream's `package.json` and the release-tarball hash from
  `checksums/v<version>.sha256`, so a `flake.lock` bump of `reolink-cli` is
  the whole update; read upstream's `CHANGELOG.md` before committing one. If
  an update 404s on the tarball, upstream bumped `package.json` before
  publishing the release assets; rerun the update later. To hold a release
  back, pin the input to a tag (`github:reolink/reolink-cli/v<version>`) and
  record the pin and its reason here.
- **reolink-native-linux** (`modules/features/reolink/`). Built from source
  off upstream's default branch (its git tags lag its releases); the version
  is parsed from `project(... VERSION x.y.z)` in `CMakeLists.txt`, so a
  `flake.lock` bump is the whole update. Read upstream's `CHANGELOG.md`
  before committing one. If the build breaks on a bump, check `CMakeLists.txt`
  for new `find_package`/`pkg_check_modules` dependencies.
- **sonolin** (`modules/features/sonos/`). Built from source off upstream's
  default branch (no tags yet); the version is read from `pyproject.toml`, so
  a `flake.lock` bump is the whole update. If a bump fails, check
  `pyproject.toml` for new dependencies and the test suite for new
  network/display assumptions.
- **boot-gardener** (`modules/features/boot-gardener/`). Built from upstream's
  `boot-gardener/boot-gardener.nix` with our nixpkgs, bypassing their flake
  (which pins nixos-26.05 and flake-utils). On a bump, check the file hasn't
  moved and its `callPackage` arguments still resolve. Pinning is unused here:
  it's Limine-only and needs an out-of-tree module plus `--impure` rebuilds.
- **crispy-recall** (`modules/services/crispy-recall/`). Pinned to a release
  tag (`github:TheSylvester/crispy-recall/v<version>`) because satellites
  upload raw transcripts; bump the tag deliberately after reading
  `CHANGELOG.md`, and refresh `npmDepsHash` in `_package.nix`. Everything
  `recall install` would do imperatively is declared instead (bundles
  symlinked into `~/.recall/bin`, Stop hook, skill, `config.json`, tokens from
  sops), so a release that changes its on-disk layout, bundle list
  (`STAGED_BUNDLES`/`SATELLITE_BUNDLES` in `src/installer/install.ts`) or
  needs an attended DB migration (`recall install`/`recall repair` on the hub,
  via `recall-hub`) has to be mirrored by hand. `_llama-cpp.nix` repackages
  upstream's pinned llama.cpp prebuilt (`LLAMA_RELEASE_TAG`, currently b5300)
  with autoPatchelf, because nixpkgs' llama-cpp no longer ships
  `llama-embedding`; bump it only when upstream bumps its tag. The CLAUDE.md
  nudge `recall install` appends is intentionally skipped; the skill carries
  the same guidance.

### Platform inputs

- **Jovian overlay and `ignoreMissingKernelModules`** are neutralised on
  non-Deck hosts in `jovian/jovian.nix`. Re-audit Jovian's modules for new
  unconditional config on each bump; see "Platform inputs" in
  [architecture.md](architecture.md).

### Stale notes

- `modules/home/claude/claude.nix` says `claude-desktop` gets a dedicated
  nixpkgs pin because upstream uses the removed `nodePackages.asar`. No such
  pin exists: the lock resolves it to the same FlakeHub `nixpkgs-weekly`, and
  it evaluates fine. The upstream problem appears fixed. Drop the comment,
  and consider `inputs.nixpkgs.follows = "nixpkgs"`.
