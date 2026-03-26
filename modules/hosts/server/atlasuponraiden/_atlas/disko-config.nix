let
  rootDevices = [ "/dev/nvme0n1p2" "/dev/nvme1n1p2" ];
  commonMountOpts = [ "discard=async" "noatime" "space_cache=v2" "ssd" ];
  generalMountOpts = commonMountOpts ++ [ "compress=zstd:3" ];
  highChurnMountOpts = commonMountOpts ++ [ "nodatacow" ];
  rootSnapHomeMountOpts = generalMountOpts ++ [ "commit=120" ];
  raidEsp = {
    size = "1G";
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountOptions = [ "fmask=0022" "dmask=0022" ];
    };
  };
  raidRoot = {
    size = "100%";
    content = {
      type = "btrfs";
      extraArgs = [ "-f" ]; # Override existing partition
      mountOptions = rootSnapHomeMountOpts;
      subvolumes = {
        "@root" = {
          mountOptions = rootSnapHomeMountOpts;
          mountpoint = "/";
        };
        "@snapshots" = {
          mountOptions = rootSnapHomeMountOpts;
          mountpoint = "/.snapshots";
        };
        "@home" = {
          mountOptions = rootSnapHomeMountOpts;
          mountpoint = "/home";
        };
        "@home/sam" = {
          mountOptions = rootSnapHomeMountOpts;
          mountpoint = "/home/sam";
        };
        "@nix" = {
          mountOptions = generalMountOpts;
          mountpoint = "/nix";
        };
        "@opt" = {
          mountOptions = generalMountOpts;
          mountpoint = "/opt";
        };
        "@opt/docker" = {
          mountOptions = highChurnMountOpts;
          mountpoint = "/opt/docker";
        };
        "@opt/data" = {
          mountOptions = highChurnMountOpts;
          mountpoint = "/opt/data";
        };
        "@var" = {
          mountOptions = generalMountOpts;
          mountpoint = "/var";
        };
        "@var/cache" = {
          mountOptions = highChurnMountOpts;
          mountpoint = "/var/cache";
        };
        "@var/lib" = {
          mountOptions = highChurnMountOpts;
          mountpoint = "/var/lib";
        };
        "@var/log" = {
          mountOptions = generalMountOpts ++ [ "autodefrag" ];
          mountpoint = "/var/log";
        };
      };
    };
  };
in
{
  disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = raidEsp // { content = raidEsp.content // { mountpoint = "/boot"; }; };
            root = raidRoot // { content = raidRoot.content // { mountpoint = "/.btrfs-root"; }; };
          };
        };
      };

      nvme1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = raidEsp // { content = raidEsp.content // { mountpoint = "/boot2"; }; };
            #root = raidRoot // { content = raidRoot.content // { mountpoint = "/.btrfs-root2"; }; };
            root = { size = "100%"; };
          };
        };
      };
    };
  };
}