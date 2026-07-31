{ inputs, lib, ... }:
{
  flake-file.inputs.impermanence = {
    url = "https://flakehub.com/f/nix-community/impermanence/*";
    inputs.home-manager.follows = "home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # The option provider must be imported before a host can use persistence.
  # Configuration remains fact-gated in the delayed broadcast module.
  imports = lib.optional (inputs ? impermanence) ./_content.nix;
}
