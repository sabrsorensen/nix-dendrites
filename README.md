# nix-dendrites

Converting my NixOS and Home Manager configurations to Dendritic Nix structuring.

## References

- [nix-dendrites-template](https://github.com/sabrsorensen/nix-dendrites-template)
- [mightyiam's Dendritic](https://github.com/mightyiam/dendritic)
- [Doc-Steve's Dendritic Design with Flake Parts](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)
- [vic/flake-file](https://github.com/vic/flake-file) and [docs](https://flake-file.oeiuwq.com/)

## Layout

- `flake.nix` is generated from the modules under `./modules`.
- `modules/dendritic.nix` enables the upstream dendritic bootstrap from `flake-file`.
- `modules/metadata.nix` holds repo-wide metadata.
- `modules/devshell.nix` adds a devshell with pre-commit for setting up the pre-commit hook.
- `modules/*` shows feature-module structure.

## Host Model

The repo is moving toward a property-driven module model similar in spirit to
the "broadcast-and-gate" pattern used by
[`wimpysworld/nix-config`](https://github.com/wimpysworld/nix-config), but
without introducing a second host metadata system.

`my.host.*` is the single source of truth for host metadata.

- `my.host.roles.*` captures broad intent such as workstation, server, rpi, steamdeck, and wsl.
- `my.host.formFactor` captures physical or operational shape such as `laptop`, `desktop`, `handheld`, and `server`.
- `my.host.features.*` captures concrete capabilities or policy toggles such as `gui`, `bluetooth`, `firmware`, `nix-ld`, `nvidia`, `flatpak`, `steam`, `wine`, `deskflow`, `minecraft`, `threedprinter`, and `zsa`.
- `my.host.tags` is a sparse escape hatch for grouping and exceptions.
- `my.host.is.*` is the derived read-side used by modules.

Rule of thumb:

- use `my.host.is.*` for broad class decisions
- use `my.host.features.*` for capability or policy toggles
- use `my.host.roles.*` and `my.host.formFactor` to define hosts, not as the first-choice read API in modules

For server classification, `roles.server` is the authoritative host declaration.
`formFactor = "server"` remains useful metadata, but modules should prefer
`my.host.is.server`.

The design goal is:

- hosts declare facts and explicit feature flags
- reusable modules self-gate with `lib.mkIf`
- broad defaults move into shared bundles
- host directories shrink toward hardware, disks, networking facts, and true exceptions

For x86 host families, the preferred descriptor API is:

- `homeProfileNames` for reusable Home Manager profile bundles
- `nixosProfileNames` for reusable NixOS profile bundles such as `system-workstation`, `system-desktop`, `system-cli`, and `system-work-dev`
- `homeImports` only for true host-local HM exceptions
- `extraImports` only for true host-local NixOS exceptions

Laptop, server, and WSL all use the same shared x86 descriptor and registration
mechanics. Their intended differences are in default profiles and environment
semantics, not in ad hoc host wiring.

WSL is treated as its own environment, not as a VM.

`features.gui` should mean "this host is expected to run a local graphical
session". It is broader than "has some GUI apps installed", and it is the
right gate for shared desktop/session modules such as Firefox, audio, Wayland,
KDE, and other local-user GUI defaults.

## Regenerating `flake.nix`

When a module adds or changes `flake-file.inputs`, regenerate the top-level
flake file with:

```bash
nix run .#write-flake
```

`flake-parts` exposes `write-flake` as a package, and also provides the
`check-flake-file` check to fail if `flake.nix` is stale.

## Automation

Local pre-commit support is configured in `.pre-commit-config.yaml`:

```bash
pre-commit install
```

The hook first runs `nix run .#write-flake`, then `nix flake check`.

`pre-commit` is also available from the repo dev shell:

```bash
nix develop
```

For repo-scoped maintenance commands, a small [justfile](./justfile) wraps the
existing workflows:

```bash
just fmt
just write-flake
just check
just checknb
just update
just install-hooks
just run-hooks
```

CI is configured in `.github/workflows/check.yml` and runs `nix flake check`
on pushes to `main` and on pull requests.

## Current Layering

The current shared NixOS bundle layering is:

- `system-cli`
  base CLI/system defaults
- `system-desktop`
  shared desktop/session foundations layered on `system-cli`
- `system-workstation`
  workstation-oriented extras layered on `system-desktop`

The current shared Home Manager layering is:

- `home`
  base HM defaults
- `graphical-home`
  minimal shared GUI layer on `home`

Sam-specific policy now mostly lives under `modules/users/sam/*` rather than
inside the generic shared HM bundles.

`system-cli` no longer implies that every CLI-shaped host runs SSH. SSH is now
expected to self-gate from host facts and deploy metadata.

## Migration Status

The broad migration toward a more `wimpysworld/nix-config`-like
"declare facts, import broadly, self-gate in modules" setup is largely in
place for the x86 families:

- laptop, server, and WSL share the x86 descriptor/registration model
- host-local wrapper modules have mostly been removed in favor of descriptor
  profiles
- many reusable programs, services, and system settings now gate on
  `my.host.*` or shared option surfaces

The biggest remaining family differences are now mostly intentional:

- RPi keeps specialized image/bootstrap/static/service-host plumbing
- Steam Deck keeps specialized platform/lifecycle/boot-mode plumbing

At this point the remaining work is mostly incremental narrowing and
documentation rather than another large structural migration.

## Bootstrapping New Modules

The recommended split layout for modules which require new inputs:

- `modules/<module>/flake-parts.nix`
- `modules/<module>/_<module>.nix`

An example of this is the formatter module:

- `modules/nix/tools/formatter/flake-parts.nix`
- `modules/nix/tools/formatter/_formatter.nix`

`flake-parts.nix` is bootstrap-safe and only declares inputs:

```nix
{
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

It conditionally imports `_formatter.nix` only after `treefmt-nix` is present
in the current root flake. The leading `_` matters: `import-tree` ignores paths
containing `/_` by default, so the consumer module is not imported too early.
This avoids the bootstrap cycle where a new module tries to consume a new input
before `write-flake` has added it to `flake.nix`.

`_formatter.nix` is where the inputs declared in `flake-parts.nix` are actually consumed:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt;
      treefmt.programs.nixfmt.enable = true;
    };
}
```

After adding a similar module, run `nix run .#write-flake` and commit the
updated generated `flake.nix`.
