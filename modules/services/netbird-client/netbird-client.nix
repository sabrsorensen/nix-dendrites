{ ... }:
{
  flake.modules.nixos.netbird-client =
    { config, lib, ... }:
    lib.mkIf config.my.host.services.netbirdClient (import ./_content.nix { });
}
