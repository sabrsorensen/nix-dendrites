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
      assertions =
        let
          identities = builtins.attrValues config.my.media.containerIdentities;
          uids = map (identity: identity.uid) identities;
        in
        [
          {
            assertion = lib.length uids == lib.length (lib.unique uids);
            message = "my.media.containerIdentities must assign a unique UID to each service.";
          }
        ];

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
          airsonic = lib.mkDefault {
            uid = 2101;
            gid = 2096;
          };
          deluge = lib.mkDefault {
            uid = 2102;
            gid = 2096;
          };
          organizr = lib.mkDefault {
            uid = 2103;
            gid = 2096;
          };
          plex = lib.mkDefault {
            uid = 2104;
            gid = 2096;
          };
          profilarr = lib.mkDefault {
            uid = 2105;
            gid = 2096;
          };
          tautulli = lib.mkDefault {
            uid = 2106;
            gid = 2096;
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
      users.groups.media.gid = lib.mkDefault 2096;

    };
}
