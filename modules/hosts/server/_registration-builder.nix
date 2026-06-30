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
      pkgs,
      ...
    }:
    let
      shared = inputs.self.lib.shared;
      bootstrap = descriptor.bootstrap;
      bootstrapUser = bootstrap.user or { };
      bootstrapHostConfig = lib.recursiveUpdate descriptor.config {
        lifecycle.mode = "bootstrap";
        bootstrap.finalConfigName = bootstrap.finalConfigName or descriptor.name;
      };
    in
    {
      imports = bootstrap.nixos.imports ++ [
        inputs.self.modules.nixos."bootstrap-base"
      ];

      networking.hostName = lib.mkDefault descriptor.hostName;
      my.host = bootstrapHostConfig;
      my.localDns.records = descriptor.localDnsRecords or [ ];

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
      imports = descriptor.nixos.imports;

      networking.hostName = lib.mkDefault descriptor.hostName;
      my.host = descriptor.config;
      my.localDns.records = descriptor.localDnsRecords or [ ];

      services.openssh.allowSFTP = true;
      nix.settings.system-features = config.systemConstants.atlas.systemFeatures;

      users.users.nix-remote =
        lib.mkIf (config.my.host.deploy.enableRemoteUser && nixRemoteAuthorizedKeyPaths != [ ])
          {
            openssh.authorizedKeys.keyFiles = sshKeyHelpers.mkBuildSecretSshKeyFiles nixRemoteAuthorizedKeyPaths;
          };

      home-manager.users.${descriptor.user.name} = {
        imports = [
          inputs.self.modules.homeManager.${descriptor.name}
        ];
        my.syncthing.enable = lib.mkForce false;
      };
    };

  mkRegisteredHost =
    descriptor:
    x86Builder.mkRegisteredHost {
      inherit descriptor mkHostModule mkBootstrapModule;
    };
}
