{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = lib.optional (inputs ? disko) ./_disko.nix;
}
