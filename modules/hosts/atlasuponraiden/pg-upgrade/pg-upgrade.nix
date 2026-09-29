{ ... }:
{
  # One-off PostgreSQL 17 -> 18 migration tool; remove once the migration in
  # docs/postgresql-17-to-18-migration.md is verified.
  flake.modules.nixos.pg-upgrade-atlasuponraiden =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.name == "AtlasUponRaiden") (import ./_pg-upgrade.nix args);
}
