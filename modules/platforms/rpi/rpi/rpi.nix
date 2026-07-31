{ lib, ... }:
{
  imports = [ ./rpi-cache/_content.nix ];

  flake.modules.nixos.platform-rpi =
    args@{ config, lib, ... }: lib.mkIf (config.my.host.platform == "rpi") (import ./_content.nix args);
}
