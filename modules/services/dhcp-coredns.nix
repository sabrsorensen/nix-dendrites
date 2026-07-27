{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  staticRecords = [
    {
      hostname = "atlas";
      ip = network.atlasuponraiden;
    }
    {
      hostname = "coruscant";
      ip = network.coruscant;
    }
    {
      hostname = "ferrix";
      ip = network.ferrix;
    }
    {
      hostname = "naboo";
      ip = network.naboo;
    }
    {
      hostname = "nevarro";
      ip = network.nevarro;
    }
    {
      hostname = "ns1";
      ip = network.nevarro;
    }
    {
      hostname = "ns2";
      ip = network.naboo;
    }
    {
      hostname = "home-gw";
      ip = network.gateway;
    }
  ];
in
{
  flake.modules.nixos.dhcp-coredns =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.dhcpCoredns;
      enabled = config.my.host.services.dhcpCoredns;
      stateDir = cfg.stateDir;
      dnsListenMatch = builtins.match "^(.+):([0-9]+)$" cfg.dnsListen;
      dnsHost = builtins.elemAt dnsListenMatch 0;
      dnsPort = builtins.elemAt dnsListenMatch 1;
      dnsBind =
        if dnsHost == "" || dnsHost == "0.0.0.0" || dnsHost == "::" then "" else "bind ${dnsHost}";
      recordsJson = builtins.toJSON (cfg.staticRecords ++ inputs.self.lib.localDns.publishedRecords);
      renderZone = pkgs.writeText "dhcp-coredns-render-zone.py" ''
        import csv, json, re
        from pathlib import Path
        state = Path("${stateDir}")
        def norm(name): return re.sub(r"[^a-z0-9-]", "", name.strip().lower().replace(" ", "-").replace("_", "-"))
        static = json.loads('${recordsJson}')
        leases = json.loads((state / "leases.static.json").read_text()).get("reservations", [])
        dynamic = []
        lease_file = state / "kea-leases4.csv"
        if lease_file.exists():
          for row in csv.DictReader(lease_file.read_text().splitlines()):
            if row.get("state", "0") in ("", "0") and row.get("hostname") and row.get("address"):
              dynamic.append({"hostname": row["hostname"], "ip": row["address"]})
        seen = set(); rows = []
        for record in static + leases + dynamic:
          name = norm(record.get("hostname", "")); ip = record.get("ip", "")
          if name and ip and name not in seen:
            seen.add(name); rows.append((name, ip))
        apex = json.loads('${builtins.toJSON cfg.localDomainApexIp}')
        lines = ["$ORIGIN ${domain}.", "$TTL 60", "@ IN SOA ns1.${domain}. admin.${domain}. (1 60 60 1209600 60)", "@ IN NS ns1.${domain}.", "@ IN NS ns2.${domain}."]
        if apex: lines.append(f"@ IN A {apex}")
        lines += [f"{name} IN A {ip}" for name, ip in rows]
        (state / "${domain}.zone").write_text("\\n".join(lines) + "\\n")
      '';
      prepare = pkgs.writeShellScript "dhcp-coredns-prepare" ''
        set -eu
        temp_key="$(mktemp)"; trap 'rm -f "$temp_key"' EXIT
        ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < /etc/ssh/ssh_host_ed25519_key > "$temp_key"
        if ! SOPS_AGE_KEY_FILE="$temp_key" ${pkgs.sops}/bin/sops --decrypt ${inputs.nix-secrets}/leases.json > ${stateDir}/leases.static.json 2>/dev/null; then echo '{"reservations":[]}' > ${stateDir}/leases.static.json; fi
        : > ${stateDir}/kea-leases4.csv
        subnet="$(${pkgs.python3}/bin/python3 -c 'import ipaddress; print(ipaddress.IPv4Network(("${network.gateway}", "${network.subnet_mask}"), strict=False))')"
        ${pkgs.jq}/bin/jq --arg subnet "$subnet" '{Dhcp4:{"interfaces-config":{interfaces:["${cfg.interface}"]},"lease-database":{type:"memfile",persist:true,name:"kea-leases4.csv"},subnet4:[{id:1,subnet:$subnet,pools:[{pool:"${network.dhcp_start} - ${network.dhcp_end}"}],"option-data":[{name:"routers",data:"${network.gateway}"},{name:"domain-name-servers",data:"${network.dns_servers}"},{name:"domain-name",data:"${domain}"}],reservations:(((.reservations // []) + (.leases // [])) | map(select(.ip and .mac and (.static // true)) | {"hw-address":(.mac|ascii_downcase),"ip-address":.ip}))}],"valid-lifetime":${toString cfg.validLifetime},"renew-timer":${toString cfg.renewTimer},"rebind-timer":${toString cfg.rebindTimer}}}' ${stateDir}/leases.static.json > ${stateDir}/kea-dhcp4.conf
        ${pkgs.python3}/bin/python3 ${renderZone}
      '';
      failover = pkgs.writeShellScript "dhcp-coredns-failover" ''
        set -eu
        peer_ip=${lib.escapeShellArg cfg.failover.peerIp}
        peer_name=${lib.escapeShellArg cfg.failover.peerName}
        peer_ok=false
        if ${pkgs.coreutils}/bin/timeout 5 ${pkgs.nmap}/bin/nmap -Pn -sU -p 67 --host-timeout 4s "$peer_ip" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -Eq '67/udp[[:space:]]+(open|open\|filtered)'; then
          peer_ok=true
          for probe in ${lib.escapeShellArgs cfg.failover.probeDomains}; do
            ${pkgs.coreutils}/bin/timeout 5 ${pkgs.dnsutils}/bin/dig @"$peer_ip" -p 53 "$probe.${domain}" +short >/dev/null 2>&1 || peer_ok=false
          done
        fi
        if "$peer_ok"; then
          ${config.systemd.package}/bin/systemctl stop dhcp-coredns-kea.service || true
        else
          ${config.systemd.package}/bin/systemctl start dhcp-coredns-kea.service
        fi
      '';
    in
    {
      options.my.dhcpCoredns = {
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
        validLifetime = lib.mkOption {
          type = lib.types.ints.positive;
          default = 3600;
        };
        renewTimer = lib.mkOption {
          type = lib.types.ints.positive;
          default = 900;
        };
        rebindTimer = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1800;
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
                hostname = lib.mkOption { type = lib.types.str; };
                ip = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          default = staticRecords;
        };
        startKeaOnBoot = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        localDomainApexIp = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional A record for the local DNS zone apex.";
        };
        failover = {
          enable = lib.mkEnableOption "Kea standby failover monitor";
          peerName = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          peerIp = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          probeDomains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Relative names that must resolve on the peer before local DHCP is stopped.";
          };
        };
      };
      config = lib.mkIf enabled {
        environment.systemPackages = [
          pkgs.jq
          pkgs.python3
          pkgs.sops
          pkgs.ssh-to-age
        ];
        assertions = [
          {
            assertion =
              builtins.length (
                lib.unique (
                  map (record: record.hostname) (cfg.staticRecords ++ inputs.self.lib.localDns.publishedRecords)
                )
              ) == builtins.length (cfg.staticRecords ++ inputs.self.lib.localDns.publishedRecords);
            message = "dhcp-coredns static and published DNS records contain duplicate hostnames.";
          }
        ];
        systemd.tmpfiles.rules = [ "d ${stateDir} 0755 root root -" ];
        systemd.services.dhcp-coredns-prepare = {
          wantedBy = [ "multi-user.target" ];
          before = [
            "dhcp-coredns-kea.service"
            "coredns.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = prepare;
          };
        };
        systemd.services.dhcp-coredns-kea = {
          requires = [ "dhcp-coredns-prepare.service" ];
          after = [ "dhcp-coredns-prepare.service" ];
          wantedBy = lib.optionals cfg.startKeaOnBoot [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.kea}/bin/kea-dhcp4 -c ${stateDir}/kea-dhcp4.conf";
            Restart = "on-failure";
          };
        };
        services.coredns = {
          enable = true;
          config = ''
            mail.${domain}:${dnsPort} {
              log
              errors
              forward . ${lib.concatStringsSep " " cfg.upstreamServers}
              cache 60
            }

            ${domain}:${dnsPort} {
              log
              errors
              ${lib.optionalString (cfg.localDomainApexIp != null) ''
                hosts {
                  ${cfg.localDomainApexIp} ${domain}
                  ${cfg.localDomainApexIp} @
                  fallthrough
                }
              ''}
              file ${stateDir}/${domain}.zone ${domain}
              forward . ${lib.concatStringsSep " " cfg.upstreamServers}
              cache 60
            }

            .:${dnsPort} {
              log
              errors
              ${lib.optionalString (dnsBind != "") dnsBind}
              hosts {
                ${network.gateway} home-gw.${domain}
                fallthrough
              }
              file ${stateDir}/${domain}.zone ${domain}
              forward . ${lib.concatStringsSep " " cfg.upstreamServers}
              cache 60
            }
          '';
        };
        systemd.services.dhcp-coredns-sync = {
          after = [ "dhcp-coredns-kea.service" ];
          serviceConfig.Type = "oneshot";
          script = "${pkgs.python3}/bin/python3 ${renderZone}; ${config.systemd.package}/bin/systemctl reload coredns.service";
        };
        systemd.timers.dhcp-coredns-sync = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = "1min";
            Unit = "dhcp-coredns-sync.service";
          };
        };
        systemd.services.dhcp-failover = lib.mkIf cfg.failover.enable {
          after = [
            "network.target"
            "blocky.service"
            "coredns.service"
          ];
          wants = [
            "blocky.service"
            "coredns.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = failover;
          };
        };
        systemd.timers.dhcp-failover = lib.mkIf cfg.failover.enable {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "30s";
            Unit = "dhcp-failover.service";
          };
        };
        networking.firewall.allowedUDPPorts = [
          67
          68
          1053
        ];
      };
    };
}
