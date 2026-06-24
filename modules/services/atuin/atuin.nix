{
  inputs,
  ...
}:
{
  flake.modules.nixos.atuin-server =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.atuin;
      pathSegment = cfg.pathSegment;
    in
    {
      options.my.services.atuin = {
        enable = lib.mkEnableOption "Atuin server service";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = "atuin";
        };

        openRegistration = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        siteHostName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = lib.mkIf cfg.enable {
        my.caddy =
          if cfg.siteHostName == null then
            {
              apexRoutes = [
                ''
                  redir /${pathSegment} /${pathSegment}/
                  reverse_proxy /${pathSegment}/* ${config.services.atuin.host}:${lib.toString config.services.atuin.port}
                ''
              ];
            }
          else
            {
              virtualHosts."${cfg.siteHostName}.{$DOMAIN}".routes = [
                ''
                  reverse_proxy /* ${config.services.atuin.host}:${lib.toString config.services.atuin.port}
                ''
              ];
            };

        my.localDns.records = lib.optional (cfg.siteHostName != null) {
          hostname = cfg.siteHostName;
        };

        services.atuin = {
          enable = true;
          port = 8888; # default
          host = "127.0.0.1";
          openFirewall = true;
          openRegistration = cfg.openRegistration;
          path = "/${pathSegment}/";
        };
      };
    };
}
