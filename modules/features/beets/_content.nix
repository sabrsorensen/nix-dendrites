{ ... }:
let
  homeModule = import ./_home-content.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.beets = lib.mkEnableOption "Beets";
      config = lib.mkIf config.my.features.beets (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.beets = featureModule;
}
