# Migration status

This is a progress record for the clean broadcast-and-gate rewrite from the
previous `nix-dendrites` repository. It is intentionally specific about what
is present and what remains, so a new working session can continue without
reconstructing decisions from chat history.

## Completed system-level port

The broadcast registry and host-fact schema are in place. Ordinary NixOS
outputs import every registered reusable module; modules activate from
`my.host.roles`, `features`, `services`, `tags`, and derived `is` facts.

Completed shared layers include:

- base system policy, locale, CLI tools, host schema, and unfree-package
  declarations, plus the default `just`/`pre-commit` development shell;
- x86 and Raspberry Pi platform policy, Pi networking/status/index support,
  and the generic-kernel policy;
- desktop and local-capability features including audio, Bluetooth, Docker,
  Podman, firmware, Flatpak, NVIDIA, Steam, Wine, AppImage execution, printing,
  Beets/Demlo music tooling, and desktop tools;
- bootstrap-delayed external integrations for Disko, SOPS, nix-flatpak,
  Jovian, and Home Manager;
- local DNS publication collection, DNS/DHCP, Caddy publication, and the
  reverse-proxy service interface;
- the ported service modules: Apprise, Attic, Atuin, Ankerctl, Airsonic,
  Arr-sync, Bazarr, Blocky, Caddy, Deluge, FlareSolverr, Gonic, Gotify,
  Immich, Jellyfin, Mealie, media networking, Minecraft, monitoring, Ntfy,
  Organizr, Plex/Tautulli/Kitana, Profilarr, Prowlarr, Radarr, RPi DNS
  monitoring, Samba, Scrutiny, Sonarr, SSH, Syncthing, Watchtower, Ombi,
  Frigate, Netbird client/server, and printing.

Syncthing's folder and device topology now comes from the secret data input
(`syncthing/sam.json`). Atlas consumes it through the system service, while
Kamino, ZaphodBeeblebrox, and Emerald Echo use the restored Home Manager
clients with their predecessor folder filtering and tray policy.

The shared installed-host `system.stateVersion` remains `26.05`, preserving
the compatibility defaults of the existing hosts. Installation media retains
the version selected by its upstream module. In particular, Atlas continues to
use its PostgreSQL 17 cluster until the documented PostgreSQL 18 migration is
carried out.

## Inputs and their boundaries

The rewrite keeps the same input families and sources as the original where
practical. Inputs that safely provide options everywhere are imported through
the delayed public/private pattern, then their configuration self-gates:

- `nix-flatpak` is broadcast; only `features.flatpak` hosts declare Flatpak
  state.
- Demlo is consumed through a delayed feature module; media-service hosts
  receive its command system-wide. Atlas additionally enables the separated
  Beets and Demlo Home Manager configuration modules through `features.beets`
  and `features.demlo`; this is an explicit post-parity enhancement.
- Impermanence is broadcast as an option provider, while its persistent-state
  policy activates only for `features.impermanence` hosts.
- Armory is an intentional, optional addition using a pinned legacy runtime.
  It is currently enabled only for the x86 ZaphodBeeblebrox host; it is not a
  predecessor-parity feature and Kamino does not receive its legacy closure.
- The flake formatter is restored through treefmt-nix with nixfmt enabled.
- nix-auto-follow again prunes redundant flake-input follows during generation.
- The GUI-gated Firefox profile restores the predecessor CSS hacks, search
  aliases, privacy and first-run preferences, MIME defaults, NUR add-ons, and
  pinned custom XPIs. It evaluates on the current graphical hosts.
- LazyVim is registered behind `features.lazyvim`; it is deliberately disabled
  on every current host until a user opts in.
- Steam Deck hardware, boot, Jovian, and Decky policy live in the first-class
  Steam Deck platform module. Their configuration is gated by
  `platform = "steamdeck"`, so Jovian's Steam overlay cannot affect ordinary
  x86 hosts.
- Disko, SOPS, and Home Manager use the same delayed-input pattern.

`nixos-wsl` is the deliberate exception: its upstream module is imported only
by the NixOS-WSL output, because non-WSL outputs must not evaluate its option
surface. The portable WSL user policy remains a normal, role-gated broadcast
module. See the architecture guide for the `mkIf`/unknown-option reason.

`nixos-hardware.raspberry-pi-4` is imported only by the five Raspberry Pi
output boundaries, where hardware-specific imports are safe. The RPi cache
policy explicitly prefers generic Nixpkgs kernels over its downstream-kernel
default. The unused `nixos-raspberrypi` input and its unused `pkgs.rpi`
overlay have been retired along with their now-unused Cachix substituter and
trusted signing key.

## Declared outputs

Runtime hosts:

- `atlasuponraiden`, `coruscant`, `emeraldecho`, `ferrix`, `kamino`, `naboo`,
  `nevarro`, `nixpi`, `zaphodbeeblebrox`, and `nixos-wsl`.

Deployment and recovery variants:

- `naboo-image`, `nevarro-image`, `nixpi-image`, `nixpi-bootstrap`, and
  `nixpi-bootstrap-image`;
- `emeraldecho-dualboot`, `emeraldecho-bootstrap`,
  `emeraldecho-dualboot-bootstrap`, `emeraldecho-singleboot`, and
  `emeraldecho-singleboot-bootstrap`;
- `emeraldecho-installer`, `emeraldecho-dualboot-installer`, and
  `emeraldecho-singleboot-installer`.

The Steam Deck variants use tags for the genuine boot-mode edge; normal Jovian
behavior keys off `platform = "steamdeck"`.

## Validation completed

Focused evaluation has succeeded for the NixOS-WSL system, the Raspberry Pi
image variants, the NixPi bootstrap image, Emerald Echo
runtime/bootstrap variants, and the Emerald Echo installer derivations. A
subsequent full evaluation also composed all declared NixOS outputs and the
`emeraldecho-steamos` Home Manager output without building or activating them.
After the final WSL host-fact split and private-payload content rename passes,
including host Disko layouts and generated Firefox/monitoring data,
`nix flake check --no-build` passed on x86_64-linux as well. Broad no-build
flake checks have also been used repeatedly during the migration as host edges
were completed. On 2026-07-30, the sibling `nix-dendrites-main-content`
checkout was strictly normalized to the same private content-file convention
and passed parse, formatting, whitespace, and `nix flake check --no-build`
validation. A normalized parity pass then matched representative host disk,
RPi boot, WSL policy, Atlas Caddy/DNS, native Home Manager, Firefox, and
VSCodium option slices between `nix-dendrites-main-content` and this rewrite.
The WSL top-level derivation also evaluates with Determinate
preserving NixOS's generated settings as
`/etc/nix/nix.custom.conf`. On 2026-07-22, the repaired broadcast WSL
configuration was successfully activated after direct closure comparison;
this exercised its Determinate daemon handoff, WSL work SOPS token, Home
Manager work profile, NuGet template, and restored Code extension/MCP profile.

Useful focused checks for follow-up work are:

```bash
nix eval '.#nixosConfigurations.nixos-wsl.config.system.build.toplevel.drvPath'
nix eval '.#nixosConfigurations."naboo-image".config.system.build.sdImage.drvPath'
nix eval '.#nixosConfigurations."emeraldecho-installer".config.system.build.isoImage.drvPath'
nix flake check --no-build
```

These evaluate derivations; they do not build or boot images. New files must
be intent-added (`git add -N path`) before Nix evaluates the Git snapshot.

## Current activation and validation state

The Home Manager foundation is now integrated with the broadcast registry.
Role-gated WSL and Steam Deck user configuration restores the common shell,
prompt, tmux, and Home Manager state; Steam Deck additionally restores its
Nix-login shell bootstrap, SOPS key path, XR driver unit, reshade directories,
Return-to-Gaming launcher, Steam client settings seed, and the upstream Decky
Loader service. The personal MCP client profile is an explicit
`my.host.features.personalMcp` opt-in on the two personal laptop outputs, not
a form-factor rule; WSL carries only its separate work MCP profile. This
deliberately does not use old descriptor builders.

The private `nix-work-secrets` input now supplies the WSL-only secret and
certificate boundary. The WSL output restores its `ssorensen` Home Manager
profile, multi-SDK .NET/Azure toolchain, NuGet credential provider and source
configuration, Docker Desktop integration, private CA bundle, and Nix daemon
trust/token settings. Home Manager also synchronizes its managed VS Code User
tree into the Windows Code profile after WSL activation, and restores the
Codex package/MCP profile with work secrets injected only at runtime. WSL-only
options remain at that output boundary rather than leaking into the ordinary
broadcast registry. Its work Git identity/signing, GPG agent and public-key
configuration and SSH/GitHub baseline are likewise
declarative and use the private work input only where needed. The WSL profile
also restores the GitHub CLI credential helper and the Vim/Night Owl editing
configuration from the predecessor repository. Its Fish profile includes the
portable SSH-agent plugins, GPG terminal setup, Windows and editor-sync
shortcuts, and generation-cleanup helper. Deployment is now a broadcast module:
host facts enable the restricted `nix-remote` account and its authorized keys,
while desktop deployers receive `nh` checkout policy, `nix-*` SSH aliases,
Atlas distributed-build routing, and the lock- and DNS-peer-gated
`secure-deploy` path through `nhsr`/`nhsur` for Naboo and Nevarro. Deployers whose
`my.deployment.sleepy` fact is enabled also hold a blocking `systemd-inhibit`
lease throughout guarded and explicit unsafe remote deployment commands.

Caddy restores its Fail2ban topology, Caddy journal filters, and the
predecessor's validated/diagnostic Cloudflare ban and unban behavior.

Netbird client and server topologies are available behind `netbirdClient` and
`netbirdServer` host service facts; neither is enabled by default. Enabling the
server is an operational decision because it publishes public authentication,
relay, and TURN endpoints.

The Decky Loader integration, its locally vendored plugin sources, declarative
plugin settings, and XR compatibility assets are now migrated. Follow-up
validation should build the Steam Deck closure and exercise Decky at runtime;
the no-build checks below do not fetch plugin sources or run their pnpm builds.
All eighteen plugin packages, including the locally customized Syncthing, CSS
Loader, enhanced Animation Changer, and XR Gaming packages, are declared in
the evaluated Steam Deck configuration. Their builds and runtime testing on
Emerald Echo remain separate Decky-specific checks.

AppImage execution is now a GUI-gated feature: graphical hosts receive the
binfmt handler and headless hosts do not. Atlas retains the predecessor's
system-wide Demlo command through its media-service role and explicitly enables
the separated Beets and Demlo Home Manager configuration modules.

The latest host-edge review also restored Atlas-only SFTP access, matching its
predecessor role as the remote deployment and build endpoint. Its evaluated
`nix.settings.system-features` already matched the predecessor's four-feature
builder set (`nixos-test`, `benchmark`, `big-parallel`, and `kvm`), so that
setting did not require a duplicate override.

Bootstrap enrollment now also carries an explicit final output name per
variant. This keeps the printed `nixos-rebuild --flake` target valid after the
rewrite's lowercase/hyphenated output naming, including the Steam Deck
dual- and single-boot variants.

The final source-snapshot review also intent-added the restored Determinate
and nix-index module files. This matters for a Git-backed flake: untracked
files are not reliably part of the source snapshot, even when a local working
tree happens to evaluate them.

Determinate is intentionally enabled on every NixOS output, including WSL.
WSL's certificate and trusted-user policy remains layered onto Determinate's
`nix-daemon` service; this is a deliberate change from the predecessor, which
did not import Determinate for WSL.

## Remaining work

The source-level content-preservation review and private `_content.nix` split
are complete for the tracked predecessor payloads. The WSL activation gaps,
global secret-gating issue, RPi Sam Home Manager SOPS edge, Atuin/laptop gates,
NuGet template namespace check, WSL Code MCP set, CA-bundle naming, and Fish
add-on generator replacement have all been corrected in source.

Remaining work is host/runtime validation and operations that require an
explicit operational choice:

- validate the upstream `nixos-hardware.raspberry-pi-4` module on hardware.
  It is now imported at the Pi output boundary and retains its firmware,
  device-tree, and boot-loader defaults while intentionally preferring the
  generic cached kernel; evaluated RPi kernel params and initrd module names
  match the predecessor. The predecessor's `nixos-raspberrypi`
  input supplied a `pkgs.rpi` overlay that no predecessor module used; its
  Cachix cache is also removed because all active Pi kernel and firmware
  derivations come from Nixpkgs;
- activate `homeConfigurations.emeraldecho-steamos` on SteamOS and verify it
  reconciles the shared `/srv/steam-library` mount from its colocated
  Home Manager payload alongside the declarative
  NixOS mount; Decky and Steam still need runtime validation;
- perform the documented Atlas runtime music-library validation. Demlo and
  Armory's declarative ports are complete; Armory must remain unbuilt and
  unrun on this machine;

- build or activate the Atlas Beets/Demlo profile to verify ownership and
  access to `/AnomalyRealm/media/music` on the deployed host;
- build the Emerald Echo system closure and exercise Decky at runtime (plugin
  staging, settings seed, XR driver setup, and Steam integration);
- build or boot the declared image, installer, and bootstrap outputs as part of
  deployment readiness; current checks evaluate them but do not boot them;
- verify one real deployment from Kamino or ZaphodBeeblebrox to Atlas and one
  peer-gated deployment to each RPi. This validates the private deployment
  identities, `nix-remote` sudo boundary, sleep-inhibition lease, remote
  builder SSH endpoint, and the target lock/health checks without changing
  the declarative model.

### Resume order

1. Build and, when operationally appropriate, activate the Atlas and Emerald
   Echo closures to perform the host-level checks above.
2. Boot or deploy one representative image/installer variant to verify its
   runtime edge, and record the result in `docs/parity-audit.md`.

No old configuration is imported as a compatibility bridge. Future behavior
should be added as independently broadcast, self-gating modules with
operational payloads kept in private `_content.nix` files.
