{ inputs, lib, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = lib.optional (inputs ? disko) ./_disko.nix;
}
