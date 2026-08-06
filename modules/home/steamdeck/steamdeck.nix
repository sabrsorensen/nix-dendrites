{ inputs, ... }:
let
  homeModule = { pkgs, ... }@args: import ./_content.nix (args // { inherit inputs pkgs; });
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.steamdeck = lib.mkEnableOption "steamdeck";
      config = lib.mkIf config.my.features.steamdeck (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.steamdeck = featureModule;
}
