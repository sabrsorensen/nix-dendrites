{ inputs, lib, ... }:
{
  # Keep the integration and its inputs together.  The temporary nix-src input
  # makes Determinate's bundled Nix follow PR #569, which fixes the ssh-ng
  # protocol corruption caused by a stale multiplexed SSH master connection.
  flake-file.inputs = {
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nix.follows = "determinate-nix-src-ssh-fix";
    };
    determinate-nix-src-ssh-fix.url = "github:DeterminateSystems/nix-src/main";
  };

  imports = lib.optional (inputs ? determinate) ./_determinate.nix;
}
