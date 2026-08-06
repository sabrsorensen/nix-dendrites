{ ... }:
let
  homeModule = import ./_content.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.tmux = lib.mkEnableOption "Tmux";
      config = lib.mkIf config.my.features.tmux homeModule;
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.tmux = featureModule;
}
