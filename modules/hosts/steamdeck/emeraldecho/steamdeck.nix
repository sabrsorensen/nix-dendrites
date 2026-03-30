{ config, pkgs, lib, ... }:

{
  imports = [
    ./home.nix
    ./firefox/firefox.nix
    ./vscode/vscode.nix
    ];

  home.username = "deck";
  home.homeDirectory = "/home/deck";
  home.packages = with pkgs; [
    bitwarden-desktop
    ferdium
    noson
    p7zip
    rclone
    signal-desktop
    vlc
  ];

  # Script to ensure Steam library btrfs subvolume is mounted in SteamOS
  home.activation.setupSteamLibraryMount = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Check if we're running on SteamOS (has steamos-readonly command)
    if command -v steamos-readonly >/dev/null 2>&1; then
      echo "Checking Steam library mount setup..."

      FSTAB_ENTRY="/dev/disk/by-partlabel/jovian /srv/steam-library btrfs subvol=@steam,compress=zstd,noatime 0 0"
      MOUNT_POINT="/srv/steam-library"

      # Check if fstab entry already exists
      if ! grep -q "/srv/steam-library" /etc/fstab 2>/dev/null; then
        echo "Steam library fstab entry missing, adding it..."

        # Disable read-only mode temporarily
        if sudo steamos-readonly status | grep -q "enabled"; then
          echo "Disabling SteamOS read-only mode..."
          sudo steamos-readonly disable
          READONLY_WAS_ENABLED=1
        else
          READONLY_WAS_ENABLED=0
        fi

        # Create mount point if it doesn't exist
        if [ ! -d "$MOUNT_POINT" ]; then
          echo "Creating mount point: $MOUNT_POINT"
          sudo mkdir -p "$MOUNT_POINT"
        fi

        # Add fstab entry
        echo "Adding fstab entry..."
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab

        # Mount the filesystem
        echo "Mounting Steam library..."
        if sudo mount "$MOUNT_POINT" 2>/dev/null; then
          echo "Successfully mounted Steam library"

          # Set proper ownership
          sudo chown -R deck:deck "$MOUNT_POINT"
          echo "Set ownership to deck:deck"
        else
          echo "Warning: Failed to mount Steam library (partition may not exist yet)"
        fi

        # Re-enable read-only mode if it was enabled
        if [ "$READONLY_WAS_ENABLED" = "1" ]; then
          echo "Re-enabling SteamOS read-only mode..."
          sudo steamos-readonly enable
        fi

        echo "Steam library mount setup complete"
      else
        echo "Steam library fstab entry already exists"

        # Ensure it's mounted if the partition exists
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