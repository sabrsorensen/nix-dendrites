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
      options.my.fish.steamdeck.enable = lib.mkEnableOption "Fish Steam Deck helpers";
      config = lib.mkIf (config.my.features.fish && config.my.fish.steamdeck.enable) {
        programs.fish.functions = import ./_functions/_steamdeck.nix { };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.fish-steamdeck = homeModule;
}
