{ ... }:
{
  flake.modules.nixos.atuin =
    { config, lib, ... }:
    let
      cfg = config.my.atuin;
    in
    {
      options.my.atuin = {
        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = "atuin";
          description = "Path below the apex domain used for Atuin synchronization.";
        };
        openRegistration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Allow unauthenticated Atuin account registration.";
        };
        siteHostName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional dedicated local hostname; null publishes Atuin at the apex path.";
        };
      };

      config = lib.mkIf config.my.host.services.atuin {
        my.caddy =
          if cfg.siteHostName == null then
            {
              apexRoutes = [
                ''
                  redir /${cfg.pathSegment} /${cfg.pathSegment}/
                  reverse_proxy /${cfg.pathSegment}/* ${config.services.atuin.host}:${toString config.services.atuin.port}
                ''
              ];
            }
          else
            {
              virtualHosts."${cfg.siteHostName}.{$DOMAIN}".routes = [
                "reverse_proxy /* ${config.services.atuin.host}:${toString config.services.atuin.port}"
              ];
            };
        my.localDns.records = lib.optional (cfg.siteHostName != null) { hostname = cfg.siteHostName; };
        services.atuin = {
          enable = true;
          host = "127.0.0.1";
          port = 8888;
          openFirewall = true;
          openRegistration = cfg.openRegistration;
          path = "/${cfg.pathSegment}/";
        };
      };
    };
}
