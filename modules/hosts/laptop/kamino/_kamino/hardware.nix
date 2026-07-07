{
  config,
  lib,
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-linux";
  boot = {
    extraModulePackages = [ ];
    loader.efi.canTouchEfiVariables = true;
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
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.buildMachines = [ ];
  nix.distributedBuilds = true;

  services.xserver.videoDrivers = [
    "nvidia"
    "intel"
    "modesetting"
  ];
}
