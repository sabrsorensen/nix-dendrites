{
  config,
  lib,
  bootUuid,
  rootFsUuid,
  rootLuksUuid,
  swapLuksUuid,
  swapUuid,
  ...
}:
{
  boot = {
    extraModulePackages = [ ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
      ];
      kernelModules = [ ];
      luks.devices = {
        "luks-${rootLuksUuid}" = {
          device = lib.mkForce "/dev/disk/by-uuid/${rootLuksUuid}";
          allowDiscards = true;
        };
        "luks-${swapLuksUuid}" = {
          device = lib.mkForce "/dev/disk/by-uuid/${swapLuksUuid}";
          allowDiscards = true;
        };
      };
    };
    kernelModules = [ "kvm-intel" ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/${rootFsUuid}";
      fsType = "ext4";
      options = [
        "noatime"
        "nodiratime"
        "discard"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/${bootUuid}";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };
  swapDevices = [ { device = "/dev/disk/by-uuid/${swapUuid}"; } ];
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia.prime = {
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:108@0:0:0";
    };
  };
  networking.networkmanager.enable = true;
  services.xserver.videoDrivers = [
    "nvidia"
    "intel"
    "modesetting"
  ];
}
