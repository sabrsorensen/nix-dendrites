# Host Families

This note documents the current host-family contract and where the repo
intentionally allows different construction strategies.

## Shared Contract

Across every family, the intended shared contract is:

- host facts live in `my.host.*`
- reusable behavior is selected through shared modules and option surfaces
- outputs and deploy topology come from descriptors and inventory

That contract matters more than forcing every family into the same builder
shape.

## X86 Families

Laptop, server, and WSL are the closest families structurally.

They now share:

- the shared x86 descriptor helper layer
- the shared x86 registration builder
- descriptor-driven NixOS/Home Manager outputs
- direct family exports without separate `_public.nix` forwarding shims

Preferred x86 descriptor fields:

- `config`
  host facts and environment semantics under `my.host.*`
- `homeProfileNames`
  shared Home Manager profiles by name
- `nixosProfileNames`
  shared NixOS profiles by name
- `homeImports`
  true host-local HM exceptions only
- `extraImports`
  true host-local NixOS exceptions only

### Laptop

Laptop hosts are workstation-oriented x86 systems.

Typical defaults:

- `sam`
- `system-workstation`
- `sam-home-personal`
- `enableSystemdBoot`
- optional `enableDisko`

### Server

Server hosts are headless or service-oriented x86 systems.

Typical defaults:

- `sam-system-cli`
- `system-cli`
- service bundles such as `caddy`, `syncthing-server`, `media-server`
- `sam-home-personal`
- optional shared HM profiles such as `sam-home-media`
- `enableSystemdBoot`
- optional `enableDisko`

### WSL

WSL is an x86 family, but it keeps environment-specific defaults.

Typical defaults:

- `nixosWsl`
- `system-work-dev`
- `sam-home-work`
- `sam-home-work-wsl`

WSL should stay aligned with x86 descriptor plumbing, but it does not need to
pretend it is a laptop or server.

It may still import `system-cli` transitively through shared profiles, but that
should not force server-like daemons such as SSH unless host facts or deploy
metadata justify them.

## RPi

RPi is descriptor-driven, but not x86-like in shape.

Why it differs:

- image outputs are first-class
- DHCP/static/service descriptors are different host kinds
- bootstrap often implies sd-image flows

RPi should stay specialized around aarch64/image concerns while still using the
shared `my.host.*` contract.

The remaining RPi differences are mostly genuine platform/output differences,
not a sign that it should be forced into the x86 family shape.

Even there, host-specific user or profile policy should prefer to live in the
per-host descriptor data rather than inside the shared family builders.

That includes bootstrap user naming, groups, and password/key policy.

## Steam Deck

Steam Deck is a platform-plus-lifecycle family, not a standard host family.

Why it differs:

- installer/bootstrap/system are separate lifecycle products
- boot mode is part of the host model
- Decky/Steam/platform runtime concerns are first-class

Steam Deck should keep its `_platform`, `_profiles`, and `_host` split.

The remaining Steam Deck differences are likewise mostly real lifecycle and
platform concerns rather than unfinished normalization.

System-profile choices for a specific Deck host should likewise be declared in
the host descriptor rather than hardcoded in the shared lifecycle profile
modules.

The same applies to bootstrap and installer user defaults.

For SteamOS Home Manager deployments, session/bootstrap wiring is part of the
platform contract. In particular, if the SteamOS userland relies on login-shell
bootstrap from the standalone Nix installer, preserve that behavior in the
shared Deck/Home Manager bash configuration so desktop-session app discovery
and profile environment setup continue to work.

## Reconciliation Guidance

Try to reconcile families when the difference is only:

- profile naming
- descriptor wiring
- shared registration mechanics
- reusable boot/install toggles

Do not force reconciliation when the difference is actually:

- output/product shape
- install media strategy
- platform runtime model
- lifecycle matrix complexity
