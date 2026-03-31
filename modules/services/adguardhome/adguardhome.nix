{
  inputs,
  ...
}:
{
  flake.modules.nixos.adguardhome =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      networkConfig = config.systemConstants.network;
      merge-dynamic-leases = ./merge_dynamic_leases.py;
      adguardhome-path = "/var/lib/AdGuardHome";
      python3Bin = "${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python3";
      readBuildValue =
        path:
        builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
      localDomain = readBuildValue "domain.txt";
    in
    {
      environment.systemPackages = with pkgs; [
        python3
        ssh-to-age
        yq-go
      ];

      imports = [ inputs.self.modules.nixos.dhcp-failover ];

      systemd.services.adguardhome-prepare = {
        description = "Prepare AdGuardHome configuration and DHCP leases";
        before = [ "adguardhome.service" ];
        after = [
          "network.target"
          "local-fs.target"
        ];
        wantedBy = [ "adguardhome.service" ];
        partOf = [
          "adguardhome.service"
          "pdns.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          RemainAfterExit = true;
        };
        script = ''
          TEMP_LEASES="/tmp/adguard-leases-$$.json"
          TEMP_AGE_KEY="/tmp/age-key-$$.txt"

          ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < /etc/ssh/ssh_host_ed25519_key > "$TEMP_AGE_KEY"

          if ! SOPS_AGE_KEY_FILE="$TEMP_AGE_KEY" \
          ${pkgs.sops}/bin/sops --decrypt "${inputs.nix-secrets}/adguardhome/leases.json" > "$TEMP_LEASES" 2>/dev/null; then
            exit 1
          fi

          if [ ! -s "$TEMP_LEASES" ]; then
            echo '{"version": 1, "leases": []}' > "$TEMP_LEASES"
          fi

          mkdir -p ${adguardhome-path}/data

          if [ -f "${adguardhome-path}/data/leases.json" ]; then
            ${python3Bin} ${merge-dynamic-leases} "$TEMP_LEASES" ${adguardhome-path}/data/leases.json
          else
            cp "$TEMP_LEASES" ${adguardhome-path}/data/leases.json
          fi

          chmod 644 ${adguardhome-path}/data/leases.json

          AGH_USER="$(cat /run/secrets/adguardhome_user)"
          AGH_PASSWORD="$(cat /run/secrets/adguardhome_hashed_password)"
          AGH_DOMAIN="$(cat /run/secrets/adguardhome_domain)"

          mkdir -p /run/adguardhome

          if [ -f "${adguardhome-path}/AdGuardHome.yaml" ]; then
            AGH_PASSWORD_ESCAPED=$(printf '%s\n' "$AGH_PASSWORD" | sed 's/[\[\.*^$()+?{|]/\\&/g')
            AGH_DOMAIN_ESCAPED=$(printf '%s\n' "$AGH_DOMAIN" | sed 's/[\[\.*^$()+?{|]/\\&/g')

            sed "s/\$AGH_USER/$AGH_USER/g; s/\$AGH_PASSWORD/$AGH_PASSWORD_ESCAPED/g; s/\$AGH_DOMAIN/$AGH_DOMAIN_ESCAPED/g" \
              "${adguardhome-path}/AdGuardHome.yaml" > "/run/adguardhome/AdGuardHome.yaml"
            chmod 644 "/run/adguardhome/AdGuardHome.yaml"
          fi

          rm -f "$TEMP_LEASES" "$TEMP_AGE_KEY"
        '';
      };

      systemd.services.adguardhome = {
        requires = [ "adguardhome-prepare.service" ];
        after = [
          "adguardhome-prepare.service"
          "pdns.service"
        ];
        preStart = lib.mkAfter ''
          if [ -f "/run/adguardhome/AdGuardHome.yaml" ]; then
            cp "/run/adguardhome/AdGuardHome.yaml" "$STATE_DIRECTORY/AdGuardHome.yaml"
          fi
        '';
        postStart = ''
          echo "Waiting for AdGuardHome DNS to become ready..."
          for i in {1..30}; do
            if ${pkgs.dig}/bin/dig @127.0.0.1 -p 53 google.com +short >/dev/null 2>&1; then
              echo "AdGuardHome DNS is responding"
              break
            fi
            if [ $i -eq 30 ]; then
              echo "AdGuardHome DNS failed to respond after 60 seconds"
              exit 1
            fi
            sleep 2
          done

          echo "Testing AdGuardHome-PowerDNS integration..."
          integration_failed=0
          for domain in "naboo.${localDomain}" "nevarro.${localDomain}" "atlasuponraiden.${localDomain}"; do
            echo "Testing resolution of $domain..."
            if ${pkgs.dig}/bin/dig @127.0.0.1 -p 53 "$domain" +short >/dev/null 2>&1; then
              echo "  ✓ $domain resolved successfully"
            else
              echo "  ⚠ WARNING: Failed to resolve $domain (PowerDNS may not be ready yet)"
              integration_failed=1
            fi
          done

          if [ $integration_failed -eq 1 ]; then
            echo "⚠ WARNING: AGH-PDNS integration not fully working yet"
            echo "  This is normal during startup - PowerDNS may still be initializing"
            echo "  AdGuardHome will continue to work for external DNS queries"
          else
            echo "✓ AGH-PDNS integration working correctly"
          fi

          echo "AdGuardHome startup validation completed successfully"
        '';
      };

      systemd.services.adguardhome-healthcheck = {
        description = "AdGuardHome Health Check";
        after = [ "adguardhome.service" ];
        wants = [ "adguardhome.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "nobody";
          ExecStart = pkgs.writeShellScript "agh-healthcheck" ''
            ${pkgs.dig}/bin/dig @127.0.0.1 -p 53 google.com +short >/dev/null 2>&1 || exit 1

            for domain in "naboo.${localDomain}" "nevarro.${localDomain}" "atlasuponraiden.${localDomain}"; do
              ${pkgs.dig}/bin/dig @127.0.0.1 -p 53 "$domain" +short >/dev/null 2>&1 || {
                echo "Failed to resolve $domain through AGH-PDNS integration"
                exit 1
              }
            done

            echo "Health check passed"
          '';
        };
      };

      systemd.timers.adguardhome-healthcheck = {
        description = "Run AdGuardHome health check every 5 minutes";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "5min";
          Unit = "adguardhome-healthcheck.service";
        };
      };

      networking.firewall.allowedUDPPorts = [
        53
        67
        68
      ];

      services = {
        caddy = {
          virtualHosts."agh-${lib.toLower config.networking.hostName}.{$DOMAIN}" = {
            logFormat = ''
              output stdout
              format console
              level DEBUG
            '';
            extraConfig = ''
              reverse_proxy http://${config.services.adguardhome.host}:${toString config.services.adguardhome.port}
            '';
          };
        };

        adguardhome = {
          enable = true;
          openFirewall = true;
          allowDHCP = true;
          mutableSettings = true;
          host = "127.0.0.1";
          port = 3003;
          settings = {
            users = [
              {
                name = "$AGH_USER";
                password = "$AGH_PASSWORD";
              }
            ];

            schema_version = 30;
            dns = {
              upstream_mode = "parallel";
              upstream_dns = [
                "[/*.$AGH_DOMAIN/]127.0.0.1:5335"
                "[/$AGH_DOMAIN/mail.$AGH_DOMAIN/]bristol.ns.cloudflare.com zod.ns.cloudflare.com"
                "1.1.1.1"
                "9.9.9.9"
              ];
              blocked_hosts = [
                "chat.avatar.ext.hp.com"
              ];
              bootstrap_dns = [
                "1.1.1.1"
                "9.9.9.9"
              ];
            };
            filtering = {
              protection_enabled = true;
              filtering_enabled = true;
              parental_enabled = false;
              safe_search.enabled = false;
              rewrites =
                map
                  (domain: {
                    inherit domain;
                    answer = networkConfig.minecraft_redirect;
                  })
                  [
                    "geo.hivebedrock.network"
                    "hivebedrock.network"
                    "play.inpvp.net"
                    "mco.lbsg.net"
                    "play.galaxite.net"
                    "play.enchanted.gg"
                  ];
            };
            filters =
              map
                (pair: {
                  enabled = true;
                  url = builtins.elemAt pair 0;
                  name = builtins.elemAt pair 1;
                })
                [
                  [
                    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"
                    "The Big List of Hacked Malware Web Sites"
                  ]
                  [
                    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"
                    "Malicious URL Blocklist (URLHaus)"
                  ]
                  [
                    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.txt"
                    "HaGeZi's Ultimate DNS Blocklist"
                  ]
                ];
            user_rules = [
              "@@||api.loganalytics.io^$client='${networkConfig.work_laptop_1}'"
              "@@||api.loganalytics.io^$client='${networkConfig.work_laptop_2}'"
              "@@||portal.loganalytics.io^$client='${networkConfig.work_laptop_1}'"
              "@@||portal.loganalytics.io^$client='${networkConfig.work_laptop_2}'"
            ];
            dhcp = {
              enabled = lib.mkDefault false;
              interface_name = "end0";
              dhcpv4 = {
                gateway_ip = networkConfig.gateway;
                subnet_mask = networkConfig.subnet_mask;
                range_start = networkConfig.dhcp_start;
                range_end = networkConfig.dhcp_end;
                lease_duration = 86400;
                options = [
                  "6 ips ${networkConfig.dns_servers}"
                  "15 text $AGH_DOMAIN"
                ];
              };
              icmp_timeout_msec = 1000;
            };
          };
        };
      };
    };
}
