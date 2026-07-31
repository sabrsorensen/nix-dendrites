{
  hasSam,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb-storage"
      "vc4"
      "pcie-brcmstb"
      "reset-raspberrypi"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [
      "cma=64M"
    ];
    # Pi kernels reject generic hardening values such as vm.mmap_rnd_bits.
    kernel.sysctl = lib.mkForce { };
    zfs.forceImportRoot = false;
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.end0.useDHCP = lib.mkDefault true;
  environment.systemPackages = [
    pkgs.libraspberrypi
    pkgs.wget
  ];
  hardware.enableRedistributableFirmware = true;
  programs.command-not-found.enable = false;
  programs.nix-index.enable = false;
  security.pam.services.sshd.updateWtmp = true;
  users.users = {
    root.extraGroups = lib.mkAfter [ "video" ];
  }
  // lib.optionalAttrs hasSam { sam.extraGroups = lib.mkAfter [ "video" ]; };
  services.udev.extraRules = ''
    SUBSYSTEM=="vchiq", GROUP="video", MODE="0664"
    SUBSYSTEM=="vcio", GROUP="video", MODE="0664"
    SUBSYSTEM=="vcsm", GROUP="video", MODE="0664"
  '';
  security.sudo.extraRules = lib.optionals hasSam [
    {
      users = [ "sam" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/vcgencmd *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
