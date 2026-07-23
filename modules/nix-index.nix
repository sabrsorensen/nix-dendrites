{ inputs, lib, ... }:
{
  imports = lib.optional (inputs ? nix-index-database) ./_nix-index.nix;
}
