{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.lazyvim = {
    url = "github:pfassina/lazyvim-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = lib.optional (inputs ? lazyvim) ./_lazyvim.nix;
}
