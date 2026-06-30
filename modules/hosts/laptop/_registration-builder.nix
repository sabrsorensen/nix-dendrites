{
  inputs,
  lib,
}:
let
  x86Builder = import ../_x86-registration-builder.nix { inherit inputs; };
  mkBootstrapModule =
    descriptor:
    {
      lib,
      ...
    }:
    let
      shared = inputs.self.lib.shared;
      bootstrap = descriptor.bootstrap;
      bootstrapUser = bootstrap.user or { };
      hasNvidia = lib.attrByPath [ "features" "nvidia" ] false descriptor.config;
      bootstrapHostConfig = lib.recursiveUpdate descriptor.config {
        lifecycle.mode = "bootstrap";
        bootstrap.finalConfigName = bootstrap.finalConfigName or descriptor.name;
        features = {
          gui = false;
          bluetooth = false;
          deskflow = false;
          nvidia = false;
          flatpak = false;
          steam = false;
          wine = false;
        };
        syncthing = {
          mode = "disabled";
          hasTray = false;
        };
      };
    in
    {
      imports = bootstrap.nixos.imports ++ [
        inputs.self.modules.nixos."bootstrap-base"
      ];

      networking.hostName = lib.mkDefault descriptor.hostName;
      my.host = bootstrapHostConfig;

      nix.buildMachines = lib.mkForce [ ];
      nix.distributedBuilds = lib.mkForce false;

      users.users.${descriptor.user.name} = {
        isNormalUser = true;
        extraGroups = bootstrapUser.extraGroups or [ "wheel" ];
        openssh.authorizedKeys.keyFiles = shared.mkSecretsSshKeyFiles bootstrap.authorizedKeyPaths;
      }
      // lib.optionalAttrs (bootstrapUser ? initialPassword) {
        initialPassword = bootstrapUser.initialPassword;
      };

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = lib.mkForce (bootstrapUser ? initialPassword);
      };

      services.xserver.videoDrivers = lib.mkIf hasNvidia (lib.mkForce [ ]);
      hardware.nvidia.open = lib.mkIf hasNvidia (lib.mkForce false);
    };
in
rec {
  mkHostModule =
    descriptor:
    { config, ... }:
    let
      sshKeyHelpers = import ../_ssh-key-helpers.nix { inherit config; };
      nixRemoteAuthorizedKeyPaths = lib.attrByPath [ "user" "authorizedKeys" "nixRemote" ] [ ] descriptor;
    in
    {
      imports = descriptor.nixos.imports ++ [
        inputs.self.modules.nixos.deploy-defaults
      ];

      networking.hostName = lib.mkDefault descriptor.hostName;
      my.host = descriptor.config;

      users.users.nix-remote =
        lib.mkIf (config.my.host.deploy.enableRemoteUser && nixRemoteAuthorizedKeyPaths != [ ])
          {
            openssh.authorizedKeys.keyFiles = sshKeyHelpers.mkBuildSecretSshKeyFiles nixRemoteAuthorizedKeyPaths;
          };

      home-manager.users.${descriptor.user.name}.imports = [
        inputs.self.modules.homeManager.${descriptor.name}
      ];
    };

  mkRegisteredHost =
    descriptor:
    x86Builder.mkRegisteredHost {
      inherit descriptor mkHostModule mkBootstrapModule;
    };
}
