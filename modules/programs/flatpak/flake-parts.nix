{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };
  };

  imports = lib.optional (inputs ? nix-flatpak) ./_flatpak.nix;
}
