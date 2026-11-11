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
    # Quadro P520 (Pascal, render-only Optimus card) is unusable, so
    # features.nvidia is off and the default nouveau driver binds it instead.
    # - The open nvidia module can't probe it: Pascal has no GSP.
    # - open = false + legacy_580 (the last Pascal branch) loaded, but hit
    #   Xid 62 with an identical signature on nearly every boot, 30s-11min in,
    #   plus Xid 31 MMU faults and suspend hangs (journal, 2026-09-20). That
    #   was in PRIME sync mode; offload mode was never tried. Most likely the
    #   card itself is failing.
    # - Nouveau is stable but can't reclock Pascal ("pmu: firmware
    #   unavailable"), so it's slower than the iGPU.
    # Nouveau is kept because it runtime-suspends the card to D3cold. If no
    # driver binds it, the card would likely stay powered on (bad for battery).
    # The catch is that Mesa's NVK then exposes it to Vulkan as a DISCRETE_GPU,
    # which DXVK/Proton and many Vulkan apps pick over Intel. Hide it: the
    # Mesa device-select layer then exposes only the default (boot_vga, Intel)
    # device. OpenGL already defaults to the boot GPU.
    nvidia.prime = {
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:108@0:0:0";
    };
  };
  environment.sessionVariables.MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE = "1";
  networking.networkmanager.enable = true;
}
