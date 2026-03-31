{
  flake.modules.nixos.dhcp-failover =
    {
      config,
      pkgs,
      ...
    }:
    let
      readBuildValue =
        path:
        builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
      localDomain = readBuildValue "domain.txt";
      networkConfig = config.systemConstants.network;
      peerConfig =
        if config.networking.hostName == "Naboo" then
          {
            ip = networkConfig.nevarro;
            name = "Nevarro";
          }
        else
          {
            ip = networkConfig.naboo;
            name = "Naboo";
          };

      dhcpFailoverScript = pkgs.writeShellScript "dhcp-failover" ''
        set -euo pipefail

        PEER_IP="${peerConfig.ip}"
        PEER_NAME="${peerConfig.name}"
        AGH_CONFIG="/var/lib/AdGuardHome/AdGuardHome.yaml"

        log() {
            echo "$(date '+%Y-%m-%d %H:%M:%S') [DHCP-Failover] $*"
        }

        check_peer_dhcp() {
            if timeout 5 ${pkgs.curl}/bin/curl -sf \
               "http://$PEER_IP:3003/control/dhcp/status" 2>/dev/null | \
               ${pkgs.jq}/bin/jq -e '.enabled == true' >/dev/null 2>&1; then
                return 0
            else
                return 1
            fi
        }

        check_peer_dns_integration() {
            for domain in "naboo.${localDomain}" "nevarro.${localDomain}" "atlasuponraiden.${localDomain}"; do
                if ! timeout 5 ${pkgs.dig}/bin/dig @$PEER_IP -p 53 "$domain" +short >/dev/null 2>&1; then
                    log "WARNING: Peer DNS integration issue - $domain not resolving"
                    return 1
                fi
            done
            return 0
        }

        get_local_dhcp_status() {
            if [ -f "$AGH_CONFIG" ]; then
                ${pkgs.yq-go}/bin/yq eval '.dhcp.enabled // false' "$AGH_CONFIG" 2>/dev/null || echo "false"
            else
                echo "false"
            fi
        }

        enable_local_dhcp() {
            log "Enabling local DHCP (peer $PEER_NAME is down)"
            ${pkgs.yq-go}/bin/yq eval '.dhcp.enabled = true' -i "$AGH_CONFIG"
            systemctl reload adguardhome || true
        }

        disable_local_dhcp() {
            log "Disabling local DHCP (peer $PEER_NAME is active)"
            ${pkgs.yq-go}/bin/yq eval '.dhcp.enabled = false' -i "$AGH_CONFIG"
            systemctl reload adguardhome || true
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
      systemd.services.dhcp-failover = {
        description = "DHCP Failover Monitor";
        after = [
          "network.target"
          "adguardhome.service"
        ];
        wants = [ "adguardhome.service" ];
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
}
