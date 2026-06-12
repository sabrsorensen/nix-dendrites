{
  config,
  lib,
  pkgs,
  ...
}:
let
  enableZenbookSpeaker = pkgs.writeShellScript "enable-zenbook-speaker" ''
    set -eu

    shopt -s nullglob

    for _attempt in $(seq 1 20); do
      for dev in /dev/snd/hwC*D*; do
        if ${pkgs.alsa-tools}/bin/hda-verb "$dev" 0x20 0x500 0x1b \
          && ${pkgs.alsa-tools}/bin/hda-verb "$dev" 0x20 0x477 0x4a4b \
          && ${pkgs.alsa-tools}/bin/hda-verb "$dev" 0x20 0x500 0xf \
          && ${pkgs.alsa-tools}/bin/hda-verb "$dev" 0x20 0x477 0x74; then
          exit 0
        fi
      done

      sleep 1
    done

    echo "No compatible HDA codec device found under /dev/snd/hwC*D*" >&2
    exit 1
  '';
in
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
    wants = [
      "enable-zenbook-speaker-resume.service"
      "systemd-udev-settle.service"
    ];
    after = [
      "systemd-udev-settle.service"
      "sound.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = enableZenbookSpeaker;
    };
  };

  systemd.services.enable-zenbook-speaker-resume = {
    description = "Re-enable ASUS ZenBook ALC294 speakers after resume";
    wants = [ "enable-zenbook-speaker.service" ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = "${config.systemd.package}/bin/systemctl restart enable-zenbook-speaker.service";
    };
  };
}
