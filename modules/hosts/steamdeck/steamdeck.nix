{
  inputs,
  lib,
  ...
}:
let
  steamdeck = import ./_public.nix { inherit inputs lib; };
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
