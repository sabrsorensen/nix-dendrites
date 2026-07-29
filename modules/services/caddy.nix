{ inputs, ... }:
{
  flake.modules.nixos.caddy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.caddy;
      renderRoutes = routes: lib.concatStringsSep "\n" (lib.filter (route: route != "") routes);
      virtualHosts = lib.mapAttrs (
        _: host:
        lib.optionalAttrs (host.routes != [ ]) { extraConfig = renderRoutes host.routes; }
        // lib.optionalAttrs (host.logFormat != null) { logFormat = host.logFormat; }
      ) (lib.filterAttrs (_: host: host.routes != [ ] || host.logFormat != null) cfg.virtualHosts);
      enabled = config.my.host.services.caddy || cfg.apexRoutes != [ ] || virtualHosts != { };
    in
    {
      options.my.caddy = {
        enableFail2ban = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether a Caddy host enables Fail2ban and Cloudflare IP bans.";
        };
        apexRoutes = lib.mkOption {
          type = lib.types.listOf lib.types.lines;
          default = [ ];
          description = "Route fragments for the apex {$DOMAIN} Caddy site.";
        };
        virtualHosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.routes = lib.mkOption {
                type = lib.types.listOf lib.types.lines;
                default = [ ];
              };
              options.logFormat = lib.mkOption {
                type = lib.types.nullOr lib.types.lines;
                default = null;
                description = "Optional Caddy logFormat block for this virtual host.";
              };
            }
          );
          default = { };
          description = "Caddy route fragments keyed by virtual host.";
        };
      };

      config = lib.mkIf enabled {
        sops.secrets.caddy_env = {
          owner = "caddy";
          group = "caddy";
          mode = "0400";
          format = "dotenv";
          sopsFile = "${inputs.nix-secrets}/env_files/caddy.env";
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
              handle @scanner_paths_{args[0]} { respond "" 403 }
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
          virtualHosts =
            lib.optionalAttrs (cfg.apexRoutes != [ ]) {
              "{$DOMAIN}".extraConfig = renderRoutes cfg.apexRoutes;
            }
            // virtualHosts;
        };

        services.fail2ban = lib.mkIf cfg.enableFail2ban {
          enable = true;
          maxretry = 5;
          ignoreIP = [
            "127.0.0.1/8"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "173.245.48.0/20"
            "103.21.244.0/22"
            "103.22.200.0/22"
            "103.31.4.0/22"
            "141.101.64.0/18"
            "108.162.192.0/18"
            "190.93.240.0/20"
            "188.114.96.0/20"
            "197.234.240.0/22"
            "198.41.128.0/17"
            "162.158.0.0/15"
            "104.16.0.0/13"
            "104.24.0.0/14"
            "172.64.0.0/13"
            "131.0.72.0/22"
            "2400:cb00::/32"
            "2606:4700::/32"
            "2803:f800::/32"
            "2405:b500::/32"
            "2405:8100::/32"
            "2a06:98c0::/29"
            "2c0f:f248::/32"
          ];
          bantime = "24h";
          bantime-increment = {
            enable = true;
            formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
            maxtime = "168h";
            overalljails = true;
          };
          jails = {
            caddy-4xx.settings = {
              enabled = true;
              filter = "caddy-4xx";
              action = "%(action_)s[blocktype=DROP]";
              backend = "systemd";
              journalmatch = "_SYSTEMD_UNIT=caddy.service";
              maxRetry = 5;
              findTime = "2h";
            };
            caddy-scan.settings = {
              enabled = true;
              filter = "caddy-scan";
              action = "caddy-cloudflare";
              backend = "systemd";
              journalmatch = "_SYSTEMD_UNIT=caddy.service";
              maxRetry = 2;
              findTime = "30m";
              bantime = "168h";
            };
            caddy-unhosted-sni.settings = {
              enabled = true;
              filter = "caddy-unhosted-sni";
              action = "caddy-cloudflare";
              backend = "systemd";
              journalmatch = "_SYSTEMD_UNIT=caddy.service";
              maxRetry = 3;
              findTime = "1h";
            };
          };
        };

        systemd.services.fail2ban.serviceConfig.EnvironmentFile = lib.mkIf cfg.enableFail2ban [
          config.sops.secrets.caddy_env.path
        ];

        environment.etc = lib.mkIf cfg.enableFail2ban {
          "fail2ban/filter.d/caddy-4xx.local".text = ''
            [Definition]
            failregex = ^(?=.*"method"\s*:\s*"(?:GET|POST|HEAD|PUT|PATCH|DELETE|OPTIONS)")(?=.*"status"\s*:\s*(?:401|403|404|405|408|429))(?=.*"headers"\s*:\s*\{.*"(?:Cf-Connecting-Ip|X-Forwarded-For)"\s*:\s*\["<HOST>(?:,[^"]*)?"\]).*$
          '';
          "fail2ban/filter.d/caddy-scan.local".text = ''
            [Definition]
            failregex = ^(?=.*"uri"\s*:\s*"[^"]*(?i:(?:wp-admin|wp-login(?:\.php)?|xmlrpc\.php|\.env(?:\.|$|\?)|\.git/config|\.DS_Store|\.svn/|\.hg/|\.bzr/|phpmyadmin|/pma(?:/|\?|$)|/cgi-bin(?:/|\?|$)|/actuator(?:/|\?|$)|/server-status(?:\?|$)|/server-info(?:\?|$)|/manager/html(?:\?|$)|/solr(?:/|\?|$)|/v2/_catalog(?:/|\?|$)|/(?:ecp|owa|autodiscover)(?:/|\?|$)|/boaform(?:/|\?|$)|/HNAP1(?:/|\?|$)|/(?:debug|config|admin)(?:/|\?|$)|\.(?:bak|old|orig|sql|zip|tar|gz)(?:\?|$))))(?=.*"headers"\s*:\s*\{.*"(?:Cf-Connecting-Ip|X-Forwarded-For)"\s*:\s*\["<HOST>(?:,[^"]*)?"\]).*$
          '';
          "fail2ban/filter.d/caddy-unhosted-sni.local".text = ''
            [Definition]
            failregex = ^.*http: TLS handshake error from <HOST>:\d+: no certificate available for '[^']+'.*$
          '';
          "fail2ban/action.d/caddy-cloudflare.conf".text = ''
            [Definition]
            actioncheck = test -n "$CLOUDFLARE_API_TOKEN" -a -n "''${CLOUDFLARE_ZONE_ID:-$CLOUDFLARE_ACCOUNT_ID}"
            actionban = /etc/fail2ban/caddy-cloudflare-ban.sh <ip> <name>
            actionunban = /etc/fail2ban/caddy-cloudflare-unban.sh <ip> <name>
          '';
          "fail2ban/caddy-cloudflare-ban.sh" = {
            mode = "0750";
            text = ''
              #!${pkgs.bash}/bin/bash
              set -euo pipefail
              ip="$1"; jail="''${2:-unknown-jail}"
              zone="''${CLOUDFLARE_ZONE_ID:-}"; account="''${CLOUDFLARE_ACCOUNT_ID:-}"; token="''${CLOUDFLARE_API_TOKEN:-}"
              case "$ip" in
                *[!0-9A-Fa-f:.]*|"") echo "invalid Fail2ban IP: $ip" >&2; exit 2 ;;
              esac
              jail="$(printf '%s' "$jail" | ${pkgs.coreutils}/bin/tr -cd 'A-Za-z0-9._:-')"
              test -n "$jail" || jail="unknown-jail"
              zone="$(printf '%s' "$zone" | ${pkgs.coreutils}/bin/tr -d '\r\n')"; account="$(printf '%s' "$account" | ${pkgs.coreutils}/bin/tr -d '\r\n')"; token="$(printf '%s' "$token" | ${pkgs.coreutils}/bin/tr -d '\r\n')"
              zone="''${zone#\"}"; zone="''${zone%\"}"; account="''${account#\"}"; account="''${account%\"}"; token="''${token#\"}"; token="''${token%\"}"
              if test -n "$account"; then
                scope="account:$account"
                base="https://api.cloudflare.com/client/v4/accounts/$account/firewall/access_rules/rules"
              elif test -n "$zone"; then
                scope="zone:$zone"
                base="https://api.cloudflare.com/client/v4/zones/$zone/firewall/access_rules/rules"
              else
                echo "missing Cloudflare scope: set CLOUDFLARE_ZONE_ID or CLOUDFLARE_ACCOUNT_ID" >&2; exit 1
              fi
              test -n "$token" || { echo "missing CLOUDFLARE_API_TOKEN" >&2; exit 1; }
              cf_api() {
                local op="$1" response http body errors
                shift
                response="$(${pkgs.curl}/bin/curl -sS "$@" -w '\n%{http_code}')"
                http="''${response##*$'\n'}"; body="''${response%$'\n'*}"
                if test "$http" -lt 200 -o "$http" -ge 300; then
                  errors="$(printf '%s' "$body" | ${pkgs.jq}/bin/jq -r '(.errors // []) | map("\(.code):\(.message)") | join("; ")' 2>/dev/null || true)"
                  echo "$op http=$http cloudflare_errors=''${errors:-unparsed response}" >&2
                  ${pkgs.systemd}/bin/systemd-cat -t fail2ban-caddy-cloudflare -p err <<<"$op http=$http cloudflare_errors=''${errors:-unparsed response}"
                  return 22
                fi
                printf '%s' "$body"
              }
              existing="$(cf_api "ban lookup failed ip=$ip scope=$scope" --get "$base" --data-urlencode "mode=block" --data-urlencode "configuration.target=ip" --data-urlencode "configuration.value=$ip" --data-urlencode "per_page=1" -H "Authorization: Bearer $token" -H "Content-Type: application/json" | ${pkgs.jq}/bin/jq -r '.result[0].id // empty')"
              test -n "$existing" && { ${pkgs.systemd}/bin/systemd-cat -t fail2ban-caddy-cloudflare -p info <<<"ban skipped existing rule ip=$ip rule_id=$existing"; exit 0; }
              cf_api "ban create failed ip=$ip scope=$scope" -X POST "$base" -H "Authorization: Bearer $token" -H "Content-Type: application/json" --data "{\"mode\":\"block\",\"configuration\":{\"target\":\"ip\",\"value\":\"$ip\"},\"notes\":\"fail2ban:$jail\"}" | ${pkgs.jq}/bin/jq -e '.success == true' >/dev/null
              ${pkgs.systemd}/bin/systemd-cat -t fail2ban-caddy-cloudflare -p info <<<"ban created ip=$ip scope=$scope jail=$jail"
            '';
          };
          "fail2ban/caddy-cloudflare-unban.sh" = {
            mode = "0750";
            text = ''
              #!${pkgs.bash}/bin/bash
              set -euo pipefail
              ip="$1"; jail="''${2:-unknown-jail}"; zone="''${CLOUDFLARE_ZONE_ID:-}"; account="''${CLOUDFLARE_ACCOUNT_ID:-}"; token="''${CLOUDFLARE_API_TOKEN:-}"
              case "$ip" in
                *[!0-9A-Fa-f:.]*|"") echo "invalid Fail2ban IP: $ip" >&2; exit 2 ;;
              esac
              zone="$(printf '%s' "$zone" | ${pkgs.coreutils}/bin/tr -d '\r\n')"; account="$(printf '%s' "$account" | ${pkgs.coreutils}/bin/tr -d '\r\n')"; token="$(printf '%s' "$token" | ${pkgs.coreutils}/bin/tr -d '\r\n')"
              zone="''${zone#\"}"; zone="''${zone%\"}"; account="''${account#\"}"; account="''${account%\"}"; token="''${token#\"}"; token="''${token%\"}"
              if test -n "$account"; then
                scope="account:$account"; base="https://api.cloudflare.com/client/v4/accounts/$account/firewall/access_rules/rules"
              elif test -n "$zone"; then
                scope="zone:$zone"; base="https://api.cloudflare.com/client/v4/zones/$zone/firewall/access_rules/rules"
              else
                echo "missing Cloudflare scope: set CLOUDFLARE_ZONE_ID or CLOUDFLARE_ACCOUNT_ID" >&2; exit 1
              fi
              test -n "$token" || { echo "missing CLOUDFLARE_API_TOKEN" >&2; exit 1; }
              cf_api() {
                local op="$1" response http body errors
                shift
                response="$(${pkgs.curl}/bin/curl -sS "$@" -w '\n%{http_code}')"
                http="''${response##*$'\n'}"; body="''${response%$'\n'*}"
                if test "$http" -lt 200 -o "$http" -ge 300; then
                  errors="$(printf '%s' "$body" | ${pkgs.jq}/bin/jq -r '(.errors // []) | map("\(.code):\(.message)") | join("; ")' 2>/dev/null || true)"
                  echo "$op http=$http cloudflare_errors=''${errors:-unparsed response}" >&2
                  ${pkgs.systemd}/bin/systemd-cat -t fail2ban-caddy-cloudflare -p err <<<"$op http=$http cloudflare_errors=''${errors:-unparsed response}"
                  return 22
                fi
                printf '%s' "$body"
              }
              rules="$(cf_api "unban lookup failed ip=$ip scope=$scope" --get "$base" --data-urlencode "mode=block" --data-urlencode "configuration.target=ip" --data-urlencode "configuration.value=$ip" --data-urlencode "per_page=100" -H "Authorization: Bearer $token" -H "Content-Type: application/json" | ${pkgs.jq}/bin/jq -r '.result[].id // empty')"
              deleted=0
              while read -r rule; do
                test -z "$rule" || { cf_api "unban delete failed ip=$ip scope=$scope rule_id=$rule" -X DELETE "$base/$rule" -H "Authorization: Bearer $token" -H "Content-Type: application/json" >/dev/null; deleted=$((deleted + 1)); }
              done <<< "$rules"
              ${pkgs.systemd}/bin/systemd-cat -t fail2ban-caddy-cloudflare -p info <<<"unban completed ip=$ip scope=$scope jail=$jail deleted_rules=$deleted"
            '';
          };
        };
      };
    };
}
