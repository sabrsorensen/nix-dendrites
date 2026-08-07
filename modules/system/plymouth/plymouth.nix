{ ... }:
{
  flake.modules.nixos.plymouth =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.plymouth (import ./_plymouth.nix args);
}
