{ inputs, lib, ... }:
{
  flake-file.inputs = {
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    };
  };

  imports = lib.optional (inputs ? determinate) ./_determinate.nix;
}
