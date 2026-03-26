{
  imports = [ ./disko-config.nix ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # ------------------------
  # RAID6 AnomalyRealm array
  # ------------------------
  fileSystems."/AnomalyRealm" = {
    device = "/dev/md127";
    fsType = "ext4";
    options = [
      "relatime"
      "stripe=384"
    ];
  };
}
