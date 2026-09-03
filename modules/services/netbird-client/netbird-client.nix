{ ... }:
{
  flake.modules.nixos.netbird-client =
    { config, lib, ... }:
    {
      options.my.host.services.netbirdClient = lib.mkEnableOption "NetBird overlay-network client";
      config = lib.mkIf config.my.host.services.netbirdClient (import ./_netbird-client.nix { });
    };
}
