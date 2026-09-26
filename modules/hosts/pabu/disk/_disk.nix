let
  commonMountOpts = [
    "discard=async"
    "compress=zstd"
    "noatime"
    "space_cache=v2"
    "ssd"
  ];
in
{
  disko.devices.disk.nvme0n1 = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "2048M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          label = "luks";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "nixos" "-f" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = commonMountOpts ++ [ "subvol=root" ];
                };
                "/root-blank" = {
                  mountpoint = "/";
                  mountOptions = commonMountOpts ++ [ "subvol=root-blank" "nodatacow" ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = commonMountOpts ++ [ "subvol=home" ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = commonMountOpts ++ [ "subvol=nix" ];
                };
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = commonMountOpts ++ [ "subvol=persist" ];
                };
                "/log" = {
                  mountpoint = "/var/log";
                  mountOptions = commonMountOpts ++ [ "subvol=log" ];
                };
                "/lib" = {
                  mountpoint = "/var/lib";
                  mountOptions = commonMountOpts ++ [ "subvol=lib" ];
                };
                "/persist/swap" = {
                  mountpoint = "/persist/swap";
                  mountOptions = ["subvol=swap" "noatime" "nodatacow" "compress=no"];
                  swap.swapfile.size = "20G";
                };
              };
            };
          };
        };
      };
    };
  };
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
  fileSystems."/var/lib".neededForBoot = true;
}
