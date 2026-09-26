{
  config,
  lib,
  ...
}:
{
  boot = {
    kernelParams = [ "video=1920x1080@60" ];
    extraModulePackages = [ ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        # The 1 GB ESP holds ~200 MB per distinct initrd; without a limit it filled up.
        configurationLimit = 6;
      };
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    #nvidia.prime = {
    #  intelBusId = "PCI:0@0:2:0";
    #  nvidiaBusId = "PCI:108@0:0:0";
    #};
  };
  networking.networkmanager.enable = true;
}
