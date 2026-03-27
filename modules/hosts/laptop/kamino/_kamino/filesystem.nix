{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/230da9ca-39ae-4965-91d5-bcd508202272";
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CDAC-BCE2";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/83346e48-3afe-4561-ab08-f2453549ab13"; }
  ];
}
