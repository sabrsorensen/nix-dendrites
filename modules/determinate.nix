{ inputs, lib, ... }:
{
  imports = lib.optional (inputs ? determinate) ./_determinate.nix;
}
