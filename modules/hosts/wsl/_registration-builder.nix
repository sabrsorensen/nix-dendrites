{
  inputs,
  lib,
  ...
}:
let
  x86Builder = import ../_x86-registration-builder.nix { inherit inputs; };
in
rec {
  mkHostModule =
    descriptor:
    { config, ... }:
    let
      username = config.my.host.primaryInteractiveUser;
    in
    {
      imports = descriptor.nixos.imports;
      networking.hostName = lib.mkDefault descriptor.hostName;
      my.host = descriptor.config;

      home-manager.users.${username} = {
        imports = [
          inputs.self.modules.homeManager.${descriptor.name}
        ];
        home.username = lib.mkDefault username;
        home.homeDirectory = lib.mkDefault "/home/${username}";
      };
    };

  mkRegisteredHost =
    descriptor:
    x86Builder.mkRegisteredHost {
      inherit descriptor mkHostModule;
    };
}
