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
- `homeassistant-proxy` is incomplete and should not be treated as a finished reference design yet.
