{
  inputs,
  lib,
  ...
}:
let
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib; };
in
descriptorHelpers.mkWslDescriptor {
  name = "NixOS-WSL";
  outputName = "nixos-wsl";
  hostModule = inputs.self.modules.nixos.nixosWsl;
  nixosProfileNames = [ "system-work-dev" ];
  homeProfileNames = [
    "sam-home-work"
    "sam-home-work-wsl"
  ];
}
