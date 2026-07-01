{ ... }:
{
  flake.modules.nixos.frigate =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.frigate;
      pathSegment = cfg.pathSegment;
      frigateExternalListen = lib.attrByPath [
        "services"
        "frigate"
        "settings"
        "networking"
        "listen"
        "external"
      ] 8971 config;
      frigateProxyTarget =
        if builtins.isInt frigateExternalListen then
          "127.0.0.1:${lib.toString frigateExternalListen}"
        else if lib.hasInfix ":" frigateExternalListen then
          frigateExternalListen
        else
          "127.0.0.1:${frigateExternalListen}";
    in
    {
      options.my.services.frigate = {
        enable = lib.mkEnableOption "Frigate NVR service";

        pathSegment = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };

        siteHostName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "frigate";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.siteHostName != null || cfg.pathSegment != null;
            message = "my.services.frigate.pathSegment must be set when my.services.frigate.siteHostName is null.";
          }
        ];

        my.caddy =
          if cfg.siteHostName == null then
            {
              apexRoutes = [
                ''
                  redir /${pathSegment} /${pathSegment}/
                  reverse_proxy /${pathSegment}/* ${frigateProxyTarget} {
                    header_up X-Ingress-Path /${pathSegment}
                  }
                ''
              ];
            }
          else
            {
              virtualHosts."${cfg.siteHostName}.{$DOMAIN}".routes = [
                ''
                  reverse_proxy /* ${frigateProxyTarget}
                ''
              ];
            };

        my.localDns.records = lib.optional (cfg.siteHostName != null) {
          hostname = cfg.siteHostName;
        };

        services.frigate = {
          enable = true;
          settings = {

          };
        };
      };
    };
}
