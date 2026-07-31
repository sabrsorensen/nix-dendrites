{ inputs, lib, ... }:
{
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = lib.optional (inputs ? nix-index-database) ./_content.nix;
}
