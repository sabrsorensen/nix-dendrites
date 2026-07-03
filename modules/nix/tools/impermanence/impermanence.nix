{
  inputs,
  lib,
  ...
}:
{
  # Modules to help you handle persistent state on systems with ephemeral root storage
  # https://github.com/nix-community/impermanence

  flake-file.inputs = {
    impermanence = {
      url = "https://flakehub.com/f/nix-community/impermanence/*";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = lib.optional (inputs ? impermanence) ./_impermanence.nix;
}
