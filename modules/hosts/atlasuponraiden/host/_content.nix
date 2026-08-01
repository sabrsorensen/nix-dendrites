{
  inputs,
  network,
}:
{
  hostModule = {
    networking.hostName = "AtlasUponRaiden";
    my.host = {
      name = "AtlasUponRaiden";
      address = network.atlasuponraiden;
      formFactor = "server";
      home.enable = true;
      roles = {
        server = true;
        builder = true;
      };
      features = {
        atuin = true;
        beets = true;
        demlo = true;
        docker = true;
        firmware = true;
        gdrive = true;
        nix-ld = true;
        podman = true;
      };
      services = {
        ankerctl = true;
        airsonic = true;
        apprise = true;
        arrSync = true;
        attic = true;
        atuinServer = true;
        bazarr = true;
        caddy = true;
        deluge = true;
        flaresolverr = true;
        gonic = true;
        gotify = true;
        hawkbit = true;
        immich = true;
        jellyfin = true;
        mealie = true;
        minecraft = true;
        monitoring = true;
        plex = true;
        profilarr = true;
        prowlarr = true;
        radarr = true;
        sonarr = true;
        ntfy = true;
        organizr = true;
        samba = true;
        scrutiny = true;
        syncthing = true;
      };
    };
    users.users.sam = {
      extraGroups = [ "dialout" ];
      openssh.authorizedKeys.keyFiles = [
        "${inputs.nix-secrets}/ssh-keys/kamino/atlas.pub"
        "${inputs.nix-secrets}/ssh-keys/no-phone/atlas.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/atlas.pub"
      ];
    };
    my.localDns.records = [ { hostname = "atlas"; } ];
    my.deployment = {
      canDeployRemotely = true;
      enableRemoteUser = true;
      localFlakePath = "/home/sam/src/nix-dendrites";
      sleepy = false;
      authorizedKeyFiles = [
        "${inputs.nix-secrets}/ssh-keys/kamino/atlas_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/atlas_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/naboo/atlas_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/nevarro/atlas_nix.pub"
      ];
    };
    my.immich.mediaLocation = "/AnomalyRealm/media/photos";
    my.media = {
      dataRoot = "/AnomalyRealm/media";
      dnsServers = [
        network.nevarro
        network.naboo
      ];
      containerIdentities = {
        airsonic = {
          uid = 2101;
          gid = 2096;
        };
        deluge = {
          uid = 2102;
          gid = 2096;
        };
        organizr = {
          uid = 2103;
          gid = 2096;
        };
        plex = {
          uid = 2104;
          gid = 2096;
        };
        profilarr = {
          uid = 2105;
          gid = 2096;
        };
        tautulli = {
          uid = 2106;
          gid = 2096;
        };
        hawkbit = {
          uid = 2201;
          gid = 2096;
        };
      };
    };
    my.monitoring = {
      basicAuthPasswordEnvVar = "SCRUTINY_PASSWORD";
      nodeTargets = [
        "naboo"
        "nevarro"
      ];
      blockyTargets = [
        "naboo"
        "nevarro"
      ];
      smartctlTargets = [
        "naboo"
        "nevarro"
      ];
    };
  };
}
