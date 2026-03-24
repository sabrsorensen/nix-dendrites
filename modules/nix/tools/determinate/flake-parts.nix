{
  inputs,
  lib,
  ...
}:
{
  # Determinate Nix is Determinate Systems' validated and secure downstream distribution of NixOS/nix.
  # https://determinate.systems/nix/

  flake-file.inputs = {
    nixpkgs.url = lib.mkForce "https://flakehub.com/f/NixOS/nixpkgs/0";
    # Determinate 3.* module
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    };
  };

  imports = lib.optional (inputs ? determinate) ./_determinate.nix;
}
