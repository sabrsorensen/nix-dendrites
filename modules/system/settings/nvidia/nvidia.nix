{
  config,
  lib,
  ...
}:
{
  flake.modules.nixos.nvidia = {
    # Hardware modules needed for boot
    boot = {
      initrd = {
        kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      };
      kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    };
    hardware = {
      cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.production;
        modesetting.enable = true;
        powerManagement = {
          enable = false;
          finegrained = false;
        };
        open = true;
        nvidiaSettings = true;
        prime = {
          sync.enable = true;
          #intelBusId = "PCI:0@0:2:0"; Device specific
          #nvidiaBusId = "PCI:1@0:0:0"; Device specific
        };
      };
    };
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "nvidia-persistenced"
      "nvidia-settings"
      "nvidia-x11"
    ];
  };
}