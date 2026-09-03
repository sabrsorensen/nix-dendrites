{ inputs, ... }:
{
  flake-file.inputs.jovian-nixos = {
    url = "github:Jovian-Experiments/Jovian-NixOS";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.platform-steamdeck = {
    imports = [ (import ./_steamdeck.nix { inherit inputs; }) ];
  };
}
