# Working Model

This note summarizes the design considerations and paradigm shifts introduced by the current branch so future changes follow the same model.

## Core Shifts

### Shared declarations over direct service mutation

Leaf modules should prefer publishing intent through shared option surfaces instead of mutating final service configuration directly.

Examples:

- Caddy routes should usually go through `my.caddy.virtualHosts`, `my.caddy.apexRoutes`, or `my.media.caddy.*`
- local DNS names should go through `my.localDns.records`
- host traits should go through `my.host.*`

The intended pattern is:

1. a leaf module declares intent
2. a shared aggregator renders final service configuration

This is a shift away from every service module writing directly to `services.caddy.virtualHosts` or maintaining its own local registry.

### Inventory is first-class topology

`flake.lib.hostInventory` is no longer just deploy metadata. It is now part of how the repo models runtime systems and derived outputs.

Examples:

- outputs are derived from inventory descriptors
- local DNS harvesting is inventory-driven
- service roles expand through shared lib helpers

When adding a host, think in three layers:

1. system and home modules
2. inventory metadata
3. derived consumers like deploy, outputs, and DNS

### Host context is a schema

`my.host.*` is now the canonical place for shared host semantics.

Shared definitions live in [`modules/lib/_host-context-options.nix`](./modules/lib/_host-context-options.nix), and are projected into:

- [`modules/system/settings/host-context/host-context.nix`](./modules/system/settings/host-context/host-context.nix)
- [`modules/home-manager/context/host-context.nix`](./modules/home-manager/context/host-context.nix)

If you want to add a new cross-cutting host trait:

1. add it to the shared helper if it applies to both NixOS and Home Manager
2. add it only to the NixOS wrapper if it is system-specific
3. consume it from modules rather than inventing another parallel option path

### X86 host families share a contract

Laptop, server, and WSL now intentionally share the same x86 descriptor
machinery even though they keep different defaults.

The preferred x86 descriptor surface is:

- `config` for host facts under `my.host.*`
- `homeProfileNames` for reusable HM profile bundles
- `nixosProfileNames` for reusable NixOS profile bundles
- `homeImports` for rare host-local HM exceptions
- `extraImports` for rare host-local NixOS exceptions

In practice, laptop descriptors should usually target `system-workstation`,
while `system-desktop` should stay closer to shared desktop/session
foundations.

The current NixOS bundle intent is:

- `system-cli`
  base CLI/system policy only
- `system-desktop`
  shared desktop/session foundations layered on `system-cli`
- `system-workstation`
  workstation-oriented extras layered on `system-desktop`

One concrete consequence is that SSH should not be treated as an automatic
property of every `system-cli` host. Shared service modules should prefer to
gate from host facts and deploy metadata instead of assuming that a broad
profile implies a daemon.

This is the intended layering:

1. shared x86 registration and output mechanics
2. family-specific default profiles and metadata
3. host-local facts and true one-offs

That means:

- laptop and server should stay very close structurally
- WSL may keep environment-specific defaults, but should avoid bespoke wiring when the shared x86 contract can express the same thing
- host-local wrapper modules are no longer the preferred way to express profile selection

### DNS is published, not curated

Old model:

- static DNS records were manually curated in one place

New model:

- services and hosts publish names they own
- DNS authorities harvest those publications from runtime configurations
- the central static registry is now reserved for infra-only records

So when adding a new service hostname, the default move is:

1. add `my.localDns.records = [ { hostname = "..."; } ];` to the owning module or host
2. avoid editing the central DNS file unless the record is infrastructure such as `ns1` or `home-gw`

### Media services are a subsystem

The media stack now has shared structure rather than being a bag of unrelated modules.

Important files:

- [`modules/services/media/_arr/default.nix`](./modules/services/media/_arr/default.nix)
- [`modules/services/media/_media-base.nix`](./modules/services/media/_media-base.nix)

When working on media services:

- prefer extending `_media-base.nix` over open-coding another media root/path/network convention
- prefer reusing `arr.mkThemeParkRoute` and `arr.mkManagedService` for `*Arr`-like apps
- treat the media stack as a cohesive subsystem

### Private helpers belong on `_` paths

This repo uses `import-tree`, so helper files inside imported trees can accidentally become flake modules if they are placed on ordinary paths.

Use underscore-prefixed helper filenames for private helpers.

Example:

- [`modules/lib/_host-context-options.nix`](./modules/lib/_host-context-options.nix)

If a file is not meant to be auto-imported as a module, default to an `_name.nix` path.

### Steam Deck host structure is normalized

The Steam Deck area now separates concerns more clearly:

- `_platform` for reusable platform mechanics
- `_profiles` for lifecycle/configuration assembly
- `_host` for EmeraldEcho-specific identity/runtime/packages/variants

This is the preferred shape for future multi-variant hosts:

1. separate platform concerns from host identity
2. separate lifecycle variants from runtime data
3. keep the top-level host file mostly focused on assembly

That now also applies to lifecycle user policy:

- bootstrap user defaults should come from host/runtime data
- installer user defaults should come from host/runtime data
- shared lifecycle modules should consume those values rather than hardcoding
  host-specific credentials or group policy

### Family differences are intentional at two levels

Some family differences are worth reconciling. Some are not.

Reasonably reconcilable:

- laptop, server, and WSL descriptor/profile plumbing
- shared x86 boot/install toggles
- shared user/home profile selection

Intentionally specialized:

- RPi image/static/DHCP/service host variants
- Steam Deck lifecycle and boot-mode matrix

Even in those specialized families, bootstrap and installer user policy should
still prefer descriptor/host-owned data over shared-module hardcoding.

The repo should aim for one shared cross-family contract:

- host facts through `my.host.*`
- reusable behavior through shared option surfaces and self-gating modules
- descriptor-driven outputs and inventory

It does not need one identical host-construction strategy for every platform.

## Current Migration Status

The main structural migration is effectively complete in these areas:

- laptop, server, and WSL descriptor/profile plumbing
- shared x86 registration/output mechanics
- broad movement from host-local imports toward self-gating modules
- removal of thin family forwarding wrappers where they did not carry real
  behavior

What remains is mostly opportunistic cleanup:

- further narrowing of broad shared bundles when they still carry policy that
  should live in a more specific layer
- occasional promotion of repeated host-local exceptions into named shared
  profiles
- documentation updates when the intended boundaries change

After the current audit, the main remaining raw `extraImports` usage is inside
Steam Deck lifecycle assembly modules. That is intentional internal family
plumbing, not a preferred host-descriptor pattern.

## Practical Guidance

When adding or changing something, default to these questions:

1. Is this a leaf declaration or a shared aggregation concern?
2. Does this belong in `my.host`, `my.caddy`, `my.media`, or `my.localDns` instead of a raw service attribute?
3. Is this specific to one host, one subsystem, or cross-cutting enough to belong in shared schema/lib?
4. If this is helper logic, should it live on an `_` path so `import-tree` ignores it?
5. If this introduces topology, should host inventory know about it?

## Notes

- `NixPi` intentionally leaves `my.host.address` unset because it is DHCP-addressed.
- `netbird-*` is intentionally dormant until it is revived on Atlas.
