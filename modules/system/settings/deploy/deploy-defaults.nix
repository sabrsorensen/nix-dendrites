{
  ...
}:
{
  flake.modules.nixos.deploy-defaults =
    { config, lib, ... }:
    {
      my.host = {
        deploy.localFlakePath = lib.mkDefault "/home/sam/src/nix-dendrites";
        nix.buildMachines = lib.mkDefault [
          {
            hostName = "AtlasNixBuilder";
            systems = config.systemConstants.atlas.supportedSystems;
            protocol = "ssh-ng";
            maxJobs = config.systemConstants.atlas.maxJobs;
            speedFactor = config.systemConstants.atlas.speedFactor;
            supportedFeatures = config.systemConstants.atlas.systemFeatures;
            mandatoryFeatures = [ ];
          }
        ];
      };

      programs.nh = lib.mkIf (config.my.host.deploy.localFlakePath != null) {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = config.my.host.deploy.localFlakePath;
      };
    };
}
