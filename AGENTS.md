# AGENTS

This repo is a Dendritic Nix flake with a gradually increasing
property-driven module model.

## Quick Commands

Run these before inventing one-off workflows:

```bash
just
just fmt
just write-flake
just check
just checknb
just update
nix develop
```

When a module adds or changes `flake-file.inputs`, regenerate `flake.nix`:

```bash
just write-flake
```

## Repo Shape

- `flake.nix` is generated from `./modules`.
- `modules/*` is the source of truth.
- `modules/*/flake-parts.nix` is bootstrap-safe input declaration.
- `modules/*/_*.nix` is delayed consumption for inputs that cannot be imported too early.

## Design Direction

Prefer property-driven behavior over per-host import selection.

The current host metadata model is `my.host.*`. Keep it as the only host
metadata namespace.

Use these buckets consistently:

- `my.host.roles.*`: broad intent and environment class such as workstation, server, rpi, steamdeck, wsl.
- `my.host.formFactor`: physical or operational shape such as `laptop`, `desktop`, `handheld`, `server`, `vm`.
- `my.host.features.*`: concrete capabilities or policy toggles such as `gui`, `bluetooth`, `firmware`, `nix-ld`, `nvidia`, `flatpak`, `steam`, `wine`, `deskflow`, `minecraft`, `threedprinter`, `zsa`.
- `my.host.tags`: sparse escape hatch for grouping and exceptions.
- `my.host.is.*`: derived read-side booleans for module authors.

`features.gui` means the host is expected to run a local graphical session.
Use it for shared desktop/session behavior, not merely as a marker that some
graphical applications happen to be installed.

Prefer module conditions against `my.host.is.*` or `my.host.features.*`.
Avoid growing new ad hoc host-name checks unless the behavior is truly a
one-off exception.

Rule of thumb:

- use `my.host.is.*` for broad class decisions
- use `my.host.features.*` for capability or policy toggles
- use `my.host.roles.*` and `my.host.formFactor` to define hosts, not to read them directly in most modules

For server classification, treat `roles.server` as the authoritative host
declaration. `formFactor = "server"` is still useful metadata, but module code
should prefer `my.host.is.server` instead of reading either raw field directly.

## Host Conventions

Host directories should trend toward:

- hardware
- disks/filesystems
- local networking facts
- secrets wiring
- explicit feature flags
- true one-off exceptions

Host directories should trend away from:

- long lists of generic feature imports
- restating broad desktop or CLI policy

## Module Conventions

When adding a reusable module:

1. Decide whether it is a broad default, a capability-gated module, or a true opt-in stack.
2. If it is broadly reusable, gate it with `lib.mkIf` using `my.host.*`.
3. If it is a stack or bundle with intentional coupling, keep it explicit.
4. If it needs a new flake input, use the `flake-parts.nix` plus `_module.nix` split.

Good candidates for shared defaults:

- `modules/system/settings/*`
- `modules/programs/*`
- selected `modules/home-manager/*`

Poor candidates for blind auto-import:

- `modules/services/*` as a whole
- service bundles like media stacks
- hardware modules with device-specific assumptions

## Auto-Import Guidance

Do not auto-import a module family until the modules in that family are safe to
self-gate.

The desired order is:

1. add `my.host` facts
2. make modules self-gating
3. move shared modules into common bundles or category importers
4. remove redundant host-level imports

## WSL And VM Policy

Treat WSL as its own environment, not as a VM.

- WSL should use `roles.wsl = true`
- WSL may use `tags = [ "wsl" ]`
- `formFactor = "vm"` is reserved for real VM-style hosts if they are added later

## Current Shared Defaults

These are already trending toward generic shared behavior:

- CLI NixOS defaults in `system-cli`
- desktop/session NixOS foundations in `system-desktop`
- workstation-oriented NixOS layering in `system-workstation`
- base HM modules in `home`
- GUI HM bundle in `graphical-home`
- host metadata in `my.host.*`

Before re-adding a host-level import, check whether the module should instead
be gated and moved into one of those shared layers.

Sam-specific personal policy should generally live under `modules/users/sam/*`
rather than being pushed back down into the generic `home` or
`graphical-home` bundles.

## Host Structure

For x86-style host families, prefer a descriptor-level profile API over
host-local wrapper modules.

The current preferred split is:

- `homeProfileNames`: named shared Home Manager profiles such as `sam-home-personal`, `sam-home-media`, `sam-home-work`, `sam-home-work-wsl`
- `nixosProfileNames`: named shared NixOS profiles such as `system-workstation`, `system-desktop`, `system-cli`, `system-work-dev`
- `homeImports`: rare escape hatch for true one-off Home Manager modules
- `extraImports`: rare escape hatch for true one-off NixOS modules

Rule of thumb:

- prefer `*ProfileNames` for reusable policy and capability bundles
- use raw `*Imports` only when the module is genuinely host-specific and not yet worth promoting
- avoid reintroducing host-local `HostHome` wrapper modules unless they carry real host-only behavior that cannot be expressed as shared profiles yet

The remaining `extraImports` usage inside Steam Deck `_profiles/*` is internal
family assembly, not a model to copy into ordinary host descriptors.

For x86-style hosts, prefer setting `networking.hostName` from the descriptor
via the registration builders. Do not restate the hostname in per-host network
modules unless a host truly needs to override the descriptor value.

For x86-style host families, shared descriptor mechanics are intentionally
aligned:

- all x86 families use the shared x86 registration builder
- laptop and server families use shared `enableSystemdBoot` / `enableDisko` toggles
- WSL intentionally diverges only where its environment semantics differ, not in basic descriptor plumbing

For Steam Deck hosts, keep the same common concepts at descriptor level where
practical:

- `descriptor.hostName`
- `descriptor.config`
- `descriptor.nixos.*`
- `descriptor.home.*`

Keep only Steam Deck-specific variant and runtime data under `descriptor.platform.*`.
That preserves alignment with the x86 host model without flattening the
multi-variant Steam Deck design.

Prefer deriving Steam Deck Home Manager helper/configuration names in the
descriptor helper from the host name unless a host needs an explicit override.
Do not mirror those names back into `host.nix` unless there is a real
platform-specific reason.

For the RPi family, prefer per-host directories for host descriptors.
Keep shared RPi platform logic under `modules/hosts/rpi/_*.nix` and
`modules/hosts/rpi/_rpi/*`, and keep `modules/hosts/rpi/rpi.nix` as the
family registry that imports those per-host descriptors.

For non-x86 lifecycle products such as RPi bootstrap images or Steam Deck
bootstrap/installer variants, prefer lifecycle user defaults in descriptor or
host data. Shared lifecycle modules should consume that data rather than
hardcoding host-specific user names, groups, or passwords.

At this point, the main migration from host-local wrapper layering toward
descriptor profiles and self-gating shared modules is mostly complete for the
x86 families. Favor documentation and narrow follow-up cleanups over new broad
restructuring unless a concrete inconsistency justifies it.

## Validation

Preferred checks:

```bash
just fmt
just write-flake
just check
just checknb
```

If you change only documentation or obviously isolated metadata wiring, say what
you did not fully evaluate.

## Work Tracking

For multi-step work, keep an implementation plan current in the repo context as
the work progresses.

- record the intended sequence before or near the start of substantial work
- update the plan when a step is completed, dropped, or changes shape
- leave enough state in notes, summaries, or docs that recovery after a crash is straightforward

Prefer short, factual plan updates over long narrative status logs.
