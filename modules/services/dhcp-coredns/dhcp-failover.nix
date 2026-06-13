{
  flake.modules.nixos.dhcp-failover =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dhcpCoreDnsEnabled =
        lib.hasAttrByPath [ "services" "dhcp-coredns" "enable" ] config
        && config.services.dhcp-coredns.enable;
      cfg = config.services.dhcp-coredns.failover;
      localDomain = config.systemConstants.domain;
      systemctl = "${config.systemd.package}/bin/systemctl";

      dhcpFailoverScript = pkgs.writeShellScript "dhcp-failover" ''
        set -euo pipefail

        PEER_IP="${cfg.peerIp}"
        PEER_NAME="${cfg.peerName}"
        LOCAL_DHCP_UNIT="dhcp-coredns-kea.service"

        log() {
            echo "$(date '+%Y-%m-%d %H:%M:%S') [DHCP-Failover] $*"
        }

        check_peer_dhcp() {
            if timeout 5 ${pkgs.nmap}/bin/nmap -Pn -sU -p 67 --host-timeout 4s "$PEER_IP" 2>/dev/null | \
               ${pkgs.gnugrep}/bin/grep -Eq '67/udp[[:space:]]+(open|open\|filtered)'; then
                return 0
            else
                return 1
            fi
        }

        check_peer_dns_integration() {
            for domain in ${
              lib.concatStringsSep " " (map (domain: "\"${domain}.${localDomain}\"") cfg.probeDomains)
            }; do
                if ! timeout 5 ${pkgs.dig}/bin/dig @$PEER_IP -p 53 "$domain" +short >/dev/null 2>&1; then
                    log "WARNING: Peer DNS integration issue - $domain not resolving"
                    return 1
                fi
            done
            return 0
        }

        get_local_dhcp_status() {
            if ${systemctl} is-active --quiet "$LOCAL_DHCP_UNIT"; then
                echo "true"
            else
                echo "false"
            fi
        }

        enable_local_dhcp() {
            log "Enabling local DHCP (peer $PEER_NAME is down)"
            ${systemctl} start "$LOCAL_DHCP_UNIT"
        }

        disable_local_dhcp() {
            log "Disabling local DHCP (peer $PEER_NAME is active)"
            ${systemctl} stop "$LOCAL_DHCP_UNIT"
        }

        if check_peer_dhcp && check_peer_dns_integration; then
            current_status=$(get_local_dhcp_status)
            if [ "$current_status" = "true" ]; then
                log "Both DHCP servers running - disabling local (peer wins)"
                disable_local_dhcp
            fi
        else
            current_status=$(get_local_dhcp_status)
            if [ "$current_status" = "false" ]; then
                log "Peer DHCP/DNS issues detected, enabling local DHCP"
                enable_local_dhcp
            fi
        fi
      '';
    in
    {
      options.services.dhcp-coredns.failover = {
        enable = lib.mkEnableOption "DHCP failover monitor";

        peerName = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Peer hostname for DHCP failover monitoring.";
        };

        peerIp = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Peer IP address for DHCP failover monitoring.";
        };

        probeDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Relative domain names that must resolve on the peer.";
        };
      };

      config = lib.mkIf (dhcpCoreDnsEnabled && cfg.enable) {
        systemd.services.dhcp-failover = {
          description = "DHCP Failover Monitor";
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
            User = "root";
            ExecStart = dhcpFailoverScript;
          };
        };

        systemd.timers.dhcp-failover = {
          description = "Run DHCP failover check every 30 seconds";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "30s";
            Unit = "dhcp-failover.service";
          };
        };
      };
    };
}
