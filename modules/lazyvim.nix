{ inputs, lib, ... }:
{
  imports = lib.optional (inputs ? lazyvim) ./_lazyvim.nix;
}
