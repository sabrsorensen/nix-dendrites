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
      localDomain = config.systemConstants.domain;
      publicHost = "${cfg.siteHostName}.${localDomain}";
      nginxPort = 8972;
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
            assertion = cfg.siteHostName != null;
            message = "my.services.frigate.siteHostName must be set. Frigate is currently supported only behind its dedicated Caddy subdomain.";
          }
          {
            assertion = cfg.pathSegment == null;
            message = "my.services.frigate.pathSegment is not supported. Frigate should be published through a dedicated subdomain-backed Caddy proxy to nginx.";
          }
        ];

        my.caddy.virtualHosts."${cfg.siteHostName}.{$DOMAIN}".routes = [
          ''
            reverse_proxy /* 127.0.0.1:${lib.toString nginxPort}
          ''
        ];

        my.localDns.records = [
          { hostname = cfg.siteHostName; }
        ];

        services.nginx.virtualHosts.${publicHost}.listen = lib.mkForce [
          {
            addr = "127.0.0.1";
            port = nginxPort;
          }
        ];

        services.frigate = {
          enable = true;
          hostname = publicHost;
          settings = {

          };
        };
      };
    };
}
