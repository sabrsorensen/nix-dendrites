{ lib, ... }:
{
  home = {
    username = "deck";
    homeDirectory = "/home/deck";
    stateVersion = "26.05";
  };
  home.activation.setupSteamLibraryMount = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="/usr/bin:/bin:$PATH"

    FSTAB_ENTRY="/dev/disk/by-partlabel/jovian /srv/steam-library btrfs subvol=@steam,compress=zstd,noatime 0 0"
    MOUNT_POINT="/srv/steam-library"
    STEAMOS_READONLY_BIN=""

    if [ -x /usr/bin/steamos-readonly ]; then
      STEAMOS_READONLY_BIN=/usr/bin/steamos-readonly
    elif [ -x /bin/steamos-readonly ]; then
      STEAMOS_READONLY_BIN=/bin/steamos-readonly
    fi

    ensure_mount_point() {
      if [ ! -d "$MOUNT_POINT" ]; then
        echo "Creating mount point: $MOUNT_POINT"
        sudo mkdir -p "$MOUNT_POINT"
      fi
    }

    ensure_mount_owner() {
      mismatched_path="$(sudo find "$MOUNT_POINT" -xdev \( ! -user deck -o ! -group deck \) -print -quit 2>/dev/null || true)"
      if [ -n "$mismatched_path" ]; then
        echo "Updating Steam library ownership to deck:deck where needed"
        sudo find "$MOUNT_POINT" -xdev \( ! -user deck -o ! -group deck \) -exec chown deck:deck '{}' +
      fi
    }

    mount_steam_library() {
      ensure_mount_point
      if sudo mount "$MOUNT_POINT" 2>/dev/null; then
        echo "Successfully mounted Steam library"
        ensure_mount_owner
        return 0
      fi

      echo "Warning: Failed to mount Steam library (partition may not exist yet)"
      return 1
    }

    with_steamos_readwrite() {
      if [ -z "$STEAMOS_READONLY_BIN" ]; then
        "$@"
        return $?
      fi

      readonly_was_enabled=0
      if sudo "$STEAMOS_READONLY_BIN" status | grep -q "enabled"; then
        echo "Disabling SteamOS read-only mode..."
        sudo "$STEAMOS_READONLY_BIN" disable
        readonly_was_enabled=1
      fi

      "$@"
      status=$?
      if [ "$readonly_was_enabled" = "1" ]; then
        echo "Re-enabling SteamOS read-only mode..."
        sudo "$STEAMOS_READONLY_BIN" enable
      fi
      return "$status"
    }

    add_fstab_entry() {
      ensure_mount_point
      echo "Adding Steam library fstab entry..."
      echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
    }

    if [ -n "$STEAMOS_READONLY_BIN" ] || grep -q '^ID=steamos$' /etc/os-release 2>/dev/null; then
      if ! grep -q "/srv/steam-library" /etc/fstab 2>/dev/null; then
        with_steamos_readwrite add_fstab_entry
      fi
      if [ -e "/dev/disk/by-partlabel/jovian" ] && ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        mount_steam_library
      elif mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        ensure_mount_owner
      fi
    else
      echo "Not running on SteamOS, skipping Steam library mount setup"
    fi
  '';
}
