{
  config,
  pkgs,
  ...
}:
let
  network = config.systemConstants.network;
in
{
  imports = [ ./hardware.nix ];

  nix.settings = {
    extra-substituters = [ "https://cache.thalheim.io" ];
    extra-trusted-public-keys = [ "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=" ];
  };

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

  environment.etc."update-nix-index.sh" = {
    text = ''
      #!/bin/sh
      echo "📦 Downloading pre-built nix-index database..."

      for user in sam root; do
        USER_HOME=$(eval echo "~$user")
        mkdir -p "$USER_HOME/.cache/nix-index"

        echo "Updating nix-index for user: $user"
        cd "$USER_HOME/.cache/nix-index"

        ARCH=$(uname -m)
        if [ "$ARCH" = "aarch64" ]; then
          INDEX_URL="https://github.com/Mic92/nix-index-database/releases/latest/download/index-aarch64-linux"
        else
          INDEX_URL="https://github.com/Mic92/nix-index-database/releases/latest/download/index-x86_64-linux"
        fi

        echo "Downloading index for $ARCH to $USER_HOME/.cache/nix-index/..."
        if wget -O files "$INDEX_URL"; then
          chown -R "$user:users" "$USER_HOME/.cache/nix-index"
          echo "✅ nix-index database updated for $user!"
        else
          echo "❌ Failed to download nix-index database for $user"
        fi
      done

      echo "You can now use 'nix-locate' to search for packages."
    '';
    mode = "0755";
  };

  environment.shellAliases.update-nix-index = "/etc/update-nix-index.sh";

  systemd.services.update-nix-index = {
    description = "Update nix-index database";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/update-nix-index.sh";
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
    text = ''
      #!/bin/sh
      echo "🥧 Pi System Status ($(hostname)):"
      echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
      echo "Load: $(cat /proc/loadavg | cut -d' ' -f1-3)"
      echo "Memory: $(free -b | awk '/^Mem:/ {printf "%.1fGi/%.1fGi (%.0f%%)", $3/1024/1024/1024, $2/1024/1024/1024, ($3/$2)*100}')"
      echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"

      TEMP_FOUND=false
      for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [ -r "$zone" ]; then
          TEMP_MILLIDEGREES=$(cat "$zone" 2>/dev/null)
          if [ -n "$TEMP_MILLIDEGREES" ] && [ "$TEMP_MILLIDEGREES" -gt 0 ]; then
            TEMP_CELSIUS=$((TEMP_MILLIDEGREES / 1000))
            echo "Temperature: $${TEMP_CELSIUS}°C"
            TEMP_FOUND=true
            break
          fi
        fi
      done

      if [ "$TEMP_FOUND" = "false" ] && command -v vcgencmd >/dev/null 2>&1; then
        TEMP=$(sudo vcgencmd measure_temp 2>/dev/null | cut -d= -f2)
        if [ -n "$TEMP" ]; then
          echo "Temperature: $TEMP"
          TEMP_FOUND=true
        fi
      fi

      if [ "$TEMP_FOUND" = "false" ]; then
        echo "Temperature: N/A"
      fi

      echo ""

      if systemctl list-unit-files adguardhome.service >/dev/null 2>&1; then
        if systemctl is-active --quiet adguardhome; then
          echo "AdGuard: ✅ Running"
        else
          echo "AdGuard: ❌ Not running"
        fi
      fi

      if systemctl list-unit-files netbird-management.service >/dev/null 2>&1; then
        if systemctl is-active --quiet netbird-management; then
          echo "Netbird Management: ✅ Running"
        else
          echo "Netbird Management: ❌ Not running"
        fi
      fi

      echo ""
      echo "💡 Run 'piStatus' for updated info or 'piLogs [lines]' for system logs"
      echo ""
    '';
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
