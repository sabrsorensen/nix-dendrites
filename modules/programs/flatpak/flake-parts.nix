{
  inputs,
  lib,
  ...
}:
{
  # Manage a user environment using Nix
  # https://github.com/nix-community/home-manager

  flake-file.inputs = {
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };
  };

  imports = lib.optional (inputs ? nix-flatpak) ./_flatpak.nix;
}
