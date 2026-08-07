{ ... }:
{
  flake.modules.nixos.desktop =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.desktop (import ./_desktop.nix args);
}
