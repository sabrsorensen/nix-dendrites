{ ... }:
{
  flake.modules.nixos.docker =
    args@{ config, lib, ... }: lib.mkIf config.my.host.features.docker (import ./_docker.nix args);
}
