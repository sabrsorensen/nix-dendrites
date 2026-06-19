{
  inputs,
  lib,
  ...
}:
let
  x86Builder = import ../_x86-registration-builder.nix { inherit inputs; };
in
rec {
  mkHostModule = descriptor: {
    imports = descriptor.nixos.imports;
    networking.hostName = lib.mkDefault descriptor.hostName;
    my.host = descriptor.config;
  };

  mkRegisteredHost =
    descriptor:
    x86Builder.mkRegisteredHost {
      inherit descriptor mkHostModule;
    };
}
