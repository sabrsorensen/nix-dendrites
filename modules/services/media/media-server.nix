{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.media-server =
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
    };

  flake.modules.nixos.media-base = ./_media-base.nix;
}
