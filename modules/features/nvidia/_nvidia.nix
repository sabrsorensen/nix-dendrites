{ lib, ... }:
{
  # modesetting.enable already sets nvidia-drm modeset=1 (and fbdev=1), and
  # udev loads the modules by modalias. They're deliberately not in the initrd:
  # they add a lot of initrd size and early KMS on the dGPU buys nothing on
  # hybrid laptops whose panel is wired to the iGPU.
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = lib.mkDefault false;
      open = true;
      nvidiaSettings = true;
      # PRIME mode (offload/sync/reverseSync), bus IDs and fine-grained power
      # management are device-specific: set them in the host's hardware file.
    };
  };
  # mkBefore keeps nvidia ahead of the desktop feature's intel/modesetting.
  services.xserver.videoDrivers = lib.mkBefore [ "nvidia" ];
  my.unfreePackageNames = [
    "nvidia-persistenced"
    "nvidia-settings"
    "nvidia-x11"
  ];
}
