{ ... }:
{
  flake.modules.nixos.wayland =
    args@{ config, lib, ... }:
    {
      options.my.host.features.wayland = lib.mkEnableOption "Wayland session environment";
      config = lib.mkIf config.my.host.features.wayland (import ./_wayland.nix args);
    };
}
