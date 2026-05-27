{
  inputs,
  ...
}:
{
  flake.modules.nixos.caddy =
    {
      config,
      pkgs,
      ...
    }:
    {
      sops.secrets = {
        caddy_env = {
          owner = "caddy";
          group = "caddy";
          mode = "0400";
          format = "dotenv";
          sopsFile = "${inputs.nix-secrets}/env_files/caddy.env";
          key = "";
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services = {
        caddy = {
          package = pkgs.caddy.withPlugins {
            plugins = [
              "github.com/caddy-dns/cloudflare@v0.2.2"
              "github.com/sjtug/caddy2-filter@v0.0.0-20230306214137-04be952a71e1"
            ];
            hash = "sha256-/zjToevOlKOwKCLf8WncYE4Nu74/Bnkc1mMA8/cdFcE=";
          };
          enable = true;
          email = "letsencrypt@{$DOMAIN}";
          environmentFile = config.sops.secrets.caddy_env.path;
          globalConfig = ''
            acme_dns cloudflare {$CLOUDFLARE_API_KEY}
            order filter after encode
          '';
          extraConfig = ''
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
            level DEBUG
          '';
        };

        fail2ban = {
          enable = true;
          maxretry = 5;
          ignoreIP = [
            "127.0.0.1/8"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
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
          };
        };
      };

      systemd.services.fail2ban.serviceConfig.EnvironmentFile = [
        config.sops.secrets.caddy_env.path
      ];

      environment.etc = {
        "fail2ban/filter.d/caddy-4xx.local".text = pkgs.lib.mkDefault (pkgs.lib.mkAfter ''
          [Definition]
          failregex = ^(?=.*"method"\s*:\s*"(?:GET|POST|HEAD|PUT|PATCH|DELETE|OPTIONS)")(?=.*"status"\s*:\s*(?:401|403|404|405|408|429))(?=.*"headers"\s*:\s*\{.*"(?:Cf-Connecting-Ip|X-Forwarded-For)"\s*:\s*\["<HOST>(?:,[^"]*)?"\]).*$
        '');

        "fail2ban/filter.d/caddy-scan.local".text = pkgs.lib.mkDefault (pkgs.lib.mkAfter ''
          [Definition]
          failregex = ^(?=.*"uri"\s*:\s*"[^"]*(?i:(?:wp-admin|wp-login(?:\.php)?|xmlrpc\.php|\.env(?:\.|$|\?)|\.git/config|\.DS_Store|\.svn/|\.hg/|\.bzr/|phpmyadmin|/pma(?:/|\?|$)|/cgi-bin(?:/|\?|$)|/actuator(?:/|\?|$)|/server-status(?:\?|$)|/server-info(?:\?|$)|/manager/html(?:\?|$)|/solr(?:/|\?|$)|/v2/_catalog(?:\?|$)|/(?:ecp|owa|autodiscover)(?:/|\?|$)|/boaform(?:/|\?|$)|/HNAP1(?:/|\?|$)|/(?:debug|config|admin)(?:/|\?|$)|\.(?:bak|old|orig|sql|zip|tar|gz)(?:\?|$))))(?=.*"headers"\s*:\s*\{.*"(?:Cf-Connecting-Ip|X-Forwarded-For)"\s*:\s*\["<HOST>(?:,[^"]*)?"\]).*$
        '');

        "fail2ban/action.d/caddy-cloudflare.local".text = pkgs.lib.mkDefault (pkgs.lib.mkAfter ''
          [Definition]
          actioncheck = test -n "$CLOUDFLARE_API_TOKEN" -a -n "$CLOUDFLARE_ZONE_ID"

          actionban = ${pkgs.bash}/bin/bash -lc "set -euo pipefail; ip='<ip>'; zone=\"$CLOUDFLARE_ZONE_ID\"; token=\"$CLOUDFLARE_API_TOKEN\"; base=\"https://api.cloudflare.com/client/v4/zones/$zone/firewall/access_rules/rules\"; existing_id=\"$(${pkgs.curl}/bin/curl -fsS \"$base?mode=block&configuration.target=ip&configuration.value=$ip&per_page=1\" -H \"Authorization: Bearer $token\" -H \"Content-Type: application/json\" | ${pkgs.jq}/bin/jq -r '.result[0].id // empty')\"; test -n \"$existing_id\" && exit 0; ${pkgs.curl}/bin/curl -fsS -X POST \"$base\" -H \"Authorization: Bearer $token\" -H \"Content-Type: application/json\" --data \"{\\\"mode\\\":\\\"block\\\",\\\"configuration\\\":{\\\"target\\\":\\\"ip\\\",\\\"value\\\":\\\"$ip\\\"},\\\"notes\\\":\\\"fail2ban:caddy-scan\\\"}\" | ${pkgs.jq}/bin/jq -e '.success == true' >/dev/null"

          actionunban = ${pkgs.bash}/bin/bash -lc "set -euo pipefail; ip='<ip>'; zone=\"$CLOUDFLARE_ZONE_ID\"; token=\"$CLOUDFLARE_API_TOKEN\"; base=\"https://api.cloudflare.com/client/v4/zones/$zone/firewall/access_rules/rules\"; ${pkgs.curl}/bin/curl -fsS \"$base?mode=block&configuration.target=ip&configuration.value=$ip&per_page=100\" -H \"Authorization: Bearer $token\" -H \"Content-Type: application/json\" | ${pkgs.jq}/bin/jq -r '.result[].id' | while read -r rule_id; do test -n \"$rule_id\" || continue; ${pkgs.curl}/bin/curl -fsS -X DELETE \"$base/$rule_id\" -H \"Authorization: Bearer $token\" -H \"Content-Type: application/json\" >/dev/null; done"
        '');
      };
    };
}
