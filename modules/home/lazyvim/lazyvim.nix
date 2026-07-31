{ inputs, lib, ... }:
{
  flake-file.inputs.lazyvim = {
    url = "github:pfassina/lazyvim-nix";
    inputs.flake-utils.follows = "flake-utils";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = lib.optional (inputs ? lazyvim) ./_content.nix;
}
