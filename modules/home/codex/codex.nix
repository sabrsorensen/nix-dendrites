{ inputs, ... }:
let
  homeModule = import ./_codex.nix { inherit inputs; };
in
{
  flake-file.inputs = {
    codex-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
  };

  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.codex = homeModule;

  flake.modules.nixos.codex =
    { lib, ... }:
    {
      options.my.host.features.codex = lib.mkEnableOption "Codex CLI";
    };
}
