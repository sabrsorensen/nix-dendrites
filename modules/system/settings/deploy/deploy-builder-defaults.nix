{
  ...
}:
{
  flake.modules.nixos."deploy-builder-defaults" =
    { config, lib, ... }:
    let
      atlasBuilderHost = "AtlasNixBuilder";
      atlasBuilderTarget = "AtlasUponRaiden";
      atlasBuilderUser = "nix-remote";
      atlasBuilderIdentity = "~/.ssh/nix_atlasuponraiden_id_ed25519";
    in
    {
      my.host.nix.buildMachines = lib.mkDefault [
        {
          hostName = atlasBuilderHost;
          systems = config.systemConstants.atlas.supportedSystems;
          protocol = "ssh-ng";
          maxJobs = config.systemConstants.atlas.maxJobs;
          speedFactor = config.systemConstants.atlas.speedFactor;
          supportedFeatures = config.systemConstants.atlas.systemFeatures;
          mandatoryFeatures = [ ];
        }
      ];

      programs.ssh.extraConfig = lib.mkAfter ''
        Host ${atlasBuilderHost}
          HostName ${atlasBuilderTarget}
          User ${atlasBuilderUser}
          IdentityFile ${atlasBuilderIdentity}
      '';

      nix.settings.extra-substituters = lib.mkAfter [ "ssh-ng://${atlasBuilderHost}" ];
    };
}
