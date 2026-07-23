{ inputs, lib, ... }:
{
  # The option provider must be imported before a host can use persistence.
  # Configuration remains fact-gated in the delayed broadcast module.
  imports = lib.optional (inputs ? impermanence) ./_impermanence.nix;
}
