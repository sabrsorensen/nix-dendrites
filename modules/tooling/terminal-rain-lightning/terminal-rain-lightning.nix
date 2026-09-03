{ inputs, ... }:
{
  flake-file.inputs.terminal-rain-lightning = {
    url = "github:delta-psi/terminal-rain-lightning-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.terminal-rain-lightning =
    args@{ pkgs, ... }: import ./_terminal-rain-lightning.nix (args // { inherit inputs; });
}
