{ ... }:
{
  flake.modules.nixos.minecraft =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.services.minecraft (import ./_content.nix args);
}
