{ ... }:
let
  homeModule = import ./_vim.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.vim = lib.mkEnableOption "Vim";
      config = lib.mkIf config.my.features.vim (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.vim = featureModule;
}
