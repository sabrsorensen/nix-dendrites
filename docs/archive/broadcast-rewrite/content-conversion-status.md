# Content conversion status

This document records the remaining work for the `module.nix` / private
`_content.nix` split. A module is considered converted when its public wrapper
contains only registration, input declarations, options, gates, and local
argument preparation; its operational NixOS/Home Manager/per-system payload
lives in a private content file.

## Already treated as wrapper-only glue

These do not need an additional content layer because they already only declare
flake inputs or import their private implementation:

- `modules/dendritic/dendritic.nix`
- `modules/features/armory/armory.nix`
- `modules/features/beets/beets.nix`
- `modules/features/demlo/demlo.nix`
- `modules/features/flatpak/flatpak.nix`
- `modules/features/impermanence/impermanence.nix`
- `modules/system/nix/determinate/determinate.nix`
- `modules/system/nix/disko/disko.nix`
- `modules/system/nix/home-manager/home-manager.nix`
- `modules/system/nix/secrets/secrets.nix`
- `modules/tooling/nix/formatter/formatter.nix`
- `modules/tooling/nix/nix-index/nix-index.nix`
- `modules/platforms/steamdeck/steamdeck.nix`
- `modules/platforms/steamdeck/_content.nix`
- `modules/home/home/home.nix`
- `modules/home/vscode/vscode.nix`
- `modules/home/lazyvim/lazyvim.nix`

`modules/platforms/x86/x86.nix` is converted; its content is intentionally
`modules/platforms/x86/_content.nix`, adjacent to the wrapper rather than in a
same-named directory.

The shared Home Manager profile is decomposed into sibling broadcast modules.
`modules/home/home/home.nix` now owns only the base managed profile registration;
program-specific and platform-specific Home Manager payloads are broadcast by
modules such as `home-git`, `home-fish`, `home-ssh`, `home-sops`, and
`home-steamdeck`. These modules consume the shared `my.host.home.username` and
`my.host.home.homeDirectory` facts instead of each translating WSL into its
separate account name.

Sam's native NixOS account is also consolidated into a shared broadcast module
at `modules/users/sam/{sam,_content}.nix`. The wrapper maps
the standard Home Manager host fact to a reusable Sam user payload. Host
modules provide host-specific account facts directly with `users.users.sam`,
such as SSH keys, UID/GID, autologin, and Sam-specific access exceptions.
Capability groups belong to the owning feature, platform, or host module, such
as Docker adding `docker`, RPi adding `video`, Steam Deck adding local device
groups, and Atlas media adding `media`.

Persistence is also a sibling Home Manager broadcast module. Shell and browser
state from main are represented in `modules/home/persistence/_content.nix`;
no current host enables the impermanence feature yet, so this payload is kept
for the planned future setup rather than exercised by a host configuration.

`modules/services/monitoring/monitoring.nix` is wrapper-only glue again; the generated
Grafana dashboard payload lives in `modules/services/monitoring/_dashboards-content.nix`
and the operational Grafana/Prometheus configuration remains in
`modules/services/monitoring/_content.nix`.

`modules/platforms/wsl/nixos-wsl/nixos-wsl.nix` is reusable platform glue that
imports the NixOS-WSL provider module and gates the `wsl.enable` payload. The
concrete `nixos-wsl` host output, host facts, user baseline, and work-specific
certificate, Nix, SOPS, and package payload live in
`modules/hosts/nixos-wsl/{host,users,system}`.

Large package/script preparation has also been moved out of public wrappers:
Decky Loader's patched package and CEF helper live in
`modules/platforms/steamdeck/_steamdeck/decky-loader/_content.nix`, WSL work
toolchain package composition lives in
`modules/platforms/wsl/wsl-work-home/_content.nix`, RPi status/nix-index
scripts live in their matching `_content.nix` files, Steam Deck hardware and
boot-mode policy lives under
`modules/platforms/steamdeck/_steamdeck/{hardware,boot-modes}`,
Zaphod's Zenbook speaker helper lives in
`modules/hosts/zaphodbeeblebrox/hardware/_content.nix`, EmeraldEcho's Steam
Deck host variants live in private `modules/hosts/emeraldecho/host/_*-content.nix`
payloads, and the local DHCP lease editor wrapper lives in
`modules/tooling/cli-tools/_content.nix`.

A follow-up hardening pass also renamed legacy private payload files into
content-named files. Armory, Flatpak, Impermanence, Music Tagging, RPi cache,
SOPS, nix-index, Determinate, Disko, Home Manager, treefmt, Steam Deck
aggregation, WSL Codex, LazyVim, Firefox, and native VSCodium now keep
operational payloads in `_content.nix` or `_*-content.nix` files. VSCodium's
profile-owned extension, settings, and profile assembly data live as named
private content files directly under `modules/home/vscode/`, while package
construction remains under `modules/home/vscode/package/` beside its patch
asset. Host Disko layouts, generated Firefox add-on packages, and generated
Grafana dashboard data have also been moved to content-named files, so no
private non-content `_*.nix` files remain under `modules/`.

The sibling `nix-dendrites-main-content` reference checkout has also been
strictly normalized. Public modules under `modules/` are wrapper imports into
private `_content.nix` or `_*-content.nix` payload files, including aggregate,
multi-output, and host export modules; legacy private names such as `_foo.nix`
have been renamed. Current scans show no private non-content `_*.nix` files and
no package/script construction outside content-named payloads in either
checkout. That normalized split is the reference source for future parity
checks.

## Remaining configuration payloads

No tracked configuration payloads remain. Service, platform, host, and Home
Manager payloads recorded in the audit have been split into private
`_content.nix` files or confirmed as wrapper-only glue.

## Ordering

The tracked conversion pass is complete. Keep new public modules limited to
registration, input declarations, options, gates, and local argument
preparation; place operational NixOS/Home Manager/per-system payloads in
private `_content.nix` files. When a public wrapper has a same-named content
directory, keep the wrapper inside that directory as well, e.g.
`modules/features/bluetooth/bluetooth.nix` beside
`modules/features/bluetooth/_content.nix`.
