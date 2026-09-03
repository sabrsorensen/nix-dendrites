{ pkgs, ... }:
let
  mergerfs = device: {
    fsType = "fuse.mergerfs";
    inherit device;
    options = [
      "cache.files=off"
      "dropcacheonclose=false"
      "category.create=pfrd"
      "func.getattr=newest"
    ];
  };
in
{
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };
  fileSystems."/AnomalyRealm" = {
    device = "/dev/md127";
    fsType = "ext4";
    options = [
      "relatime"
      "stripe=384"
    ];
  };
  environment.systemPackages = [ pkgs.mergerfs ];
  fileSystems = {
    "/AnomalyRealm/media/jellyfin/anime" =
      mergerfs "/AnomalyRealm/media/4k_anime:/AnomalyRealm/media/anime";
    "/AnomalyRealm/media/jellyfin/movies" =
      mergerfs "/AnomalyRealm/media/4k_movies:/AnomalyRealm/media/movies";
    "/AnomalyRealm/media/jellyfin/tv_shows" =
      mergerfs "/AnomalyRealm/media/4k_shows:/AnomalyRealm/media/tv_shows";
  };
}
