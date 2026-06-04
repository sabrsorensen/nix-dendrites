{
  inputs,
  ...
}:
{
  flake.modules.nixos."deploy-builder-defaults" =
    { lib, ... }:
    let
      builders = builtins.filter (builder: builder != null) (
        map (host: host.builder or null) (builtins.attrValues inputs.self.lib.hostInventory)
      );
      buildMachines = map (builder: {
        hostName = builder.alias;
        protocol = "ssh-ng";
        inherit (builder)
          mandatoryFeatures
          maxJobs
          speedFactor
          supportedFeatures
          systems
          ;
      }) builders;
      builderSshConfig = lib.concatMapStrings (builder: ''
        Host ${builder.alias}
          HostName ${builder.targetHost}
          User ${builder.user}
          IdentityFile ${builder.identityFile}
      '') builders;
      builderSubstituters = map (builder: "ssh-ng://${builder.alias}") builders;
    in
    {
      my.host.nix.buildMachines = lib.mkDefault buildMachines;

      programs.ssh.extraConfig = lib.mkAfter builderSshConfig;

      nix.settings.extra-substituters = lib.mkAfter builderSubstituters;
    };
}
