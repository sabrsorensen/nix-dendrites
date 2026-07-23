{ inputs, lib, ... }:
{
  # flake-file makes the input available after bootstrap; delay consumption so
  # this source module remains safe during flake generation.
  imports = lib.optional (inputs ? nix-flatpak) ./_flatpak.nix;
}
