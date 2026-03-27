{
  config,
  lib,
  ...
}:
{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  services.xserver.videoDrivers = [
    "nvidia"
    "intel"
    "modesetting"
  ];

  hardware.nvidia = {
    prime = {
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:108@0:0:0";
    };
  };
}
