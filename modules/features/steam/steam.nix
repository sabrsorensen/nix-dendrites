{ ... }:
{
  flake.modules.nixos.steam =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.steam (import ./_content.nix { });
}
