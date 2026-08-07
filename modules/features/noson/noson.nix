{ ... }:
let
  homeModule = import ./_noson-home.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.noson = lib.mkEnableOption "Noson";
      config = lib.mkIf config.my.features.noson (homeModule args);
    };
  nixosModule = import ./_noson-nixos.nix;
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.noson = featureModule;

  flake.modules.nixos.noson =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.features.noson && config.my.host.home.enable) (nixosModule args);
}
