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
    # Quadro P520 (Pascal) has no GSP, so the shared module's open = true never
    # probes it - GPU sits unused, Intel handles everything. Tried fixing this
    # (open = false + legacy_580): worked, but the card would intermittently
    # hit Xid 62 (fatal RC error), including hangs on later suspend attempts.
    # Tried nouveau instead: stable, but no Pascal reclocking, and worse - apps
    # seem to prefer the "discrete" GPU it exposes over Intel, so performance
    # was worse than just leaving the card unclaimed. Leaving it unclaimed.
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
