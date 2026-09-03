# Predecessor parity audit

This is the living, source-by-source audit of `../nix-dendrites` against this
broadcast rewrite. It is deliberately separate from `migration-status.md`:
this document records evidence and classifications, while the status document
is the actionable remaining-work list.

## Method

Every predecessor module is classified as one of:

- **ported**: the behavior is present in a broadcast, self-gating module;
- **pending**: it has a concrete consumer or user-visible behavior and must be
  brought forward;
- **structural glue**: descriptor builders, import aggregators, or other
  assembly machinery intentionally replaced by broadcast registration; or
- **retired**: no current consumer or an explicitly superseded behavior.

A ported item is additionally marked **verified** only after its predecessor
option content and host consumer were compared. Until then, it is a
**ported candidate** rather than evidence of equivalent behavior.

The file inventory is complete. Findings are refined as option-level
comparisons and implementations proceed; items classified **pending** are also
maintained in `migration-status.md`. A structural destination is not evidence
that every option from main has been ported.

## Active source audit — 2026-07-28

The reference is the clean sibling worktree `../nix-dendrites-main-audit` at
`6e59d5a` (`main`). Use `just audit-reference` to confirm that reference and
`just audit-diff <path>` for a filesystem comparison. This pass distinguishes
the intended broadcast architecture from missing user-visible behavior.

| Family | Status | Source-comparison finding |
| --- | --- | --- |
| Dendritic bootstrap | verified after correction | `modules/dendritic/dendritic.nix` matches main's ownership of flake-file, flake-compat, flake-utils, flake-parts, Nixpkgs, Dendritic import, output construction, and flake description metadata. `nix-auto-follow` remains an intentional extra import in the rewrite. |
| Host/output assembly | intentional structural change | Direct broadcast registration replaces main's descriptor, registration, and output-constructor graph. Host facts and output boundaries must preserve the resulting configuration. |
| Platform model | intentional structural change | `my.host.platform` replaces the former RPi, WSL, and Steam Deck role flags. This makes Steam Deck integration a reusable platform module and keeps Jovian out of ordinary x86 systems. |
| Determinate Nix | intentional temporary divergence | The module exists and the rewrite currently enables it by default through `features.determinateNix`, while following the temporary nix-src SSH-ng fix branch. Hosts can opt out through the same host fact. |
| VS Code/VSCodium | verified after correction | Native profiles now retain main's package-flavor/profile gates, extension inventories, settings, Higi profile, secret-wrapped launchers, and OpenSSH/desktop-item adjustments. The WSL synchronization module remains output-scoped; generated Windows manifests are intentionally not stored because they contain immutable Linux store paths. |
| DHCP/CoreDNS | verified after correction | The Kea/CoreDNS unit graph and zone renderer match main. The rewrite now combines fixed bootstrap records with `my.localDns.publishedRecords`, restoring main's service/host DNS publication behavior. |
| Blocky and local-DNS collector | verified | Blocky's port, forwarding, blocklists, metrics gate, firewall, and CoreDNS ordering match main. The rewrite's explicit publisher-output list is an intentional replacement for main's inventory traversal; the two DNS authorities publish no records themselves, so excluding them preserves the evaluated record set and prevents a cycle. |
| Mealie | source-equivalent; runtime migration risk | The rewrite matches main's Mealie options, loopback listener, Caddy route, local PostgreSQL setting, and implicit service data location. `system.stateVersion` remains `26.05`; the earlier welcome-page regression therefore points to an upstream Mealie module/schema transition rather than a rewrite-only data-path override. Keep the separately documented data migration plan before changing that service's compatibility generation. |
| Deployment and remote builders | verified | `nhs` derives its lower-case output name from the current host rather than hard-coding Zaphod. Local-checkout hosts such as Naboo, Nevarro, and Zaphod evaluate to the same Atlas `ssh-ng` builder contract as main; Atlas and non-checkout Pi hosts have no self/default builder. `secure-deploy` retains the two-host peer-health lock protocol, while `nhsr`/`nhsur` keep the main-style dispatcher and secure deployment remains the guarded Pi path. |
| Raspberry Pi platform | intentional kernel change; evaluated | The base filesystem, DHCP, firmware, initrd module names, `cma=64M`, Pi device access, and service-host policy match main. The generic cached `linuxPackages` kernel and 100% ZRAM on Naboo/Nevarro are intentional changes to avoid multi-hour downstream kernel builds and provide build headroom. Nevarro evaluates with kernel `6.18.39`, ZRAM enabled, and no `vm.mmap_rnd_bits` setting; an already-busy `/dev/zram0` remains a live-transition cleanup issue rather than a declarative mismatch. |
| Firefox/Home Manager | verified | The managed GUI profile preserves main's CSS, policies, search engines, preferences, NUR/custom add-ons, and MIME defaults on laptop graphical homes. Emerald Echo remains disabled like main's Steam Deck profile rather than receiving the managed browser policy. |
| WSL boundary and work policy | verified | The output-scoped NixOS-WSL import retains main's default user, Docker Desktop, interop, start-menu, certificate/sandbox, token-include, Nix trust, and work-tool policies. The rewrite evaluates with `ssorensen`, Docker Desktop, and interop enabled; the duplicate inherited `wheel` entry is harmless but can be normalized later without changing access. |
| Caddy/Fail2ban | verified | Caddy's Cloudflare DNS plugin, scanner/CORS snippets, virtual-host rendering, secret environment, Cloudflare-aware Fail2ban actions, and Atlas virtual-host set are present. The rewrite consolidates main's split Caddy files without changing their effective policy. |
| Media base/network | verified after correction | Atlas's current media settings and Airsonic container match main, including the repaired PUID/PGID, existing config volume, and the unique container-UID assertion. Its narrower Podman-network gate is intentional and safe: direct source inspection shows Deluge and Watchtower are the only consumers of that named network. |
| Native Home Manager policy | verified | Shell, Git, GPG, SSH, Atuin, MCP, Syncthing, Starship, tmux, Vim, GDrive, and the generated SSH blocks compare with main. The GPG agent includes the stale-keybox lock cleanup user unit. |
| Feature policy | verified after correction | Audio, Bluetooth, firmware, nix-ld, NVIDIA, ZSA, AppImage, Bitwarden, Deskflow, Docker, Flatpak, Minecraft, Noson, Podman, Steam, 3D printing, Wine, music tagging, and Office are reviewed; Office includes `libreoffice-qt6` as in main. |
| Remaining families | audited | The module inventory, source payloads, host gates, and representative consumer outputs have now been reviewed. Remaining items are intentional design choices or runtime validation work, not unreviewed source scope. |

## Ported behavior ledger

This ledger names the broadcast destination and activation interface for the
predecessor behavior already brought forward. It is expanded during the audit;
an omitted predecessor area is not evidence that it was intentionally retired.

| Predecessor area | Broadcast destination | Activation / replacement |
| --- | --- | --- |
| Host inventory, descriptor registration, and outputs | `modules/hosts/**/host.nix`, `modules/hosts/*.nix` | Direct `flake.nixosConfigurations` outputs broadcast the registered NixOS modules and state intent in `my.host`. |
| Host context and feature/service switches | `modules/system/host-context/host-context.nix` | Shared option schema plus derived `my.host.is` facts. |
| Disk and hardware edges | `modules/hosts/**/{hardware,disk,storage,users}.nix` | Host-name self-gating preserves physical facts without descriptor imports. |
| Base platform policy | `modules/system/{base,locale}.nix`, `modules/platforms/**` | Architecture and explicit platform facts gate platform policy. |
| Desktop/local programs | `modules/features/*/*.nix` | Individual `my.host.features.*` facts: audio, Bluetooth, Docker, Podman, firmware, Flatpak, NVIDIA, Steam, Wine, AppImage, Office, Bitwarden, Deskflow, Minecraft, Noson, 3D printing, ZSA, and music tagging. |
| Nix integrations | `modules/system/nix/**`, `modules/tooling/nix/**` | System integrations expose NixOS options; tooling integrations provide repository and user-facing tooling. Inputs remain beside their consumer. |
| Services | `modules/services/*/*.nix` | Individual `my.host.services.*` facts replace the predecessor media/service-stack aggregators. |
| DNS and proxy publication | `modules/system/local-dns/local-dns.nix`, `modules/services/{caddy,dhcp-coredns}/**` | Services publish records through `my.localDns.records`; host outputs are collected without an evaluation cycle. |
| Steam Deck/Decky | `modules/platforms/steamdeck/**`, `modules/platforms/steamdeck/_steamdeck/decky-catalog/packages/**` | The first-class Steam Deck platform module provides Jovian and Decky behavior; platform facts and boot-mode tags replace profile assembly without applying Jovian's Steam overlay globally. |
| WSL work profile | `modules/platforms/wsl/**` | The WSL output boundary supplies upstream options; platform-gated modules supply portable user policy. |
| Beets, Demlo, and impermanence | `modules/features/{beets,demlo,impermanence}/*.nix` | **Declaratively complete.** |
| Armory | `modules/features/armory/armory.nix` | **Intentional addition, not predecessor parity.** It is enabled only for ZaphodBeeblebrox and is intentionally not built on this machine. |
| Flake formatter and follows optimization | `modules/{dendritic,tooling}/**` | treefmt-nix provides `formatter`; Dendritic's nix-auto-follow module prunes redundant follows. |

## Intentionally not ported

These predecessor files are deliberately replaced by the architecture, rather
than being functionality gaps:

- host `exports.nix` files, descriptor helpers, registration builders, and
  profile aggregators: replaced by direct host output declarations and the
  broadcast registry;
- flake output/inventory constructors and descriptor bridges: replaced by the
  host-fact interface and self-gating modules;
- old deployment/inventory helper graph: replaced by `modules/deployment.nix`.
  Direct host facts now drive the restricted `nix-remote` account, deployment
  keys, local `nh` checkout, Atlas builder route, and laptop deploy helpers;
- `nix-auto-follow` as a standalone predecessor module: replaced by the same
  Dendritic integration in `modules/dendritic/dendritic.nix`.

## Inventory and structural classification

The predecessor has 275 Nix modules under `modules/`; the rewrite currently
has 142. This is not itself a parity failure. The predecessor's large host
subtree contains descriptor builders, registration builders, exports files,
configuration constructors, and profile aggregators. These are **structural
glue**: broadcast outputs replace them with direct host facts and
`builtins.attrValues config.flake.modules.nixos`.

The following predecessor areas are therefore intentionally not copied as
files: `hosts/**/exports.nix`, descriptor/registration builders, generic
`all`-style assembly, inventory/output constructors, and the old deployment
helper graph. Their behavior must instead be accounted for by a host fact,
self-gating module, or a documented output-boundary exception.

## Input audit

| Predecessor input | Classification | Finding |
| --- | --- | --- |
| `armory-runtime-nixpkgs`, `demlo`, `disko`, `impermanence`, `jovian-nixos`, `nix-flatpak`, secrets, hardware, RPi, WSL, SOPS, Home Manager | ported | Present in the rewrite with delayed consumption or the documented WSL exception. |
| `treefmt-nix` | ported | Restored as the flake formatter and check. |
| `lazyvim` | ported, disabled | Registered behind `my.host.features.lazyvim`; no host enables it. |
| `nix-auto-follow` | ported | Restored through the Dendritic module for follow-graph pruning during generation. |
| `determinate` | intentional current daemon policy | The module and input are retained. The rewrite currently defaults `features.determinateNix = true` and points Determinate at the temporary nix-src SSH-ng fix branch; hosts can opt out if needed. |
| `firefox-csshacks`, `nur` | ported | `modules/home/firefox/firefox.nix` restores the GUI-gated CSS, NUR Rycee add-ons, and pinned custom XPI profile. |
| `gitignore` | ported | The common Sam Home Manager profile supplies the same executable helper. |
| `nix-index-database` | ported | Restored through the common Sam Home Manager profile with its prebuilt database, shell integrations, command-not-found replacement, and `comma`. |
| `nix4vscode` and three VS Code theme flakes | ported | The inputs, native package selection, secret launcher wrapping, OpenSSH/desktop cleanup, conditional profile flags, Higi LLP profile, and Marketplace/Open VSX extension split are retained. |
| `pkgs-by-name-for-flake-parts` and `packages` | intentionally retired | This was predecessor package-discovery/overlay glue. Current local packages are owned directly by `features/armory/_content.nix` and the Decky catalog modules, so no host consumes a global `pkgs.local` or package-index interface. |

`lazyvim` was installed by a reusable predecessor module but its only shown
Sam-home import was commented out; keeping the new fact disabled preserves
that effective behavior.

## First-pass module findings

### Services and host edges

The predecessor service areas (media workloads, notifications, DNS/DHCP,
monitoring, Caddy, storage-facing services, NetBird, printing, SSH, Samba,
Syncthing, and Minecraft) have direct broadcast counterparts. Their completed
option and enabled-host comparison is recorded in the service table below.
The host-edge comparison for Atlas, the RPi boards, WSL, Steam Deck, Kamino,
and Zaphod is recorded in the host-edge table below. The old host exports,
descriptor helpers, registration builders, and variant-profile assemblers are
**structural glue**.

### Programs and system policy

The following predecessor capabilities have clear broadcast equivalents:
AppImage support, Armory, Beets/Demlo, Bitwarden, Deskflow, Flatpak, Minecraft
tools, Noson, Office, Steam, 3D-printing, Wine, audio, Bluetooth, firmware,
nix-ld, NVIDIA, locale, and ZSA.

The formerly pending browser/Home Manager, KDE, Wayland/Plymouth,
cross-compilation, deployment, and work-development comparisons are now
recorded in the verification tables below. Remaining partial items are stated
explicitly in the current-state and migration-status sections.

### Verification findings: input-specific features

Direct source comparison corrected three earlier ported labels:

- **Demlo — equivalent active command, intentional enhancement.** Atlas
  receives the predecessor's system-wide Demlo command through its media-service
  role. At the user's request, its separate `beets` and `demlo` feature facts
  also enable the Beets and Demlo Home Manager configuration modules,
  activating the predecessor's previously unimported user configuration.
  Remaining script differences are help/debug text rather than transformations.
- **Impermanence — verified equivalent.** The system persistence paths, FUSE
  setting, `mkIfPersistence` helper, and shared Home Manager `home.persistence`
  hook are present behind the same feature gate.
- **Armory — declaratively equivalent, untested here.** The package/input,
  SDM.py argument fixes, and complete launcher behavior are present. It is not
  built or run on this machine by explicit instruction.

### Verification findings: core desktop features

- **Verified equivalent:** audio, Bluetooth, firmware, nix-ld, ZSA, and the
  predecessor KDE desktop policy. The broadcast desktop module additionally
  places its X-server configuration behind the derived desktop-session fact.
- **NVIDIA — verified equivalent.** The driver, graphics, PRIME, unfree-package
  policy, and Intel microcode default match the predecessor.

### Home Manager

The rewrite has a shared Sam Home Manager profile on WSL, Steam Deck, and
workstation hosts. The native personal profile now restores its generic
packages, Git/GitHub/GPG/SSH policy, nix-index, shell/prompt/tmux/editor
configuration, MCP clients, and filtered Syncthing clients. The WSL-specific
modules remain an output-boundary supplement, not the source of native-host
behavior.

| Predecessor Home Manager family | Classification | Broadcast reconciliation |
| --- | --- | --- |
| Codex/MCP, Fish, Git/GPG, SSH, VS Code WSL sync | ported | `modules/platforms/wsl/{codex,fish,git-gpg,ssh,vscode}.nix` restores the WSL-specific profile. Atuin is deliberately not enabled: the predecessor's work profile did not import it. Native personal laptops opt into the personal Arr/Context7/GitHub/NixOS MCP client contract with `my.host.features.personalMcp`; WSL retains only its separately declared work MCP profile. |
| Bash, Fish, Git/GPG, SSH, Starship, tmux, Vim | ported | `modules/home/home/home.nix` restores the predecessor shell profile, full Starship module/prompt/battery/runtime configuration, Git identity/settings, GPG-agent policy and cleanup unit, generated SSH blocks, and tmux/vim bindings. |
| Vim | ported | WSL and native personal hosts restore the pinned Night Owl plugin/colorscheme and guarded last-edit-position behavior. |
| Syncthing | ported | `modules/services/syncthing/syncthing.nix` restores the Atlas system service and secret-backed topology, including the original folder paths/labels and Emerald Echo SteamOS membership, plus Home Manager clients on Kamino, ZaphodBeeblebrox, and Emerald Echo with filtered folders, the GUI credential secret, and the predecessor tray policy. |
| Firefox | ported | `modules/home/firefox/firefox.nix` restores the GUI-gated CSS files, policies, search aliases, preferences, MIME defaults, NUR add-ons, and pinned custom XPIs. `nix flake check --no-build` evaluates the graphical host path. |
| graphical-home, Konsole | ported | The shared profile restores the predecessor media/font and GUI desktop packages, its portable policy, the GUI-gated Night Owl Konsole scheme, and the desktop VSCodium default/Nix/Python/STM32 profiles. |
| GDrive | ported | `modules/home/gdrive/gdrive.nix` restores the per-host SOPS-backed rclone remote and `~/gdrive` mount for the predecessor's Sam profiles that enabled it, including Atlas and the two laptops. |
| GitHub CLI | ported | The common Sam profile enables GitHub CLI and its Git credential helper; WSL inherits the same behavior. |
| VS Code/VSCodium | ported | `modules/home/vscode/vscode.nix` retains the theme/input boundary, package-flavor/profile options, extension inventories, default/Nix/Python/STM32/Higi profiles, secret-wrapped launchers, and OpenSSH/desktop package adjustments. The WSL Windows policy now lives under `modules/home/vscode/wsl-vscode/_content.nix` and consumes the shared VSCode settings/snippet/extension payloads. Generated Windows extension manifests remain intentionally omitted because they contain immutable Linux store paths. |
| LazyVim | ported, disabled | `modules/home/lazyvim/lazyvim.nix` registers the full integration behind an off-by-default host fact. |
| Work and WSL work profiles | verified equivalent | `modules/platforms/wsl/wsl-work-home/wsl-work-home.nix` and related WSL modules restore the private CA/secret boundary, multi-SDK .NET toolchain, Azure DevOps CLI, NuGet credential provider/source, Pulumi/uv/Node packages, session policy, and Windows-owned Higi editor profile. |

### Nix tooling, system policy, users, and network

| Predecessor family | Classification | Broadcast reconciliation |
| --- | --- | --- |
| Dendritic metadata/prune-lock and development shell | ported | Generated flake metadata is intentionally simplified; `modules/dendritic/dendritic.nix` imports flake-file's Dendritic and nix-auto-follow modules, while `modules/tooling/devshell/devshell.nix` restores the default `just` and `pre-commit` development shell. |
| Flake constructors, inventory constructors, output helpers | structural glue | Replaced by direct `flake.nixosConfigurations` declarations in host modules and the broadcast registry. |
| Disko, Home Manager, SOPS, impermanence | ported | Delayed system-Nix modules under `modules/system/nix/` and `modules/features/impermanence/impermanence.nix`. |
| Formatter | ported | `modules/tooling/nix/formatter/formatter.nix` restores treefmt/nixfmt. |
| nix-index | ported | RPi updater and the reusable Home Manager database/`comma` integration are present. |
| Local package discovery/overlays | intentionally retired/replaced | Global package discovery is structural glue; Armory and Decky own their local packages directly, while NUR and the VS Code overlay are consumed by their own gated modules. |
| Determinate Nix | ported, intentionally enabled by default | Imported by the delayed Determinate module on every NixOS host. The current rewrite defaults to Determinate Nix, including WSL; WSL's certificate and trusted-user policy remains layered onto the resulting daemon. |
| Cross compilation | ported | `modules/tooling/cross-compile/cross-compile.nix` restores `aarch64-linux` binfmt for every derived builder host. |
| Bootstrap, deployment, systemd-boot policy | equivalent pending runtime validation | Declared variants and host boot edges remain direct; `bootstrap-enroll` is restored for explicit bootstrap tags and carries each variant's current final output name rather than deriving it from a display name. `modules/deployment.nix` replaces inventory metadata with self-gating host facts and restores the restricted remote account, Nix trust/sudo policy, local `nh` policy, Atlas builder routing, and guarded RPi deployment command. The predecessor Fish command surface—including direct remote switches, build-then-switch, secure deployment inspection, and Emerald Echo's standalone Home Manager activation—is retained as compatibility helpers backed by the broadcast output names. The deployer-side `sleepy` fact now wraps guarded and explicit unsafe remote deployments in a blocking `systemd-inhibit` lease. |
| Audio, Bluetooth, firmware, locale, nix-ld, NVIDIA, ZSA | ported | Corresponding feature/platform modules exist. |
| Plymouth and Wayland | ported | GUI-gated `modules/system/plymouth/plymouth.nix` and `modules/home/wayland/wayland.nix` restore the Cybernetic boot theme, quiet high-resolution boot policy, and `NIXOS_OZONE_WL=1`. |
| WSL base/certificates/work policy | verified equivalent | Output-scoped WSL modules restore interop, Docker Desktop, private CA handling, Nix trust/token settings, Fish, multi-SDK .NET, Azure/NuGet tooling, Git/GPG/SSH, Codex/MCP, and Windows editor synchronization including the stable Higi profile. |
| Sam users, secrets, Syncthing user state | ported | The native `github_nixos_token` Nix include, generic personal Git/GPG/SSH/Atuin/MCP policy, and the filtered Syncthing Home Manager clients are restored. Native and Pi/bootstrapped Sam accounts explicitly declare `sam` as their primary group before SOPS installs secrets owned by that group. |
| Static local DNS | ported | `modules/system/local-dns/local-dns.nix` plus service publication replaces the predecessor static/collector split. |
| Shared deploy/site/secret-wrap helpers | replaced | Descriptor-only helpers are retired. Their resulting deployment behavior is expressed by `my.deployment` host facts and `modules/deployment.nix`; only live credential/connectivity validation remains. |

### Services and host-output reconciliation

| Predecessor service family | Classification | Broadcast destination |
| --- | --- | --- |
| Attic, Atuin, Blocky, Caddy/Fail2ban, DHCP/CoreDNS, Frigate, Immich, Mealie, Samba, Scrutiny, SSH | reconciled | Matching self-gated files in `modules/services/`; completed option and enabled-host evidence is in the verification table below. |
| Media base, networking, and Arr workloads | reconciled | Split into independently gated `modules/services/*/*.nix` wrappers for `media-network`, `airsonic`, `arr-sync`, `bazarr`, `deluge`, `flaresolverr`, `gonic`, `jellyfin`, `ombi`, `organizr`, `plex`, `profilarr`, `prowlarr`, `radarr`, and `sonarr`; completed evidence is below. |
| Notifications | reconciled | `modules/services/{apprise,gotify,ntfy}/*.nix`; completed evidence is below. |
| Minecraft and printing | reconciled | `modules/services/minecraft/minecraft.nix` and `{printing,ankerctl}.nix`; completed evidence is below. |
| Docker and Podman support | reconciled | Separate feature switches in `modules/features/{docker,podman}.nix`; completed evidence is in the feature table below. |
| NetBird client/server | reconciled | `modules/services/{netbird-client,netbird-server}/*.nix`; completed evidence is below. |
| NetBird proxy | intentionally retired | The predecessor media-server import left `netbird-proxy` commented out, so it supplied no effective host behavior. The active NetBird server module owns its public Caddy routes directly. |
| Watchtower | reconciled | `modules/services/watchtower/watchtower.nix`; completed evidence is below. |
| X server policy | ported | `modules/features/desktop/desktop.nix` contains the same desktop-session gate and `nvidia`/`intel`/`modesetting` driver list as the predecessor X-server module. |

The predecessor host families are reconciled as follows:

- **Atlas, Kamino, Zaphod, RPi boards, NixOS-WSL, and Emerald Echo:** ported as
  direct outputs with host facts and host-edge modules. Existing image,
  bootstrap, installer, and boot-mode variants are declared directly rather
  than assembled by descriptor builders.
- **Host descriptor/registration/export files:** structural glue, intentionally
  retired.
- **Steam Deck profile helpers:** structural glue where they assemble profiles;
  behavior is ported to the Steam Deck platform, Jovian integration, Decky modules,
  and direct variant tags. Runtime Decky validation remains pending.

## Planned implementation ledger

The source audit closed on 2026-07-28. The four confirmed declarative gaps
found during that audit—flake description metadata, the Office package,
media UID validation, and native VS Code/VSCodium parity—have been corrected.
Remaining work is runtime validation on the affected machines, not unreviewed
source scope.

After those changes, the remaining tracks require a host build, boot, or
activation:

1. Perform the recorded runtime builds/boots and host activation checks.
2. Perform runtime music-library validation on Atlas before relying on the
   Demlo command and the explicitly enabled Beets/Demlo user configuration.

## Verification closure: current state

This section closes the current verification pass. It records the exact level
of evidence available today; it does **not** promote a module to verified just
because it evaluates.

### Verified equivalent

- Audio, Bluetooth, firmware, nix-ld, ZSA, and KDE desktop policy were
  compared directly and match the predecessor behavior. The desktop module's
  derived `desktopSession` gate is an intentional narrowing of the old `gui`
  gate for X-server configuration.
- treefmt/nixfmt and nix-auto-follow are verified as flake tooling: the
  formatter/check evaluate and Dendritic imports the follow-pruning module.

### Verified partial or changed behavior

- Demlo's active system package is equivalent; it remains subject to the
  recorded Atlas runtime media-path validation. Beets and Demlo user
  configuration are an explicit Atlas enhancement, split into their own
  feature modules.
- A follow-up source review found native Sam-profile differences; the GitHub
  Nix token include, Git/GPG/SSH identity policy, Atuin/MCP clients, filtered
  user Syncthing clients, Vim/Starship/tmux configuration, and local
  deployment-helper payload are now restored. Their remaining work is runtime
  validation rather than missing declarative configuration.

### Completed source-comparison scope

The service, feature, platform, integration, publication, host-edge, and
shared Home Manager inventories have received a predecessor-option and
enabled-consumer comparison. Their individual results appear in the tables
that follow. Items labelled **changed** or **untested** are intentional
divergences or runtime-validation work; they are not unreviewed candidates.

### Verification conclusion

The rewrite is structurally valid and evaluates: on 2026-07-21,
`nix flake check --no-build` evaluated every declared runtime, bootstrap,
image, installer, Steam Deck, and WSL configuration. Behavioral parity is
nevertheless **not complete**: remaining work is operational and runtime
validation in this audit and `migration-status.md`. No task may be marked
complete merely because an output evaluates; source evidence and the affected
host consumer remain required for each disposition.

### Verification findings: initial services

- **SSH — verified equivalent.** Server/RPi auto-activation is retained; the
  remotely managed Kamino and Zaphod hosts set the explicit SSH service fact,
  and the former unintended Steam Deck activation is removed.
- **Attic — verified equivalent.** The configurable `hostName` drives Caddy
  and DNS publication, and the bootstrap helper now emits the concrete public
  cache endpoint derived from the secret domain.
- **Atlas Caddy, Mealie, Naboo Blocky, and Naboo CoreDNS — evaluated
  equivalent (2026-07-27).** Direct evaluation against main confirmed the
  Mealie settings, Blocky settings, and rendered CoreDNS configuration. The
  review restored Mealie's per-vhost console DEBUG log format. Atlas Caddy has
  the same virtual-host and apex endpoint set; remaining route-order and
  indentation differences do not change matching or proxy targets.
- **Deployment helpers and builders — evaluated equivalent (2026-07-27).**
  Zaphod's generated SSH host blocks and all evaluated remote-builder entries
  match main.  The guarded Pi path now uses the configured `nix-<host>` target
  alias and installs its lock cleanup before acquiring the target lock, so a
  failed lock attempt cannot strand a retry-blocking lock.
- **Runtime-host networking and boot policy — evaluated equivalent
  (2026-07-27).** Atlas, Naboo, Nevarro, and Zaphod have matching effective
  network, DNS, gateway, firewall, user, and service policy. Atlas again sets
  systemd-boot's console mode to `max`; the generic Pi kernel, duplicate-safe
  initrd module aliases, and serial-console arguments remain intentional Pi
  migration choices. Pi hosts also force an empty `boot.kernel.sysctl`, as
  main does, avoiding unsupported generic `vm.mmap_rnd_bits` writes during
  `systemd-sysctl` activation; their `zstd` 100%-RAM zram configuration is
  unchanged.
- **Desktop boot and Airsonic identity — evaluated equivalent (2026-07-28).**
  Kamino and Zaphod use the Cybernetic Plymouth theme, maximum boot-console
  mode, and 1920×1080 framebuffer policy; Kamino receives this from the shared
  GUI-gated module, so no host-specific duplication is needed. Atlas Airsonic
  evaluates to the matching UID/PUID 2101, media GID/PGID 2096, and identical
  media/config bind mounts.
- **Atlas OCI container surface — evaluated equivalent (2026-07-28; rechecked
  2026-07-29).** All twelve enabled containers have matching image references,
  environment, ports, mounts, dependencies, network options, and journald
  logging. Plex uses main's pinned LinuxServer image again; the generated
  Minecraft plugin store path is the only expected derivation-path difference.
- **Firefox profile CSS — evaluated equivalent (2026-07-27; rechecked
  2026-07-29).** The tab-toolbar stylesheet is installed beneath the profile's
  `chrome/chrome/` path on laptop graphical homes, matching the relative import
  from generated `userChrome.css`. Emerald Echo remains disabled like main.

### Verification findings: service implementations

The following table is the completed source comparison for every current
`modules/services/*/*.nix` implementation. “Equivalent” means the predecessor
service payload and its current enabled-host consumer match after the option
namespace was moved to `my.host.services.*`; “changed” identifies a concrete
lost or narrowed interface. Added tmpfiles rules and fact-gating alone are not
treated as regressions.

| Broadcast service | Predecessor counterpart | Disposition and evidence |
| --- | --- | --- |
| `airsonic`, `arr-sync`, `bazarr`, `deluge`, `flaresolverr`, `gonic`, `jellyfin`, `ombi`, `organizr`, `plex`, `profilarr`, `prowlarr`, `radarr`, `sonarr` | corresponding `media/**` modules | **Equivalent.** Container/service payloads, paths, proxy routes, identities, and Arr 4K systemd units match. The old `_arr` helper was inlined; added tmpfiles rules make required state explicit. |
| `media-network` | `media/_podman-network.nix` | **Verified equivalent.** The network is now created for either Deluge or Watchtower, every current consumer, and both consumers order after it. |
| `watchtower` | `containers/watchtower/watchtower.nix` | **Verified equivalent with intentional Podman adaptation.** It mounts Podman's native socket at Watchtower's Docker-socket path and asserts Podman; standalone operation now has the required media network and ordering. It does not enable Podman's competing Docker-compatible host socket, because Atlas also retains Docker and current NixOS correctly rejects two providers for that socket. |
| `apprise` | `notifications/apprise/apprise.nix` | **Verified equivalent.** Hostname, configuration directory, and attachment directory options have been restored. |
| `gotify`, `ntfy`, `atuin`, `ankerctl`, `frigate` | corresponding notification/printing/service modules | **Equivalent.** Their publication, authentication, listener, and runtime settings match after moving enablement to host facts. |
| `blocky` | `blocky/blocky.nix` | **Verified equivalent.** Configurable Prometheus enablement/port/path, conditional firewall exposure, and CoreDNS ordering are restored; Naboo and Nevarro explicitly enable metrics as before. |
| `dhcp-coredns` | `dhcp-coredns/{dhcp-coredns,dhcp-failover}.nix` | **Verified equivalent.** Interface/state/listener/upstream/static-record options, zone apex/mail handling, duplicate detection, lease conversion/lifetimes, exposed tools, and the timed `dhcp-failover` service/timer are restored. Coruscant’s published Home Assistant record is the single source of truth. |
| `caddy` | `caddy/{_caddy-service,_fail2ban}.nix` | **Verified equivalent.** Route rendering, plugins, Fail2ban filters/jails, target-aware Cloudflare lookup, IP/jail validation, scope/token diagnostics, idempotent actions, and structured Cloudflare API error logging are restored. |
| `immich` | `immich/immich.nix` | **Verified equivalent.** Configurable hostname and external-domain options are restored; Atlas’s media path remains present. |
| `mealie` | `mealie/mealie.nix` | **Verified equivalent.** Configurable hostname, base URL, and registration policy are restored. |
| `monitoring` | `monitoring-stack.nix` | **Verified equivalent.** Configurable public hostnames, optional basic-auth controls, Smartctl enablement, the predecessor Atlas, Blocky, and RPi metric coverage, and the complete Grafana panel layouts, legends, transformations, and thresholds are restored. |
| `netbird-client` | `netbird/netbird-client.nix` | **Equivalent.** Client routing and firewall policy match. |
| `netbird-server` | `netbird/netbird-server.nix` | **Verified equivalent.** The Pocket-ID secret path and public topology match; the explicit Podman assertion documents the relay container prerequisite already implicit in the predecessor runtime. |
| `samba` | `samba/samba.nix` | **Verified equivalent.** The reusable settings-merge interface is restored as `my.samba.settings`; Atlas’s direct NixOS share settings also remain effective. |
| `scrutiny` | `scrutiny/scrutiny.nix` | **Verified equivalent.** The configurable hostname is restored. |
| `syncthing` | `syncthing-server/syncthing-server.nix` and Home Manager client module | **Verified equivalent.** Atlas retains the system service while Kamino, ZaphodBeeblebrox, and Emerald Echo receive the filtered Home Manager clients, GUI credential secret, matching tray behavior, original folder paths/labels, and Emerald Echo SteamOS folder membership. |
| `minecraft` | `games/minecraft/minecraft.nix` | **Verified equivalent.** Runtime settings and the predecessor Floodgate artifact spelling match. |
| `printing` | `printing/printing.nix` | **Verified equivalent.** Activation now follows the predecessor non-handheld workstation scope. |
| `monitoring-exporters` | no standalone predecessor module | **New broadcast glue.** It supplies generic Prometheus node and SMART exporters for hosts selected by `my.host.services.monitoringExporters`; Naboo and Nevarro enable it for the predecessor monitoring targets. Runtime scrape validation is still required. |

This replaces the former blanket “ported candidate” label for service modules.
The changed rows are implementation work, not merely documentation debt, and
are mirrored in `migration-status.md`.

### Verification findings: host, platform, and output edges

| Current edge | Predecessor equivalent | Disposition and evidence |
| --- | --- | --- |
| Atlas runtime, disk, storage, users, and builder edge | `server/atlasuponraiden/_atlas/**` | **Equivalent for physical/runtime policy.** RAID/storage mounts, mirrored-ESP installation replacement, Intel microcode, media identities, users, Samba shares, deployment SFTP access, and the evaluated four-feature Nix builder set were compared. The old NetBird proxy stanza remains commented out in both effective configurations. The predecessor Atlas bootstrap output was retired because there is no known current use for it. Service-level changes are governed by the table above. |
| Kamino and Zaphod runtime facts, hardware, disks, and users | `laptop/{kamino,zaphodbeeblebrox}/**` | **Equivalent pending runtime validation.** Their predecessor `containers` feature maps to both Docker and Podman. Their desktop feature lists, builder role, physical edges, native Git/GPG/SSH/Atuin/MCP profile, filtered Syncthing client/tray policy, VSCodium remote extensions, .NET SDK, and STM32CubeMX package match. Armory is an intentional Zaphod-only addition and is not built or run on this machine. |
| Naboo and Nevarro runtime/image edges | `rpi/{naboo,nevarro}/**`, `deployment.nix` | **Equivalent pending hardware/runtime validation.** Static addresses, resolver pairing, service activation, image outputs, exporters, DNS/DHCP behavior, restricted deployment account, peer-gated target locking, device access, and the safe Pi 4 hardware subset are present. |
| NixPi runtime, image, and bootstrap-image edges | `rpi/nixpi/**` | **Equivalent pending hardware/runtime validation.** DHCP/runtime and image/bootstrap variants, bootstrap user/groups/key, generic RPi policy, device access, and the safe Pi 4 hardware subset match. |
| Coruscant and Ferrix | `rpi/{coruscant,ferrix}/**` | **Equivalent pending hardware/runtime validation.** Static RPi address facts live with each host while common static `end0` wiring remains in `rpi-network.nix`; Coruscant's Home Assistant DNS publication and device access are retained, and the safe Pi 4 hardware subset is restored. |
| Emerald Echo runtime, dual-/single-boot, bootstrap, installer, and SteamOS-home edges | `steamdeck/emeraldecho/**` | **Equivalent source policy, pending runtime validation.** The variant matrix, boot tags, SteamOS mount activation, users, ISO parameters, package/SSH/deployment-key policy, and SteamOS-home behavior are present as Emerald Echo host content. Reusable Steam Deck disk, boot, graphics, audio, font, Nix-retention, KDE Connect, Flatpak, Jovian splash, timezone, Dvorak graphical layout, and Plasma Desktop Mode policy now live under the Steam Deck platform modules. Decky and Steam runtime behavior still require validation. |
| NixOS-WSL output and work boundary | `wsl/nixos-wsl/**` and predecessor WSL Home Manager modules | **Verified equivalent with intentional Determinate change.** Output-scoped NixOS-WSL activation, WSL interop/Docker/certificates/Nix trust, the work profile, Windows Code/Higi synchronization, workstation/nix-ld/local-checkout facts, local `nh`/Fish/formatter tooling, work MCP inventory, and the Home Manager SOPS session helper have been restored and closure-checked. Determinate remains an intentional change while its certificate/trust policy stays layered onto its daemon. |
| `platform-x86`, `rpi-base`, `platform-rpi`, `rpi-status`, `rpi-nix-index`, `rpi-network` | predecessor x86/RPi common modules | **Equivalent pending hardware/runtime validation.** x86 host platform and RPi boot/root/network/MOTD/index/static-addressing/device-access behavior match, including evaluated RPi kernel params and initrd module names. Static RPi addresses and resolvers are host facts; `rpi-network` owns only the shared static `end0` mechanics. The Pi output boundaries import upstream `nixos-hardware.raspberry-pi-4`, restoring firmware, device-tree, and boot-loader policy while the cache module explicitly keeps the generic kernel. The predecessor `nixos-raspberrypi` input, its unused `pkgs.rpi` overlay, and its now-unused Cachix trust are retired; active Pi kernel and firmware derivations come from Nixpkgs. |
| `platform-steamdeck` hardware/boot-modes, `hardware-atlasuponraiden`, per-laptop hardware/disk modules | predecessor hardware/filesystem modules | **Equivalent.** Steam Deck physical boot, graphics, audio, dual-boot filesystem policy, and single-boot Disko policy are platform-gated instead of EmeraldEcho-gated. Atlas and laptop hardware/disk modules remain self-gated copies of predecessor physical configuration; the generic NVIDIA feature policy also restores the predecessor Intel-microcode default. |

The host comparison also confirms that the old descriptors, registration
builders, output constructors, and deployment records are structural assembly
glue. Their resulting runtime configuration is accounted for in the rows
above; `modules/deployment.nix` is the current deployment consumer, with only
live key, connectivity, and remote-switch validation outstanding.

### Verification findings: feature and shared-policy modules

| Broadcast area | Disposition |
| --- | --- |
| `audio`, `bluetooth`, `firmware`, `nix-ld`, `zsa`, `desktop` KDE policy, `appimage`, `deskflow`, `docker`, `flatpak`, `minecraft` tools, `threedprinter`, `steam` | **Equivalent.** Direct comparison found only self-gating/formatting changes or the deliberate central unfree-package collector. |
| `bitwarden`, `noson` | **Verified equivalent.** The restored desktop Sam profile receives these through Home Manager, matching the predecessor user scope. |
| `office` | **Verified equivalent.** The Home Manager package scope includes `libreoffice-qt6`, matching main. |
| `wine` | **Verified equivalent.** Packages, Nixpkgs policy, fonts, 32-bit graphics/audio, dconf, and the OpenLDAP test workaround match. |
| `podman` | **Equivalent base runtime.** It enables Podman and selects it as the OCI backend. Watchtower uses Podman's native socket directly, so it remains compatible with Atlas retaining Docker. |
| `nvidia` | **Verified equivalent.** The generic Intel microcode default is restored alongside the driver, graphics, PRIME, and unfree policy. |
| `beets`, `demlo` | **Verified equivalent declarative behavior.** Atlas runtime access to the music library remains to be exercised. |
| `impermanence` | **Verified equivalent.** System paths, FUSE policy, persistence helper, and shared Home Manager hook match. |
| `armory` | **Intentional addition; untested here.** The pinned legacy runtime, SDM quoting fix, HOME/working-directory launcher, offline launcher, desktop entry, and Bitcoind path are provided only when explicitly enabled. |
| `base`, `locale`, `cli-tools` | **Equivalent.** Locale and base restore Dvorak, tmpfs/clean-on-boot, ZFS import policy, Nix store/build settings, substituter order, the native GitHub token include, the domain-derived Attic endpoint, and Atlas public key; the Steam Deck deliberately retains its predecessor override that does not keep derivations or outputs. The CLI module installs `write-flake`, `write-inputs`, and `write-lock` on local-checkout hosts, and the PyQt DHCP reservations editor only on local graphical checkout hosts. |
| `disko`, `home-manager`, `secrets`, Steam Deck Jovian/Decky, and NixOS-WSL integration boundaries | **Equivalent source policy, pending runtime validation.** Broad option providers evaluate everywhere; NixOS-WSL and the private Steam Deck bundle are imported only by their matching output boundaries. Host activation remains to be exercised. |

Accordingly, the earlier “Required option-level verification work” table is
superseded: all current service, feature, platform, integration, and host-edge
modules now have a recorded disposition in this audit. A disposition of
**partial**, **changed**, or **pending** is required remaining work, not an
equivalence claim.

## Content-preservation review

This source-level review is complete for the tracked predecessor payloads. It
compares predecessor-generated scripts, source patches, fallback branches,
package checks, and output-boundary profiles rather than accepting an
equivalent-looking rewrite. It restored the WSL editor-sync helper and work
Codex/Git profile, Pi status/index fallbacks and reporting, bootstrap
enrollment guidance, Attic script checks and consumer instructions, and Decky
patch/runtime-bundle safeguards. A real WSL activation changelog then exposed
omitted workstation/nix-ld/local-checkout facts and incomplete Windows Code
profile content; they were restored and independently closure-compared below.

On 2026-07-30, the normalized `nix-dendrites-main-content` checkout was used
as an additional source reference. A compact option-slice comparison matched
the rewrite against main-content for host Disko layouts, RPi boot policy, WSL
policy, Atlas local-DNS/Caddy publication, native Home Manager Git/GPG/SSH/
Starship/tmux/Vim payloads, Firefox profile/search data, and VSCodium settings.
Differences observed before normalization were list or route ordering only.

### WSL activation-closure comparison (2026-07-22)

The predecessor and broadcast WSL system-package closures were compared by
evaluating `environment.systemPackages` by package name. After restoring the
descriptor facts and local tooling, they match for the predecessor package set:
printer/Avahi support, `nh`, `treefmt`, `write-flake`, `write-inputs`,
`write-lock`, and the separate `ps` package are again present. The deliberate
remaining system closure difference is Determinate Nix (and its daemon), which
replaces the predecessor's stock Nix implementation.

The Home Manager package closure matches after removing the broadcast-only
Atuin and `xclip` additions. Its local flake path evaluates to
`/home/ssorensen/src/nix-dendrites`, matching the active checkout path. The
predecessor's Marketplace-resolved VS Code extension closure and its Higi/Nix
profile `extensions.json` metadata are retained, while Windows remains the live
extension location. The preserved identifiers also drive explicit Windows-side
installation.

The WSL Code profiles receive the predecessor work MCP set (Azure, Azure
DevOps, Context7, GitHub, NixOS, Postman, Pulumi, and Snyk) through Home
Manager's MCP integration. They do not receive the personal Arr MCP profile.

The resulting WSL configuration was activated successfully on 2026-07-22.
This validates the Determinate Nix handoff, work-only SOPS activation, Home
Manager `SOPS_AGE_KEY_CMD`, NuGet template, and Home Manager Code profile
generation; it does not by itself validate each Windows-side extension or MCP
server at runtime.

WSL now uses the shared local-checkout `nhs`/`nhsu` implementation.  The
former WSL-specific aliases overlapped with the shared function after Home
Manager merged them, producing a recursive switch loop.  The shared
implementation retains WSL's `-j`/`--max-jobs` argument handling while keeping
`nhs`/`nhsu` as the one command surface for every host with a local flake
checkout.

After restoring the empty Python/STM32 profile metadata and Nix-profile
snippets, the remaining managed-file differences are intentional format or
source-interface replacements: Codex's versioned wrapper preserves the CLI's
TOML configuration interface at `config.toml`. Firefox custom add-ons retain the
predecessor's generated JSON-to-Nix model, now exposed as the repository
package `update-firefox-addons` (`nix run .#update-firefox-addons`) rather than
a Fish function. The package is installed on local-checkout hosts alongside
`nix-auto-follow`, the formatter, and flake-writing tools, without embedding a
machine-specific checkout path.
