{
  inputs,
  lib,
  ...
}:
{
  # Determinate Nix is Determinate Systems' validated and secure downstream distribution of NixOS/nix.
  # https://determinate.systems/nix/

  flake-file.inputs = {
    # Determinate 3.* module
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    };
  };

  imports = lib.optional (inputs ? determinate) ./_determinate.nix;
}
