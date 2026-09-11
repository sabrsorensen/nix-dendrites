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
  # raspberrypi-eeprom pulls in flashrom to write the Pi's SPI EEPROM.
  # flashrom 1.8.0's cmocka test suite (read_chip_bad_status_test /
  # write_chip_bad_status_test) fails spuriously on aarch64-linux -- a
  # dangling stack pointer in tests/chip.c:setup_bad_chip() corrupts later
  # stack allocations (nixpkgs#558302, Hydra-reproducible, introduced by the
  # 1.7.0 -> 1.8.0 bump). The runtime binary is unaffected, so drop the
  # build-time check rather than carry an unverified source patch.
  nixpkgs.overlays = [
    (_: prev: {
      flashrom = prev.flashrom.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];
  warnings = [
    ''
      pkgs.flashrom is overridden to skip its test suite (chip.c
      read/write_chip_bad_status_test fail spuriously on aarch64-linux --
      nixpkgs#558302, a dangling stack pointer introduced by the
      flashrom 1.7.0 -> 1.8.0 bump). Remove the overlay in
      modules/platforms/rpi/rpi-base/_rpi-base.nix once this is fixed
      upstream -- check with:
        nix build .#nixosConfigurations.naboo.pkgs.flashrom
      after removing the override (needs an aarch64 builder), and confirm
      https://github.com/NixOS/nixpkgs/issues/558302 is closed.
    ''
  ];
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
