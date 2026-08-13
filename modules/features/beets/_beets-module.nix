{ ... }:
let
  homeModule = import ./_beets.nix;
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

  flake.modules.nixos.beets =
    { lib, ... }:
    {
      options.my.host.features.beets = lib.mkEnableOption "Beets music-library management";
    };
}
