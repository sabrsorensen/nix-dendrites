{ inputs, lib, ... }:
{
  flake-file.inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  imports = lib.optional (inputs ? plasma-manager) ./_plasma.nix;
}
