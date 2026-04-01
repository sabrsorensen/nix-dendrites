bootMode:
{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  isDualBoot = bootMode == "dual";
in
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ]
  ++ (
    if isDualBoot then
      [ ./disk-configs/steamdeck-dualboot-disk-config.nix ]
    else
      [ ./disk-configs/steamdeck-singleboot-disk-config.nix ]
  );

  fileSystems."/boot" = lib.mkIf isDualBoot {
    device = lib.mkDefault "/dev/disk/by-partlabel/esp";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  boot = {
    extraModulePackages = [ ];
    initrd = {
      availableKernelModules = [
        "nvme"
        "sd_mod"
        "sdhci_pci"
        "sr_mod"
        "usbhid"
        "usb_storage"
        "xhci_pci"
      ];
      kernelModules = [ ];
      verbose = false;
    };
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
        configurationLimit = 5;
        consoleMode = "5";
        extraEntries = lib.mkIf isDualBoot {
          "steamos.conf" = ''
            title   SteamOS
            efi     /efi/steamos/steamcl.efi
          '';
        };
      };
    };
    plymouth = {
      enable = true;
      theme = "cybernetic";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "cybernetic" ];
        })
      ];
    };
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.pipewire.wireplumber.extraConfig."10-steamdeck-audio-names" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {
            "device.nick" = "sof-nau8821-max";
          }
        ];
        actions.update-props = {
          "device.product.name" = "Steam Deck Audio";
          "device.description" = "Steam Deck Audio";
        };
      }
    ];
  };
}
