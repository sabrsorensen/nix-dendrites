{
  config,
  lib,
  pkgs,
  cfg,
  tokenFile,
  ...
}:
let
  # Polls `systemctl --failed` rather than adding a global OnFailure= drop-in:
  # it also catches units that failed before this ran (early boot), and
  # filters transient podman healthcheck units in one place.
  alert = pkgs.writeShellApplication {
    name = "unit-failure-alert";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.systemd
    ];
    text = ''
      host=${lib.escapeShellArg config.my.host.name}
      url=${lib.escapeShellArg cfg.gotifyUrl}
      # The RuntimeDirectory is wiped at boot, so anything still failed after a
      # reboot is reported again.
      state="''${RUNTIME_DIRECTORY:?}/notified"
      touch "$state"

      send() {
        curl -fsS --max-time 15 -o /dev/null \
          -H "X-Gotify-Key: ''${GOTIFY_TOKEN:?}" \
          --form-string "title=$1" \
          --form-string "message=$2" \
          --form-string "priority=$3" \
          "$url/message"
      }

      # Podman healthcheck runs are transient <container id>-<hex>.service
      # units; failed ones are swept by podman-healthcheck-reset-failed.
      current=$(systemctl list-units --state=failed --plain --no-legend \
        | awk '{ print $1 }' \
        | grep -Ev '^[0-9a-f]{64}-[0-9a-f]+\.(service|timer)$' \
        | sort -u || true)

      next=$(comm -12 "$state" <(printf '%s\n' "$current" | sed '/^$/d'))
      while IFS= read -r unit; do
        [[ -n "$unit" ]] || continue
        logs=$(journalctl -u "$unit" -b -n 15 -o cat --no-pager 2>&1 | tail -c 3000 || true)
        if send "$host: $unit failed" "$logs" 8; then
          next=$(printf '%s\n%s\n' "$next" "$unit")
        else
          echo "could not notify Gotify about $unit; will retry" >&2
        fi
      done < <(comm -13 "$state" <(printf '%s\n' "$current" | sed '/^$/d'))

      while IFS= read -r unit; do
        [[ -n "$unit" ]] || continue
        send "$host: $unit recovered" "$unit is no longer failed." 3 \
          || echo "could not notify Gotify that $unit recovered" >&2
      done < <(comm -23 "$state" <(printf '%s\n' "$current" | sed '/^$/d'))

      printf '%s\n' "$next" | sed '/^$/d' | sort -u > "$state"
    '';
  };
in
{
  assertions = [
    {
      assertion = cfg.gotifyUrl != null;
      message = "my.unitFailureAlerts.gotifyUrl must be set on hosts that don't run Gotify.";
    }
  ];
  sops.secrets.unit-failure-alerts_env = {
    mode = "0400";
    format = "dotenv";
    sopsFile = tokenFile;
    key = "";
  };
  systemd.services.unit-failure-alert = {
    description = "Report failed systemd units to Gotify";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe alert;
      EnvironmentFile = config.sops.secrets.unit-failure-alerts_env.path;
      RuntimeDirectory = "unit-failure-alert";
      RuntimeDirectoryPreserve = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };
  systemd.timers.unit-failure-alert = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = cfg.interval;
      OnUnitActiveSec = cfg.interval;
    };
  };
}
