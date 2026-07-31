{
  config,
  lib,
  pkgs,
  domain,
  ...
}:
{
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
      kernelModules = [ "nvme" ];
      systemd.enable = true;
      verbose = false;
    };
    kernelModules = [
      "kvm-intel"
      "i915"
    ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        extraInstallCommands = ''
          if [ -d /boot2 ]; then
            ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot2/
          fi
        '';
      };
    };
    swraid = {
      enable = true;
      mdadmConf = "MAILADDR admin@${domain}";
    };
  };
  programs.msmtp.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  networking = {
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };
}
