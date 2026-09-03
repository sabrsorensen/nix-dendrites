{ ... }:
{
  # Builders compile Raspberry Pi closures locally through binfmt.
  flake.modules.nixos.cross-compile =
    args@{ config, lib, ... }: lib.mkIf config.my.host.roles.builder (import ./_cross-compile.nix args);
}
