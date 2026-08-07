{ ... }:
{
  flake.modules.nixos.wayland =
    args@{ config, lib, ... }: lib.mkIf config.my.host.features.wayland (import ./_wayland.nix args);
}
