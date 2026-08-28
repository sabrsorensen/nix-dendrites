{ inputs, ... }:
let
  homeModule = import ./_claude-code.nix { inherit inputs; };
in
{
  flake-file.inputs = {
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
  };

  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.claude-code = homeModule;

  flake.modules.nixos.claude-code =
    { lib, ... }:
    {
      options.my.host.features.claudeCode = lib.mkEnableOption "Claude Code";
    };
}
