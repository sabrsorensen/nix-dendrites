{ ... }:
let
  homeModule = { ... }: {
    programs.direnv = import ./_content.nix;
  };
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.direnv = lib.mkEnableOption "Direnv";
      config = lib.mkIf config.my.features.direnv (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.direnv = featureModule;
}
