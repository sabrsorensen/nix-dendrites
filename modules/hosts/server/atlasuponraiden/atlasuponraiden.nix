{
  inputs,
  lib,
  ...
}:
let
  primaryInteractiveUser = "sam";
in
{
  flake.modules.nixos.AtlasUponRaiden =
    { config, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        samCli
        ./_atlas/hardware.nix
        ./_atlas/filesystem.nix
        ./_atlas/network.nix
        ./_atlas/users/sam.nix
        ./_atlas/immich.nix
        (import ./_atlas/syncthing.nix { inherit inputs; })
        (import ./_atlas/nix-remote.nix { inherit inputs lib; })
        samba
        ./_atlas/samba.nix
        deploy-defaults
        system-cli
        systemd-boot
        disko
        podman
        cross-compile
        nix-index
        caddy
        apprise
        ankerctl
        immich
        mealie
        media-server
        minecraft-server
        demlo
        scrutiny
        syncthing-server
        #homeassistant-proxy
      ];

      my.host = {
        inherit primaryInteractiveUser;
        roles = {
          server = true;
          builder = true;
        };
        deploy = {
          canDeployRemotely = true;
          enableRemoteUser = true;
          sleepy = false;
        };
        ssh.enableNixBlocks = true;
        syncthing.mode = "system";
      };

      my.localDns.records = [
        { hostname = "atlas"; }
      ];

      services.openssh.allowSFTP = true;

      nix.settings.system-features = config.systemConstants.atlas.systemFeatures;

      home-manager.users.sam = {
        imports = [
          inputs.self.modules.homeManager.AtlasUponRaiden
        ];
        # Force disable Home Manager syncthing to avoid conflicts with NixOS service.
        my.syncthing.enable = lib.mkForce false;
      };
    };

  flake.modules.homeManager.AtlasUponRaiden = {
    imports = with inputs.self.modules.homeManager; [
      beets
      nix-index
      demlo
    ];
  };

  flake.lib.hostInventory.AtlasUponRaiden = inputs.self.lib.mkInventoryHost {
    builder = inputs.self.lib.mkInventoryBuilder {
      hostName = "AtlasUponRaiden";
      sshKey = "/root/.ssh/nix_atlasuponraiden_id_ed25519";
      systems = inputs.self.lib.site.atlas.supportedSystems;
      maxJobs = inputs.self.lib.site.atlas.maxJobs;
      speedFactor = inputs.self.lib.site.atlas.speedFactor;
      supportedFeatures = inputs.self.lib.site.atlas.systemFeatures;
    };
    ssh = inputs.self.lib.mkInventorySsh {
      base = inputs.self.lib.mkInventorySshBase {
        user = primaryInteractiveUser;
        identityFile = "~/.ssh/atlasuponraiden_id_ed25519";
      };
      nix = inputs.self.lib.mkInventorySshNix {
        identityFile = "~/.ssh/nix_atlasuponraiden_id_ed25519";
      };
    };
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "switch";
    };
    outputs = inputs.self.lib.mkNixosOutputs {
      system = "x86_64-linux";
      name = "atlasuponraiden";
      configuration = "AtlasUponRaiden";
    };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "AtlasUponRaiden";
}
