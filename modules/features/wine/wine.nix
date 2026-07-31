{ ... }:
{
  flake.modules.nixos.wine =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.wine (import ./_content.nix args);
}
