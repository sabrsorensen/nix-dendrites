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
  disko.devices.disk.main = {
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
          label = "disk-main-luks";
          content = {
            type = "luks";
            name = "crypted";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = commonMountOpts;
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = commonMountOpts;
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = commonMountOpts;
                };
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = commonMountOpts;
                };
                "/log" = {
                  mountpoint = "/var/log";
                  mountOptions = commonMountOpts;
                };
              };
            };
          };
        };
        swap = {
          size = "20G";
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true;
          };
        };
      };
    };
  };
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
}
