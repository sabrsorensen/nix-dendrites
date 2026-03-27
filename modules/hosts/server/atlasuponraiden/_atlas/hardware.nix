{
  config,
  lib,
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-linux";
  # Hardware modules needed for boot
  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "nvme"
        "sd_mod"
        "thunderbolt"
      ];
      includeDefaultModules = true;
      kernelModules = [
        "nvme"
      ];
      # Ensure systemd in initrd for better device handling
      systemd.enable = true;
      verbose = false;
    };
    kernelModules = [ "kvm-intel" ];
    # ------------------------
    # Bootloader with dual ESP
    # ------------------------
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      systemd-boot = {
        enable = true;
        mirroredEspPaths = [ "/boot2" ];
      };
    };
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR ${config.systemConstants.adminEmail}
      '';
    };
  };
  # Mail for mdadm
  programs.msmtp.enable = true;

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      prime = {
        #intelBusId = "PCI:0@0:2:0";
        #nvidiaBusId = "PCI:1@0:0:0";
      };
    };
  };
}
