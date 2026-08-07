{ ... }:
let
  homeModule = import ./_starship.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.starship = lib.mkEnableOption "starship";
      config = lib.mkIf config.my.features.starship (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.starship = featureModule;
}
