{
  lib,
  pkgs,
  ...
}:
let
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
in
{
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
}
