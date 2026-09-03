{ lib, ... }:
{
  imports = [ ./rpi-cache/_rpi-cache.nix ];

  flake.modules.nixos.platform-rpi =
    args@{ config, lib, ... }: lib.mkIf (config.my.host.platform == "rpi") (import ./_rpi.nix args);
}
