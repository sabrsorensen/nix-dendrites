{ lib, ... }:
let
  steamdeckSubvolumes = import ./_subvolumes.nix;
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = lib.mapAttrs (subvol: mountpoint: {
              inherit mountpoint;
              mountOptions = [ "subvol=${subvol}" ] ++ steamdeckSubvolumes.mountOptions;
            }) steamdeckSubvolumes.mountpoints;
          };
        };
      };
    };
  };
}
