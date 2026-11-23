{ ... }:
{
  flake.modules.nixos.kosync =
    args@{ config, lib, ... }:
    let
      cfg = config.my.kosync;
    in
    {
      options.my.kosync = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = "kosync";
          description = "Subdomain (below {$DOMAIN}) the KOReader sync server is served on.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 17200;
          description = "Loopback port mapped to the container's plain-HTTP listener (17200).";
        };
        allowRegistration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether POST /users/create accepts new accounts. The endpoint is
            public, so enable only long enough to register from KOReader,
            then turn it back off; existing accounts keep working.
          '';
        };
      };

      options.my.host.services.kosync = lib.mkEnableOption "KOReader progress sync server";
      config = lib.mkIf config.my.host.services.kosync (import ./_kosync.nix (args // { inherit cfg; }));
    };
}
