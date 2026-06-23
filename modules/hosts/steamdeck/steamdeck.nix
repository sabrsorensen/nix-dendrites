{
  inputs,
  lib,
  ...
}:
let
  platformHelpers = import ./_platform-helpers.nix { inherit inputs; };
  steamdeck = {
    inherit (platformHelpers) steamdeck;
  }
  // import ./_registration-builder.nix {
    inherit lib;
    inherit (platformHelpers) steamdeck;
  };
  descriptors = [
    (import ./emeraldecho/_host/host-data.nix { inherit inputs lib; })
  ];
in
{
  imports = [ ./exports.nix ] ++ map steamdeck.mkRegisteredHost descriptors;

  flake-file.inputs = {
    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
