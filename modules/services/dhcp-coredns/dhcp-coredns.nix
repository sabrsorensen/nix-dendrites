{
  inputs,
  ...
}:
{
  flake.modules.nixos.dhcp-coredns =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.dhcp-coredns;
      publishedDnsRecords = config.my.localDns.publishedRecords;
      zoneStaticRecords = cfg.staticRecords ++ publishedDnsRecords;
      networkConfig = config.systemConstants.network;
      localDomain = config.systemConstants.domain;

      python3Bin = "${pkgs.python3}/bin/python3";
      collectLeases = ./collect_leases.py;
      renderZone = ./render_zone.py;

      staticLeasesPath = "${cfg.stateDir}/leases.static.json";
      dynamicLeaseFileName = "kea-leases4.csv";
      dynamicLeasePath = "${cfg.stateDir}/${dynamicLeaseFileName}";
      keaConfPath = "${cfg.stateDir}/kea-dhcp4.conf";
      mergedRecordsPath = "${cfg.stateDir}/records.json";
      zonePath = "${cfg.stateDir}/${localDomain}.zone";
      dnsListenMatch = builtins.match "^(.+):([0-9]+)$" cfg.dnsListen;
      dnsHostRaw = builtins.elemAt dnsListenMatch 0;
      dnsHost =
        if lib.hasPrefix "[" dnsHostRaw && lib.hasSuffix "]" dnsHostRaw then
          builtins.substring 1 ((builtins.stringLength dnsHostRaw) - 2) dnsHostRaw
        else
          dnsHostRaw;
      dnsPort = builtins.elemAt dnsListenMatch 1;
      dnsBindDirective =
        if dnsHost == "" || dnsHost == "0.0.0.0" || dnsHost == "::" then "" else "bind ${dnsHost}";
      upstreamServers = builtins.concatStringsSep " " cfg.upstreamServers;
      staticDnsRecords = builtins.toJSON zoneStaticRecords;
    in
    {
      imports = [ inputs.self.modules.nixos.dhcp-failover ];

      options.services.dhcp-coredns = {
        enable = lib.mkEnableOption "DHCP + CoreDNS local DNS stack";

        interface = lib.mkOption {
          type = lib.types.str;
          default = "end0";
        };

        stateDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/dhcp-coredns";
        };

        dnsListen = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0:1053";
        };

        upstreamServers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        };

        staticRecords = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                hostname = lib.mkOption {
                  type = lib.types.str;
                };
                ip = lib.mkOption {
                  type = lib.types.str;
                };
              };
            }
          );
          default = [ ];
          description = "Static DNS records rendered into the local CoreDNS zone.";
        };

        startKeaOnBoot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether the runtime-generated Kea DHCP service should start automatically at boot.";
        };

        localDomainApexIp = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "If set, resolve the root of the local domain to this local IP in CoreDNS.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion =
              builtins.length (lib.unique (map (record: record.hostname) zoneStaticRecords))
              == builtins.length zoneStaticRecords;
            message = "services.dhcp-coredns static/published DNS records contain duplicate hostnames.";
          }
        ];

        environment.systemPackages = with pkgs; [
          jq
          python3
          sops
          ssh-to-age
        ];

        systemd.tmpfiles.rules = [
          "d ${cfg.stateDir} 0755 root root -"
        ];

        systemd.services.dhcp-coredns-prepare = {
          description = "Prepare Kea config inputs and CoreDNS zone data";
          wantedBy = [ "multi-user.target" ];
          before = [
            "dhcp-coredns-kea.service"
            "coredns.service"
          ];
          after = [
            "network.target"
            "local-fs.target"
          ];
          serviceConfig = {
            Type = "oneshot";
          };
          script = ''
            set -eu

            TEMP_AGE_KEY="/tmp/dhcp-coredns-age-key-$$.txt"
            ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < /etc/ssh/ssh_host_ed25519_key > "$TEMP_AGE_KEY"

            if ! SOPS_AGE_KEY_FILE="$TEMP_AGE_KEY" ${pkgs.sops}/bin/sops --decrypt "${inputs.nix-secrets}/leases.json" > "${staticLeasesPath}" 2>/dev/null; then
              echo '{"version":1,"leases":[]}' > "${staticLeasesPath}"
            fi
            rm -f "$TEMP_AGE_KEY"

            if [ ! -s "${staticLeasesPath}" ]; then
              echo '{"version":1,"leases":[]}' > "${staticLeasesPath}"
            fi

            if [ ! -f "${dynamicLeasePath}" ]; then
              : > "${dynamicLeasePath}"
            fi

            export GATEWAY="${networkConfig.gateway}"
            export SUBNET_MASK="${networkConfig.subnet_mask}"
            SUBNET_CIDR="$(${python3Bin} - <<'PY'
            import os
            import ipaddress
            network = ipaddress.IPv4Network((os.environ["GATEWAY"], os.environ["SUBNET_MASK"]), strict=False)
            print(str(network))
            PY
            )"

            ${pkgs.jq}/bin/jq '
              {
                "Dhcp4": {
                  "interfaces-config": { "interfaces": [ "'"${cfg.interface}"'" ] },
                  "lease-database": { "type": "memfile", "persist": true, "name": "'"${dynamicLeaseFileName}"'" },
                  "subnet4": [
                    {
                      "id": 1,
                      "subnet": "'"$SUBNET_CIDR"'",
                      "pools": [ { "pool": "'"${networkConfig.dhcp_start} - ${networkConfig.dhcp_end}"'" } ],
                      "option-data": [
                        { "name": "routers", "data": "'"${networkConfig.gateway}"'" },
                        { "name": "domain-name-servers", "data": "'"${networkConfig.dns_servers}"'" },
                        { "name": "domain-name", "data": "'"${localDomain}"'" }
                      ],
                      "reservations": ((.leases // [])
                        | map(select(.static == true and .ip and .mac)
                          | { "hw-address": (.mac|ascii_downcase), "ip-address": .ip }))
                    }
                  ],
                  "valid-lifetime": 3600,
                  "renew-timer": 900,
                  "rebind-timer": 1800
                }
              }
            ' "${staticLeasesPath}" > "${keaConfPath}"

            ${python3Bin} ${collectLeases} \
              --static-leases "${staticLeasesPath}" \
              --backend "kea-dhcp4" \
              --dynamic-leases "${dynamicLeasePath}" \
              --output "${mergedRecordsPath}"

            ${python3Bin} ${renderZone} \
              --domain "${localDomain}" \
              --records "${mergedRecordsPath}" \
              --static-records-json '${staticDnsRecords}' \
              --zone "${zonePath}" \
              --ns "ns1" \
              --ns2 "ns2"
          '';
        };

        systemd.services.dhcp-coredns-kea = {
          description = "Kea DHCP4 server (runtime-generated config)";
          after = [
            "dhcp-coredns-prepare.service"
            "network.target"
          ];
          requires = [ "dhcp-coredns-prepare.service" ];
          wantedBy = lib.optionals cfg.startKeaOnBoot [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.kea}/bin/kea-dhcp4 -c ${keaConfPath}";
            Environment = "KEA_DHCP_DATA_DIR=${cfg.stateDir}";
            RuntimeDirectory = "kea";
            Restart = "on-failure";
          };
        };

        services.coredns = {
          enable = true;
          config = ''
            mail.${localDomain}:${dnsPort} {
              log
              errors
              forward . ${upstreamServers}
              cache 60
            }

            ${localDomain}:${dnsPort} {
              log
              errors
              ${lib.optionalString (cfg.localDomainApexIp != null) ''
                hosts {
                  ${cfg.localDomainApexIp} ${localDomain}
                  ${cfg.localDomainApexIp} @
                  fallthrough
                }
              ''}
              file ${zonePath} ${localDomain}
              forward . ${upstreamServers}
              cache 60
            }

            .:${dnsPort} {
              log
              errors
              ${lib.optionalString (dnsBindDirective != "") dnsBindDirective}
              hosts {
                ${networkConfig.gateway} home-gw.${localDomain}
                fallthrough
              }
              file ${zonePath} ${localDomain}
              forward . ${upstreamServers}
              cache 60
            }
          '';
        };

        systemd.services.dhcp-coredns-sync = {
          description = "Sync DHCP leases into CoreDNS records";
          after = [
            "dhcp-coredns-kea.service"
            "coredns.service"
          ];
          serviceConfig = {
            Type = "oneshot";
          };
          script = ''
            set -eu
            ${python3Bin} ${collectLeases} \
              --static-leases "${staticLeasesPath}" \
              --backend "kea-dhcp4" \
              --dynamic-leases "${dynamicLeasePath}" \
              --output "${mergedRecordsPath}"

            ${python3Bin} ${renderZone} \
              --domain "${localDomain}" \
              --records "${mergedRecordsPath}" \
              --static-records-json '${staticDnsRecords}' \
              --zone "${zonePath}" \
              --ns "ns1" \
              --ns2 "ns2"

            systemctl reload coredns.service || systemctl restart coredns.service
          '';
        };

        systemd.timers.dhcp-coredns-sync = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = "1min";
            Unit = "dhcp-coredns-sync.service";
          };
        };

        networking.firewall.allowedUDPPorts = [
          53
          67
          68
          1053
        ];
      };
    };
}
