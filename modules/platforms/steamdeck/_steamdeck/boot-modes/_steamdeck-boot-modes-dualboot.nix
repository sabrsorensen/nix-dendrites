{ lib, ... }:
let
  btrfs = subvol: {
    device = "/dev/disk/by-partlabel/jovian";
    fsType = "btrfs";
    options = [
      "subvol=${subvol}"
      "compress=zstd"
      "noatime"
    ];
  };
in
{
  boot.loader.systemd-boot.extraEntries = {
    "steamos.conf" = "title SteamOS\nefi /efi/steamos/steamcl.efi\n";
  };

  fileSystems = {
    "/" = btrfs "@root";
    "/boot" = {
      device = "/dev/disk/by-partlabel/esp";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
    "/home" = btrfs "@home";
    "/nix" = btrfs "@nix";
    "/srv/steam-library" = btrfs "@steam";
  };
}
