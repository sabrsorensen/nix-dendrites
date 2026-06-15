{
  pkgs,
  ...
}:
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
  environment.systemPackages = with pkgs; [
    mergerfs
  ];
  fileSystems."/AnomalyRealm/media/jellyfin/anime" = {
    fsType = "fuse.mergerfs";
    device = "/AnomalyRealm/media/4k_anime:/AnomalyRealm/media/anime";
    options = [
      "cache.files=off"
      "dropcacheonclose=false"
      "category.create=pfrd"
      "func.getattr=newest"
    ];
  };
  fileSystems."/AnomalyRealm/media/jellyfin/movies" = {
    fsType = "fuse.mergerfs";
    device = "/AnomalyRealm/media/4k_movies:/AnomalyRealm/media/movies";
    options = [
      "cache.files=off"
      "dropcacheonclose=false"
      "category.create=pfrd"
      "func.getattr=newest"
    ];
  };
  fileSystems."/AnomalyRealm/media/jellyfin/tv_shows" = {
    fsType = "fuse.mergerfs";
    device = "/AnomalyRealm/media/4k_shows:/AnomalyRealm/media/tv_shows";
    options = [
      "cache.files=off"
      "dropcacheonclose=false"
      "category.create=pfrd"
      "func.getattr=newest"
    ];
  };
}
