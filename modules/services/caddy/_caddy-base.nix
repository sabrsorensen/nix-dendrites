{
  config,
  pkgs,
  caddyEnvFile,
  cfg,
  lib,
  renderRoutes,
  virtualHosts,
  ...
}:
{
  sops.secrets.caddy_env = {
    owner = "caddy";
    group = "caddy";
    mode = "0400";
    format = "dotenv";
    sopsFile = caddyEnvFile;
    key = "";
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.2"
        "github.com/sjtug/caddy2-filter@v0.0.0-20230306214137-04be952a71e1"
      ];
      hash = "sha256-rAtkJdnD5UJeyU1gqCj9PD/gDxlmQdFMDLUUft/iL7Y=";
    };
    email = "letsencrypt@{$DOMAIN}";
    environmentFile = config.sops.secrets.caddy_env.path;
    globalConfig = ''
      cert_issuer acme {
        dns cloudflare {$CLOUDFLARE_API_KEY}
        resolvers 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
      }
      order filter after encode
    '';
    extraConfig = ''
      (drop_scanners) {
        @scanner_paths_{args[0]} path_regexp scanner_paths_{args[0]} (?i).*(/wp-admin(?:/.*)?|/wp-login(?:\.php)?(?:\?.*)?|/xmlrpc\.php(?:\?.*)?|/\.env(?:\..*)?|/\.git/config(?:\?.*)?|/\.DS_Store(?:\?.*)?|/cgi-bin(?:/.*)?|/actuator(?:/.*)?|/server-status(?:\?.*)?|/server-info(?:\?.*)?|/manager/html(?:\?.*)?|/solr(?:/.*)?|/v2/_catalog(?:\?.*)?|/(ecp|owa|autodiscover)(?:/.*)?|/HNAP1(?:/.*)?|/boaform(?:/.*)?|\.(bak|old|orig|sql|zip|tar|gz)(\?.*)?)$
        handle @scanner_paths_{args[0]} {
          respond "" 403
        }
      }

      (cors) {
        @cors_preflight method OPTIONS
        @cors header Origin {args[0]}

        handle @cors_preflight {
          header Access-Control-Allow-Origin "{args[0]}"
          header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE"
          header Access-Control-Allow-Headers "Content-Type"
          header Access-Control-Max-Age "3600"
          respond "" 204
        }
        handle @cors {
          header Access-Control-Allow-Origin "{args[0]}"
          header Access-Control-Expose-Headers "Link"
        }
      }
    '';
    logFormat = ''
      output stdout
      format console
      level INFO
    '';
    virtualHosts =
      lib.optionalAttrs (cfg.apexRoutes != [ ]) {
        "{$DOMAIN}".extraConfig = lib.mkAfter (renderRoutes cfg.apexRoutes);
      }
      // virtualHosts;
  };
}
