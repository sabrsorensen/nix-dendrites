{ ... }:
{
  flake.modules.nixos.nvidia =
    args@{ config, lib, ... }: lib.mkIf config.my.host.features.nvidia (import ./_content.nix args);
}
