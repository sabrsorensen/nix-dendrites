{
  inputs,
  ...
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  caddyCfg = config.my.caddy;
  renderRoutes = routes: lib.concatStringsSep "\n" (lib.filter (route: route != "") routes);
  renderedVirtualHosts =
    lib.mapAttrs
      (
        _: hostCfg:
        lib.optionalAttrs (hostCfg.routes != [ ] || hostCfg.logFormat != null) (
          lib.optionalAttrs (hostCfg.logFormat != null) {
            logFormat = hostCfg.logFormat;
          }
          // lib.optionalAttrs (hostCfg.routes != [ ]) {
            extraConfig = renderRoutes hostCfg.routes;
          }
        )
      )
      (
        lib.filterAttrs (
          _: hostCfg: hostCfg.routes != [ ] || hostCfg.logFormat != null
        ) caddyCfg.virtualHosts
      );
in
{
  options.my.caddy = {
    apexRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.lines;
      default = [ ];
      description = "Route fragments appended to the apex {$DOMAIN} Caddy site.";
    };

    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            routes = lib.mkOption {
              type = lib.types.listOf lib.types.lines;
              default = [ ];
              description = "Caddy route fragments for this virtual host.";
            };

            logFormat = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
              description = "Optional logFormat block for this virtual host.";
            };
          };
        }
      );
      default = { };
      description = "Declarative Caddy virtual host fragments keyed by hostname.";
    };
  };

  config = {
    sops.secrets.caddy_env = {
      owner = "caddy";
      group = "caddy";
      mode = "0400";
      format = "dotenv";
      sopsFile = "${inputs.nix-secrets}/env_files/caddy.env";
      key = "";
    };

    services.caddy.virtualHosts =
      lib.optionalAttrs (caddyCfg.apexRoutes != [ ]) {
        "{$DOMAIN}" = {
          extraConfig = lib.mkAfter (renderRoutes caddyCfg.apexRoutes);
        };
      }
      // renderedVirtualHosts;

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.caddy = {
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/caddy-dns/cloudflare@v0.2.2"
          "github.com/sjtug/caddy2-filter@v0.0.0-20230306214137-04be952a71e1"
        ];
        hash = "sha256-eQd14FYl4LdHT6P3U7biHkp++l6hi4ScreAGeWKT2zo=";
      };
      enable = true;
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
    };
  };
}
