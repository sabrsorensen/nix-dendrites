let
  commonMountOpts = [
    "discard=async"
    "noatime"
    "space_cache=v2"
    "ssd"
  ];
  generalMountOpts = commonMountOpts ++ [ "compress=zstd:3" ];
  highChurnMountOpts = commonMountOpts ++ [ "nodatacow" ];
  rootSnapHomeMountOpts = generalMountOpts ++ [ "commit=120" ];
  raidEsp = {
    size = "1G";
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountOptions = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };
  raidRoot = {
    size = "100%";
    content = {
      type = "btrfs";
      extraArgs = [ "-f" ];
      mountOptions = rootSnapHomeMountOpts;
      subvolumes = {
        "@root" = {
          mountpoint = "/";
          mountOptions = rootSnapHomeMountOpts;
        };
        "@snapshots" = {
          mountpoint = "/.snapshots";
          mountOptions = rootSnapHomeMountOpts;
        };
        "@home" = {
          mountpoint = "/home";
          mountOptions = rootSnapHomeMountOpts;
        };
        "@home/sam" = {
          mountpoint = "/home/sam";
          mountOptions = rootSnapHomeMountOpts;
        };
        "@nix" = {
          mountpoint = "/nix";
          mountOptions = generalMountOpts;
        };
        "@opt" = {
          mountpoint = "/opt";
          mountOptions = generalMountOpts;
        };
        "@opt/docker" = {
          mountpoint = "/opt/docker";
          mountOptions = highChurnMountOpts;
        };
        "@opt/data" = {
          mountpoint = "/opt/data";
          mountOptions = highChurnMountOpts;
        };
        "@var" = {
          mountpoint = "/var";
          mountOptions = generalMountOpts;
        };
        "@var/cache" = {
          mountpoint = "/var/cache";
          mountOptions = highChurnMountOpts;
        };
        "@var/lib" = {
          mountpoint = "/var/lib";
          mountOptions = highChurnMountOpts;
        };
        "@var/log" = {
          mountpoint = "/var/log";
          mountOptions = generalMountOpts ++ [ "autodefrag" ];
        };
      };
    };
  };
in
{
  disko.devices.disk = {
    nvme0 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = raidEsp // {
            content = raidEsp.content // {
              mountpoint = "/boot";
            };
          };
          root = raidRoot // {
            content = raidRoot.content // {
              mountpoint = "/.btrfs-root";
            };
          };
        };
      };
    };
    nvme1 = {
      type = "disk";
      device = "/dev/nvme1n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = raidEsp // {
            content = raidEsp.content // {
              mountpoint = "/boot2";
            };
          };
          root.size = "100%";
        };
      };
    };
  };
}
