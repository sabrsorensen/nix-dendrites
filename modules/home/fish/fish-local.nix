{ ... }:
let
  homeModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.fish.local.enable = lib.mkEnableOption "Fish local helpers";
      config = lib.mkIf (config.my.features.fish && config.my.fish.local.enable) {
        programs.fish.functions = import ./_functions/_maintenance.nix { };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.fish-local = homeModule;
}
