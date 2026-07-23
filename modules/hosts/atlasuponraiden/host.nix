{
  config,
  inputs,
  lib,
  ...
}:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  bootstrapModule = {
    networking.hostName = "AtlasUponRaiden";
    my.host = {
      name = "AtlasUponRaiden";
      address = network.atlasuponraiden;
      formFactor = "server";
      tags = [ "bootstrap" ];
      bootstrap.finalConfigName = "atlasuponraiden";
      roles.server = true;
    };
    users.users.sam = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      openssh.authorizedKeys.keyFiles = [
        "${inputs.nix-secrets}/ssh-keys/kamino/atlas.pub"
        "${inputs.nix-secrets}/ssh-keys/no-phone/atlas.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/atlas.pub"
      ];
    };
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    services.btrfs.autoScrub.enable = lib.mkForce false;
    nix.buildMachines = [ ];
    nix.distributedBuilds = false;
    virtualisation.docker.enable = false;
    virtualisation.podman.enable = false;
  };
in
{
  flake.nixosConfigurations.atlasuponraiden = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      {
        networking.hostName = "AtlasUponRaiden";
        my.host = {
          name = "AtlasUponRaiden";
          address = network.atlasuponraiden;
          formFactor = "server";
          roles = {
            server = true;
            builder = true;
          };
          features = {
            docker = true;
            firmware = true;
            gdrive = true;
            nix-ld = true;
            podman = true;
            musicTagging = true;
          };
          services = {
            ankerctl = true;
            airsonic = true;
            apprise = true;
            arrSync = true;
            attic = true;
            atuin = true;
            bazarr = true;
            caddy = true;
            deluge = true;
            flaresolverr = true;
            gonic = true;
            gotify = true;
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
            watchtower = true;
          };
        };
        # Bootstrap deliberately leaves this disabled.
        my.deployment = {
          canDeployRemotely = true;
          enableRemoteUser = true;
          localFlakePath = "/home/sam/src/nix-dendrites";
          sleepy = false;
          authorizedKeyFiles = [
            "${inputs.nix-secrets}/ssh-keys/kamino/atlas_nix.pub"
            "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/atlas_nix.pub"
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
      }
    ];
  };
  flake.nixosConfigurations."atlasuponraiden-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [ bootstrapModule ];
  };
}
