{ ... }:
{
  flake.modules.nixos.watchtower =
    { config, lib, ... }:
    lib.mkIf config.my.host.services.watchtower (import ./_content.nix { inherit config; });
}
