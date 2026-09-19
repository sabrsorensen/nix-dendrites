{ lib, ... }:
let
  steamdeckSubvolumes = import ./_subvolumes.nix;
  btrfs = subvol: {
    device = "/dev/disk/by-partlabel/jovian";
    fsType = "btrfs";
    options = [ "subvol=${subvol}" ] ++ steamdeckSubvolumes.mountOptions;
  };
in
{
  boot.loader.systemd-boot.extraEntries = {
    "steamos.conf" = "title SteamOS\nefi /efi/steamos/steamcl.efi\n";
  };

  fileSystems =
    lib.mapAttrs' (
      subvol: mountpoint: lib.nameValuePair mountpoint (btrfs subvol)
    ) steamdeckSubvolumes.mountpoints
    // {
      "/boot" = {
        device = "/dev/disk/by-partlabel/esp";
        fsType = "vfat";
        options = [ "umask=0077" ];
      };
    };
}
