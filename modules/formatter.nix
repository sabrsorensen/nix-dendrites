{ inputs, lib, ... }:
{
  # treefmt's flake module is consumed only after flake-file bootstrap.
  imports = lib.optional (inputs ? treefmt-nix) ./_formatter.nix;
}
