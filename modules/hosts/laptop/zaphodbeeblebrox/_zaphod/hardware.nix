{
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-linux";
  # Hardware modules needed for boot
  boot = {
    initrd = {
      availableKernelModules = [
        # Detected by nixos-generate-config
        "xhci_pci"
        "thunderbolt"
        "vmd"
        "nvme"
        "usb_storage"
        "sd_mod"
        # LUKS
        "dm-crypt"
        # LVM
        "dm-mod"
      ];
      includeDefaultModules = true;
      kernelModules = [
        "dm-crypt"
        "nvme"
      ];
      # Ensure systemd in initrd for better device handling
      systemd.enable = true;
      verbose = false;
    };
    kernelModules = [ "kvm-intel" ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      prime = {
        intelBusId = "PCI:0@0:2:0";
        nvidiaBusId = "PCI:1@0:0:0";
      };
    };
  };

  # Zenbook Duo specific - dual screen support
  services.xserver.xrandrHeads = [
    # Configure when you know the screen setup
    # "DP-1" "eDP-1" etc.
  ];

  # Ensure alsa-tools (for hda-verb) is available
  environment.systemPackages = with pkgs; [ alsa-tools ];

  # Systemd service to enable ZenBook speakers at boot
  # https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1850439/comments/172
  systemd.services.enable-zenbook-speaker = {
    description = "Enable ASUS ZenBook ALC294 speakers";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'for dev in /dev/snd/hwC*D0; do if [ -e \"$dev\" ]; then ${pkgs.alsa-tools}/bin/hda-verb \"$dev\" 0x20 0x500 0x1b && ${pkgs.alsa-tools}/bin/hda-verb \"$dev\" 0x20 0x477 0x4a4b && ${pkgs.alsa-tools}/bin/hda-verb \"$dev\" 0x20 0x500 0xf && ${pkgs.alsa-tools}/bin/hda-verb \"$dev\" 0x20 0x477 0x74; fi; done'";
    };
  };
}
