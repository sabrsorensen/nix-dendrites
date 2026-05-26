{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.media-server =
  {
    pkgs,
    ...
  }:
  {
    imports = with inputs.self.modules.nixos; [
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
    ];

    systemd.services."podman-network-media" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f media";
      };
      script = ''
        podman network inspect media || podman network create media --driver=bridge
      '';
      # Ensure this runs before any containers needing the network
      wantedBy = [ "multi-user.target" ];
    };
    users.groups.media = { };

  };
}