{
  config,
  lib,
  ...
}:
{
  flake.modules.nixos.zaphodbeeblebrox = {
    nixpkgs.hostPlatform = "x86_64-linux";
    # Hardware modules needed for boot
    boot = {
      initrd = {
        availableKernelModules = [
          # Detected by nixos-generate-config
          "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod"
          # LUKS
          "dm-crypt"
          # LVM
          "dm-mod"
        ];
        includeDefaultModules = true;
        kernelModules = [ "dm-crypt" "nvme" ];
        # Ensure systemd in initrd for better device handling
        systemd.enable = true;
        verbose = false;
      };
      kernelModules = [ "kvm-intel" ];
      loader = {
        efi = {
          canTouchEfiVariables = true;
        };
      };
    };
    hardware = {
      cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      nvidia = {
        prime = {
          intelBusId = "PCI:0@0:2:0";
          nvidiaBusId = "PCI:1@0:0:0";
        };
      };
    };
    # Zenbook Duo specific - dual screen support
    services.xserver.xrandrHeads = [
      # Configure when you know the screen setup
      # "DP-1" "eDP-1" etc.
    ];
  };
}
