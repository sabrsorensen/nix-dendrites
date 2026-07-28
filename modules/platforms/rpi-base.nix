{ ... }:
{
  flake.modules.nixos.rpi-base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasSam =
        builtins.elem config.my.host.name [
          "Naboo"
          "Nevarro"
          "NixPi"
        ]
        || builtins.elem "bootstrap" config.my.host.tags;
    in
    lib.mkIf config.my.host.is.rpi {
      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "vc4"
        # Pi 4 PCIe/VL805 support from nixos-hardware's Pi module.
        "pcie_brcmstb"
        "reset-raspberrypi"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];
      boot.kernelParams = [
        "cma=64M"
        "console=serial0,115200n8"
        "console=tty1"
      ];
      # Pi kernels reject some of NixOS's generic hardening defaults (notably
      # vm.mmap_rnd_bits).  Keep the RPi sysctl surface empty, as in the
      # established Pi configuration, rather than letting systemd-sysctl fail
      # during activation.
      boot.kernel.sysctl = lib.mkForce { };
      boot.zfs.forceImportRoot = false;

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

      # Raspberry Pi firmware exposes these devices to the video group. Grant
      # root access unconditionally and Sam access only when the account exists.
      users.users = {
        root.extraGroups = lib.mkAfter [ "video" ];
      }
      // lib.optionalAttrs hasSam {
        sam.extraGroups = lib.mkAfter [ "video" ];
      };
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
    };
}
