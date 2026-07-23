{ ... }:
{
  flake.modules.nixos.hardware-emeraldecho =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dual = builtins.elem "steamdeck-dualboot" config.my.host.tags;
    in
    lib.mkIf (config.my.host.name == "EmeraldEcho") {
      boot = {
        initrd.availableKernelModules = [
          "nvme"
          "sd_mod"
          "sdhci_pci"
          "sr_mod"
          "usbhid"
          "usb_storage"
          "xhci_pci"
        ];
        kernelModules = [ "kvm-amd" ];
        consoleLogLevel = 3;
        kernelParams = [
          "quiet"
          "udev.log_level=3"
          "systemd.show_status=auto"
        ];
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot = {
            enable = true;
            configurationLimit = 2;
            consoleMode = "5";
            extraEntries = lib.mkIf dual {
              "steamos.conf" = ''
                title SteamOS
                efi /efi/steamos/steamcl.efi
              '';
            };
          };
        };
        plymouth = {
          enable = true;
          theme = "cybernetic";
          themePackages = [
            (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "cybernetic" ]; })
          ];
        };
      };

      fileSystems = lib.mkIf dual {
        "/" = {
          device = "/dev/disk/by-partlabel/jovian";
          fsType = "btrfs";
          options = [
            "subvol=@root"
            "compress=zstd"
            "noatime"
          ];
        };
        "/boot" = {
          device = "/dev/disk/by-partlabel/esp";
          fsType = "vfat";
          options = [ "umask=0077" ];
        };
        "/home" = {
          device = "/dev/disk/by-partlabel/jovian";
          fsType = "btrfs";
          options = [
            "subvol=@home"
            "compress=zstd"
            "noatime"
          ];
        };
        "/nix" = {
          device = "/dev/disk/by-partlabel/jovian";
          fsType = "btrfs";
          options = [
            "subvol=@nix"
            "compress=zstd"
            "noatime"
          ];
        };
        "/srv/steam-library" = {
          device = "/dev/disk/by-partlabel/jovian";
          fsType = "btrfs";
          options = [
            "subvol=@steam"
            "compress=zstd"
            "noatime"
          ];
        };
      };

      hardware = {
        cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        enableRedistributableFirmware = true;
        graphics = {
          enable = true;
          enable32Bit = true;
        };
      };
      networking.networkmanager.enable = true;
      services.pipewire.wireplumber.extraConfig."10-steamdeck-audio-names"."monitor.alsa.rules" = [
        {
          matches = [ { "device.nick" = "sof-nau8821-max"; } ];
          actions.update-props = {
            "device.product.name" = "Steam Deck Audio";
            "device.description" = "Steam Deck Audio";
          };
        }
      ];
    };
}
