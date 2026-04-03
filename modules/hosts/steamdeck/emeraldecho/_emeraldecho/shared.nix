{
  inputs,
  ...
}:
let
  root = ../../../..;
in
{
  inherit root;

  steamUser = "sam";
  installerUser = "jovian";

  steamUserExtraGroups = [
    "wheel"
    "networkmanager"
    "audio"
    "video"
  ];

  steamUserAuthorizedKeys = [
    "${inputs.nix-secrets}/ssh-keys/atlas_emeraldecho.pub"
    "${inputs.nix-secrets}/ssh-keys/kamino_emeraldecho.pub"
    "${inputs.nix-secrets}/ssh-keys/zaphod_emeraldecho.pub"
    "${inputs.nix-secrets}/ssh-keys/wsl_emeraldecho.pub"
  ];

  nixRemoteAuthorizedKeys = [
    "${inputs.nix-secrets}/ssh-keys/atlas_emeraldecho_nix.pub"
    "${inputs.nix-secrets}/ssh-keys/zaphod_emeraldecho_nix.pub"
  ];

  deckSystemPackages = [
    "bitwarden-desktop"
    "deskflow"
    "noson"
    "rclone"
    "signal-desktop"
    "vlc"
  ];

  deckSteamHomePackages = [
    "bitwarden-desktop"
    "ferdium"
    "noson"
    "p7zip"
    "rclone"
    "signal-desktop"
    "vlc"
  ];

  deckSteamOsConfig = {
    networking.hostName = "EmeraldEcho";
  };

  setupSteamLibraryMount = ''
    if command -v steamos-readonly >/dev/null 2>&1; then
      echo "Checking Steam library mount setup..."

      FSTAB_ENTRY="/dev/disk/by-partlabel/jovian /srv/steam-library btrfs subvol=@steam,compress=zstd,noatime 0 0"
      MOUNT_POINT="/srv/steam-library"

      if ! grep -q "/srv/steam-library" /etc/fstab 2>/dev/null; then
        echo "Steam library fstab entry missing, adding it..."

        if sudo steamos-readonly status | grep -q "enabled"; then
          echo "Disabling SteamOS read-only mode..."
          sudo steamos-readonly disable
          READONLY_WAS_ENABLED=1
        else
          READONLY_WAS_ENABLED=0
        fi

        if [ ! -d "$MOUNT_POINT" ]; then
          echo "Creating mount point: $MOUNT_POINT"
          sudo mkdir -p "$MOUNT_POINT"
        fi

        echo "Adding fstab entry..."
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab

        echo "Mounting Steam library..."
        if sudo mount "$MOUNT_POINT" 2>/dev/null; then
          echo "Successfully mounted Steam library"
          sudo chown -R deck:deck "$MOUNT_POINT"
          echo "Set ownership to deck:deck"
        else
          echo "Warning: Failed to mount Steam library (partition may not exist yet)"
        fi

        if [ "$READONLY_WAS_ENABLED" = "1" ]; then
          echo "Re-enabling SteamOS read-only mode..."
          sudo steamos-readonly enable
        fi

        echo "Steam library mount setup complete"
      else
        echo "Steam library fstab entry already exists"

        if [ -e "/dev/disk/by-partlabel/jovian" ] && ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
          echo "Mounting existing Steam library..."
          sudo mkdir -p "$MOUNT_POINT"
          if sudo mount "$MOUNT_POINT" 2>/dev/null; then
            sudo chown -R deck:deck "$MOUNT_POINT"
            echo "Successfully mounted existing Steam library"
          fi
        fi
      fi
    else
      echo "Not running on SteamOS, skipping Steam library mount setup"
    fi
  '';
}
