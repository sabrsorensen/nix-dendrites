{ ... }:
let
  homeModule =
    { config, lib, ... }:
    {
      options.my.features.wslFish = lib.mkEnableOption "WSL Fish integration";
      config = lib.mkIf config.my.features.wslFish {
        programs.fish = import ./_wsl-fish-module.nix { };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.wsl-fish = homeModule;
}
