{ ... }:
{
  flake.modules.nixos.frigate =
    {
      config,
      lib,
      pkgs,
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

        services.nginx = lib.mkForce {
          enable = false;
        };

        systemd.services.nginx = lib.mkForce {
          description = "Disabled nginx stub for Frigate";
          wantedBy = [ ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.coreutils}/bin/true";
          };
        };

        services.frigate = {
          enable = true;
          # Upstream Frigate currently requires hostname because its module
          # unconditionally defines an nginx vhost. We satisfy that contract
          # with a dummy name and keep nginx disabled because this repo
          # publishes Frigate through Caddy instead.
          hostname = "frigate.internal.invalid";
          settings = {

          };
        };
      };
    };
}
