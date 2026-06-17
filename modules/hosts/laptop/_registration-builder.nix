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
    {
      imports = descriptor.nixos.imports ++ [
        inputs.self.modules.nixos.deploy-defaults
      ];

      my.host = descriptor.config;

      home-manager.users.${descriptor.user.name}.imports = [
        inputs.self.modules.homeManager.${descriptor.name}
      ];
    };

  mkRegisteredHost =
    descriptor:
    x86Builder.mkRegisteredHost {
      inherit descriptor mkHostModule;
    };
}
