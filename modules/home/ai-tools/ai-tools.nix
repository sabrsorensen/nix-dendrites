{ inputs, lib, ... }:
let
  homeModule = import ./_ai-tools.nix { inherit inputs; };
in
{
  flake-file.inputs = {
      context-mode = {
        url = "github:mksglu/context-mode";
        flake = false;
      };
      superpowers = {
        url = "github:obra/superpowers";
        flake = false;
      };
    };

  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.ai-tools = homeModule;

  flake.modules.nixos.ai-tools =
    { lib, ... }:
    {
      options.my.host.features.ai-tools =
        lib.mkEnableOption "Tools for AI tools (Claude, Codex, etc)";
    };
}
