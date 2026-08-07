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
      options.my.fish.rpi.enable = lib.mkEnableOption "Fish Raspberry Pi helpers";
      config = lib.mkIf (config.my.features.fish && config.my.fish.rpi.enable) {
        programs.fish.functions = import ./_functions/_rpi.nix { };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.fish-rpi = homeModule;
}
