{ inputs, lib, ... }:
{
  imports = lib.optional (inputs ? jovian-nixos) ./_jovian.nix;
}
