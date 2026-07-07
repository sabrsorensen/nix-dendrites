{
  lib,
  bootUuid,
  rootFsUuid,
  rootLuksUuid,
  swapLuksUuid,
  swapUuid,
  ...
}:
{
  boot.initrd.luks = {
    devices."luks-${rootLuksUuid}" = {
      device = lib.mkForce "/dev/disk/by-uuid/${rootLuksUuid}";
      allowDiscards = true;
    };
    devices."luks-${swapLuksUuid}" = {
      device = lib.mkForce "/dev/disk/by-uuid/${swapLuksUuid}";
      allowDiscards = true;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/${rootFsUuid}";
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/${bootUuid}";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/${swapUuid}"; }
  ];
}
