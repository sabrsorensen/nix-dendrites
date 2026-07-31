{ ... }:
{
  flake.modules.nixos.audio =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.audio (import ./_content.nix { });
}
