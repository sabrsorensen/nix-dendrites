{
  config,
  lib,
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-linux";
  boot = {
    extraModulePackages = [ ];
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      prime = {
        intelBusId = "PCI:0@0:2:0";
        nvidiaBusId = "PCI:108@0:0:0";
      };
    };
  }

  services.xserver.videoDrivers = [
    "nvidia"
    "intel"
    "modesetting"
  ];
}
