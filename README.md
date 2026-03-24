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

CI is configured in `.github/workflows/check.yml` and runs `nix flake check`
on pushes to `main` and on pull requests.

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
