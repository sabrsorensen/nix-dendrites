{ ... }:
{
  flake.modules.nixos.rpi-status =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.is.rpi (import ./_content.nix args);
}
