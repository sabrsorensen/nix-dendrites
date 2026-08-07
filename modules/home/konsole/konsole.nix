{ ... }:
let
  homeModule = import ./_konsole.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.konsole = lib.mkEnableOption "Konsole";
      config = lib.mkIf config.my.features.konsole (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.konsole = featureModule;
}
