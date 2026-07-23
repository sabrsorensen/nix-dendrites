{ inputs, lib, ... }:
{
  imports = lib.optional (inputs ? sops-nix) ./_secrets.nix;
}
