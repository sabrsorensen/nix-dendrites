{
  bootUuid,
  rootFsUuid,
  swapUuid,
  ...
}:
{
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
