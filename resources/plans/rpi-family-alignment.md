# RPi Family Alignment Plan

## Goal

Bring the RPi family into the same descriptor-first shape as the x86 hosts
without pretending that Raspberry Pi image/bootstrap/service-host plumbing is
the same as ordinary x86 machines.

The target is "same style, different platform details":

- per-host descriptors remain the source of truth
- shared registration logic stays in one family builder
- ordinary host facts live under `my.host.*`
- genuinely RPi-only concerns live under an explicit RPi/platform namespace

## Current State

Today the RPi family is already descriptor-driven, but the descriptor API is
split by scenario:

- `mkStaticDescriptor`
- `mkDhcpDescriptor`
- `mkServiceDescriptor`

That split duplicates structure across descriptors and pushes lifecycle/output
decisions into the constructor choice instead of into explicit descriptor data.

The current host mix is:

- static hosts: `Coruscant`, `Ferrix`
- service hosts: `Naboo`, `Nevarro`
- DHCP/image/bootstrap host: `NixPi`

## Recommended Target Shape

Replace the constructor-per-scenario model with one primary RPi descriptor API,
with scenario differences expressed as data.

Preferred descriptor shape:

```nix
{
  name = "Nevarro";
  hostName = "Nevarro";
  outputName = "nevarro";

  systemType = "sam-system-cli";

  config = { };
  nixos.imports = [ ];

  my.host = {
    roles.rpi = true;
    roles.server = true;
    formFactor = "server";
  };

  network = {
    mode = "static" | "dhcp";
    address = null;
    nameservers = [ ];
    localDnsRecords = [ ];
  };

  deploy = {
    method = "switch" | "secure";
    remoteUser = null;
    secure.peer = null;
  };

  services = {
    roles = [ ];
    dhcpCoredns = null;
  };

  outputs = {
    system.enable = true;
    image.enable = false;
    image.name = null;
    bootstrap = null;
  };

  users.primary = null;

  platform.rpi = {
    hardwareModule = "raspberry-pi-4";
  };
}
```

Notes:

- `kind = "static" | "dhcp" | "service"` should disappear. The builder should
  read `network.mode`, `deploy.method`, `services.roles`, and `outputs.*`
  instead.
- `bootstrap` should be treated as a lifecycle/output concern, not as a
  separate host class.
- service-host behavior should be enabled by explicit descriptor data, not by
  selecting a special constructor.
- `systemType` should become the normal top-level shared-system selector, just
  like the x86 families.

## What Should Stay RPi-Specific

Do not force the RPi family onto the exact x86 implementation. These concerns
are legitimately Pi-specific and should remain in `modules/hosts/rpi/_*.nix`
and `modules/hosts/rpi/_rpi/*`:

- SD image outputs
- bootstrap image outputs
- Raspberry Pi hardware module wiring
- `end0` network interface assumptions
- secure deploy peer wiring for the service-host pair
- DHCP/CoreDNS failover defaults for the Pi DNS pair

The goal is API alignment, not code deduplication for its own sake.

## Recommended File Direction

Keep:

- `modules/hosts/rpi/rpi.nix` as the family registry
- per-host descriptor files under each host directory
- shared RPi implementation under `modules/hosts/rpi/_*.nix` and `_rpi/*`

Refactor toward:

- one descriptor helper such as `mkRpiDescriptor`
- one registration builder that derives outputs from descriptor data
- small helper functions for optional image/bootstrap/service overlays

Likely file split:

- `_descriptor-helpers.nix`
  expose `mkRpiDescriptor` and thin convenience wrappers only if they still add
  real value during migration
- `_registration-builder.nix`
  derive module/output registration from `descriptor.network`, `descriptor.deploy`,
  `descriptor.services`, and `descriptor.outputs`
- `_module-builders.nix`
  keep base/static/image/bootstrap assembly helpers, but make them consumers of
  the unified descriptor data model

## Migration Sequence

1. Introduce `mkRpiDescriptor` alongside the existing constructors.
2. Teach `_registration-builder.nix` to operate on the unified descriptor
   shape while still tolerating the old compatibility fields during migration.
3. Keep the current RPi family wiring available during migration so the new
   descriptor path can be compared against the existing outputs instead of
   replacing them blindly.
4. Compare old and new host outputs for each migrated host before cutover.
   The comparison should cover at least:
   - registered `nixosConfigurations`
   - host inventory/deploy metadata
   - image/bootstrap outputs where applicable
   - key host facts and service settings in the evaluated config
5. Migrate `Coruscant` and `Ferrix` first.
   They are the simplest static hosts and validate the basic descriptor shape.
6. Migrate `NixPi` next.
   That validates DHCP plus image/bootstrap lifecycle handling.
7. Migrate `Nevarro` and `Naboo` last.
   They carry the most special-case behavior: secure deploy, failover, and
   service-role inventory.
8. Remove the old constructor compatibility surface once all hosts use the new
   descriptor API.

## Parity Requirement

During the migration, the existing RPi family should remain the reference
implementation. The new family path should prove parity against it before any
host is cut over permanently.

Preferred approach:

- keep the current descriptor/registration path buildable during the transition
- expose the new path in a way that can be evaluated side-by-side
- compare per-host evaluated results before switching the canonical host
  registration to the new path

Recommended comparison layers:

- semantic parity
  compare runtime host facts, deploy metadata, service state, and normalized
  output shape
- exact parity
  compare raw inventory outputs and names literally
- exact parity with aliasing
  compare raw outputs after rewriting the new-family `New*` names back to the
  reference names so naming drift does not hide structural parity

The migration is complete only when the new family reproduces the current
behavior intentionally, with any differences called out as deliberate changes.

## Non-Goals

- merging the RPi builder into the x86 builder
- flattening all RPi-specific modules into generic shared bundles immediately
- redesigning the service-host DHCP/CoreDNS feature set as part of this cut
- changing host behavior while the family API is being normalized

## First Implementation Cut

The next code change should be narrow:

1. add `mkRpiDescriptor`
2. adapt the registration builder to prefer the new fields
3. convert one static host and one DHCP/bootstrap host

That gives a clean proof that the new API works before touching the
service-host pair.

## Current Progress

The promoted canonical RPi path now uses the unified descriptor/registration
shape directly for:

- `Coruscant`
- `Ferrix`
- `Naboo`
- `Nevarro`
- `NixPi`

Exact parity was confirmed against the preserved reference family for:

- `Coruscant`
- `Ferrix`
- `NixPi`
- `NixPiImage`
- `NixPiBootstrap`
- `NixPiBootstrapImage`
- `Naboo`
- `Nevarro`

That archived family has now been removed after successful deployment of the
canonical tree.

The validated comparison method is:

- construct an alternate flake that disables the canonical `modules/hosts/rpi`
  family entry points
- import the preserved reference family under the original host names
- compare canonical and old outputs under identical inventory names

That detail matters because aliasing old hosts under temporary `Old*` names
perturbs shared host inventory and changes Home Manager-generated SSH config,
which creates a false build mismatch.

At this point, the canonical RPi family is model-aligned with the x86 families
to the intended degree for this migration, and the migration cleanup is
complete.

The current expected validation status is:

- the suffix-free canonical RPi outputs are the promoted unified family
- all current RPi hosts and NixPi lifecycle outputs matched the reference
  family before cutover
- the `_old` tree and its compatibility shims have been removed
