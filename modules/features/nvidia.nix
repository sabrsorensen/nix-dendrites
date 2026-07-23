{ ... }:
{
  flake.modules.nixos.nvidia =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.nvidia {
      boot = {
        initrd.kernelModules = [
          "nvidia"
          "nvidia_drm"
          "nvidia_modeset"
          "nvidia_uvm"
        ];
        kernelModules = [
          "nvidia"
          "nvidia_drm"
          "nvidia_modeset"
          "nvidia_uvm"
        ];
        kernelParams = [ "nvidia-drm.modeset=1" ];
      };

      hardware = {
        cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        graphics = {
          enable = true;
          enable32Bit = true;
        };
        nvidia = {
          modesetting.enable = true;
          powerManagement = {
            enable = false;
            finegrained = false;
          };
          open = true;
          nvidiaSettings = true;
          prime.sync.enable = true;
        };
      };

      my.unfreePackageNames = [
        "nvidia-persistenced"
        "nvidia-settings"
        "nvidia-x11"
      ];
    };
}
