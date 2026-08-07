{
  config,
  lib,
  pkgs,
  rootLuksUuid,
  ...
}:
let
  enableZenbookSpeaker = pkgs.writeShellScript "enable-zenbook-speaker" ''
    set -eu
    shopt -s nullglob

    find_realtek_alc294_devices() {
      local codec_path
      for codec_path in /proc/asound/card*/codec#*; do
        [ -r "$codec_path" ] || continue
        grep -q "Codec: Realtek ALC294" "$codec_path" || continue
        local card="''${codec_path#/proc/asound/card}"
        card="''${card%%/*}"
        local codec="''${codec_path##*codec#}"
        printf '/dev/snd/hwC%sD%s\n' "$card" "$codec"
      done
    }

    for _attempt in $(seq 1 20); do
      devices=()
      while IFS= read -r dev; do
        [ -n "$dev" ] && devices+=("$dev")
      done < <(find_realtek_alc294_devices)
      if [ "''${#devices[@]}" -eq 0 ]; then
        for dev in /dev/snd/hwC*D*; do devices+=("$dev"); done
      fi
      for dev in "''${devices[@]}"; do
        if ${pkgs.alsa-tools}/bin/hda-verb "$dev" 0x20 0x500 0x1b \
          && ${pkgs.alsa-tools}/bin/hda-verb "$dev" 0x20 0x477 0x4a4b \
          && ${pkgs.alsa-tools}/bin/hda-verb "$dev" 0x20 0x500 0xf \
          && ${pkgs.alsa-tools}/bin/hda-verb "$dev" 0x20 0x477 0x74; then
          exit 0
        fi
      done
      sleep 1
    done
    echo "No compatible ALC294 HDA codec device found" >&2
    exit 1
  '';
in
{
  networking.networkmanager.enable = true;

  boot = {
    kernelParams = [ "video=1920x1080@60" ];
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "vmd"
        "nvme"
        "usb_storage"
        "sd_mod"
        "dm-crypt"
        "dm-mod"
      ];
      includeDefaultModules = true;
      kernelModules = [
        "dm-crypt"
        "nvme"
      ];
      systemd.enable = true;
      verbose = false;
      luks.devices.crypted = {
        device = lib.mkForce "/dev/disk/by-uuid/${rootLuksUuid}";
        allowDiscards = true;
      };
    };
    kernelModules = [ "kvm-intel" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia.prime = {
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:1@0:0:0";
    };
  };

  environment.systemPackages = [ pkgs.alsa-tools ];
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
