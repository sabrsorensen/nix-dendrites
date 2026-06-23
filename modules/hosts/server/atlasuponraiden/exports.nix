{
  inputs,
  lib,
  ...
}:
let
  atlasConfig = import ./_atlas/config.nix;
in
{
  flake.modules.nixos = {
    atlasUponRaiden = {
      imports = [
        ./_atlas/hardware.nix
        ./_atlas/filesystem.nix
        ./_atlas/network.nix
        atlasConfig.services
        ./_atlas/service-overrides.nix
        ./_atlas/users/sam.nix
        ./_atlas/media.nix
        inputs.self.modules.nixos.sam-syncthing
      ];
    };
  };
}
