{
  config,
  lib,
  pkgs,
  ...
}:
let
  network = config.systemConstants.network;
  updateNixIndexScript = pkgs.writeShellScriptBin "update-nix-index" ''
    set -eu

    echo "Downloading pre-built nix-index database..."

    resolve_user_home() {
      ${pkgs.glibc.bin}/bin/getent passwd "$1" | ${pkgs.gawk}/bin/awk -F: '{print $6}'
    }

    for user in sam root; do
      user_home="$(resolve_user_home "$user")"
      if [ -z "$user_home" ]; then
        echo "Skipping nix-index update for $user: home directory not found"
        continue
      fi

      cache_dir="$user_home/.cache/nix-index"
      install -d -m 700 -o "$user" -g users "$cache_dir"

      echo "Updating nix-index for user: $user"
      cd "$cache_dir"

      arch="$(${pkgs.coreutils}/bin/uname -m)"
      if [ "$arch" = "aarch64" ]; then
        index_url="https://github.com/Mic92/nix-index-database/releases/latest/download/index-aarch64-linux"
      else
        index_url="https://github.com/Mic92/nix-index-database/releases/latest/download/index-x86_64-linux"
      fi

      echo "Downloading index for $arch to $cache_dir/..."
      if ${pkgs.wget}/bin/wget -O files "$index_url"; then
        ${pkgs.coreutils}/bin/chown "$user:users" files
        echo "nix-index database updated for $user"
      else
        echo "Failed to download nix-index database for $user"
      fi
    done

    echo "You can now use 'nix-locate' to search for packages."
  '';
  piStatusMotdScript = pkgs.writeShellScript "pi-status-motd" ''
    set -eu

    echo "Pi System Status ($(${pkgs.coreutils}/bin/hostname)):"
    echo "Uptime: $(${pkgs.procps}/bin/uptime | ${pkgs.gawk}/bin/awk -F'up ' '{print $2}' | ${pkgs.gawk}/bin/awk -F',' '{print $1}')"
    echo "Load: $(${pkgs.coreutils}/bin/cat /proc/loadavg | ${pkgs.coreutils}/bin/cut -d' ' -f1-3)"
    echo "Memory: $(${pkgs.procps}/bin/free -b | ${pkgs.gawk}/bin/awk '/^Mem:/ {printf "%.1fGi/%.1fGi (%.0f%%)", $3/1024/1024/1024, $2/1024/1024/1024, ($3/$2)*100}')"
    echo "Disk: $(${pkgs.coreutils}/bin/df -h / | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $3 "/" $2 " (" $5 ")"}')"

    temp_found=false
    for zone in /sys/class/thermal/thermal_zone*/temp; do
      if [ -r "$zone" ]; then
        temp_millidegrees="$(${pkgs.coreutils}/bin/cat "$zone" 2>/dev/null || true)"
        if [ -n "$temp_millidegrees" ] && [ "$temp_millidegrees" -gt 0 ]; then
          temp_celsius=$((temp_millidegrees / 1000))
          echo "Temperature: ''${temp_celsius}C"
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

    echo ""

    if ${config.systemd.package}/bin/systemctl list-unit-files blocky.service >/dev/null 2>&1; then
      if ${config.systemd.package}/bin/systemctl is-active --quiet blocky; then
        echo "Blocky: Running"
      else
        echo "Blocky: Not running"
      fi
    fi

    if ${config.systemd.package}/bin/systemctl list-unit-files netbird-management.service >/dev/null 2>&1; then
      if ${config.systemd.package}/bin/systemctl is-active --quiet netbird-management; then
        echo "Netbird Management: Running"
      else
        echo "Netbird Management: Not running"
      fi
    fi

    echo ""
    echo "Run 'piStatus' for updated info or 'piLogs [lines]' for system logs"
    echo ""
  '';
in
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    wget
  ];

  users.users.sam.hashedPasswordFile = config.sops.secrets.hashed_password.path;
  users.users.sam.extraGroups = [ "video" ];
  users.users.root.extraGroups = [ "video" ];

  services.udev.extraRules = ''
    SUBSYSTEM=="vchiq", GROUP="video", MODE="0664"
    SUBSYSTEM=="vcio", GROUP="video", MODE="0664"
    SUBSYSTEM=="vcsm", GROUP="video", MODE="0664"
  '';

  programs.command-not-found.enable = false;
  programs.nix-index.enable = false;
  programs.nix-ld.enable = lib.mkForce false;

  environment.etc."update-nix-index.sh" = {
    source = lib.getExe updateNixIndexScript;
    mode = "0755";
  };

  environment.shellAliases.update-nix-index = lib.getExe updateNixIndexScript;

  systemd.services.update-nix-index = {
    description = "Update nix-index database";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe updateNixIndexScript;
      User = "root";
    };
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  systemd.timers.update-nix-index = {
    description = "Update nix-index database weekly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  users.motd = "";

  environment.etc."update-motd.d/00-pi-status" = {
    source = piStatusMotdScript;
    mode = "0755";
  };

  security.pam.services.sshd.updateWtmp = true;

  networking.defaultGateway = {
    address = network.gateway;
    interface = "end0";
  };

  boot.kernelParams = [ "cma=64M" ];

  security.sudo.extraRules = [
    {
      users = [ "sam" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/vcgencmd *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
