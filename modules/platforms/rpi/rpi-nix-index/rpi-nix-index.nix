{ ... }:
{
  flake.modules.nixos.rpi-nix-index =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.is.rpi (import ./_rpi-nix-index.nix args);
}
