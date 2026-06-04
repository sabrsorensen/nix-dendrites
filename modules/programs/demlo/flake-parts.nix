{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.demlo = {
    url = "github:sabrsorensen/demlo/v3.8.1";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = lib.optional (inputs ? demlo) ./_demlo.nix;
}
