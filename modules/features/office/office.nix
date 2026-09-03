{ ... }:
let
  homeModule = import ./_office.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.office = lib.mkEnableOption "Office applications";
      config = lib.mkIf config.my.features.office (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.office = featureModule;

  flake.modules.nixos.office =
    { lib, ... }:
    {
      options.my.host.features.office = lib.mkEnableOption "office tools";
    };
}
