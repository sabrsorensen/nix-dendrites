{ inputs, lib, ... }:
{
  flake-file.inputs.treefmt-nix = {
    url = "https://flakehub.com/f/numtide/treefmt-nix/*";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # treefmt's flake module is consumed only after flake-file bootstrap.
  imports = lib.optional (inputs ? treefmt-nix) ./_content.nix;
}
