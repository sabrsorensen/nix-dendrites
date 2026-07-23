# Architecture guide

## Purpose

This repository uses Dendritic Nix to make host intent easy to see and shared
behavior easy to change. The desired experience is that enabling a feature,
adding a service, or understanding a host should require reading a small,
direct fact block—not following descriptor builders and several layers of
imports.

This document is normative. Prefer a small, explicit exception over a new
abstraction that obscures which host receives what.

## The model: broadcast and gate

`import-tree` imports every Nix file in `modules/` unless its path contains
`/_`. NixOS configuration modules register themselves in
`flake.modules.nixos`; flake tooling may instead use ordinary flake-parts
interfaces. A host configuration broadcasts the complete NixOS registry:

```nix
modules = builtins.attrValues config.flake.modules.nixos ++ [ hostFacts ];
```

There is intentionally no `all.nix`, category aggregator, or per-host list of
generic module imports. Adding a reusable module must not require updating a
central list.

Broadcasting means every reusable module is evaluated for every NixOS host.
Therefore a reusable module must be safe when its capability is absent and use
`lib.mkIf` to activate its configuration. Examples:

```nix
lib.mkIf config.my.host.features.docker { virtualisation.docker.enable = true; }
lib.mkIf config.my.host.services.samba { services.samba.enable = true; }
lib.mkIf config.my.host.is.rpi { /* RPi defaults */ }
```

Do not conditionally import an ordinary reusable broadcast module from a host.
That recreates the hidden selection graph this structure removes. Inputs whose
option surfaces are unsafe to broadcast remain explicit output-boundary
exceptions.

## Host facts are the interface

Every host declares its intent directly in `my.host`:

```nix
my.host = {
  name = "Kamino";
  formFactor = "laptop";
  roles = { workstation = true; builder = true; };
  features = { gui = true; docker = true; nvidia = true; };
  services = { minecraft = true; };
};
```

Use the buckets consistently:

- `roles`: broad environment or identity—`workstation`, `server`, `rpi`,
  `steamdeck`, `wsl`, and similar classifications.
- `formFactor`: physical/operational shape—`laptop`, `desktop`, `handheld`,
  `server`, or `vm`.
- `features`: a local capability or policy toggle—GUI, Docker, Podman,
  firmware, NVIDIA, Flatpak, Steam, the personal MCP client profile, and
  desktop tools.
- `services`: a system service intentionally hosted there—Samba, Scrutiny,
  Minecraft, DNS/DHCP, and later service-stack entries.
- `tags`: rare grouping or exception labels.
- `is`: derived, read-only booleans for module authors.

Module authors normally read `my.host.is.*` for broad classifications and
`my.host.features.*` or `my.host.services.*` for concrete activation. Avoid
host-name checks except for genuine hardware-edge facts.

## Docker and Podman are separate choices

`features.docker` and `features.podman` are deliberately separate. A generic
`containers` switch made it unclear which runtime was selected and could enable
both. A host must state the runtime it wants. A service that needs OCI
containers should not silently select one for the host.

## Native capability first

Prefer the native NixOS option surface when it expresses the host capability.
When an input provides a safe NixOS option-provider module, import it through a
bootstrap-delayed broadcast module and gate its configuration with host facts.
For example, `nix-flatpak` exposes declarative Flatpak package management to
all hosts, but only hosts with `features.flatpak` receive any Flatpak state.

## Host directories are organization, not assembly

Keep host-specific files together:

```text
modules/hosts/kamino/
  host.nix       # output and visible facts
  hardware.nix   # self-gating hardware, disks, boot, network edge facts
  users.nix      # if truly host-specific
```

Each public file is independently discovered by `import-tree`. It may use a
private `_` helper in the same directory, but public host files must not form a
feature or service import aggregator. Host directories communicate locality to
humans, while self-gating preserves the broadcast model for Nix.

Put device UUIDs, bootloader configuration, physical interfaces, disk layouts,
and exceptional hardware quirks here. Keep broad policy out of these files.

## Architecture versus integration roles

CPU architecture and platform integration are different concerns:

- Steam Deck is `x86_64-linux`; it receives the normal x86 layer.
- Steam Deck also has `roles.steamdeck = true`. Its private Steam Deck role
  bundle imports Jovian and Decky only at Emerald Echo's output boundary; those
  modules must not enter the universal module set because Jovian overlays the
  ordinary Steam package with the Steam Deck runtime.
- Raspberry Pi is an aarch64 host with `roles.rpi = true`; shared Pi defaults
  belong in an RPi-gated module, while each board's boot and network facts stay
  in its host directory.
- WSL is identified by `roles.wsl = true`. Its current output also declares
  `formFactor = "vm"`, so module policy must use the role rather than treating
  that form factor as a WSL discriminator.
- Personal MCP clients use the explicit `features.personalMcp` opt-in rather
  than a form-factor heuristic. WSL therefore retains only its separately
  declared work MCP configuration.

Do not create a separate architecture layer merely because a machine has a
special integration stack.

## Services and publication

Service enablement belongs in the visible host facts:

```nix
my.host.services.scrutiny = true;
```

The service module owns the implementation and gates on that fact. When a
service needs host-specific data (storage path, public name, credentials
reference), add that data alongside the service declaration in the host-facing
schema rather than putting it in an import helper or a hidden descriptor.

Reverse-proxy and local-DNS publication are shared service concerns. Build a
small, explicit publication interface before porting services that need it;
do not copy a service module while dropping its publication behavior or revive
a hidden central service importer.

The local-DNS interface is `my.localDns.records`: a service publishes short
hostnames there and may omit `ip` when its host has `my.host.address`. The
derived `my.localDns.publishedRecords` contains only concrete records and is
the interface DNS authorities consume. Host-edge network modules own the
address; services own only the names they publish.

The flake-level collector reads `publishedRecords` from ordinary host outputs.
DNS authorities do not collect themselves; their bootstrap records remain
explicit. This avoids a Nix evaluation cycle while keeping service publication
decentralized.

## Inputs and bootstrap safety

Use `flake-file`, `flake-parts`, and the Dendritic bootstrap in
`modules/dendritic.nix`. Declare a new input there, then regenerate:

```bash
nix run .#write-flake
```

`flake.nix` is generated. The `/_` path convention excludes private helpers
and bootstrap-delayed input consumers from automatic discovery; it is not a
substitute for `all.nix` or a general module-grouping mechanism.

The Firefox custom-add-on source list is
`modules/_firefox-addons.json`; refresh its committed generated package set
with `nix run .#update-firefox-addons`. This update tool is installed on hosts
with `my.deployment.localFlakePath`, along with `nix-auto-follow`, the
formatter, and flake-writing tools. It performs AMO lookups only when
explicitly invoked; normal evaluation and deployment use the pinned generated
Nix file.

When an input provides a NixOS module that is safe to import everywhere, use a
public bootstrap module plus a private `/_` delayed module: the public file
declares or waits for the flake input, and the delayed file registers a
broadcast NixOS module that imports the input module. Gate its configuration,
not its import, with `my.host` facts. This makes the input's options shared
vocabulary without enabling its behavior everywhere.

Keep a NixOS input host-scoped only when importing it is itself unsafe: for
example, it has unconditional platform behavior, assertions, incompatible
evaluation, or special-argument requirements. Record that exception and why.

### The WSL exception

`nixos-wsl` is deliberately host-scoped. Its option-provider module is added
only to the `nixos-wsl` output in `modules/hosts/nixos-wsl.nix`; the ordinary
broadcast module contains only portable user policy gated by `roles.wsl`.

This is not a stylistic exception. `lib.mkIf` gates configuration values, not
the evaluation of option names. Putting `wsl.enable` in a broadcast module
would still make non-WSL hosts encounter an unknown `wsl` option before the
WSL module supplied it. When an input's options are unavailable to ordinary
hosts, scope the import at the output boundary instead of trying to hide it
behind `mkIf`.

### Raspberry Pi kernel cache policy

The RPi cache module uses the generic Nixpkgs `pkgs.linuxPackages` as the
default kernel package set. The normal NixOS binary cache supplies that kernel
and the active Nixpkgs firmware packages; the retired `nixos-raspberrypi`
Cachix cache is neither required nor trusted.

Do not switch a Pi host to a downstream `linux_rpi` package set merely because
it sounds more specific. First verify a substitute for the exact derivation.
An otherwise-valid downstream kernel can turn routine DNS-rule changes into a
multi-hour local rebuild.

Secrets are data inputs, not architecture. A host hardware module may read a
UUID from the secrets input directly when that is the source of truth, but it
must not import configuration from another repository.

## Porting method

Port one behavior at a time as a new module. It may consult the prior
configuration to preserve derivation content, but the new module must stand on
its own: no imports of old modules, no compatibility wrappers, and no
descriptor bridge.

Preserve predecessor content by default. The rewrite may change registration,
module boundaries, and activation gates, but it must carry forward scripts,
patches, fallback paths, validation checks, and user-facing behavior verbatim
unless a concrete incompatibility or an explicitly documented policy decision
requires a change. A shorter or more idiomatic replacement is not sufficient
justification by itself.

Recommended order:

1. Create the host facts and shared option schema.
2. Port generic feature and role modules with self-gating.
3. Port host-edge hardware, boot, filesystem, and network modules into the
   relevant host directory.
4. Port service implementations behind `my.host.services.*`.
5. Port shared publication/data layers needed by service stacks.
6. Evaluate each affected configuration, then run broad checks once required
   host-edge configuration exists.

Do not fake a successful full check by adding generic root filesystems or boot
settings that do not describe the actual machine.

## Editing discipline

Before patching an existing file, read its current contents from disk in the
current worktree. Do not patch from memory, an earlier terminal result, a chat
excerpt, or an assumed version of the file. Other work may have changed it,
and a patch should preserve those changes intentionally.

After a patch fails to apply, stop and re-read the target before trying again.
Do not broaden context or force a replacement based on the stale version.

Before creating a file, verify that its parent directory exists. Create the
directory explicitly when needed, then add the file. Do not assume a patch or
write operation will create missing parent directories; this keeps failures
clear and avoids partially applied migrations.

## Validation

Nix reads the Git snapshot. Intent-add new files before evaluation:

```bash
git add -N path/to/new-file.nix
```

Use focused evaluation while a host is being ported:

```bash
nix eval .#nixosConfigurations.kamino.config.system.build.toplevel.drvPath
```

Use `nix flake show` to verify output discovery. Run `nix flake check` only
when each output being checked has its real boot and filesystem configuration.
An assertion about a missing root filesystem is an honest indication that a
host edge has not yet been ported, not a reason to weaken the check.

`nix flake check --no-build` composes configurations but does not necessarily
force every system top-level derivation. Before a first activation, evaluate
the exact target's `config.system.build.toplevel.drvPath`; this catches
activation-only errors such as an unresolved `/etc` entry.

Build-time checks also apply to generated helper scripts. `writeShellApplication`
uses ShellCheck, so deletion commands must guard every path component (for
example, `${var:?}`) rather than relying only on earlier validation.

### Atlas dual ESP intent

Atlas has two EFI system partitions so the machine remains bootable after one
boot disk fails. The secondary ESP must contain the same current bootloader,
entries, kernels, and initrds as the primary. The implementation may change,
but it must synchronize additions and deletions after every bootloader update.

Do not remove or stop synchronizing the second ESP merely to make evaluation
pass. Validate changes with a real bootloader update and a recovery boot from
the secondary disk.

## Record lessons when they are learned

When implementation, evaluation, or a user decision reveals a non-obvious
constraint, add the lesson to this document in the same change (or create a
short focused document linked here). Record:

1. the decision or observed behavior;
2. why it matters;
3. the rule or preferred pattern that follows; and
4. the validation that demonstrated it, when applicable.

Examples include the Docker-versus-Podman split, Steam Deck being x86 plus a
private Jovian role bundle, `imports` not being placeable behind `mkIf`, and
keeping host-specific files together without using them as an import
aggregator.

Do not rely on chat history, memory, or a future maintainer rediscovering the
same failure mode. If it was expensive or surprising to learn, document it.

## Migration progress is a maintained interface

Keep `docs/migration-status.md` accurate in every porting change. Add each
discovered missing behavior to its remaining-work list before or alongside the
implementation, then move it to completed work in the same change once its
focused evaluation passes. Do not leave completed tasks in the remaining list,
and do not claim parity while a predecessor behavior is untracked.
