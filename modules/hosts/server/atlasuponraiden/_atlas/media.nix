{
  config,
  lib,
  ...
}:
{
  my.media = {
    enable = true;
    dataRoot = lib.mkDefault "/AnomalyRealm/media";
    dnsServers = lib.mkDefault [
      config.systemConstants.network.nevarro
      config.systemConstants.network.naboo
    ];
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

  users.groups.media.gid = lib.mkDefault 2096;
}
