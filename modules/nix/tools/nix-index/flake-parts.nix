{
  inputs,
  lib,
  ...
}:
{
  # Pre-built nix-index database for faster command-not-found functionality
  # https://github.com/nix-community/nix-index-database

  flake-file.inputs = {
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = lib.optional (inputs ? nix-index-database) ./_nix-index.nix;
}