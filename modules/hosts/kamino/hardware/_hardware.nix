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
    nvidia = {
      # Quadro P520 (Pascal) has no GSP, so the open kernel module can't drive it,
      # and Pascal support ended after the 580 driver branch.
      open = lib.mkForce false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      prime = {
        intelBusId = "PCI:0@0:2:0";
        nvidiaBusId = "PCI:108@0:0:0";
      };
    };
  };
  networking.networkmanager.enable = true;
  services.xserver.videoDrivers = [
    "nvidia"
    "intel"
    "modesetting"
  ];
}
