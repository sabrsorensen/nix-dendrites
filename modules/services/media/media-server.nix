{ inputs, lib, ... }:
{
  flake.modules.nixos.media-server =
    { config, ... }:
    {
      imports = [
        inputs.self.modules.nixos.media-base
        ./_defaults.nix
        ./_podman-network.nix
      ]
      ++ (with inputs.self.modules.nixos; [
        airsonic
        arr-sync
        bazarr
        deluge
        demlo
        flaresolverr
        gonic
        gotify
        jellyfin
        #netbird-proxy
        ntfy-sh
        #ombi
        organizr
        plex
        profilarr
        prowlarr
        radarr
        sonarr
      ]);

      config = lib.mkIf config.my.media.enable {
        my.services = {
          airsonic.enable = lib.mkDefault true;
          "arr-sync".enable = lib.mkDefault true;
          bazarr.enable = lib.mkDefault true;
          deluge.enable = lib.mkDefault true;
          flaresolverr.enable = lib.mkDefault true;
          gonic.enable = lib.mkDefault true;
          gotify.enable = lib.mkDefault true;
          jellyfin.enable = lib.mkDefault true;
          ntfy.enable = lib.mkDefault true;
          organizr.enable = lib.mkDefault true;
          plex.enable = lib.mkDefault true;
          profilarr.enable = lib.mkDefault true;
          prowlarr.enable = lib.mkDefault true;
          radarr.enable = lib.mkDefault true;
          sonarr.enable = lib.mkDefault true;
        };
      };
    };

  flake.modules.nixos.media-base = ./_media-base.nix;
}
