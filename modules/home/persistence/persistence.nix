{ ... }:
let
  homeModule = import ./_persistence.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.persistence = lib.mkEnableOption "Home persistence";
      config = lib.mkIf config.my.features.persistence (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.persistence = featureModule;
}
