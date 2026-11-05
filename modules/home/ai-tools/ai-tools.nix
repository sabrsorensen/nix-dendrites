{ inputs, ... }:
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
    { config, lib, ... }:
    lib.mkIf (config.my.host.features.claudeCode || config.my.host.features.codex) {
      # Home Manager uses the global pkgs, and rtk is licensed asl20 + bsl11.
      my.unfreePackageNames = [ "rtk" ];
    };
}
