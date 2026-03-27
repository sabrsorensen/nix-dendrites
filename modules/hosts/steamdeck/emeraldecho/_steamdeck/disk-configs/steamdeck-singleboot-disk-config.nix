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
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = [
                  "subvol=@root"
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [
                  "subvol=@home"
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "subvol=@nix"
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@steam" = {
                mountpoint = "/srv/steam-library";
                mountOptions = [
                  "subvol=@steam"
                  "compress=zstd"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
