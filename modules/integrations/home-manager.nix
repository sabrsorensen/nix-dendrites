{ inputs, lib, ... }:
{
  imports = lib.optional (inputs ? home-manager) ./_home-manager.nix;
}
