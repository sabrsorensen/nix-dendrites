{ config }:
{
  # Permit DNS on the default and additional Podman bridge networks.
  networking.firewall.interfaces =
    let
      matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
    in
    {
      "${matchAll}".allowedUDPPorts = [ 53 ];
    };
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";

  # Podman runs each container's healthcheck as a transient systemd unit
  # named "<container-id>-<hex>.service" (…-startup-<hex> for startup
  # probes).  A probe that fires while its container is briefly down — for
  # instance during the `podman-<name>.service` restarts that every
  # `nixos-rebuild switch` performs — leaves that transient unit in
  # "failed" state, and Podman then orphans it (the next probe is created
  # with a fresh random suffix).  `switch-to-configuration` enumerates
  # *every* failed unit on the system after activation and exits 4 when
  # any remain, so these orphans turn an otherwise-clean activation into a
  # reported deploy failure.  Sweep them on a short interval so they clear
  # well within switch-to-configuration's post-activation settle window.
  systemd.services.podman-healthcheck-reset-failed = {
    description = "Reset orphaned Podman healthcheck transient units";
    serviceConfig.Type = "oneshot";
    script = ''
      set -uo pipefail
      mapfile -t stale < <(
        systemctl list-units --all --plain --no-legend --state=failed \
          | awk '{ print $1 }' \
          | grep -E '^[0-9a-f]{64}(-startup)?-[0-9a-f]+\.(service|timer)$' || true
      )
      if [ "''${#stale[@]}" -gt 0 ]; then
        systemctl reset-failed "''${stale[@]}"
      fi
    '';
  };

  systemd.timers.podman-healthcheck-reset-failed = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "15s";
      AccuracySec = "1s";
      Unit = "podman-healthcheck-reset-failed.service";
    };
  };
}
