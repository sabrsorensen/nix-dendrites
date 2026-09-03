{ ... }:
{
  flake.modules.nixos.apprise =
    args@{ config, lib, ... }:
    let
      cfg = config.my.apprise;
      serviceName = "apprise";
      containerUid = 2200;
      containerGid = 2200;
      localAddr = "127.0.0.1:8000";
    in
    {
      options.my.apprise = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };
        dataDir = lib.mkOption {
          type = lib.types.str;
          default = "/opt/apprise/config";
        };
        attachDir = lib.mkOption {
          type = lib.types.str;
          default = "/opt/apprise/attach";
        };
      };

      options.my.host.services.apprise = lib.mkEnableOption "Apprise notification service";
      config = lib.mkIf config.my.host.services.apprise (
        import ./_apprise.nix (
          args
          // {
            inherit
              cfg
              containerGid
              containerUid
              localAddr
              serviceName
              ;
          }
        )
      );
    };
}
