{
  inputs,
  lib,
  ...
}:
{
  # Manage a user environment using Nix
  # https://github.com/nix-community/home-manager

  flake-file.inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate-home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = lib.optional (inputs ? home-manager) ./_home-manager.nix;
}
