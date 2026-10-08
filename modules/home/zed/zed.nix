{ ... }:
let
  homeModule = import ./_zed.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.zed = lib.mkEnableOption "Zed";
      config = lib.mkIf config.my.features.zed (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.zed = featureModule;

  flake.modules.nixos.zed =
    { lib, ... }:
    {
      options.my.host.features.zed = lib.mkEnableOption "the declarative Zed editor profile";
    };
}
