{ inputs, lib, ... }:
{
  imports = lib.optional (inputs ? disko) ./_disko.nix;
}
