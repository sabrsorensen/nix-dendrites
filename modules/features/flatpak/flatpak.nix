{ inputs, lib, ... }:
{
  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak";

  # flake-file makes the input available after bootstrap; delay consumption so
  # this source module remains safe during flake generation.
  imports = lib.optional (inputs ? nix-flatpak) ./_flatpak-module.nix;
}
