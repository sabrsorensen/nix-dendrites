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
    zfs.forceImportRoot = false;
  };
  # The Pi 4 kernel's own configfile advertises an mmap_rnd_bits max that the
  # running kernel rejects at boot. NixOS computes that value from the kernel
  # configfile straight into sysctl.d/55-nixos-aslr-entropy.conf, bypassing
  # boot.kernel.sysctl entirely, so disable that file specifically rather
  # than clearing boot.kernel.sysctl (which wouldn't touch this value anyway,
  # and would silently drop any sysctls other modules set).
  environment.etc."sysctl.d/55-nixos-aslr-entropy.conf".enable = false;
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  # Bound journald's footprint on the SD card. Kept persistent (not
  # volatile) so crash/reboot logs -- e.g. from the undervoltage events
  # rpi-status surfaces -- survive a power cycle.
  services.journald.extraConfig = ''
    SystemMaxUse=200M
  '';
  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.end0.useDHCP = lib.mkDefault true;
  environment.systemPackages = [
    pkgs.libraspberrypi
    pkgs.raspberrypi-eeprom
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
