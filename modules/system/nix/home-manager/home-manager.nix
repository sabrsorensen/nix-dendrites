{ inputs, lib, ... }:
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = lib.optional (inputs ? home-manager) ./_home-manager.nix;
}
