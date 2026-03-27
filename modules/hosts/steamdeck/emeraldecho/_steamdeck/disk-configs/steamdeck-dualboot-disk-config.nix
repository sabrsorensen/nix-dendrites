{
  disko.devices = {
    # Dual-boot mode assumes SteamOS already owns the GPT.
    # Create a new partition labeled "jovian" before running the installer.
    disk.jovian = {
      type = "disk";
      device = "/dev/disk/by-partlabel/jovian";
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
}
