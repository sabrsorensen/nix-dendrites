{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.media-server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        ./_media-base.nix
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

      my.media = {
        configRoot = lib.mkDefault "/opt";
        dataRoot = lib.mkDefault "/AnomalyRealm/media";
        dnsServers = lib.mkDefault [
          config.systemConstants.network.nevarro
          config.systemConstants.network.naboo
        ];
        podmanNetwork = lib.mkDefault "media";
        containerIdentities = {
          deluge = lib.mkDefault {
            uid = "1000";
            gid = "996";
          };
          plex = lib.mkDefault {
            uid = "978";
            gid = "978";
          };
          tautulli = lib.mkDefault {
            uid = "976";
            gid = "978";
          };
        };
      };

      systemd.services."podman-network-media" = {
        path = [ pkgs.podman ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "podman network rm -f ${config.my.media.podmanNetwork}";
        };
        script = ''
          podman network inspect ${config.my.media.podmanNetwork} || podman network create ${config.my.media.podmanNetwork} --driver=bridge
        '';
        # Ensure this runs before any containers needing the network
        wantedBy = [ "multi-user.target" ];
      };
      users.groups.media = { };

    };
}
