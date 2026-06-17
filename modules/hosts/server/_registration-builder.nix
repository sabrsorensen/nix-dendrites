{
  inputs,
  lib,
}:
let
  x86Builder = import ../_x86-registration-builder.nix { inherit inputs; };
in
rec {
  mkHostModule =
    descriptor:
    { config, ... }:
    {
      imports = descriptor.nixos.imports;

      my.host = descriptor.config;
      my.localDns.records = descriptor.localDnsRecords or [ ];

      services.openssh.allowSFTP = true;
      nix.settings.system-features = config.systemConstants.atlas.systemFeatures;

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
      inherit descriptor mkHostModule;
    };
}
