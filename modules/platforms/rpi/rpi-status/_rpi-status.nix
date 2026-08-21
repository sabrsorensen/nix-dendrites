{ config, pkgs, ... }:
let
  status = pkgs.writeShellScript "pi-status-motd" ''
    set -eu
    echo "Pi System Status ($(${pkgs.coreutils}/bin/hostname)):"
    echo "Uptime: $(${pkgs.procps}/bin/uptime | ${pkgs.gawk}/bin/awk -F'up ' '{print $2}' | ${pkgs.gawk}/bin/awk -F',' '{print $1}')"
    echo "Load: $(${pkgs.coreutils}/bin/cat /proc/loadavg | ${pkgs.coreutils}/bin/cut -d' ' -f1-3)"
    echo "Memory: $(${pkgs.procps}/bin/free -b | ${pkgs.gawk}/bin/awk '/^Mem:/ {printf \"%.1fGi/%.1fGi (%.0f%%)\", $3/1024/1024/1024, $2/1024/1024/1024, ($3/$2)*100}')"
    echo "Disk: $(${pkgs.coreutils}/bin/df -h / | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $3 \"/\" $2 \" (\" $5 \")\"}')"

    temp_found=false
    for zone in /sys/class/thermal/thermal_zone*/temp; do
      if [ -r "$zone" ]; then
        temp="$(${pkgs.coreutils}/bin/cat "$zone" 2>/dev/null || true)"
        if [ -n "$temp" ] && [ "$temp" -gt 0 ]; then
          echo "Temperature: $((temp / 1000))C"
          temp_found=true
          break
        fi
      fi
    done

    if [ "$temp_found" = "false" ] && [ -x ${pkgs.libraspberrypi}/bin/vcgencmd ]; then
      temp="$(${pkgs.sudo}/bin/sudo ${pkgs.libraspberrypi}/bin/vcgencmd measure_temp 2>/dev/null | ${pkgs.coreutils}/bin/cut -d= -f2)"
      if [ -n "$temp" ]; then
        echo "Temperature: $temp"
        temp_found=true
      fi
    fi

    if [ "$temp_found" = "false" ]; then
      echo "Temperature: N/A"
    fi

    if [ -x ${pkgs.libraspberrypi}/bin/vcgencmd ]; then
      throttled_raw="$(${pkgs.sudo}/bin/sudo ${pkgs.libraspberrypi}/bin/vcgencmd get_throttled 2>/dev/null | ${pkgs.coreutils}/bin/cut -d= -f2)"
      if [ -n "$throttled_raw" ]; then
        throttled_val=$((throttled_raw))
        flags=""
        [ $((throttled_val & 0x1)) -ne 0 ] && flags="$flags undervoltage-now"
        [ $((throttled_val & 0x2)) -ne 0 ] && flags="$flags freq-capped-now"
        [ $((throttled_val & 0x4)) -ne 0 ] && flags="$flags throttled-now"
        [ $((throttled_val & 0x8)) -ne 0 ] && flags="$flags soft-temp-limit-now"
        [ $((throttled_val & 0x10000)) -ne 0 ] && flags="$flags undervoltage-occurred"
        [ $((throttled_val & 0x20000)) -ne 0 ] && flags="$flags freq-capped-occurred"
        [ $((throttled_val & 0x40000)) -ne 0 ] && flags="$flags throttled-occurred"
        [ $((throttled_val & 0x80000)) -ne 0 ] && flags="$flags soft-temp-limit-occurred"
        if [ -z "$flags" ]; then
          echo "Power: OK"
        else
          echo "Power: WARNING -$flags"
        fi
      fi
    fi

    echo
    if ${config.systemd.package}/bin/systemctl list-unit-files blocky.service >/dev/null 2>&1; then
      ${config.systemd.package}/bin/systemctl is-active --quiet blocky && echo "Blocky: Running" || echo "Blocky: Not running"
    fi

    if ${config.systemd.package}/bin/systemctl list-unit-files netbird-management.service >/dev/null 2>&1; then
      ${config.systemd.package}/bin/systemctl is-active --quiet netbird-management && echo "Netbird Management: Running" || echo "Netbird Management: Not running"
    fi

    echo
    echo "Run 'piStatus' for updated info or 'piLogs [lines]' for system logs"
    echo
  '';
in
{
  users.motd = "";
  environment.etc."update-motd.d/00-pi-status" = {
    source = status;
    mode = "0755";
  };
}
