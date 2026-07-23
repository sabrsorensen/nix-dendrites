{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.frigate =
    { config, lib, ... }:
    let
      cfg = config.my.frigate;
      nginxPort = 8972;
      publicHost = "${cfg.siteHostName}.${domain}";
    in
    {
      options.my.frigate = {
        pathSegment = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Unsupported legacy path publication setting; keep null for a dedicated Frigate hostname.";
        };
        siteHostName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "frigate";
          description = "Dedicated local and public hostname for Frigate.";
        };
      };

      config = lib.mkIf config.my.host.services.frigate {
        assertions = [
          {
            assertion = cfg.siteHostName != null;
            message = "Frigate requires my.frigate.siteHostName for dedicated Caddy-subdomain publication.";
          }
          {
            assertion = cfg.pathSegment == null;
            message = "Frigate supports only its dedicated Caddy subdomain, not apex-path publication.";
          }
        ];

        my.caddy.virtualHosts."${cfg.siteHostName}.{$DOMAIN}".routes = [
          "reverse_proxy /* 127.0.0.1:${toString nginxPort}"
        ];
        my.localDns.records = [ { hostname = cfg.siteHostName; } ];
        services.nginx.virtualHosts.${publicHost}.listen = lib.mkForce [
          {
            addr = "127.0.0.1";
            port = nginxPort;
          }
        ];
        services.frigate = {
          enable = true;
          hostname = publicHost;
          settings = { };
        };
      };
    };
}
