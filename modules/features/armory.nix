{ inputs, lib, ... }:
{
  imports = lib.optional (inputs ? armory-runtime-nixpkgs) ./_armory.nix;
}
